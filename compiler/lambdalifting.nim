#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements lambda lifting for the transformator.

import
  intsets, strutils, options, ast, astalgo, msgs,
  idents, renderer, types, magicsys, lowerings, tables, modulegraphs, lineinfos,
  transf, liftdestructors

discard """
  The basic approach is that captured vars need to be put on the heap and
  that the calling chain needs to be explicitly modelled. Things to consider:

  proc a =
    var v = 0
    proc b =
      var w = 2

      for x in 0..3:
        proc c = capture v, w, x
        c()
    b()

    for x in 0..4:
      proc d = capture x
      d()

  Needs to be translated into:

  proc a =
    var cl: *
    new cl
    cl.v = 0

    proc b(cl) =
      var bcl: *
      new bcl
      bcl.w = 2
      bcl.up = cl

      for x in 0..3:
        var bcl2: *
        new bcl2
        bcl2.up = bcl
        bcl2.up2 = cl
        bcl2.x = x

        proc c(cl) = capture cl.up2.v, cl.up.w, cl.x
        c(bcl2)

      c(bcl)

    b(cl)

    for x in 0..4:
      var acl2: *
      new acl2
      acl2.x = x
      proc d(cl) = capture cl.x
      d(acl2)

  Closures as interfaces:

  proc outer: T =
    var captureMe: TObject # value type required for efficiency
    proc getter(): int = result = captureMe.x
    proc setter(x: int) = captureMe.x = x

    result = (getter, setter)

  Is translated to:

  proc outer: T =
    var cl: *
    new cl

    proc getter(cl): int = result = cl.captureMe.x
    proc setter(cl: *, x: int) = cl.captureMe.x = x

    result = ((cl, getter), (cl, setter))


  For 'byref' capture, the outer proc needs to access the captured var through
  the indirection too. For 'bycopy' capture, the outer proc accesses the var
  not through the indirection.

  Possible optimizations:

  1) If the closure contains a single 'ref' and this
  reference is not re-assigned (check ``sfAddrTaken`` flag) make this the
  closure. This is an important optimization if closures are used as
  interfaces.
  2) If the closure does not escape, put it onto the stack, not on the heap.
  3) Dataflow analysis would help to eliminate the 'up' indirections.
  4) If the captured var is not actually used in the outer proc (common?),
  put it into an inner proc.

"""

# Important things to keep in mind:
# * Don't base the analysis on nkProcDef et al. This doesn't work for
#   instantiated (formerly generic) procs. The analysis has to look at nkSym.
#   This also means we need to prevent the same proc is processed multiple
#   times via the 'processed' set.
# * Keep in mind that the owner of some temporaries used to be unreliable.
# * For closure iterators we merge the "real" potential closure with the
#   local storage requirements for efficiency. This means closure iterators
#   have slightly different semantics from ordinary closures.

# ---------------- essential helpers -------------------------------------

const
  upName* = ":up" # field name for the 'up' reference
  paramName* = ":envP"
  envName* = ":env"

proc newCall(a: PSym, b: PNode): PNode =
  result = newNodeI(nkCall, a.info)
  result.add newSymNode(a)
  result.add b

proc createClosureIterStateType*(g: ModuleGraph; iter: PSym): PType =
  var n = newNodeI(nkRange, iter.info)
  addSon(n, newIntNode(nkIntLit, -1))
  addSon(n, newIntNode(nkIntLit, 0))
  result = newType(tyRange, iter)
  result.n = n
  var intType = nilOrSysInt(g)
  if intType.isNil: intType = newType(tyInt, iter)
  rawAddSon(result, intType)

proc createStateField(g: ModuleGraph; iter: PSym): PSym =
  result = newSym(skField, getIdent(g.cache, ":state"), iter, iter.info)
  result.typ = createClosureIterStateType(g, iter)

proc createEnvObj(g: ModuleGraph; owner: PSym; info: TLineInfo): PType =
  # YYY meh, just add the state field for every closure for now, it's too
  # hard to figure out if it comes from a closure iterator:
  result = createObj(g, owner, info, final=false)
  rawAddField(result, createStateField(g, owner))

proc getClosureIterResult*(g: ModuleGraph; iter: PSym): PSym =
  if resultPos < iter.ast.len:
    result = iter.ast.sons[resultPos].sym
  else:
    # XXX a bit hacky:
    result = newSym(skResult, getIdent(g.cache, ":result"), iter, iter.info, {})
    result.typ = iter.typ.sons[0]
    incl(result.flags, sfUsed)
    iter.ast.add newSymNode(result)

proc addHiddenParam(routine: PSym, param: PSym) =
  assert param.kind == skParam
  var params = routine.ast.sons[paramsPos]
  # -1 is correct here as param.position is 0 based but we have at position 0
  # some nkEffect node:
  param.position = routine.typ.n.len-1
  addSon(params, newSymNode(param))
  #incl(routine.typ.flags, tfCapturesEnv)
  assert sfFromGeneric in param.flags
  #echo "produced environment: ", param.id, " for ", routine.id

proc getHiddenParam(g: ModuleGraph; routine: PSym): PSym =
  let params = routine.ast.sons[paramsPos]
  let hidden = lastSon(params)
  if hidden.kind == nkSym and hidden.sym.kind == skParam and hidden.sym.name.s == paramName:
    result = hidden.sym
    assert sfFromGeneric in result.flags
  else:
    # writeStackTrace()
    localError(g.config, routine.info, "internal error: could not find env param for " & routine.name.s)
    result = routine

proc getEnvParam*(routine: PSym): PSym =
  let params = routine.ast.sons[paramsPos]
  let hidden = lastSon(params)
  if hidden.kind == nkSym and hidden.sym.name.s == paramName:
    result = hidden.sym
    assert sfFromGeneric in result.flags

proc interestingVar(s: PSym): bool {.inline.} =
  result = s.kind in {skVar, skLet, skTemp, skForVar, skParam, skResult} and
    sfGlobal notin s.flags and
    s.typ.kind notin {tyStatic, tyTypeDesc}

proc illegalCapture(s: PSym): bool {.inline.} =
  result = skipTypes(s.typ, abstractInst).kind in
                   {tyVar, tyOpenArray, tyVarargs, tyLent} or
      s.kind == skResult

proc isInnerProc(s: PSym): bool =
  if s.kind in {skProc, skFunc, skMethod, skConverter, skIterator} and s.magic == mNone:
    result = s.skipGenericOwner.kind in routineKinds

proc newAsgnStmt(le, ri: PNode, info: TLineInfo): PNode =
  # Bugfix: unfortunately we cannot use 'nkFastAsgn' here as that would
  # mean to be able to capture string literals which have no GC header.
  # However this can only happen if the capture happens through a parameter,
  # which is however the only case when we generate an assignment in the first
  # place.
  result = newNodeI(nkAsgn, info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc makeClosure*(g: ModuleGraph; prc: PSym; env: PNode; info: TLineInfo): PNode =
  result = newNodeIT(nkClosure, info, prc.typ)
  result.add(newSymNode(prc))
  if env == nil:
    result.add(newNodeIT(nkNilLit, info, getSysType(g, info, tyNil)))
  else:
    if env.skipConv.kind == nkClosure:
      localError(g.config, info, "internal error: taking closure of closure")
    result.add(env)

proc interestingIterVar(s: PSym): bool {.inline.} =
  # XXX optimization: Only lift the variable if it lives across
  # yield/return boundaries! This can potentially speed up
  # closure iterators quite a bit.
  result = s.kind in {skResult, skVar, skLet, skTemp, skForVar} and sfGlobal notin s.flags

template isIterator*(owner: PSym): bool =
  owner.kind == skIterator and owner.typ.callConv == ccClosure

proc liftingHarmful(conf: ConfigRef; owner: PSym): bool {.inline.} =
  ## lambda lifting can be harmful for JS-like code generators.
  let isCompileTime = sfCompileTime in owner.flags or owner.kind == skMacro
  result = conf.cmd == cmdCompileToJS and not isCompileTime

proc liftIterSym*(g: ModuleGraph; n: PNode; owner: PSym): PNode =
  # transforms  (iter)  to  (let env = newClosure[iter](); (iter, env))
  if liftingHarmful(g.config, owner): return n
  let iter = n.sym
  assert iter.isIterator

  result = newNodeIT(nkStmtListExpr, n.info, n.typ)

  let hp = getHiddenParam(g, iter)
  var env: PNode
  if owner.isIterator:
    let it = getHiddenParam(g, owner)
    addUniqueField(it.typ.skipTypes({tyOwned}).sons[0], hp, g.cache)
    env = indirectAccess(newSymNode(it), hp, hp.info)
  else:
    let e = newSym(skLet, iter.name, owner, n.info)
    e.typ = hp.typ
    e.flags = hp.flags
    env = newSymNode(e)
    var v = newNodeI(nkVarSection, n.info)
    addVar(v, env)
    result.add(v)
  # add 'new' statement:
  result.add newCall(getSysSym(g, n.info, "internalNew"), env)
  if optOwnedRefs in g.config.globalOptions:
    createTypeBoundOps(g, nil, env.typ, n.info)
  result.add makeClosure(g, iter, env, n.info)

proc freshVarForClosureIter*(g: ModuleGraph; s, owner: PSym): PNode =
  let envParam = getHiddenParam(g, owner)
  let obj = envParam.typ.skipTypes({tyOwned, tyRef, tyPtr})
  addField(obj, s, g.cache)

  var access = newSymNode(envParam)
  assert obj.kind == tyObject
  let field = getFieldFromObj(obj, s)
  if field != nil:
    result = rawIndirectAccess(access, field, s.info)
  else:
    localError(g.config, s.info, "internal error: cannot generate fresh variable")
    result = access

# ------------------ new stuff -------------------------------------------

proc markAsClosure(g: ModuleGraph; owner: PSym; n: PNode) =
  let s = n.sym
  if illegalCapture(s):
    localError(g.config, n.info,
      ("'$1' is of type <$2> which cannot be captured as it would violate memory" &
       " safety, declared here: $3") % [s.name.s, typeToString(s.typ), g.config$s.info])
  elif owner.typ.callConv notin {ccClosure, ccDefault}:
    localError(g.config, n.info, "illegal capture '$1' because '$2' has the calling convention: <$3>" %
      [s.name.s, owner.name.s, CallingConvToStr[owner.typ.callConv]])
  incl(owner.typ.flags, tfCapturesEnv)
  owner.typ.callConv = ccClosure

type
  DetectionPass = object
    processed, capturedVars: IntSet
    ownerToType: Table[int, PType]
    somethingToDo, noDestructors: bool
    graph: ModuleGraph

proc initDetectionPass(g: ModuleGraph; fn: PSym): DetectionPass =
  result.processed = initIntSet()
  result.capturedVars = initIntSet()
  result.ownerToType = initTable[int, PType]()
  result.processed.incl(fn.id)
  result.graph = g

discard """
proc outer =
  var a, b: int
  proc innerA = use(a)
  proc innerB = use(b); innerA()
# --> innerA and innerB need to *share* the closure type!
This is why need to store the 'ownerToType' table and use it
during .closure'fication.
"""

proc getEnvTypeForOwner(c: var DetectionPass; owner: PSym;
                        info: TLineInfo): PType =
  result = c.ownerToType.getOrDefault(owner.id)
  if result.isNil:
    result = newType(tyRef, owner)
    let obj = createEnvObj(c.graph, owner, info)
    rawAddSon(result, obj)
    c.ownerToType[owner.id] = result

proc asOwnedRef(c: DetectionPass; t: PType): PType =
  if optOwnedRefs in c.graph.config.globalOptions:
    assert t.kind == tyRef
    result = newType(tyOwned, t.owner)
    result.flags.incl tfHasOwned
    result.rawAddSon t
  else:
    result = t

proc getEnvTypeForOwnerUp(c: var DetectionPass; owner: PSym;
                          info: TLineInfo): PType =
  var r = c.getEnvTypeForOwner(owner, info)
  result = newType(tyPtr, owner)
  rawAddSon(result, r.skipTypes({tyOwned, tyRef, tyPtr}))

proc createUpField(c: var DetectionPass; dest, dep: PSym; info: TLineInfo) =
  let refObj = c.getEnvTypeForOwner(dest, info) # getHiddenParam(dest).typ
  let obj = refObj.skipTypes({tyOwned, tyRef, tyPtr})
  # The assumption here is that gcDestructors means we cannot deal
  # with cycles properly, so it's better to produce a weak ref (=ptr) here.
  # This seems to be generally correct but since it's a bit risky it's disabled
  # for now.
  let fieldType = if isDefined(c.graph.config, "nimCycleBreaker"):
                    c.getEnvTypeForOwnerUp(dep, info) #getHiddenParam(dep).typ
                  else:
                    c.getEnvTypeForOwner(dep, info)
  if refObj == fieldType:
    localError(c.graph.config, dep.info, "internal error: invalid up reference computed")

  let upIdent = getIdent(c.graph.cache, upName)
  let upField = lookupInRecord(obj.n, upIdent)
  if upField != nil:
    if upField.typ.skipTypes({tyOwned, tyRef, tyPtr}) != fieldType.skipTypes({tyOwned, tyRef, tyPtr}):
      localError(c.graph.config, dep.info, "internal error: up references do not agree")
  else:
    let result = newSym(skField, upIdent, obj.owner, obj.owner.info)
    result.typ = fieldType
    rawAddField(obj, result)

discard """
There are a couple of possibilities of how to implement closure
iterators that capture outer variables in a traditional sense
(aka closure closure iterators).

1. Transform iter() to  iter(state, capturedEnv). So use 2 hidden
   parameters.
2. Add the captured vars directly to 'state'.
3. Make capturedEnv an up-reference of 'state'.

We do (3) here because (2) is obviously wrong and (1) is wrong too.
Consider:

  proc outer =
    var xx = 9

    iterator foo() =
      var someState = 3

      proc bar = echo someState
      proc baz = someState = 0
      baz()
      bar()

"""

proc addClosureParam(c: var DetectionPass; fn: PSym; info: TLineInfo) =
  var cp = getEnvParam(fn)
  let owner = if fn.kind == skIterator: fn else: fn.skipGenericOwner
  let t = c.getEnvTypeForOwner(owner, info)
  if cp == nil:
    cp = newSym(skParam, getIdent(c.graph.cache, paramName), fn, fn.info)
    incl(cp.flags, sfFromGeneric)
    cp.typ = t
    addHiddenParam(fn, cp)
  elif cp.typ != t and fn.kind != skIterator:
    localError(c.graph.config, fn.info, "internal error: inconsistent environment type")
  #echo "adding closure to ", fn.name.s

proc detectCapturedVars(n: PNode; owner: PSym; c: var DetectionPass) =
  case n.kind
  of nkSym:
    let s = n.sym
    if s.kind in {skProc, skFunc, skMethod, skConverter, skIterator} and
        s.typ != nil and s.typ.callConv == ccClosure:
      # this handles the case that the inner proc was declared as
      # .closure but does not actually capture anything:
      addClosureParam(c, s, n.info)
      c.somethingToDo = true

    let innerProc = isInnerProc(s)
    if innerProc:
      if s.isIterator: c.somethingToDo = true
      if not c.processed.containsOrIncl(s.id):
        let body = transformBody(c.graph, s, cache = true,
                                 noDestructors = c.noDestructors)
        detectCapturedVars(body, s, c)
    let ow = s.skipGenericOwner
    if ow == owner:
      if owner.isIterator:
        c.somethingToDo = true
        addClosureParam(c, owner, n.info)
        if interestingIterVar(s):
          if not c.capturedVars.containsOrIncl(s.id):
            let obj = getHiddenParam(c.graph, owner).typ.skipTypes({tyOwned, tyRef, tyPtr})
            #let obj = c.getEnvTypeForOwner(s.owner).skipTypes({tyOwned, tyRef, tyPtr})

            if s.name.id == getIdent(c.graph.cache, ":state").id:
              obj.n[0].sym.id = -s.id
            else:
              addField(obj, s, c.graph.cache)
    # direct or indirect dependency:
    elif (innerProc and s.typ.callConv == ccClosure) or interestingVar(s):
      discard """
        proc outer() =
          var x: int
          proc inner() =
            proc innerInner() =
              echo x
            innerInner()
          inner()
        # inner() takes a closure too!
      """
      # mark 'owner' as taking a closure:
      c.somethingToDo = true
      markAsClosure(c.graph, owner, n)
      addClosureParam(c, owner, n.info)
      #echo "capturing ", n.info
      # variable 's' is actually captured:
      if interestingVar(s) and not c.capturedVars.containsOrIncl(s.id):
        let obj = c.getEnvTypeForOwner(ow, n.info).skipTypes({tyOwned, tyRef, tyPtr})
        #getHiddenParam(owner).typ.skipTypes({tyOwned, tyRef, tyPtr})
        addField(obj, s, c.graph.cache)
      # create required upFields:
      var w = owner.skipGenericOwner
      if isInnerProc(w) or owner.isIterator:
        if owner.isIterator: w = owner
        let last = if ow.isIterator: ow.skipGenericOwner else: ow
        while w != nil and w.kind != skModule and last != w:
          discard """
          proc outer =
            var a, b: int
            proc outerB =
              proc innerA = use(a)
              proc innerB = use(b); innerA()
          # --> make outerB of calling convention .closure and
          # give it the same env type that outer's env var gets:
          """
          let up = w.skipGenericOwner
          #echo "up for ", w.name.s, " up ", up.name.s
          markAsClosure(c.graph, w, n)
          addClosureParam(c, w, n.info) # , ow
          createUpField(c, w, up, n.info)
          w = up
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit,
     nkTemplateDef, nkTypeSection, nkProcDef, nkMethodDef,
     nkConverterDef, nkMacroDef, nkFuncDef, nkCommentStmt, nkTypeOfExpr:
    discard
  of nkLambdaKinds, nkIteratorDef:
    if n.typ != nil:
      detectCapturedVars(n[namePos], owner, c)
  of nkReturnStmt:
    detectCapturedVars(n[0], owner, c)
  else:
    for i in 0..<n.len:
      detectCapturedVars(n[i], owner, c)

type
  LiftingPass = object
    processed: IntSet
    envVars: Table[int, PNode]
    inContainer: int
    unownedEnvVars: Table[int, PNode] # only required for --newruntime

proc initLiftingPass(fn: PSym): LiftingPass =
  result.processed = initIntSet()
  result.processed.incl(fn.id)
  result.envVars = initTable[int, PNode]()

proc accessViaEnvParam(g: ModuleGraph; n: PNode; owner: PSym): PNode =
  let s = n.sym
  # Type based expression construction for simplicity:
  let envParam = getHiddenParam(g, owner)
  if not envParam.isNil:
    var access = newSymNode(envParam)
    while true:
      let obj = access.typ.sons[0]
      assert obj.kind == tyObject
      let field = getFieldFromObj(obj, s)
      if field != nil:
        return rawIndirectAccess(access, field, n.info)
      let upField = lookupInRecord(obj.n, getIdent(g.cache, upName))
      if upField == nil: break
      access = rawIndirectAccess(access, upField, n.info)
  localError(g.config, n.info, "internal error: environment misses: " & s.name.s)
  result = n

proc newEnvVar(cache: IdentCache; owner: PSym; typ: PType; info: TLineInfo): PNode =
  var v = newSym(skVar, getIdent(cache, envName), owner, info)
  v.flags = {sfShadowed, sfGeneratedOp}
  v.typ = typ
  result = newSymNode(v)
  when false:
    if owner.kind == skIterator and owner.typ.callConv == ccClosure:
      let it = getHiddenParam(owner)
      addUniqueField(it.typ.sons[0], v)
      result = indirectAccess(newSymNode(it), v, v.info)
    else:
      result = newSymNode(v)

proc setupEnvVar(owner: PSym; d: DetectionPass;
                 c: var LiftingPass; info: TLineInfo): PNode =
  if owner.isIterator:
    return getHiddenParam(d.graph, owner).newSymNode
  result = c.envVars.getOrDefault(owner.id)
  if result.isNil:
    let envVarType = d.ownerToType.getOrDefault(owner.id)
    if envVarType.isNil:
      localError d.graph.config, owner.info, "internal error: could not determine closure type"
    result = newEnvVar(d.graph.cache, owner, asOwnedRef(d, envVarType), info)
    c.envVars[owner.id] = result
    if optOwnedRefs in d.graph.config.globalOptions:
      var v = newSym(skVar, getIdent(d.graph.cache, envName & "Alt"), owner, info)
      v.flags = {sfShadowed, sfGeneratedOp}
      v.typ = envVarType
      c.unownedEnvVars[owner.id] = newSymNode(v)

proc getUpViaParam(g: ModuleGraph; owner: PSym): PNode =
  let p = getHiddenParam(g, owner)
  result = p.newSymNode
  if owner.isIterator:
    let upField = lookupInRecord(p.typ.skipTypes({tyOwned, tyRef, tyPtr}).n, getIdent(g.cache, upName))
    if upField == nil:
      localError(g.config, owner.info, "could not find up reference for closure iter")
    else:
      result = rawIndirectAccess(result, upField, p.info)

proc rawClosureCreation(owner: PSym;
                        d: DetectionPass; c: var LiftingPass;
                        info: TLineInfo): PNode =
  result = newNodeI(nkStmtList, owner.info)

  var env: PNode
  if owner.isIterator:
    env = getHiddenParam(d.graph, owner).newSymNode
  else:
    env = setupEnvVar(owner, d, c, info)
    if env.kind == nkSym:
      var v = newNodeI(nkVarSection, env.info)
      addVar(v, env)
      result.add(v)
      if optOwnedRefs in d.graph.config.globalOptions:
        let unowned = c.unownedEnvVars[owner.id]
        assert unowned != nil
        addVar(v, unowned)

    # add 'new' statement:
    result.add(newCall(getSysSym(d.graph, env.info, "internalNew"), env))
    if optOwnedRefs in d.graph.config.globalOptions:
      let unowned = c.unownedEnvVars[owner.id]
      assert unowned != nil
      let env2 = copyTree(env)
      env2.typ = unowned.typ
      result.add newAsgnStmt(unowned, env2, env.info)
      createTypeBoundOps(d.graph, nil, unowned.typ, env.info)

    # add assignment statements for captured parameters:
    for i in 1..<owner.typ.n.len:
      let local = owner.typ.n[i].sym
      if local.id in d.capturedVars:
        let fieldAccess = indirectAccess(env, local, env.info)
        # add ``env.param = param``
        result.add(newAsgnStmt(fieldAccess, newSymNode(local), env.info))

  let upField = lookupInRecord(env.typ.skipTypes({tyOwned, tyRef, tyPtr}).n, getIdent(d.graph.cache, upName))
  if upField != nil:
    let up = getUpViaParam(d.graph, owner)
    if up != nil and upField.typ.skipTypes({tyOwned, tyRef, tyPtr}) == up.typ.skipTypes({tyOwned, tyRef, tyPtr}):
      result.add(newAsgnStmt(rawIndirectAccess(env, upField, env.info),
                 up, env.info))
    #elif oldenv != nil and oldenv.typ == upField.typ:
    #  result.add(newAsgnStmt(rawIndirectAccess(env, upField, env.info),
    #             oldenv, env.info))
    else:
      localError(d.graph.config, env.info, "internal error: cannot create up reference")
  # we are not in the sem'check phase anymore! so pass 'nil' for the PContext
  # and hope for the best:
  if optOwnedRefs in d.graph.config.globalOptions:
    createTypeBoundOps(d.graph, nil, env.typ, owner.info)

proc finishClosureCreation(owner: PSym; d: DetectionPass; c: LiftingPass;
                           info: TLineInfo; res: PNode) =
  if optOwnedRefs in d.graph.config.globalOptions:
    let unowned = c.unownedEnvVars[owner.id]
    assert unowned != nil
    let nilLit = newNodeIT(nkNilLit, info, unowned.typ)
    res.add newAsgnStmt(unowned, nilLit, info)

proc closureCreationForIter(iter: PNode;
                            d: DetectionPass; c: var LiftingPass): PNode =
  result = newNodeIT(nkStmtListExpr, iter.info, iter.sym.typ)
  let owner = iter.sym.skipGenericOwner
  var v = newSym(skVar, getIdent(d.graph.cache, envName), owner, iter.info)
  incl(v.flags, sfShadowed)
  v.typ = asOwnedRef(d, getHiddenParam(d.graph, iter.sym).typ)
  var vnode: PNode
  if owner.isIterator:
    let it = getHiddenParam(d.graph, owner)
    addUniqueField(it.typ.skipTypes({tyOwned, tyRef, tyPtr}), v, d.graph.cache)
    vnode = indirectAccess(newSymNode(it), v, v.info)
  else:
    vnode = v.newSymNode
    var vs = newNodeI(nkVarSection, iter.info)
    addVar(vs, vnode)
    result.add(vs)
  result.add(newCall(getSysSym(d.graph, iter.info, "internalNew"), vnode))
  if optOwnedRefs in d.graph.config.globalOptions:
    createTypeBoundOps(d.graph, nil, vnode.typ, iter.info)

  let upField = lookupInRecord(v.typ.skipTypes({tyOwned, tyRef, tyPtr}).n, getIdent(d.graph.cache, upName))
  if upField != nil:
    let u = setupEnvVar(owner, d, c, iter.info)
    if u.typ.skipTypes({tyOwned, tyRef, tyPtr}) == upField.typ.skipTypes({tyOwned, tyRef, tyPtr}):
      result.add(newAsgnStmt(rawIndirectAccess(vnode, upField, iter.info),
                 u, iter.info))
    else:
      localError(d.graph.config, iter.info, "internal error: cannot create up reference for iter")
  result.add makeClosure(d.graph, iter.sym, vnode, iter.info)

proc accessViaEnvVar(n: PNode; owner: PSym; d: DetectionPass;
                     c: var LiftingPass): PNode =
  var access = setupEnvVar(owner, d, c, n.info)
  if optOwnedRefs in d.graph.config.globalOptions:
    access = c.unownedEnvVars[owner.id]
  let obj = access.typ.skipTypes({tyOwned, tyRef, tyPtr})
  let field = getFieldFromObj(obj, n.sym)
  if field != nil:
    result = rawIndirectAccess(access, field, n.info)
  else:
    localError(d.graph.config, n.info, "internal error: not part of closure object type")
    result = n

proc getStateField*(g: ModuleGraph; owner: PSym): PSym =
  getHiddenParam(g, owner).typ.skipTypes({tyOwned, tyRef, tyPtr}).n.sons[0].sym

proc liftCapturedVars(n: PNode; owner: PSym; d: DetectionPass;
                      c: var LiftingPass): PNode

proc symToClosure(n: PNode; owner: PSym; d: DetectionPass;
                  c: var LiftingPass): PNode =
  let s = n.sym
  if s == owner:
    # recursive calls go through (lambda, hiddenParam):
    let available = getHiddenParam(d.graph, owner)
    result = makeClosure(d.graph, s, available.newSymNode, n.info)
  elif s.isIterator:
    result = closureCreationForIter(n, d, c)
  elif s.skipGenericOwner == owner:
    # direct dependency, so use the outer's env variable:
    result = makeClosure(d.graph, s, setupEnvVar(owner, d, c, n.info), n.info)
  else:
    let available = getHiddenParam(d.graph, owner)
    let wanted = getHiddenParam(d.graph, s).typ
    # ugh: call through some other inner proc;
    var access = newSymNode(available)
    while true:
      if access.typ == wanted:
        return makeClosure(d.graph, s, access, n.info)
      let obj = access.typ.skipTypes({tyOwned, tyRef, tyPtr})
      let upField = lookupInRecord(obj.n, getIdent(d.graph.cache, upName))
      if upField == nil:
        localError(d.graph.config, n.info, "internal error: no environment found")
        return n
      access = rawIndirectAccess(access, upField, n.info)

proc liftCapturedVars(n: PNode; owner: PSym; d: DetectionPass;
                      c: var LiftingPass): PNode =
  result = n
  case n.kind
  of nkSym:
    let s = n.sym
    if isInnerProc(s):
      if not c.processed.containsOrIncl(s.id):
        #if s.name.s == "temp":
        #  echo renderTree(s.getBody, {renderIds})
        let oldInContainer = c.inContainer
        c.inContainer = 0
        var body = transformBody(d.graph, s)
        body = liftCapturedVars(body, s, d, c)
        if c.envVars.getOrDefault(s.id).isNil:
          s.transformedBody = body
        else:
          s.transformedBody = newTree(nkStmtList, rawClosureCreation(s, d, c, n.info), body)
          finishClosureCreation(s, d, c, n.info, s.transformedBody)
        c.inContainer = oldInContainer

      if s.typ.callConv == ccClosure:
        result = symToClosure(n, owner, d, c)

    elif s.id in d.capturedVars:
      if s.owner != owner:
        result = accessViaEnvParam(d.graph, n, owner)
      elif owner.isIterator and interestingIterVar(s):
        result = accessViaEnvParam(d.graph, n, owner)
      else:
        result = accessViaEnvVar(n, owner, d, c)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit, nkComesFrom,
     nkTemplateDef, nkTypeSection, nkProcDef, nkMethodDef, nkConverterDef,
     nkMacroDef, nkFuncDef:
    discard
  of nkClosure:
    if n[1].kind == nkNilLit:
      n.sons[0] = liftCapturedVars(n[0], owner, d, c)
      let x = n.sons[0].skipConv
      if x.kind == nkClosure:
        #localError(n.info, "internal error: closure to closure created")
        # now we know better, so patch it:
        n.sons[0] = x.sons[0]
        n.sons[1] = x.sons[1]
  of nkLambdaKinds, nkIteratorDef:
    if n.typ != nil and n[namePos].kind == nkSym:
      let oldInContainer = c.inContainer
      c.inContainer = 0
      let m = newSymNode(n[namePos].sym)
      m.typ = n.typ
      result = liftCapturedVars(m, owner, d, c)
      c.inContainer = oldInContainer
  of nkHiddenStdConv:
    if n.len == 2:
      n.sons[1] = liftCapturedVars(n[1], owner, d, c)
      if n[1].kind == nkClosure: result = n[1]
  of nkReturnStmt:
    if n[0].kind in {nkAsgn, nkFastAsgn}:
      # we have a `result = result` expression produced by the closure
      # transform, let's not touch the LHS in order to make the lifting pass
      # correct when `result` is lifted
      n[0].sons[1] = liftCapturedVars(n[0].sons[1], owner, d, c)
    else:
      n.sons[0] = liftCapturedVars(n[0], owner, d, c)
  of nkTypeOfExpr:
    result = n
  else:
    if owner.isIterator:
      if nfLL in n.flags:
        # special case 'when nimVm' due to bug #3636:
        n.sons[1] = liftCapturedVars(n[1], owner, d, c)
        return

    let inContainer = n.kind in {nkObjConstr, nkBracket}
    if inContainer: inc c.inContainer
    for i in 0..<n.len:
      n.sons[i] = liftCapturedVars(n[i], owner, d, c)
    if inContainer: dec c.inContainer

# ------------------ old stuff -------------------------------------------

proc semCaptureSym*(s, owner: PSym) =
  discard """
    proc outer() =
      var x: int
      proc inner() =
        proc innerInner() =
          echo x
        innerInner()
      inner()
    # inner() takes a closure too!
  """
  proc propagateClosure(start, last: PSym) =
    var o = start
    while o != nil and o.kind != skModule:
      if o == last: break
      o.typ.callConv = ccClosure
      o = o.skipGenericOwner

  if interestingVar(s) and s.kind != skResult:
    if owner.typ != nil and not isGenericRoutine(owner):
      # XXX: is this really safe?
      # if we capture a var from another generic routine,
      # it won't be consider captured.
      var o = owner.skipGenericOwner
      while o != nil and o.kind != skModule:
        if s.owner == o:
          if owner.typ.callConv in {ccClosure, ccDefault} or owner.kind == skIterator:
            owner.typ.callConv = ccClosure
            propagateClosure(owner.skipGenericOwner, s.owner)
          else:
            discard "do not produce an error here, but later"
          #echo "computing .closure for ", owner.name.s, " because of ", s.name.s
        o = o.skipGenericOwner
    # since the analysis is not entirely correct, we don't set 'tfCapturesEnv'
    # here

proc liftIterToProc*(g: ModuleGraph; fn: PSym; body: PNode; ptrType: PType): PNode =
  var d = initDetectionPass(g, fn)
  var c = initLiftingPass(fn)
  # pretend 'fn' is a closure iterator for the analysis:
  let oldKind = fn.kind
  let oldCC = fn.typ.callConv
  fn.kind = skIterator
  fn.typ.callConv = ccClosure
  d.ownerToType[fn.id] = ptrType
  detectCapturedVars(body, fn, d)
  result = liftCapturedVars(body, fn, d, c)
  fn.kind = oldKind
  fn.typ.callConv = oldCC

proc liftLambdas*(g: ModuleGraph; fn: PSym, body: PNode; tooEarly: var bool;
                  noDestructors: bool): PNode =
  # XXX gCmd == cmdCompileToJS does not suffice! The compiletime stuff needs
  # the transformation even when compiling to JS ...

  # However we can do lifting for the stuff which is *only* compiletime.
  let isCompileTime = sfCompileTime in fn.flags or fn.kind == skMacro

  if body.kind == nkEmpty or (
      g.config.cmd == cmdCompileToJS and not isCompileTime) or
      fn.skipGenericOwner.kind != skModule:

    # ignore forward declaration:
    result = body
    tooEarly = true
  else:
    var d = initDetectionPass(g, fn)
    d.noDestructors = noDestructors
    detectCapturedVars(body, fn, d)
    if not d.somethingToDo and fn.isIterator:
      addClosureParam(d, fn, body.info)
      d.somethingToDo = true
    if d.somethingToDo:
      var c = initLiftingPass(fn)
      result = liftCapturedVars(body, fn, d, c)
      # echo renderTree(result, {renderIds})
      if c.envVars.getOrDefault(fn.id) != nil:
        result = newTree(nkStmtList, rawClosureCreation(fn, d, c, body.info), result)
        finishClosureCreation(fn, d, c, body.info, result)
    else:
      result = body
    #if fn.name.s == "get2":
    #  echo "had something to do ", d.somethingToDo
    #  echo renderTree(result, {renderIds})

proc liftLambdasForTopLevel*(module: PSym, body: PNode): PNode =
  # XXX implement it properly
  result = body

# ------------------- iterator transformation --------------------------------

proc liftForLoop*(g: ModuleGraph; body: PNode; owner: PSym): PNode =
  # problem ahead: the iterator could be invoked indirectly, but then
  # we don't know what environment to create here:
  #
  # iterator count(): int =
  #   yield 0
  #
  # iterator count2(): int =
  #   var x = 3
  #   yield x
  #   inc x
  #   yield x
  #
  # proc invoke(iter: iterator(): int) =
  #   for x in iter(): echo x
  #
  # --> When to create the closure? --> for the (count) occurrence!
  discard """
      for i in foo(): ...

    Is transformed to:

      cl = createClosure()
      while true:
        let i = foo(cl)
        if (nkBreakState(cl.state)):
          break
        ...
    """
  if liftingHarmful(g.config, owner): return body
  var L = body.len
  if not (body.kind == nkForStmt and body[L-2].kind in nkCallKinds):
    localError(g.config, body.info, "ignored invalid for loop")
    return body
  var call = body[L-2]

  result = newNodeI(nkStmtList, body.info)

  # static binding?
  var env: PSym
  let op = call[0]
  if op.kind == nkSym and op.sym.isIterator:
    # createClosure()
    let iter = op.sym

    let hp = getHiddenParam(g, iter)
    env = newSym(skLet, iter.name, owner, body.info)
    env.typ = hp.typ
    env.flags = hp.flags

    var v = newNodeI(nkVarSection, body.info)
    addVar(v, newSymNode(env))
    result.add(v)
    # add 'new' statement:
    result.add(newCall(getSysSym(g, env.info, "internalNew"), env.newSymNode))
    if optOwnedRefs in g.config.globalOptions:
      createTypeBoundOps(g, nil, env.typ, body.info)

  elif op.kind == nkStmtListExpr:
    let closure = op.lastSon
    if closure.kind == nkClosure:
      call.sons[0] = closure
      for i in 0 .. op.len-2:
        result.add op[i]

  var loopBody = newNodeI(nkStmtList, body.info, 3)
  var whileLoop = newNodeI(nkWhileStmt, body.info, 2)
  whileLoop.sons[0] = newIntTypeNode(1, getSysType(g, body.info, tyBool))
  whileLoop.sons[1] = loopBody
  result.add whileLoop

  # setup loopBody:
  # gather vars in a tuple:
  var v2 = newNodeI(nkLetSection, body.info)
  var vpart = newNodeI(if L == 3: nkIdentDefs else: nkVarTuple, body.info)
  for i in 0 .. L-3:
    if body[i].kind == nkSym:
      body[i].sym.kind = skLet
    addSon(vpart, body[i])

  addSon(vpart, newNodeI(nkEmpty, body.info)) # no explicit type
  if not env.isNil:
    call.sons[0] = makeClosure(g, call.sons[0].sym, env.newSymNode, body.info)
  addSon(vpart, call)
  addSon(v2, vpart)

  loopBody.sons[0] = v2
  var bs = newNodeI(nkBreakState, body.info)
  bs.addSon(call.sons[0])

  let ibs = newNodeI(nkIfStmt, body.info)
  let elifBranch = newNodeI(nkElifBranch, body.info)
  elifBranch.add(bs)

  let br = newNodeI(nkBreakStmt, body.info)
  br.add(g.emptyNode)

  elifBranch.add(br)
  ibs.add(elifBranch)

  loopBody.sons[1] = ibs
  loopBody.sons[2] = body[L-1]
