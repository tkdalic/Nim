#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## The compiler depends on the System module to work properly and the System
## module depends on the compiler. Most of the routines listed here use
## special compiler magic.
##
## Each module implicitly imports the System module; it must not be listed
## explicitly. Because of this there cannot be a user-defined module named
## ``system``.
##
## System module
## =============
##
## .. include:: ./system_overview.rst


type
  int* {.magic: Int.}         ## Default integer type; bitwidth depends on
                              ## architecture, but is always the same as a pointer.
  int8* {.magic: Int8.}       ## Signed 8 bit integer type.
  int16* {.magic: Int16.}     ## Signed 16 bit integer type.
  int32* {.magic: Int32.}     ## Signed 32 bit integer type.
  int64* {.magic: Int64.}     ## Signed 64 bit integer type.
  uint* {.magic: UInt.}       ## Unsigned default integer type.
  uint8* {.magic: UInt8.}     ## Unsigned 8 bit integer type.
  uint16* {.magic: UInt16.}   ## Unsigned 16 bit integer type.
  uint32* {.magic: UInt32.}   ## Unsigned 32 bit integer type.
  uint64* {.magic: UInt64.}   ## Unsigned 64 bit integer type.
  float* {.magic: Float.}     ## Default floating point type.
  float32* {.magic: Float32.} ## 32 bit floating point type.
  float64* {.magic: Float.}   ## 64 bit floating point type.

# 'float64' is now an alias to 'float'; this solves many problems

type # we need to start a new type section here, so that ``0`` can have a type
  bool* {.magic: Bool.} = enum ## Built-in boolean type.
    false = 0, true = 1

type
  char* {.magic: Char.}         ## Built-in 8 bit character type (unsigned).
  string* {.magic: String.}     ## Built-in string type.
  cstring* {.magic: Cstring.}   ## Built-in cstring (*compatible string*) type.
  pointer* {.magic: Pointer.}   ## Built-in pointer type, use the ``addr``
                                ## operator to get a pointer to a variable.

  typedesc* {.magic: TypeDesc.} ## Meta type to denote a type description.

const
  on* = true    ## Alias for ``true``.
  off* = false  ## Alias for ``false``.

{.push warning[GcMem]: off, warning[Uninit]: off.}
{.push hints: off.}

proc `or`*(a, b: typedesc): typedesc {.magic: "TypeTrait", noSideEffect.}
  ## Constructs an `or` meta class.

proc `and`*(a, b: typedesc): typedesc {.magic: "TypeTrait", noSideEffect.}
  ## Constructs an `and` meta class.

proc `not`*(a: typedesc): typedesc {.magic: "TypeTrait", noSideEffect.}
  ## Constructs an `not` meta class.

type
  Ordinal*[T] {.magic: Ordinal.} ## Generic ordinal type. Includes integer,
                                 ## bool, character, and enumeration types
                                 ## as well as their subtypes. Note `uint`
                                 ## and `uint64` are not ordinal types for
                                 ## implementation reasons.
  `ptr`*[T] {.magic: Pointer.}   ## Built-in generic untraced pointer type.
  `ref`*[T] {.magic: Pointer.}   ## Built-in generic traced pointer type.

  `nil` {.magic: "Nil".}

  void* {.magic: "VoidType".}    ## Meta type to denote the absence of any type.
  auto* {.magic: Expr.}          ## Meta type for automatic type determination.
  any* = distinct auto           ## Meta type for any supported type.
  untyped* {.magic: Expr.}       ## Meta type to denote an expression that
                                 ## is not resolved (for templates).
  typed* {.magic: Stmt.}         ## Meta type to denote an expression that
                                 ## is resolved (for templates).

  SomeSignedInt* = int|int8|int16|int32|int64
    ## Type class matching all signed integer types.

  SomeUnsignedInt* = uint|uint8|uint16|uint32|uint64
    ## Type class matching all unsigned integer types.

  SomeInteger* = SomeSignedInt|SomeUnsignedInt
    ## Type class matching all integer types.

  SomeOrdinal* = int|int8|int16|int32|int64|bool|enum|uint|uint8|uint16|uint32|uint64
    ## Type class matching all ordinal types; however this includes enums with
    ## holes.

  SomeFloat* = float|float32|float64
    ## Type class matching all floating point number types.

  SomeNumber* = SomeInteger|SomeFloat
    ## Type class matching all number types.

proc defined*(x: untyped): bool {.magic: "Defined", noSideEffect, compileTime.}
  ## Special compile-time procedure that checks whether `x` is
  ## defined.
  ##
  ## `x` is an external symbol introduced through the compiler's
  ## `-d:x switch <nimc.html#compiler-usage-compile-time-symbols>`_ to enable
  ## build time conditionals:
  ##
  ## .. code-block:: Nim
  ##   when not defined(release):
  ##     # Do here programmer friendly expensive sanity checks.
  ##   # Put here the normal code

when defined(nimHasRunnableExamples):
  proc runnableExamples*(body: untyped) {.magic: "RunnableExamples".}
    ## A section you should use to mark `runnable example`:idx: code with.
    ##
    ## - In normal debug and release builds code within
    ##   a ``runnableExamples`` section is ignored.
    ## - The documentation generator is aware of these examples and considers them
    ##   part of the ``##`` doc comment. As the last step of documentation
    ##   generation each runnableExample is put in its own file ``$file_examples$i.nim``,
    ##   compiled and tested. The collected examples are
    ##   put into their own module to ensure the examples do not refer to
    ##   non-exported symbols.
    ##
    ## Usage:
    ##
    ## .. code-block:: Nim
    ##   proc double*(x: int): int =
    ##     ## This proc doubles a number.
    ##     runnableExamples:
    ##       ## at module scope
    ##       assert double(5) == 10
    ##       block: ## at block scope
    ##         defer: echo "done"
    ##
    ##     result = 2 * x
else:
  template runnableExamples*(body: untyped) =
    discard

proc declared*(x: untyped): bool {.magic: "Defined", noSideEffect, compileTime.}
  ## Special compile-time procedure that checks whether `x` is
  ## declared. `x` has to be an identifier or a qualified identifier.
  ##
  ## See also:
  ## * `declaredInScope <#declaredInScope,untyped>`_
  ##
  ## This can be used to check whether a library provides a certain
  ## feature or not:
  ##
  ## .. code-block:: Nim
  ##   when not declared(strutils.toUpper):
  ##     # provide our own toUpper proc here, because strutils is
  ##     # missing it.

when defined(useNimRtl):
  {.deadCodeElim: on.}  # dce option deprecated

proc declaredInScope*(x: untyped): bool {.
  magic: "DefinedInScope", noSideEffect, compileTime.}
  ## Special compile-time procedure that checks whether `x` is
  ## declared in the current scope. `x` has to be an identifier.

proc `addr`*[T](x: var T): ptr T {.magic: "Addr", noSideEffect.} =
  ## Builtin `addr` operator for taking the address of a memory location.
  ## Cannot be overloaded.
  ##
  ## See also:
  ## * `unsafeAddr <#unsafeAddr,T>`_
  ##
  ## .. code-block:: Nim
  ##  var
  ##    buf: seq[char] = @['a','b','c']
  ##    p = buf[1].addr
  ##  echo p.repr # ref 0x7faa35c40059 --> 'b'
  ##  echo p[]    # b
  discard

proc unsafeAddr*[T](x: T): ptr T {.magic: "Addr", noSideEffect.} =
  ## Builtin `addr` operator for taking the address of a memory
  ## location. This works even for ``let`` variables or parameters
  ## for better interop with C and so it is considered even more
  ## unsafe than the ordinary `addr <#addr,T>`_.
  ##
  ## **Note**: When you use it to write a wrapper for a C library, you should
  ## always check that the original library does never write to data behind the
  ## pointer that is returned from this procedure.
  ##
  ## Cannot be overloaded.
  discard

when defined(nimNewTypedesc):
  type
    `static`*[T] {.magic: "Static".}
      ## Meta type representing all values that can be evaluated at compile-time.
      ##
      ## The type coercion ``static(x)`` can be used to force the compile-time
      ## evaluation of the given expression ``x``.

    `type`*[T] {.magic: "Type".}
      ## Meta type representing the type of all type values.
      ##
      ## The coercion ``type(x)`` can be used to obtain the type of the given
      ## expression ``x``.
else:
  proc `type`*(x: untyped): typedesc {.magic: "TypeOf", noSideEffect, compileTime.} =
    ## Builtin `type` operator for accessing the type of an expression.
    ## Cannot be overloaded.
    discard

when defined(nimHasTypeof):
  type
    TypeOfMode* = enum ## Possible modes of `typeof`.
      typeOfProc,      ## Prefer the interpretation that means `x` is a proc call.
      typeOfIter       ## Prefer the interpretation that means `x` is an iterator call.

  proc typeof*(x: untyped; mode = typeOfIter): typedesc {.
    magic: "TypeOf", noSideEffect, compileTime.} =
    ## Builtin `typeof` operation for accessing the type of an expression.
    ## Since version 0.20.0.
    discard

proc `not`*(x: bool): bool {.magic: "Not", noSideEffect.}
  ## Boolean not; returns true if ``x == false``.

proc `and`*(x, y: bool): bool {.magic: "And", noSideEffect.}
  ## Boolean ``and``; returns true if ``x == y == true`` (if both arguments
  ## are true).
  ##
  ## Evaluation is lazy: if ``x`` is false, ``y`` will not even be evaluated.
proc `or`*(x, y: bool): bool {.magic: "Or", noSideEffect.}
  ## Boolean ``or``; returns true if ``not (not x and not y)`` (if any of
  ## the arguments is true).
  ##
  ## Evaluation is lazy: if ``x`` is true, ``y`` will not even be evaluated.
proc `xor`*(x, y: bool): bool {.magic: "Xor", noSideEffect.}
  ## Boolean `exclusive or`; returns true if ``x != y`` (if either argument
  ## is true while the other is false).

const ThisIsSystem = true

proc internalNew*[T](a: var ref T) {.magic: "New", noSideEffect.}
  ## Leaked implementation detail. Do not use.

proc new*[T](a: var ref T, finalizer: proc (x: ref T) {.nimcall.}) {.
  magic: "NewFinalize", noSideEffect.}
  ## Creates a new object of type ``T`` and returns a safe (traced)
  ## reference to it in ``a``.
  ##
  ## When the garbage collector frees the object, `finalizer` is called.
  ## The `finalizer` may not keep a reference to the
  ## object pointed to by `x`. The `finalizer` cannot prevent the GC from
  ## freeing the object.
  ##
  ## **Note**: The `finalizer` refers to the type `T`, not to the object!
  ## This means that for each object of type `T` the finalizer will be called!

when defined(nimV2):
  proc reset*[T](obj: var T) {.magic: "Destroy", noSideEffect.}
    ## Old runtime target: Resets an object `obj` to its initial (binary zero) value.
    ##
    ## New runtime target: An alias for `=destroy`.
else:
  proc reset*[T](obj: var T) {.magic: "Reset", noSideEffect.}
    ## Old runtime target: Resets an object `obj` to its initial (binary zero) value.
    ##
    ## New runtime target: An alias for `=destroy`.

proc wasMoved*[T](obj: var T) {.magic: "WasMoved", noSideEffect.} =
  ## Resets an object `obj` to its initial (binary zero) value to signify
  ## it was "moved" and to signify its destructor should do nothing and
  ## ideally be optimized away.
  discard

proc move*[T](x: var T): T {.magic: "Move", noSideEffect.} =
  result = x
  wasMoved(x)

type
  range*[T]{.magic: "Range".}         ## Generic type to construct range types.
  array*[I, T]{.magic: "Array".}      ## Generic type to construct
                                      ## fixed-length arrays.
  openArray*[T]{.magic: "OpenArray".} ## Generic type to construct open arrays.
                                      ## Open arrays are implemented as a
                                      ## pointer to the array data and a
                                      ## length field.
  varargs*[T]{.magic: "Varargs".}     ## Generic type to construct a varargs type.
  seq*[T]{.magic: "Seq".}             ## Generic type to construct sequences.
  set*[T]{.magic: "Set".}             ## Generic type to construct bit sets.

when defined(nimUncheckedArrayTyp):
  type
    UncheckedArray*[T]{.magic: "UncheckedArray".}
    ## Array with no bounds checking.
else:
  type
    UncheckedArray*[T]{.unchecked.} = array[0,T]
    ## Array with no bounds checking.

type sink*[T]{.magic: "BuiltinType".}
type lent*[T]{.magic: "BuiltinType".}

proc high*[T: Ordinal|enum|range](x: T): T {.magic: "High", noSideEffect.}
  ## Returns the highest possible value of an ordinal value `x`.
  ##
  ## As a special semantic rule, `x` may also be a type identifier.
  ##
  ## See also:
  ## * `low(T) <#low,T>`_
  ##
  ## .. code-block:: Nim
  ##  high(2) # => 9223372036854775807

proc high*[T: Ordinal|enum|range](x: typedesc[T]): T {.magic: "High", noSideEffect.}
  ## Returns the highest possible value of an ordinal or enum type.
  ##
  ## ``high(int)`` is Nim's way of writing `INT_MAX`:idx: or `MAX_INT`:idx:.
  ##
  ## See also:
  ## * `low(typedesc) <#low,typedesc[T]>`_
  ##
  ## .. code-block:: Nim
  ##  high(int) # => 9223372036854775807

proc high*[T](x: openArray[T]): int {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of a sequence `x`.
  ##
  ## See also:
  ## * `low(openArray) <#low,openArray[T]>`_
  ##
  ## .. code-block:: Nim
  ##  var s = @[1, 2, 3, 4, 5, 6, 7]
  ##  high(s) # => 6
  ##  for i in low(s)..high(s):
  ##    echo s[i]

proc high*[I, T](x: array[I, T]): I {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of an array `x`.
  ##
  ## See also:
  ## * `low(array) <#low,array[I,T]>`_
  ##
  ## .. code-block:: Nim
  ##  var arr = [1, 2, 3, 4, 5, 6, 7]
  ##  high(arr) # => 6
  ##  for i in low(arr)..high(arr):
  ##    echo arr[i]

proc high*[I, T](x: typedesc[array[I, T]]): I {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of an array type.
  ##
  ## See also:
  ## * `low(typedesc[array]) <#low,typedesc[array[I,T]]>`_
  ##
  ## .. code-block:: Nim
  ##  high(array[7, int]) # => 6

proc high*(x: cstring): int {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of a compatible string `x`.
  ## This is sometimes an O(n) operation.
  ##
  ## See also:
  ## * `low(cstring) <#low,cstring>`_

proc high*(x: string): int {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of a string `x`.
  ##
  ## See also:
  ## * `low(string) <#low,string>`_
  ##
  ## .. code-block:: Nim
  ##  var str = "Hello world!"
  ##  high(str) # => 11

proc low*[T: Ordinal|enum|range](x: T): T {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible value of an ordinal value `x`. As a special
  ## semantic rule, `x` may also be a type identifier.
  ##
  ## See also:
  ## * `high(T) <#high,T>`_
  ##
  ## .. code-block:: Nim
  ##  low(2) # => -9223372036854775808

proc low*[T: Ordinal|enum|range](x: typedesc[T]): T {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible value of an ordinal or enum type.
  ##
  ## ``low(int)`` is Nim's way of writing `INT_MIN`:idx: or `MIN_INT`:idx:.
  ##
  ## See also:
  ## * `high(typedesc) <#high,typedesc[T]>`_
  ##
  ## .. code-block:: Nim
  ##  low(int) # => -9223372036854775808

proc low*[T](x: openArray[T]): int {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of a sequence `x`.
  ##
  ## See also:
  ## * `high(openArray) <#high,openArray[T]>`_
  ##
  ## .. code-block:: Nim
  ##  var s = @[1, 2, 3, 4, 5, 6, 7]
  ##  low(s) # => 0
  ##  for i in low(s)..high(s):
  ##    echo s[i]

proc low*[I, T](x: array[I, T]): I {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of an array `x`.
  ##
  ## See also:
  ## * `high(array) <#high,array[I,T]>`_
  ##
  ## .. code-block:: Nim
  ##  var arr = [1, 2, 3, 4, 5, 6, 7]
  ##  low(arr) # => 0
  ##  for i in low(arr)..high(arr):
  ##    echo arr[i]

proc low*[I, T](x: typedesc[array[I, T]]): I {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of an array type.
  ##
  ## See also:
  ## * `high(typedesc[array]) <#high,typedesc[array[I,T]]>`_
  ##
  ## .. code-block:: Nim
  ##  low(array[7, int]) # => 0

proc low*(x: cstring): int {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of a compatible string `x`.
  ##
  ## See also:
  ## * `high(cstring) <#high,cstring>`_

proc low*(x: string): int {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of a string `x`.
  ##
  ## See also:
  ## * `high(string) <#high,string>`_
  ##
  ## .. code-block:: Nim
  ##  var str = "Hello world!"
  ##  low(str) # => 0

proc shallowCopy*[T](x: var T, y: T) {.noSideEffect, magic: "ShallowCopy".}
  ## Use this instead of `=` for a `shallow copy`:idx:.
  ##
  ## The shallow copy only changes the semantics for sequences and strings
  ## (and types which contain those).
  ##
  ## Be careful with the changed semantics though!
  ## There is a reason why the default assignment does a deep copy of sequences
  ## and strings.

when defined(nimArrIdx):
  # :array|openArray|string|seq|cstring|tuple
  proc `[]`*[I: Ordinal;T](a: T; i: I): T {.
    noSideEffect, magic: "ArrGet".}
  proc `[]=`*[I: Ordinal;T,S](a: T; i: I;
    x: S) {.noSideEffect, magic: "ArrPut".}
  proc `=`*[T](dest: var T; src: T) {.noSideEffect, magic: "Asgn".}

  proc arrGet[I: Ordinal;T](a: T; i: I): T {.
    noSideEffect, magic: "ArrGet".}
  proc arrPut[I: Ordinal;T,S](a: T; i: I;
    x: S) {.noSideEffect, magic: "ArrPut".}

  proc `=destroy`*[T](x: var T) {.inline, magic: "Destroy".} =
    ## Generic `destructor`:idx: implementation that can be overridden.
    discard
  proc `=sink`*[T](x: var T; y: T) {.inline, magic: "Asgn".} =
    ## Generic `sink`:idx: implementation that can be overridden.
    shallowCopy(x, y)

type
  HSlice*[T, U] = object   ## "Heterogeneous" slice type.
    a*: T                  ## The lower bound (inclusive).
    b*: U                  ## The upper bound (inclusive).
  Slice*[T] = HSlice[T, T] ## An alias for ``HSlice[T, T]``.

proc `..`*[T, U](a: T, b: U): HSlice[T, U] {.noSideEffect, inline, magic: "DotDot".} =
  ## Binary `slice`:idx: operator that constructs an interval ``[a, b]``, both `a`
  ## and `b` are inclusive.
  ##
  ## Slices can also be used in the set constructor and in ordinal case
  ## statements, but then they are special-cased by the compiler.
  ##
  ## .. code-block:: Nim
  ##   let a = [10, 20, 30, 40, 50]
  ##   echo a[2 .. 3] # @[30, 40]
  result = HSlice[T, U](a: a, b: b)

proc `..`*[T](b: T): HSlice[int, T] {.noSideEffect, inline, magic: "DotDot".} =
  ## Unary `slice`:idx: operator that constructs an interval ``[default(int), b]``.
  ##
  ## .. code-block:: Nim
  ##   let a = [10, 20, 30, 40, 50]
  ##   echo a[.. 2] # @[10, 20, 30]
  result = HSlice[int, T](a: 0, b: b)

when not defined(niminheritable):
  {.pragma: inheritable.}
when not defined(nimunion):
  {.pragma: unchecked.}
when not defined(nimHasHotCodeReloading):
  {.pragma: nonReloadable.}
when defined(hotCodeReloading):
  {.pragma: hcrInline, inline.}
else:
  {.pragma: hcrInline.}

# comparison operators:
proc `==`*[Enum: enum](x, y: Enum): bool {.magic: "EqEnum", noSideEffect.}
  ## Checks whether values within the *same enum* have the same underlying value.
  ##
  ## .. code-block:: Nim
  ##  type
  ##    Enum1 = enum
  ##      Field1 = 3, Field2
  ##    Enum2 = enum
  ##      Place1, Place2 = 3
  ##  var
  ##    e1 = Field1
  ##    e2 = Enum1(Place2)
  ##  echo (e1 == e2) # true
  ##  echo (e1 == Place2) # raises error
proc `==`*(x, y: pointer): bool {.magic: "EqRef", noSideEffect.}
  ## .. code-block:: Nim
  ##  var # this is a wildly dangerous example
  ##    a = cast[pointer](0)
  ##    b = cast[pointer](nil)
  ##  echo (a == b) # true due to the special meaning of `nil`/0 as a pointer
proc `==`*(x, y: string): bool {.magic: "EqStr", noSideEffect.}
  ## Checks for equality between two `string` variables.

proc `==`*(x, y: char): bool {.magic: "EqCh", noSideEffect.}
  ## Checks for equality between two `char` variables.
proc `==`*(x, y: bool): bool {.magic: "EqB", noSideEffect.}
  ## Checks for equality between two `bool` variables.
proc `==`*[T](x, y: set[T]): bool {.magic: "EqSet", noSideEffect.}
  ## Checks for equality between two variables of type `set`.
  ##
  ## .. code-block:: Nim
  ##  var a = {1, 2, 2, 3} # duplication in sets is ignored
  ##  var b = {1, 2, 3}
  ##  echo (a == b) # true
proc `==`*[T](x, y: ref T): bool {.magic: "EqRef", noSideEffect.}
  ## Checks that two `ref` variables refer to the same item.
proc `==`*[T](x, y: ptr T): bool {.magic: "EqRef", noSideEffect.}
  ## Checks that two `ptr` variables refer to the same item.
proc `==`*[T: proc](x, y: T): bool {.magic: "EqProc", noSideEffect.}
  ## Checks that two `proc` variables refer to the same procedure.

proc `<=`*[Enum: enum](x, y: Enum): bool {.magic: "LeEnum", noSideEffect.}
proc `<=`*(x, y: string): bool {.magic: "LeStr", noSideEffect.}
  ## Compares two strings and returns true if `x` is lexicographically
  ## before `y` (uppercase letters come before lowercase letters).
  ##
  ## .. code-block:: Nim
  ##     let
  ##       a = "abc"
  ##       b = "abd"
  ##       c = "ZZZ"
  ##     assert a <= b
  ##     assert a <= a
  ##     assert (a <= c) == false
proc `<=`*(x, y: char): bool {.magic: "LeCh", noSideEffect.}
  ## Compares two chars and returns true if `x` is lexicographically
  ## before `y` (uppercase letters come before lowercase letters).
  ##
  ## .. code-block:: Nim
  ##     let
  ##       a = 'a'
  ##       b = 'b'
  ##       c = 'Z'
  ##     assert a <= b
  ##     assert a <= a
  ##     assert (a <= c) == false
proc `<=`*[T](x, y: set[T]): bool {.magic: "LeSet", noSideEffect.}
  ## Returns true if `x` is a subset of `y`.
  ##
  ## A subset `x` has all of its members in `y` and `y` doesn't necessarily
  ## have more members than `x`. That is, `x` can be equal to `y`.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {3, 5}
  ##     b = {1, 3, 5, 7}
  ##     c = {2}
  ##   assert a <= b
  ##   assert a <= a
  ##   assert (a <= c) == false
proc `<=`*(x, y: bool): bool {.magic: "LeB", noSideEffect.}
proc `<=`*[T](x, y: ref T): bool {.magic: "LePtr", noSideEffect.}
proc `<=`*(x, y: pointer): bool {.magic: "LePtr", noSideEffect.}

proc `<`*[Enum: enum](x, y: Enum): bool {.magic: "LtEnum", noSideEffect.}
proc `<`*(x, y: string): bool {.magic: "LtStr", noSideEffect.}
  ## Compares two strings and returns true if `x` is lexicographically
  ## before `y` (uppercase letters come before lowercase letters).
  ##
  ## .. code-block:: Nim
  ##     let
  ##       a = "abc"
  ##       b = "abd"
  ##       c = "ZZZ"
  ##     assert a < b
  ##     assert (a < a) == false
  ##     assert (a < c) == false
proc `<`*(x, y: char): bool {.magic: "LtCh", noSideEffect.}
  ## Compares two chars and returns true if `x` is lexicographically
  ## before `y` (uppercase letters come before lowercase letters).
  ##
  ## .. code-block:: Nim
  ##     let
  ##       a = 'a'
  ##       b = 'b'
  ##       c = 'Z'
  ##     assert a < b
  ##     assert (a < a) == false
  ##     assert (a < c) == false
proc `<`*[T](x, y: set[T]): bool {.magic: "LtSet", noSideEffect.}
  ## Returns true if `x` is a strict or proper subset of `y`.
  ##
  ## A strict or proper subset `x` has all of its members in `y` but `y` has
  ## more elements than `y`.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {3, 5}
  ##     b = {1, 3, 5, 7}
  ##     c = {2}
  ##   assert a < b
  ##   assert (a < a) == false
  ##   assert (a < c) == false
proc `<`*(x, y: bool): bool {.magic: "LtB", noSideEffect.}
proc `<`*[T](x, y: ref T): bool {.magic: "LtPtr", noSideEffect.}
proc `<`*[T](x, y: ptr T): bool {.magic: "LtPtr", noSideEffect.}
proc `<`*(x, y: pointer): bool {.magic: "LtPtr", noSideEffect.}

template `!=`*(x, y: untyped): untyped =
  ## Unequals operator. This is a shorthand for ``not (x == y)``.
  not (x == y)

template `>=`*(x, y: untyped): untyped =
  ## "is greater or equals" operator. This is the same as ``y <= x``.
  y <= x

template `>`*(x, y: untyped): untyped =
  ## "is greater" operator. This is the same as ``y < x``.
  y < x

const
  appType* {.magic: "AppType"}: string = ""
    ## A string that describes the application type. Possible values:
    ## `"console"`, `"gui"`, `"lib"`.

include "system/inclrtl"

const NoFakeVars* = defined(nimscript) ## `true` if the backend doesn't support \
  ## "fake variables" like `var EBADF {.importc.}: cint`.

when not defined(JS) and not defined(nimSeqsV2):
  type
    TGenericSeq {.compilerproc, pure, inheritable.} = object
      len, reserved: int
      when defined(gogc):
        elemSize: int
    PGenericSeq {.exportc.} = ptr TGenericSeq
    # len and space without counting the terminating zero:
    NimStringDesc {.compilerproc, final.} = object of TGenericSeq
      data: UncheckedArray[char]
    NimString = ptr NimStringDesc

when not defined(JS) and not defined(nimscript):
  when not defined(nimSeqsV2):
    template space(s: PGenericSeq): int {.dirty.} =
      s.reserved and not (seqShallowFlag or strlitFlag)
  when not defined(nimV2):
    include "system/hti"

type
  byte* = uint8 ## This is an alias for ``uint8``, that is an unsigned
                ## integer, 8 bits wide.

  Natural* = range[0..high(int)]
    ## is an `int` type ranging from zero to the maximum value
    ## of an `int`. This type is often useful for documentation and debugging.

  Positive* = range[1..high(int)]
    ## is an `int` type ranging from one to the maximum value
    ## of an `int`. This type is often useful for documentation and debugging.

  RootObj* {.compilerproc, inheritable.} =
    object ## The root of Nim's object hierarchy.
           ##
           ## Objects should inherit from `RootObj` or one of its descendants.
           ## However, objects that have no ancestor are also allowed.
  RootRef* = ref RootObj ## Reference to `RootObj`.

  RootEffect* {.compilerproc.} = object of RootObj ## \
    ## Base effect class.
    ##
    ## Each effect should inherit from `RootEffect` unless you know what
    ## you're doing.
  TimeEffect* = object of RootEffect   ## Time effect.
  IOEffect* = object of RootEffect     ## IO effect.
  ReadIOEffect* = object of IOEffect   ## Effect describing a read IO operation.
  WriteIOEffect* = object of IOEffect  ## Effect describing a write IO operation.
  ExecIOEffect* = object of IOEffect   ## Effect describing an executing IO operation.

  StackTraceEntry* = object ## In debug mode exceptions store the stack trace that led
                            ## to them. A `StackTraceEntry` is a single entry of the
                            ## stack trace.
    procname*: cstring      ## Name of the proc that is currently executing.
    line*: int              ## Line number of the proc that is currently executing.
    filename*: cstring      ## Filename of the proc that is currently executing.

  Exception* {.compilerproc, magic: "Exception".} = object of RootObj ## \
    ## Base exception class.
    ##
    ## Each exception has to inherit from `Exception`. See the full `exception
    ## hierarchy <manual.html#exception-handling-exception-hierarchy>`_.
    parent*: ref Exception ## Parent exception (can be used as a stack).
    name*: cstring         ## The exception's name is its Nim identifier.
                           ## This field is filled automatically in the
                           ## ``raise`` statement.
    msg* {.exportc: "message".}: string ## The exception's message. Not
                                        ## providing an exception message
                                        ## is bad style.
    when defined(js):
      trace: string
    else:
      trace: seq[StackTraceEntry]
    when defined(nimBoostrapCsources0_19_0):
      # see #10315, bootstrap with `nim cpp` from csources gave error:
      # error: no member named 'raise_id' in 'Exception'
      raise_id: uint # set when exception is raised
    else:
      raiseId: uint # set when exception is raised
    up: ref Exception # used for stacking exceptions. Not exported!

  Defect* = object of Exception ## \
    ## Abstract base class for all exceptions that Nim's runtime raises
    ## but that are strictly uncatchable as they can also be mapped to
    ## a ``quit`` / ``trap`` / ``exit`` operation.

  CatchableError* = object of Exception ## \
    ## Abstract class for all exceptions that are catchable.
  IOError* = object of CatchableError ## \
    ## Raised if an IO error occurred.
  EOFError* = object of IOError ## \
    ## Raised if an IO "end of file" error occurred.
  OSError* = object of CatchableError ## \
    ## Raised if an operating system service failed.
    errorCode*: int32 ## OS-defined error code describing this error.
  LibraryError* = object of OSError ## \
    ## Raised if a dynamic library could not be loaded.
  ResourceExhaustedError* = object of CatchableError ## \
    ## Raised if a resource request could not be fulfilled.
  ArithmeticError* = object of Defect ## \
    ## Raised if any kind of arithmetic error occurred.
  DivByZeroError* = object of ArithmeticError ## \
    ## Raised for runtime integer divide-by-zero errors.

  OverflowError* = object of ArithmeticError ## \
    ## Raised for runtime integer overflows.
    ##
    ## This happens for calculations whose results are too large to fit in the
    ## provided bits.
  AccessViolationError* = object of Defect ## \
    ## Raised for invalid memory access errors
  AssertionError* = object of Defect ## \
    ## Raised when assertion is proved wrong.
    ##
    ## Usually the result of using the `assert() template
    ## <assertions.html#assert.t,untyped,string>`_.
  ValueError* = object of CatchableError ## \
    ## Raised for string and object conversion errors.
  KeyError* = object of ValueError ## \
    ## Raised if a key cannot be found in a table.
    ##
    ## Mostly used by the `tables <tables.html>`_ module, it can also be raised
    ## by other collection modules like `sets <sets.html>`_ or `strtabs
    ## <strtabs.html>`_.
  OutOfMemError* = object of Defect ## \
    ## Raised for unsuccessful attempts to allocate memory.
  IndexError* = object of Defect ## \
    ## Raised if an array index is out of bounds.

  FieldError* = object of Defect ## \
    ## Raised if a record field is not accessible because its dicriminant's
    ## value does not fit.
  RangeError* = object of Defect ## \
    ## Raised if a range check error occurred.
  StackOverflowError* = object of Defect ## \
    ## Raised if the hardware stack used for subroutine calls overflowed.
  ReraiseError* = object of Defect ## \
    ## Raised if there is no exception to reraise.
  ObjectAssignmentError* = object of Defect ## \
    ## Raised if an object gets assigned to its parent's object.
  ObjectConversionError* = object of Defect ## \
    ## Raised if an object is converted to an incompatible object type.
    ## You can use ``of`` operator to check if conversion will succeed.
  FloatingPointError* = object of Defect ## \
    ## Base class for floating point exceptions.
  FloatInvalidOpError* = object of FloatingPointError ## \
    ## Raised by invalid operations according to IEEE.
    ##
    ## Raised by ``0.0/0.0``, for example.
  FloatDivByZeroError* = object of FloatingPointError ## \
    ## Raised by division by zero.
    ##
    ## Divisor is zero and dividend is a finite nonzero number.
  FloatOverflowError* = object of FloatingPointError ## \
    ## Raised for overflows.
    ##
    ## The operation produced a result that exceeds the range of the exponent.
  FloatUnderflowError* = object of FloatingPointError ## \
    ## Raised for underflows.
    ##
    ## The operation produced a result that is too small to be represented as a
    ## normal number.
  FloatInexactError* = object of FloatingPointError ## \
    ## Raised for inexact results.
    ##
    ## The operation produced a result that cannot be represented with infinite
    ## precision -- for example: ``2.0 / 3.0, log(1.1)``
    ##
    ## **Note**: Nim currently does not detect these!
  DeadThreadError* = object of Defect ## \
    ## Raised if it is attempted to send a message to a dead thread.
  NilAccessError* = object of Defect ## \
    ## Raised on dereferences of ``nil`` pointers.
    ##
    ## This is only raised if the `segfaults module <segfaults.html>`_ was imported!

when defined(js) or defined(nimdoc):
  type
    JsRoot* = ref object of RootObj
      ## Root type of the JavaScript object hierarchy

proc unsafeNew*[T](a: var ref T, size: Natural) {.magic: "New", noSideEffect.}
  ## Creates a new object of type ``T`` and returns a safe (traced)
  ## reference to it in ``a``.
  ##
  ## This is **unsafe** as it allocates an object of the passed ``size``.
  ## This should only be used for optimization purposes when you know
  ## what you're doing!
  ##
  ## See also:
  ## * `new <#new,ref.T,proc(ref.T)>`_

proc sizeof*[T](x: T): int {.magic: "SizeOf", noSideEffect.}
  ## Returns the size of ``x`` in bytes.
  ##
  ## Since this is a low-level proc,
  ## its usage is discouraged - using `new <#new,ref.T,proc(ref.T)>`_ for
  ## the most cases suffices that one never needs to know ``x``'s size.
  ##
  ## As a special semantic rule, ``x`` may also be a type identifier
  ## (``sizeof(int)`` is valid).
  ##
  ## Limitations: If used for types that are imported from C or C++,
  ## sizeof should fallback to the ``sizeof`` in the C compiler. The
  ## result isn't available for the Nim compiler and therefore can't
  ## be used inside of macros.
  ##
  ## .. code-block:: Nim
  ##  sizeof('A') # => 1
  ##  sizeof(2) # => 8

when defined(nimHasalignOf):
  proc alignof*[T](x: T): int {.magic: "AlignOf", noSideEffect.}
  proc alignof*(x: typedesc): int {.magic: "AlignOf", noSideEffect.}

  proc offsetOfDotExpr(typeAccess: typed): int {.magic: "OffsetOf", noSideEffect, compileTime.}

  template offsetOf*[T](t: typedesc[T]; member: untyped): int =
    var tmp {.noinit.}: ptr T
    offsetOfDotExpr(tmp[].member)

  template offsetOf*[T](value: T; member: untyped): int =
    offsetOfDotExpr(value.member)

  #proc offsetOf*(memberaccess: typed): int {.magic: "OffsetOf", noSideEffect.}

when defined(nimtypedescfixed):
  proc sizeof*(x: typedesc): int {.magic: "SizeOf", noSideEffect.}

proc `<`*[T](x: Ordinal[T]): T {.magic: "UnaryLt", noSideEffect, deprecated.}
  ## **Deprecated since version 0.18.0**. For the common excluding range
  ## write ``0 ..< 10`` instead of ``0 .. < 10`` (look at the spacing).
  ## For ``<x`` write ``pred(x)``.
  ##
  ## Unary ``<`` that can be used for excluding ranges.
  ## Semantically this is the same as `pred <#pred,T,int>`_.
  ##
  ## .. code-block:: Nim
  ##   for i in 0 .. <10: echo i # => 0 1 2 3 4 5 6 7 8 9
  ##

proc succ*[T: Ordinal](x: T, y = 1): T {.magic: "Succ", noSideEffect.}
  ## Returns the ``y``-th successor (default: 1) of the value ``x``.
  ## ``T`` has to be an `ordinal type <#Ordinal>`_.
  ##
  ## If such a value does not exist, ``OverflowError`` is raised
  ## or a compile time error occurs.
  ##
  ## .. code-block:: Nim
  ##   let x = 5
  ##   echo succ(5)    # => 6
  ##   echo succ(5, 3) # => 8

proc pred*[T: Ordinal](x: T, y = 1): T {.magic: "Pred", noSideEffect.}
  ## Returns the ``y``-th predecessor (default: 1) of the value ``x``.
  ## ``T`` has to be an `ordinal type <#Ordinal>`_.
  ##
  ## If such a value does not exist, ``OverflowError`` is raised
  ## or a compile time error occurs.
  ##
  ## .. code-block:: Nim
  ##   let x = 5
  ##   echo pred(5)    # => 4
  ##   echo pred(5, 3) # => 2

proc inc*[T: Ordinal|uint|uint64](x: var T, y = 1) {.magic: "Inc", noSideEffect.}
  ## Increments the ordinal ``x`` by ``y``.
  ##
  ## If such a value does not exist, ``OverflowError`` is raised or a compile
  ## time error occurs. This is a short notation for: ``x = succ(x, y)``.
  ##
  ## .. code-block:: Nim
  ##  var i = 2
  ##  inc(i)    # i <- 3
  ##  inc(i, 3) # i <- 6

proc dec*[T: Ordinal|uint|uint64](x: var T, y = 1) {.magic: "Dec", noSideEffect.}
  ## Decrements the ordinal ``x`` by ``y``.
  ##
  ## If such a value does not exist, ``OverflowError`` is raised or a compile
  ## time error occurs. This is a short notation for: ``x = pred(x, y)``.
  ##
  ## .. code-block:: Nim
  ##  var i = 2
  ##  dec(i)    # i <- 1
  ##  dec(i, 3) # i <- -2

proc newSeq*[T](s: var seq[T], len: Natural) {.magic: "NewSeq", noSideEffect.}
  ## Creates a new sequence of type ``seq[T]`` with length ``len``.
  ##
  ## This is equivalent to ``s = @[]; setlen(s, len)``, but more
  ## efficient since no reallocation is needed.
  ##
  ## Note that the sequence will be filled with zeroed entries.
  ## After the creation of the sequence you should assign entries to
  ## the sequence instead of adding them. Example:
  ##
  ## .. code-block:: Nim
  ##   var inputStrings : seq[string]
  ##   newSeq(inputStrings, 3)
  ##   assert len(inputStrings) == 3
  ##   inputStrings[0] = "The fourth"
  ##   inputStrings[1] = "assignment"
  ##   inputStrings[2] = "would crash"
  ##   #inputStrings[3] = "out of bounds"

proc newSeq*[T](len = 0.Natural): seq[T] =
  ## Creates a new sequence of type ``seq[T]`` with length ``len``.
  ##
  ## Note that the sequence will be filled with zeroed entries.
  ## After the creation of the sequence you should assign entries to
  ## the sequence instead of adding them.
  ##
  ## See also:
  ## * `newSeqOfCap <#newSeqOfCap,Natural>`_
  ## * `newSeqUninitialized <#newSeqUninitialized,Natural>`_
  ##
  ## .. code-block:: Nim
  ##   var inputStrings = newSeq[string](3)
  ##   assert len(inputStrings) == 3
  ##   inputStrings[0] = "The fourth"
  ##   inputStrings[1] = "assignment"
  ##   inputStrings[2] = "would crash"
  ##   #inputStrings[3] = "out of bounds"
  newSeq(result, len)

proc newSeqOfCap*[T](cap: Natural): seq[T] {.
  magic: "NewSeqOfCap", noSideEffect.} =
  ## Creates a new sequence of type ``seq[T]`` with length zero and capacity
  ## ``cap``.
  ##
  ## .. code-block:: Nim
  ##   var x = newSeqOfCap[int](5)
  ##   assert len(x) == 0
  ##   x.add(10)
  ##   assert len(x) == 1
  discard

when not defined(JS):
  proc newSeqUninitialized*[T: SomeNumber](len: Natural): seq[T] =
    ## Creates a new sequence of type ``seq[T]`` with length ``len``.
    ##
    ## Only available for numbers types. Note that the sequence will be
    ## uninitialized. After the creation of the sequence you should assign
    ## entries to the sequence instead of adding them.
    ##
    ## .. code-block:: Nim
    ##   var x = newSeqUninitialized[int](3)
    ##   assert len(x) == 3
    ##   x[0] = 10
    result = newSeqOfCap[T](len)
    when defined(nimSeqsV2):
      cast[ptr int](addr result)[] = len
    else:
      var s = cast[PGenericSeq](result)
      s.len = len

proc len*[TOpenArray: openArray|varargs](x: TOpenArray): int {.
  magic: "LengthOpenArray", noSideEffect.}
  ## Returns the length of an openArray.
  ##
  ## .. code-block:: Nim
  ##   var s = [1, 1, 1, 1, 1]
  ##   echo len(s) # => 5

proc len*(x: string): int {.magic: "LengthStr", noSideEffect.}
  ## Returns the length of a string.
  ##
  ## .. code-block:: Nim
  ##   var str = "Hello world!"
  ##   echo len(str) # => 12

proc len*(x: cstring): int {.magic: "LengthStr", noSideEffect.}
  ## Returns the length of a compatible string. This is sometimes
  ## an O(n) operation.
  ##
  ## .. code-block:: Nim
  ##   var str: cstring = "Hello world!"
  ##   len(str) # => 12

proc len*(x: (type array)|array): int {.magic: "LengthArray", noSideEffect.}
  ## Returns the length of an array or an array type.
  ## This is roughly the same as ``high(T)-low(T)+1``.
  ##
  ## .. code-block:: Nim
  ##   var arr = [1, 1, 1, 1, 1]
  ##   echo len(arr) # => 5
  ##   echo len(array[3..8, int]) # => 6

proc len*[T](x: seq[T]): int {.magic: "LengthSeq", noSideEffect.}
  ## Returns the length of a sequence.
  ##
  ## .. code-block:: Nim
  ##   var s = @[1, 1, 1, 1, 1]
  ##   echo len(s) # => 5

# set routines:
proc incl*[T](x: var set[T], y: T) {.magic: "Incl", noSideEffect.}
  ## Includes element ``y`` in the set ``x``.
  ##
  ## This is the same as ``x = x + {y}``, but it might be more efficient.
  ##
  ## .. code-block:: Nim
  ##   var a = {1, 3, 5}
  ##   a.incl(2) # a <- {1, 2, 3, 5}
  ##   a.incl(4) # a <- {1, 2, 3, 4, 5}

template incl*[T](x: var set[T], y: set[T]) =
  ## Includes the set ``y`` in the set ``x``.
  ##
  ## .. code-block:: Nim
  ##   var a = {1, 3, 5, 7}
  ##   var b = {4, 5, 6}
  ##   a.incl(b)  # a <- {1, 3, 4, 5, 6, 7}
  x = x + y

proc excl*[T](x: var set[T], y: T) {.magic: "Excl", noSideEffect.}
  ## Excludes element ``y`` from the set ``x``.
  ##
  ## This is the same as ``x = x - {y}``, but it might be more efficient.
  ##
  ## .. code-block:: Nim
  ##   var b = {2, 3, 5, 6, 12, 545}
  ##   b.excl(5)  # b <- {2, 3, 6, 12, 545}

template excl*[T](x: var set[T], y: set[T]) =
  ## Excludes the set ``y`` from the set ``x``.
  ##
  ## .. code-block:: Nim
  ##   var a = {1, 3, 5, 7}
  ##   var b = {3, 4, 5}
  ##   a.excl(b)  # a <- {1, 7}
  x = x - y

proc card*[T](x: set[T]): int {.magic: "Card", noSideEffect.}
  ## Returns the cardinality of the set ``x``, i.e. the number of elements
  ## in the set.
  ##
  ## .. code-block:: Nim
  ##   var a = {1, 3, 5, 7}
  ##   echo card(a) # => 4

proc len*[T](x: set[T]): int {.magic: "Card", noSideEffect.}
  ## An alias for `card(x)`.

proc ord*[T: Ordinal|enum](x: T): int {.magic: "Ord", noSideEffect.}
  ## Returns the internal `int` value of an ordinal value ``x``.
  ##
  ## .. code-block:: Nim
  ##   echo ord('A') # => 65
  ##   echo ord('a') # => 97

proc chr*(u: range[0..255]): char {.magic: "Chr", noSideEffect.}
  ## Converts an `int` in the range `0..255` to a character.
  ##
  ## .. code-block:: Nim
  ##   echo chr(65) # => A
  ##   echo chr(97) # => a

# --------------------------------------------------------------------------
# built-in operators

when defined(nimNoZeroExtendMagic):
  proc ze*(x: int8): int {.deprecated.} =
    ## zero extends a smaller integer type to ``int``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

    cast[int](uint(cast[uint8](x)))

  proc ze*(x: int16): int {.deprecated.} =
    ## zero extends a smaller integer type to ``int``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int](uint(cast[uint16](x)))

  proc ze64*(x: int8): int64 {.deprecated.} =
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint8](x)))

  proc ze64*(x: int16): int64 {.deprecated.} =
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint16](x)))

  proc ze64*(x: int32): int64 {.deprecated.} =
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint32](x)))

  proc ze64*(x: int): int64 {.deprecated.} =
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned. Does nothing if the size of an ``int`` is the same as ``int64``.
    ## (This is the case on 64 bit processors.)
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint](x)))

  proc toU8*(x: int): int8 {.deprecated.} =
    ## treats `x` as unsigned and converts it to a byte by taking the last 8 bits
    ## from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int8](x)

  proc toU16*(x: int): int16 {.deprecated.} =
    ## treats `x` as unsigned and converts it to an ``int16`` by taking the last
    ## 16 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int16](x)

  proc toU32*(x: int64): int32 {.deprecated.} =
    ## treats `x` as unsigned and converts it to an ``int32`` by taking the
    ## last 32 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int32](x)

elif not defined(JS):
  proc ze*(x: int8): int {.magic: "Ze8ToI", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze*(x: int16): int {.magic: "Ze16ToI", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int8): int64 {.magic: "Ze8ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int16): int64 {.magic: "Ze16ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int32): int64 {.magic: "Ze32ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int): int64 {.magic: "ZeIToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned. Does nothing if the size of an ``int`` is the same as ``int64``.
    ## (This is the case on 64 bit processors.)
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU8*(x: int): int8 {.magic: "ToU8", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to a byte by taking the last 8 bits
    ## from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU16*(x: int): int16 {.magic: "ToU16", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to an ``int16`` by taking the last
    ## 16 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU32*(x: int64): int32 {.magic: "ToU32", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to an ``int32`` by taking the
    ## last 32 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

# integer calculations:
proc `+`*(x: int): int {.magic: "UnaryPlusI", noSideEffect.}
  ## Unary `+` operator for an integer. Has no effect.
proc `+`*(x: int8): int8 {.magic: "UnaryPlusI", noSideEffect.}
proc `+`*(x: int16): int16 {.magic: "UnaryPlusI", noSideEffect.}
proc `+`*(x: int32): int32 {.magic: "UnaryPlusI", noSideEffect.}
proc `+`*(x: int64): int64 {.magic: "UnaryPlusI", noSideEffect.}

proc `-`*(x: int): int {.magic: "UnaryMinusI", noSideEffect.}
  ## Unary `-` operator for an integer. Negates `x`.
proc `-`*(x: int8): int8 {.magic: "UnaryMinusI", noSideEffect.}
proc `-`*(x: int16): int16 {.magic: "UnaryMinusI", noSideEffect.}
proc `-`*(x: int32): int32 {.magic: "UnaryMinusI", noSideEffect.}
proc `-`*(x: int64): int64 {.magic: "UnaryMinusI64", noSideEffect.}

proc `not`*(x: int): int {.magic: "BitnotI", noSideEffect.}
  ## Computes the `bitwise complement` of the integer `x`.
  ##
  ## .. code-block:: Nim
  ##   var
  ##     a = 0'u8
  ##     b = 0'i8
  ##     c = 1000'u16
  ##     d = 1000'i16
  ##
  ##   echo not a # => 255
  ##   echo not b # => -1
  ##   echo not c # => 64535
  ##   echo not d # => -1001
proc `not`*(x: int8): int8 {.magic: "BitnotI", noSideEffect.}
proc `not`*(x: int16): int16 {.magic: "BitnotI", noSideEffect.}
proc `not`*(x: int32): int32 {.magic: "BitnotI", noSideEffect.}
proc `not`*(x: int64): int64 {.magic: "BitnotI", noSideEffect.}

proc `+`*(x, y: int): int {.magic: "AddI", noSideEffect.}
  ## Binary `+` operator for an integer.
proc `+`*(x, y: int8): int8 {.magic: "AddI", noSideEffect.}
proc `+`*(x, y: int16): int16 {.magic: "AddI", noSideEffect.}
proc `+`*(x, y: int32): int32 {.magic: "AddI", noSideEffect.}
proc `+`*(x, y: int64): int64 {.magic: "AddI", noSideEffect.}

proc `-`*(x, y: int): int {.magic: "SubI", noSideEffect.}
  ## Binary `-` operator for an integer.
proc `-`*(x, y: int8): int8 {.magic: "SubI", noSideEffect.}
proc `-`*(x, y: int16): int16 {.magic: "SubI", noSideEffect.}
proc `-`*(x, y: int32): int32 {.magic: "SubI", noSideEffect.}
proc `-`*(x, y: int64): int64 {.magic: "SubI", noSideEffect.}

proc `*`*(x, y: int): int {.magic: "MulI", noSideEffect.}
  ## Binary `*` operator for an integer.
proc `*`*(x, y: int8): int8 {.magic: "MulI", noSideEffect.}
proc `*`*(x, y: int16): int16 {.magic: "MulI", noSideEffect.}
proc `*`*(x, y: int32): int32 {.magic: "MulI", noSideEffect.}
proc `*`*(x, y: int64): int64 {.magic: "MulI", noSideEffect.}

proc `div`*(x, y: int): int {.magic: "DivI", noSideEffect.}
  ## Computes the integer division.
  ##
  ## This is roughly the same as ``trunc(x/y)``.
  ##
  ## .. code-block:: Nim
  ##   ( 1 div  2) ==  0
  ##   ( 2 div  2) ==  1
  ##   ( 3 div  2) ==  1
  ##   ( 7 div  3) ==  2
  ##   (-7 div  3) == -2
  ##   ( 7 div -3) == -2
  ##   (-7 div -3) ==  2
proc `div`*(x, y: int8): int8 {.magic: "DivI", noSideEffect.}
proc `div`*(x, y: int16): int16 {.magic: "DivI", noSideEffect.}
proc `div`*(x, y: int32): int32 {.magic: "DivI", noSideEffect.}
proc `div`*(x, y: int64): int64 {.magic: "DivI", noSideEffect.}

proc `mod`*(x, y: int): int {.magic: "ModI", noSideEffect.}
  ## Computes the integer modulo operation (remainder).
  ##
  ## This is the same as ``x - (x div y) * y``.
  ##
  ## .. code-block:: Nim
  ##   ( 7 mod  5) ==  2
  ##   (-7 mod  5) == -2
  ##   ( 7 mod -5) ==  2
  ##   (-7 mod -5) == -2
proc `mod`*(x, y: int8): int8 {.magic: "ModI", noSideEffect.}
proc `mod`*(x, y: int16): int16 {.magic: "ModI", noSideEffect.}
proc `mod`*(x, y: int32): int32 {.magic: "ModI", noSideEffect.}
proc `mod`*(x, y: int64): int64 {.magic: "ModI", noSideEffect.}

when defined(nimOldShiftRight) or not defined(nimAshr):
  const shrDepMessage = "`shr` will become sign preserving."
  proc `shr`*(x: int, y: SomeInteger): int {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
  proc `shr`*(x: int8, y: SomeInteger): int8 {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
  proc `shr`*(x: int16, y: SomeInteger): int16 {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
  proc `shr`*(x: int32, y: SomeInteger): int32 {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
  proc `shr`*(x: int64, y: SomeInteger): int64 {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
else:
  proc `shr`*(x: int, y: SomeInteger): int {.magic: "AshrI", noSideEffect.}
    ## Computes the `shift right` operation of `x` and `y`, filling
    ## vacant bit positions with the sign bit.
    ##
    ## **Note**: `Operator precedence <manual.html#syntax-precedence>`_
    ## is different than in *C*.
    ##
    ## See also:
    ## * `ashr proc <#ashr,int,SomeInteger>`_ for arithmetic shift right
    ##
    ## .. code-block:: Nim
    ##   0b0001_0000'i8 shr 2 == 0b0000_0100'i8
    ##   0b0000_0001'i8 shr 1 == 0b0000_0000'i8
    ##   0b1000_0000'i8 shr 4 == 0b1111_1000'i8
    ##   -1 shr 5 == -1
    ##   1 shr 5 == 0
    ##   16 shr 2 == 4
    ##   -16 shr 2 == -4
  proc `shr`*(x: int8, y: SomeInteger): int8 {.magic: "AshrI", noSideEffect.}
  proc `shr`*(x: int16, y: SomeInteger): int16 {.magic: "AshrI", noSideEffect.}
  proc `shr`*(x: int32, y: SomeInteger): int32 {.magic: "AshrI", noSideEffect.}
  proc `shr`*(x: int64, y: SomeInteger): int64 {.magic: "AshrI", noSideEffect.}


proc `shl`*(x: int, y: SomeInteger): int {.magic: "ShlI", noSideEffect.}
  ## Computes the `shift left` operation of `x` and `y`.
  ##
  ## **Note**: `Operator precedence <manual.html#syntax-precedence>`_
  ## is different than in *C*.
  ##
  ## .. code-block:: Nim
  ##  1'i32 shl 4 == 0x0000_0010
  ##  1'i64 shl 4 == 0x0000_0000_0000_0010
proc `shl`*(x: int8, y: SomeInteger): int8 {.magic: "ShlI", noSideEffect.}
proc `shl`*(x: int16, y: SomeInteger): int16 {.magic: "ShlI", noSideEffect.}
proc `shl`*(x: int32, y: SomeInteger): int32 {.magic: "ShlI", noSideEffect.}
proc `shl`*(x: int64, y: SomeInteger): int64 {.magic: "ShlI", noSideEffect.}

when defined(nimAshr):
  proc ashr*(x: int, y: SomeInteger): int {.magic: "AshrI", noSideEffect.}
    ## Shifts right by pushing copies of the leftmost bit in from the left,
    ## and let the rightmost bits fall off.
    ##
    ## Note that `ashr` is not an operator so use the normal function
    ## call syntax for it.
    ##
    ## See also:
    ## * `shr proc <#shr,int,SomeInteger>`_
    ##
    ## .. code-block:: Nim
    ##   ashr(0b0001_0000'i8, 2) == 0b0000_0100'i8
    ##   ashr(0b1000_0000'i8, 8) == 0b1111_1111'i8
    ##   ashr(0b1000_0000'i8, 1) == 0b1100_0000'i8
  proc ashr*(x: int8, y: SomeInteger): int8 {.magic: "AshrI", noSideEffect.}
  proc ashr*(x: int16, y: SomeInteger): int16 {.magic: "AshrI", noSideEffect.}
  proc ashr*(x: int32, y: SomeInteger): int32 {.magic: "AshrI", noSideEffect.}
  proc ashr*(x: int64, y: SomeInteger): int64 {.magic: "AshrI", noSideEffect.}
else:
  # used for bootstrapping the compiler
  proc ashr*[T](x: T, y: SomeInteger): T = discard

proc `and`*(x, y: int): int {.magic: "BitandI", noSideEffect.}
  ## Computes the `bitwise and` of numbers `x` and `y`.
  ##
  ## .. code-block:: Nim
  ##   (0b0011 and 0b0101) == 0b0001
  ##   (0b0111 and 0b1100) == 0b0100
proc `and`*(x, y: int8): int8 {.magic: "BitandI", noSideEffect.}
proc `and`*(x, y: int16): int16 {.magic: "BitandI", noSideEffect.}
proc `and`*(x, y: int32): int32 {.magic: "BitandI", noSideEffect.}
proc `and`*(x, y: int64): int64 {.magic: "BitandI", noSideEffect.}

proc `or`*(x, y: int): int {.magic: "BitorI", noSideEffect.}
  ## Computes the `bitwise or` of numbers `x` and `y`.
  ##
  ## .. code-block:: Nim
  ##   (0b0011 or 0b0101) == 0b0111
  ##   (0b0111 or 0b1100) == 0b1111
proc `or`*(x, y: int8): int8 {.magic: "BitorI", noSideEffect.}
proc `or`*(x, y: int16): int16 {.magic: "BitorI", noSideEffect.}
proc `or`*(x, y: int32): int32 {.magic: "BitorI", noSideEffect.}
proc `or`*(x, y: int64): int64 {.magic: "BitorI", noSideEffect.}

proc `xor`*(x, y: int): int {.magic: "BitxorI", noSideEffect.}
  ## Computes the `bitwise xor` of numbers `x` and `y`.
  ##
  ## .. code-block:: Nim
  ##   (0b0011 xor 0b0101) == 0b0110
  ##   (0b0111 xor 0b1100) == 0b1011
proc `xor`*(x, y: int8): int8 {.magic: "BitxorI", noSideEffect.}
proc `xor`*(x, y: int16): int16 {.magic: "BitxorI", noSideEffect.}
proc `xor`*(x, y: int32): int32 {.magic: "BitxorI", noSideEffect.}
proc `xor`*(x, y: int64): int64 {.magic: "BitxorI", noSideEffect.}

proc `==`*(x, y: int): bool {.magic: "EqI", noSideEffect.}
  ## Compares two integers for equality.
proc `==`*(x, y: int8): bool {.magic: "EqI", noSideEffect.}
proc `==`*(x, y: int16): bool {.magic: "EqI", noSideEffect.}
proc `==`*(x, y: int32): bool {.magic: "EqI", noSideEffect.}
proc `==`*(x, y: int64): bool {.magic: "EqI", noSideEffect.}

proc `<=`*(x, y: int): bool {.magic: "LeI", noSideEffect.}
  ## Returns true if `x` is less than or equal to `y`.
proc `<=`*(x, y: int8): bool {.magic: "LeI", noSideEffect.}
proc `<=`*(x, y: int16): bool {.magic: "LeI", noSideEffect.}
proc `<=`*(x, y: int32): bool {.magic: "LeI", noSideEffect.}
proc `<=`*(x, y: int64): bool {.magic: "LeI", noSideEffect.}

proc `<`*(x, y: int): bool {.magic: "LtI", noSideEffect.}
  ## Returns true if `x` is less than `y`.
proc `<`*(x, y: int8): bool {.magic: "LtI", noSideEffect.}
proc `<`*(x, y: int16): bool {.magic: "LtI", noSideEffect.}
proc `<`*(x, y: int32): bool {.magic: "LtI", noSideEffect.}
proc `<`*(x, y: int64): bool {.magic: "LtI", noSideEffect.}

type
  IntMax32 = int|int8|int16|int32

proc `+%`*(x, y: IntMax32): IntMax32 {.magic: "AddU", noSideEffect.}
proc `+%`*(x, y: int64): int64 {.magic: "AddU", noSideEffect.}
  ## Treats `x` and `y` as unsigned and adds them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

proc `-%`*(x, y: IntMax32): IntMax32 {.magic: "SubU", noSideEffect.}
proc `-%`*(x, y: int64): int64 {.magic: "SubU", noSideEffect.}
  ## Treats `x` and `y` as unsigned and subtracts them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

proc `*%`*(x, y: IntMax32): IntMax32 {.magic: "MulU", noSideEffect.}
proc `*%`*(x, y: int64): int64 {.magic: "MulU", noSideEffect.}
  ## Treats `x` and `y` as unsigned and multiplies them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

proc `/%`*(x, y: IntMax32): IntMax32 {.magic: "DivU", noSideEffect.}
proc `/%`*(x, y: int64): int64 {.magic: "DivU", noSideEffect.}
  ## Treats `x` and `y` as unsigned and divides them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

proc `%%`*(x, y: IntMax32): IntMax32 {.magic: "ModU", noSideEffect.}
proc `%%`*(x, y: int64): int64 {.magic: "ModU", noSideEffect.}
  ## Treats `x` and `y` as unsigned and compute the modulo of `x` and `y`.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

proc `<=%`*(x, y: IntMax32): bool {.magic: "LeU", noSideEffect.}
proc `<=%`*(x, y: int64): bool {.magic: "LeU64", noSideEffect.}
  ## Treats `x` and `y` as unsigned and compares them.
  ## Returns true if ``unsigned(x) <= unsigned(y)``.

proc `<%`*(x, y: IntMax32): bool {.magic: "LtU", noSideEffect.}
proc `<%`*(x, y: int64): bool {.magic: "LtU64", noSideEffect.}
  ## Treats `x` and `y` as unsigned and compares them.
  ## Returns true if ``unsigned(x) < unsigned(y)``.

template `>=%`*(x, y: untyped): untyped = y <=% x
  ## Treats `x` and `y` as unsigned and compares them.
  ## Returns true if ``unsigned(x) >= unsigned(y)``.

template `>%`*(x, y: untyped): untyped = y <% x
  ## Treats `x` and `y` as unsigned and compares them.
  ## Returns true if ``unsigned(x) > unsigned(y)``.


# unsigned integer operations:
proc `not`*(x: uint): uint {.magic: "BitnotI", noSideEffect.}
  ## Computes the `bitwise complement` of the integer `x`.
proc `not`*(x: uint8): uint8 {.magic: "BitnotI", noSideEffect.}
proc `not`*(x: uint16): uint16 {.magic: "BitnotI", noSideEffect.}
proc `not`*(x: uint32): uint32 {.magic: "BitnotI", noSideEffect.}
proc `not`*(x: uint64): uint64 {.magic: "BitnotI", noSideEffect.}

proc `shr`*(x: uint, y: SomeInteger): uint {.magic: "ShrI", noSideEffect.}
  ## Computes the `shift right` operation of `x` and `y`.
proc `shr`*(x: uint8, y: SomeInteger): uint8 {.magic: "ShrI", noSideEffect.}
proc `shr`*(x: uint16, y: SomeInteger): uint16 {.magic: "ShrI", noSideEffect.}
proc `shr`*(x: uint32, y: SomeInteger): uint32 {.magic: "ShrI", noSideEffect.}
proc `shr`*(x: uint64, y: SomeInteger): uint64 {.magic: "ShrI", noSideEffect.}

proc `shl`*(x: uint, y: SomeInteger): uint {.magic: "ShlI", noSideEffect.}
  ## Computes the `shift left` operation of `x` and `y`.
proc `shl`*(x: uint8, y: SomeInteger): uint8 {.magic: "ShlI", noSideEffect.}
proc `shl`*(x: uint16, y: SomeInteger): uint16 {.magic: "ShlI", noSideEffect.}
proc `shl`*(x: uint32, y: SomeInteger): uint32 {.magic: "ShlI", noSideEffect.}
proc `shl`*(x: uint64, y: SomeInteger): uint64 {.magic: "ShlI", noSideEffect.}

proc `and`*(x, y: uint): uint {.magic: "BitandI", noSideEffect.}
  ## Computes the `bitwise and` of numbers `x` and `y`.
proc `and`*(x, y: uint8): uint8 {.magic: "BitandI", noSideEffect.}
proc `and`*(x, y: uint16): uint16 {.magic: "BitandI", noSideEffect.}
proc `and`*(x, y: uint32): uint32 {.magic: "BitandI", noSideEffect.}
proc `and`*(x, y: uint64): uint64 {.magic: "BitandI", noSideEffect.}

proc `or`*(x, y: uint): uint {.magic: "BitorI", noSideEffect.}
  ## Computes the `bitwise or` of numbers `x` and `y`.
proc `or`*(x, y: uint8): uint8 {.magic: "BitorI", noSideEffect.}
proc `or`*(x, y: uint16): uint16 {.magic: "BitorI", noSideEffect.}
proc `or`*(x, y: uint32): uint32 {.magic: "BitorI", noSideEffect.}
proc `or`*(x, y: uint64): uint64 {.magic: "BitorI", noSideEffect.}

proc `xor`*(x, y: uint): uint {.magic: "BitxorI", noSideEffect.}
  ## Computes the `bitwise xor` of numbers `x` and `y`.
proc `xor`*(x, y: uint8): uint8 {.magic: "BitxorI", noSideEffect.}
proc `xor`*(x, y: uint16): uint16 {.magic: "BitxorI", noSideEffect.}
proc `xor`*(x, y: uint32): uint32 {.magic: "BitxorI", noSideEffect.}
proc `xor`*(x, y: uint64): uint64 {.magic: "BitxorI", noSideEffect.}

proc `==`*(x, y: uint): bool {.magic: "EqI", noSideEffect.}
  ## Compares two unsigned integers for equality.
proc `==`*(x, y: uint8): bool {.magic: "EqI", noSideEffect.}
proc `==`*(x, y: uint16): bool {.magic: "EqI", noSideEffect.}
proc `==`*(x, y: uint32): bool {.magic: "EqI", noSideEffect.}
proc `==`*(x, y: uint64): bool {.magic: "EqI", noSideEffect.}

proc `+`*(x, y: uint): uint {.magic: "AddU", noSideEffect.}
  ## Binary `+` operator for unsigned integers.
proc `+`*(x, y: uint8): uint8 {.magic: "AddU", noSideEffect.}
proc `+`*(x, y: uint16): uint16 {.magic: "AddU", noSideEffect.}
proc `+`*(x, y: uint32): uint32 {.magic: "AddU", noSideEffect.}
proc `+`*(x, y: uint64): uint64 {.magic: "AddU", noSideEffect.}

proc `-`*(x, y: uint): uint {.magic: "SubU", noSideEffect.}
  ## Binary `-` operator for unsigned integers.
proc `-`*(x, y: uint8): uint8 {.magic: "SubU", noSideEffect.}
proc `-`*(x, y: uint16): uint16 {.magic: "SubU", noSideEffect.}
proc `-`*(x, y: uint32): uint32 {.magic: "SubU", noSideEffect.}
proc `-`*(x, y: uint64): uint64 {.magic: "SubU", noSideEffect.}

proc `*`*(x, y: uint): uint {.magic: "MulU", noSideEffect.}
  ## Binary `*` operator for unsigned integers.
proc `*`*(x, y: uint8): uint8 {.magic: "MulU", noSideEffect.}
proc `*`*(x, y: uint16): uint16 {.magic: "MulU", noSideEffect.}
proc `*`*(x, y: uint32): uint32 {.magic: "MulU", noSideEffect.}
proc `*`*(x, y: uint64): uint64 {.magic: "MulU", noSideEffect.}

proc `div`*(x, y: uint): uint {.magic: "DivU", noSideEffect.}
  ## Computes the integer division for unsigned integers.
  ## This is roughly the same as ``trunc(x/y)``.
proc `div`*(x, y: uint8): uint8 {.magic: "DivU", noSideEffect.}
proc `div`*(x, y: uint16): uint16 {.magic: "DivU", noSideEffect.}
proc `div`*(x, y: uint32): uint32 {.magic: "DivU", noSideEffect.}
proc `div`*(x, y: uint64): uint64 {.magic: "DivU", noSideEffect.}

proc `mod`*(x, y: uint): uint {.magic: "ModU", noSideEffect.}
  ## Computes the integer modulo operation (remainder) for unsigned integers.
  ## This is the same as ``x - (x div y) * y``.
proc `mod`*(x, y: uint8): uint8 {.magic: "ModU", noSideEffect.}
proc `mod`*(x, y: uint16): uint16 {.magic: "ModU", noSideEffect.}
proc `mod`*(x, y: uint32): uint32 {.magic: "ModU", noSideEffect.}
proc `mod`*(x, y: uint64): uint64 {.magic: "ModU", noSideEffect.}

proc `<=`*(x, y: uint): bool {.magic: "LeU", noSideEffect.}
  ## Returns true if ``x <= y``.
proc `<=`*(x, y: uint8): bool {.magic: "LeU", noSideEffect.}
proc `<=`*(x, y: uint16): bool {.magic: "LeU", noSideEffect.}
proc `<=`*(x, y: uint32): bool {.magic: "LeU", noSideEffect.}
proc `<=`*(x, y: uint64): bool {.magic: "LeU", noSideEffect.}

proc `<`*(x, y: uint): bool {.magic: "LtU", noSideEffect.}
  ## Returns true if ``unsigned(x) < unsigned(y)``.
proc `<`*(x, y: uint8): bool {.magic: "LtU", noSideEffect.}
proc `<`*(x, y: uint16): bool {.magic: "LtU", noSideEffect.}
proc `<`*(x, y: uint32): bool {.magic: "LtU", noSideEffect.}
proc `<`*(x, y: uint64): bool {.magic: "LtU", noSideEffect.}

# floating point operations:
proc `+`*(x: float32): float32 {.magic: "UnaryPlusF64", noSideEffect.}
proc `-`*(x: float32): float32 {.magic: "UnaryMinusF64", noSideEffect.}
proc `+`*(x, y: float32): float32 {.magic: "AddF64", noSideEffect.}
proc `-`*(x, y: float32): float32 {.magic: "SubF64", noSideEffect.}
proc `*`*(x, y: float32): float32 {.magic: "MulF64", noSideEffect.}
proc `/`*(x, y: float32): float32 {.magic: "DivF64", noSideEffect.}

proc `+`*(x: float): float {.magic: "UnaryPlusF64", noSideEffect.}
proc `-`*(x: float): float {.magic: "UnaryMinusF64", noSideEffect.}
proc `+`*(x, y: float): float {.magic: "AddF64", noSideEffect.}
proc `-`*(x, y: float): float {.magic: "SubF64", noSideEffect.}
proc `*`*(x, y: float): float {.magic: "MulF64", noSideEffect.}
proc `/`*(x, y: float): float {.magic: "DivF64", noSideEffect.}

proc `==`*(x, y: float32): bool {.magic: "EqF64", noSideEffect.}
proc `<=`*(x, y: float32): bool {.magic: "LeF64", noSideEffect.}
proc `<`  *(x, y: float32): bool {.magic: "LtF64", noSideEffect.}

proc `==`*(x, y: float): bool {.magic: "EqF64", noSideEffect.}
proc `<=`*(x, y: float): bool {.magic: "LeF64", noSideEffect.}
proc `<`*(x, y: float): bool {.magic: "LtF64", noSideEffect.}

# set operators
proc `*`*[T](x, y: set[T]): set[T] {.magic: "MulSet", noSideEffect.}
  ## This operator computes the intersection of two sets.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {1, 2, 3}
  ##     b = {2, 3, 4}
  ##   echo a * b # => {2, 3}
proc `+`*[T](x, y: set[T]): set[T] {.magic: "PlusSet", noSideEffect.}
  ## This operator computes the union of two sets.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {1, 2, 3}
  ##     b = {2, 3, 4}
  ##   echo a + b # => {1, 2, 3, 4}
proc `-`*[T](x, y: set[T]): set[T] {.magic: "MinusSet", noSideEffect.}
  ## This operator computes the diference of two sets.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {1, 2, 3}
  ##     b = {2, 3, 4}
  ##   echo a - b # => {1}

proc contains*[T](x: set[T], y: T): bool {.magic: "InSet", noSideEffect.}
  ## One should overload this proc if one wants to overload the ``in`` operator.
  ##
  ## The parameters are in reverse order! ``a in b`` is a template for
  ## ``contains(b, a)``.
  ## This is because the unification algorithm that Nim uses for overload
  ## resolution works from left to right.
  ## But for the ``in`` operator that would be the wrong direction for this
  ## piece of code:
  ##
  ## .. code-block:: Nim
  ##   var s: set[range['a'..'z']] = {'a'..'c'}
  ##   assert s.contains('c')
  ##   assert 'b' in s
  ##
  ## If ``in`` had been declared as ``[T](elem: T, s: set[T])`` then ``T`` would
  ## have been bound to ``char``. But ``s`` is not compatible to type
  ## ``set[char]``! The solution is to bind ``T`` to ``range['a'..'z']``. This
  ## is achieved by reversing the parameters for ``contains``; ``in`` then
  ## passes its arguments in reverse order.

proc contains*[U, V, W](s: HSlice[U, V], value: W): bool {.noSideEffect, inline.} =
  ## Checks if `value` is within the range of `s`; returns true if
  ## `value >= s.a and value <= s.b`
  ##
  ## .. code-block:: Nim
  ##   assert((1..3).contains(1) == true)
  ##   assert((1..3).contains(2) == true)
  ##   assert((1..3).contains(4) == false)
  result = s.a <= value and value <= s.b

template `in`*(x, y: untyped): untyped {.dirty.} = contains(y, x)
  ## Sugar for `contains`.
  ##
  ## .. code-block:: Nim
  ##   assert(1 in (1..3) == true)
  ##   assert(5 in (1..3) == false)
template `notin`*(x, y: untyped): untyped {.dirty.} = not contains(y, x)
  ## Sugar for `not contains`.
  ##
  ## .. code-block:: Nim
  ##   assert(1 notin (1..3) == false)
  ##   assert(5 notin (1..3) == true)

proc `is`*[T, S](x: T, y: S): bool {.magic: "Is", noSideEffect.}
  ## Checks if `T` is of the same type as `S`.
  ##
  ## For a negated version, use `isnot <#isnot.t,untyped,untyped>`_.
  ##
  ## .. code-block:: Nim
  ##   assert 42 is int
  ##   assert @[1, 2] is seq
  ##
  ##   proc test[T](a: T): int =
  ##     when (T is int):
  ##       return a
  ##     else:
  ##       return 0
  ##
  ##   assert(test[int](3) == 3)
  ##   assert(test[string]("xyz") == 0)
template `isnot`*(x, y: untyped): untyped = not (x is y)
  ## Negated version of `is <#is,T,S>`_. Equivalent to ``not(x is y)``.
  ##
  ## .. code-block:: Nim
  ##   assert 42 isnot float
  ##   assert @[1, 2] isnot enum

when (defined(nimV2) and not defined(nimscript)) or defined(nimFixedOwned):
  type owned*[T]{.magic: "BuiltinType".} ## type constructor to mark a ref/ptr or a closure as `owned`.
else:
  template owned*(t: typedesc): typedesc = t

when defined(nimV2) and not defined(nimscript):
  proc new*[T](a: var owned(ref T)) {.magic: "New", noSideEffect.}
    ## Creates a new object of type ``T`` and returns a safe (traced)
    ## reference to it in ``a``.

  proc new*(t: typedesc): auto =
    ## Creates a new object of type ``T`` and returns a safe (traced)
    ## reference to it as result value.
    ##
    ## When ``T`` is a ref type then the resulting type will be ``T``,
    ## otherwise it will be ``ref T``.
    when (t is ref):
      var r: owned t
    else:
      var r: owned(ref t)
    new(r)
    return r

  proc unown*[T](x: T): T {.magic: "Unown", noSideEffect.}
    ## Use the expression ``x`` ignoring its ownership attribute.

  # This is only required to make 0.20 compile with the 0.19 line.
  template `<//>`*(t: untyped): untyped = owned(t)

else:
  template unown*(x: typed): untyped = x

  proc new*[T](a: var ref T) {.magic: "New", noSideEffect.}
    ## Creates a new object of type ``T`` and returns a safe (traced)
    ## reference to it in ``a``.

  proc new*(t: typedesc): auto =
    ## Creates a new object of type ``T`` and returns a safe (traced)
    ## reference to it as result value.
    ##
    ## When ``T`` is a ref type then the resulting type will be ``T``,
    ## otherwise it will be ``ref T``.
    when (t is ref):
      var r: t
    else:
      var r: ref t
    new(r)
    return r

  # This is only required to make 0.20 compile with the 0.19 line.
  template `<//>`*(t: untyped): untyped = t

template disarm*(x: typed) =
  ## Useful for ``disarming`` dangling pointers explicitly for the
  ## --newruntime. Regardless of whether --newruntime is used or not
  ## this sets the pointer or callback ``x`` to ``nil``. This is an
  ## experimental API!
  x = nil

proc `of`*[T, S](x: typedesc[T], y: typedesc[S]): bool {.magic: "Of", noSideEffect.}
proc `of`*[T, S](x: T, y: typedesc[S]): bool {.magic: "Of", noSideEffect.}
proc `of`*[T, S](x: T, y: S): bool {.magic: "Of", noSideEffect.}
  ## Checks if `x` has a type of `y`.
  ##
  ## .. code-block:: Nim
  ##   assert(FloatingPointError of Exception)
  ##   assert(DivByZeroError of Exception)

proc cmp*[T](x, y: T): int {.procvar.} =
  ## Generic compare proc.
  ##
  ## Returns:
  ## * a value less than zero, if `x < y`
  ## * a value greater than zero, if `x > y`
  ## * zero, if `x == y`
  ##
  ## This is useful for writing generic algorithms without performance loss.
  ## This generic implementation uses the `==` and `<` operators.
  ##
  ## .. code-block:: Nim
  ##  import algorithm
  ##  echo sorted(@[4, 2, 6, 5, 8, 7], cmp[int])
  if x == y: return 0
  if x < y: return -1
  return 1

proc cmp*(x, y: string): int {.noSideEffect, procvar.}
  ## Compare proc for strings. More efficient than the generic version.
  ##
  ## **Note**: The precise result values depend on the used C runtime library and
  ## can differ between operating systems!

when defined(nimHasDefault):
  proc `@`* [IDX, T](a: sink array[IDX, T]): seq[T] {.
    magic: "ArrToSeq", noSideEffect.}
    ## Turns an array into a sequence.
    ##
    ## This most often useful for constructing
    ## sequences with the array constructor: ``@[1, 2, 3]`` has the type
    ## ``seq[int]``, while ``[1, 2, 3]`` has the type ``array[0..2, int]``.
    ##
    ## .. code-block:: Nim
    ##   let
    ##     a = [1, 3, 5]
    ##     b = "foo"
    ##
    ##   echo @a # => @[1, 3, 5]
    ##   echo @b # => @['f', 'o', 'o']
else:
  proc `@`* [IDX, T](a: array[IDX, T]): seq[T] {.
    magic: "ArrToSeq", noSideEffect.}

when defined(nimHasDefault):
  proc default*(T: typedesc): T {.magic: "Default", noSideEffect.}
    ## returns the default value of the type ``T``.

proc setLen*[T](s: var seq[T], newlen: Natural) {.
  magic: "SetLengthSeq", noSideEffect.}
  ## Sets the length of seq `s` to `newlen`. ``T`` may be any sequence type.
  ##
  ## If the current length is greater than the new length,
  ## ``s`` will be truncated.
  ##
  ## .. code-block:: Nim
  ##   var x = @[10, 20]
  ##   x.setLen(5)
  ##   x[4] = 50
  ##   assert x == @[10, 20, 0, 0, 50]
  ##   x.setLen(1)
  ##   assert x == @[10]

proc setLen*(s: var string, newlen: Natural) {.
  magic: "SetLengthStr", noSideEffect.}
  ## Sets the length of string `s` to `newlen`.
  ##
  ## If the current length is greater than the new length,
  ## ``s`` will be truncated.
  ##
  ## .. code-block:: Nim
  ##  var myS = "Nim is great!!"
  ##  myS.setLen(3) # myS <- "Nim"
  ##  echo myS, " is fantastic!!"

proc newString*(len: Natural): string {.
  magic: "NewString", importc: "mnewString", noSideEffect.}
  ## Returns a new string of length ``len`` but with uninitialized
  ## content. One needs to fill the string character after character
  ## with the index operator ``s[i]``.
  ##
  ## This procedure exists only for optimization purposes;
  ## the same effect can be achieved with the ``&`` operator or with ``add``.

proc newStringOfCap*(cap: Natural): string {.
  magic: "NewStringOfCap", importc: "rawNewString", noSideEffect.}
  ## Returns a new string of length ``0`` but with capacity `cap`.
  ##
  ## This procedure exists only for optimization purposes; the same effect can
  ## be achieved with the ``&`` operator or with ``add``.

proc `&`*(x: string, y: char): string {.
  magic: "ConStrStr", noSideEffect, merge.}
  ## Concatenates `x` with `y`.
  ##
  ## .. code-block:: Nim
  ##   assert("ab" & 'c' == "abc")
proc `&`*(x, y: char): string {.
  magic: "ConStrStr", noSideEffect, merge.}
  ## Concatenates characters `x` and `y` into a string.
  ##
  ## .. code-block:: Nim
  ##   assert('a' & 'b' == "ab")
proc `&`*(x, y: string): string {.
  magic: "ConStrStr", noSideEffect, merge.}
  ## Concatenates strings `x` and `y`.
  ##
  ## .. code-block:: Nim
  ##   assert("ab" & "cd" == "abcd")
proc `&`*(x: char, y: string): string {.
  magic: "ConStrStr", noSideEffect, merge.}
  ## Concatenates `x` with `y`.
  ##
  ## .. code-block:: Nim
  ##   assert('a' & "bc" == "abc")

# implementation note: These must all have the same magic value "ConStrStr" so
# that the merge optimization works properly.

proc add*(x: var string, y: char) {.magic: "AppendStrCh", noSideEffect.}
  ## Appends `y` to `x` in place.
  ##
  ## .. code-block:: Nim
  ##   var tmp = ""
  ##   tmp.add('a')
  ##   tmp.add('b')
  ##   assert(tmp == "ab")
proc add*(x: var string, y: string) {.magic: "AppendStrStr", noSideEffect.}
  ## Concatenates `x` and `y` in place.
  ##
  ## .. code-block:: Nim
  ##   var tmp = ""
  ##   tmp.add("ab")
  ##   tmp.add("cd")
  ##   assert(tmp == "abcd")


type
  Endianness* = enum ## Type describing the endianness of a processor.
    littleEndian, bigEndian

const
  isMainModule* {.magic: "IsMainModule".}: bool = false
    ## True only when accessed in the main module. This works thanks to
    ## compiler magic. It is useful to embed testing code in a module.

  CompileDate* {.magic: "CompileDate"}: string = "0000-00-00"
    ## The date (in UTC) of compilation as a string of the form
    ## ``YYYY-MM-DD``. This works thanks to compiler magic.

  CompileTime* {.magic: "CompileTime"}: string = "00:00:00"
    ## The time (in UTC) of compilation as a string of the form
    ## ``HH:MM:SS``. This works thanks to compiler magic.

  cpuEndian* {.magic: "CpuEndian"}: Endianness = littleEndian
    ## The endianness of the target CPU. This is a valuable piece of
    ## information for low-level code only. This works thanks to compiler
    ## magic.

  hostOS* {.magic: "HostOS".}: string = ""
    ## A string that describes the host operating system.
    ##
    ## Possible values:
    ## `"windows"`, `"macosx"`, `"linux"`, `"netbsd"`, `"freebsd"`,
    ## `"openbsd"`, `"solaris"`, `"aix"`, `"haiku"`, `"standalone"`.

  hostCPU* {.magic: "HostCPU".}: string = ""
    ## A string that describes the host CPU.
    ##
    ## Possible values:
    ## `"i386"`, `"alpha"`, `"powerpc"`, `"powerpc64"`, `"powerpc64el"`,
    ## `"sparc"`, `"amd64"`, `"mips"`, `"mipsel"`, `"arm"`, `"arm64"`,
    ## `"mips64"`, `"mips64el"`, `"riscv64"`.

  seqShallowFlag = low(int)
  strlitFlag = 1 shl (sizeof(int)*8 - 2) # later versions of the codegen \
  # emit this flag
  # for string literals, it allows for some optimizations.

{.push profiler: off.}
let nimvm* {.magic: "Nimvm", compileTime.}: bool = false
  ## May be used only in `when` expression.
  ## It is true in Nim VM context and false otherwise.
{.pop.}

proc compileOption*(option: string): bool {.
  magic: "CompileOption", noSideEffect.}
  ## Can be used to determine an `on|off` compile-time option. Example:
  ##
  ## .. code-block:: Nim
  ##   when compileOption("floatchecks"):
  ##     echo "compiled with floating point NaN and Inf checks"

proc compileOption*(option, arg: string): bool {.
  magic: "CompileOptionArg", noSideEffect.}
  ## Can be used to determine an enum compile-time option. Example:
  ##
  ## .. code-block:: Nim
  ##   when compileOption("opt", "size") and compileOption("gc", "boehm"):
  ##     echo "compiled with optimization for size and uses Boehm's GC"

const
  hasThreadSupport = compileOption("threads") and not defined(nimscript)
  hasSharedHeap = defined(boehmgc) or defined(gogc) # don't share heaps; every thread has its own
  taintMode = compileOption("taintmode")
  nimEnableCovariance* = defined(nimEnableCovariance) # or true

when hasThreadSupport and defined(tcc) and not compileOption("tlsEmulation"):
  # tcc doesn't support TLS
  {.error: "``--tlsEmulation:on`` must be used when using threads with tcc backend".}

when defined(boehmgc):
  when defined(windows):
    when sizeof(int) == 8:
      const boehmLib = "boehmgc64.dll"
    else:
      const boehmLib = "boehmgc.dll"
  elif defined(macosx):
    const boehmLib = "libgc.dylib"
  elif defined(openbsd):
    const boehmLib = "libgc.so.4.0"
  else:
    const boehmLib = "libgc.so.1"
  {.pragma: boehmGC, noconv, dynlib: boehmLib.}

when taintMode:
  type TaintedString* = distinct string ## A distinct string type that
                                        ## is `tainted`:idx:, see `taint mode
                                        ## <manual_experimental.html#taint-mode>`_
                                        ## for details. It is an alias for
                                        ## ``string`` if the taint mode is not
                                        ## turned on.

  proc len*(s: TaintedString): int {.borrow.}
else:
  type TaintedString* = string          ## A distinct string type that
                                        ## is `tainted`:idx:, see `taint mode
                                        ## <manual_experimental.html#taint-mode>`_
                                        ## for details. It is an alias for
                                        ## ``string`` if the taint mode is not
                                        ## turned on.

when defined(profiler) and not defined(nimscript):
  proc nimProfile() {.compilerproc, noinline.}
when hasThreadSupport:
  {.pragma: rtlThreadVar, threadvar.}
else:
  {.pragma: rtlThreadVar.}

const
  QuitSuccess* = 0
    ## is the value that should be passed to `quit <#quit,int>`_ to indicate
    ## success.

  QuitFailure* = 1
    ## is the value that should be passed to `quit <#quit,int>`_ to indicate
    ## failure.

when defined(js) and defined(nodejs) and not defined(nimscript):
  var programResult* {.importc: "process.exitCode".}: int
  programResult = 0
elif hostOS != "standalone":
  var programResult* {.compilerproc, exportc: "nim_program_result".}: int
    ## deprecated, prefer ``quit``

when defined(nimdoc):
  proc quit*(errorcode: int = QuitSuccess) {.magic: "Exit", noreturn.}
    ## Stops the program immediately with an exit code.
    ##
    ## Before stopping the program the "quit procedures" are called in the
    ## opposite order they were added with `addQuitProc <#addQuitProc,proc>`_.
    ## ``quit`` never returns and ignores any exception that may have been raised
    ## by the quit procedures.  It does *not* call the garbage collector to free
    ## all the memory, unless a quit procedure calls `GC_fullCollect
    ## <#GC_fullCollect>`_.
    ##
    ## The proc ``quit(QuitSuccess)`` is called implicitly when your nim
    ## program finishes without incident for platforms where this is the
    ## expected behavior. A raised unhandled exception is
    ## equivalent to calling ``quit(QuitFailure)``.
    ##
    ## Note that this is a *runtime* call and using ``quit`` inside a macro won't
    ## have any compile time effect. If you need to stop the compiler inside a
    ## macro, use the `error <manual.html#pragmas-error-pragma>`_ or `fatal
    ## <manual.html#pragmas-fatal-pragma>`_ pragmas.

elif defined(genode):
  include genode/env

  var systemEnv {.exportc: runtimeEnvSym.}: GenodeEnvPtr

  type GenodeEnv* = GenodeEnvPtr
    ## Opaque type representing Genode environment.

  proc quit*(env: GenodeEnv; errorcode: int) {.magic: "Exit", noreturn,
    importcpp: "#->parent().exit(@); Genode::sleep_forever()", header: "<base/sleep.h>".}

  proc quit*(errorcode: int = QuitSuccess) =
    systemEnv.quit(errorcode)



elif defined(js) and defined(nodejs) and not defined(nimscript):
  proc quit*(errorcode: int = QuitSuccess) {.magic: "Exit",
    importc: "process.exit", noreturn.}

else:
  proc quit*(errorcode: int = QuitSuccess) {.
    magic: "Exit", importc: "exit", header: "<stdlib.h>", noreturn.}

template sysAssert(cond: bool, msg: string) =
  when defined(useSysAssert):
    if not cond:
      cstderr.rawWrite "[SYSASSERT] "
      cstderr.rawWrite msg
      cstderr.rawWrite "\n"
      quit 1

const hasAlloc = (hostOS != "standalone" or not defined(nogc)) and not defined(nimscript)

when not defined(JS) and not defined(nimscript) and hostOS != "standalone":
  include "system/cgprocs"
when not defined(JS) and not defined(nimscript) and hasAlloc and not defined(nimSeqsV2):
  proc addChar(s: NimString, c: char): NimString {.compilerproc, benign.}

when not defined(nimSeqsV2) or defined(nimscript):
  proc add*[T](x: var seq[T], y: T) {.magic: "AppendSeqElem", noSideEffect.}
    ## Generic proc for adding a data item `y` to a container `x`.
    ##
    ## For containers that have an order, `add` means *append*. New generic
    ## containers should also call their adding proc `add` for consistency.
    ## Generic code becomes much easier to write if the Nim naming scheme is
    ## respected.

proc add*[T](x: var seq[T], y: openArray[T]) {.noSideEffect.} =
  ## Generic proc for adding a container `y` to a container `x`.
  ##
  ## For containers that have an order, `add` means *append*. New generic
  ## containers should also call their adding proc `add` for consistency.
  ## Generic code becomes much easier to write if the Nim naming scheme is
  ## respected.
  ##
  ## See also:
  ## * `& proc <#&,seq[T][T],seq[T][T]>`_
  ##
  ## .. code-block:: Nim
  ##   var s: seq[string] = @["test2","test2"]
  ##   s.add("test") # s <- @[test2, test2, test]
  let xl = x.len
  setLen(x, xl + y.len)
  for i in 0..high(y): x[xl+i] = y[i]

when defined(nimSeqsV2):
  template movingCopy(a, b) =
    a = move(b)
else:
  template movingCopy(a, b) =
    shallowCopy(a, b)

proc del*[T](x: var seq[T], i: Natural) {.noSideEffect.} =
  ## Deletes the item at index `i` by putting ``x[high(x)]`` into position `i`.
  ##
  ## This is an `O(1)` operation.
  ##
  ## See also:
  ## * `delete <#delete,seq[T][T],Natural>`_ for preserving the order
  ##
  ## .. code-block:: Nim
  ##  var i = @[1, 2, 3, 4, 5]
  ##  i.del(2) # => @[1, 2, 5, 4]
  let xl = x.len - 1
  movingCopy(x[i], x[xl])
  setLen(x, xl)

proc delete*[T](x: var seq[T], i: Natural) {.noSideEffect.} =
  ## Deletes the item at index `i` by moving all ``x[i+1..]`` items by one position.
  ##
  ## This is an `O(n)` operation.
  ##
  ## See also:
  ## * `del <#delete,seq[T][T],Natural>`_ for O(1) operation
  ##
  ## .. code-block:: Nim
  ##  var i = @[1, 2, 3, 4, 5]
  ##  i.delete(2) # => @[1, 2, 4, 5]
  template defaultImpl =
    let xl = x.len
    for j in i.int..xl-2: movingCopy(x[j], x[j+1])
    setLen(x, xl-1)

  when nimvm:
    defaultImpl()
  else:
    when defined(js):
      {.emit: "`x`.splice(`i`, 1);".}
    else:
      defaultImpl()

proc insert*[T](x: var seq[T], item: T, i = 0.Natural) {.noSideEffect.} =
  ## Inserts `item` into `x` at position `i`.
  ##
  ## .. code-block:: Nim
  ##  var i = @[1, 3, 5]
  ##  i.insert(99, 0) # i <- @[99, 1, 3, 5]
  template defaultImpl =
    let xl = x.len
    setLen(x, xl+1)
    var j = xl-1
    while j >= i:
      movingCopy(x[j+1], x[j])
      dec(j)
  when nimvm:
    defaultImpl()
  else:
    when defined(js):
      var it : T
      {.emit: "`x` = `x` || []; `x`.splice(`i`, 0, `it`);".}
    else:
      defaultImpl()
  x[i] = item

proc repr*[T](x: T): string {.magic: "Repr", noSideEffect.}
  ## Takes any Nim variable and returns its string representation.
  ##
  ## It works even for complex data graphs with cycles. This is a great
  ## debugging tool.
  ##
  ## .. code-block:: Nim
  ##  var s: seq[string] = @["test2", "test2"]
  ##  var i = @[1, 2, 3, 4, 5]
  ##  echo repr(s) # => 0x1055eb050[0x1055ec050"test2", 0x1055ec078"test2"]
  ##  echo repr(i) # => 0x1055ed050[1, 2, 3, 4, 5]

type
  ByteAddress* = int
    ## is the signed integer type that should be used for converting
    ## pointers to integer addresses for readability.

  BiggestInt* = int64
    ## is an alias for the biggest signed integer type the Nim compiler
    ## supports. Currently this is ``int64``, but it is platform-dependant
    ## in general.

  BiggestFloat* = float64
    ## is an alias for the biggest floating point type the Nim
    ## compiler supports. Currently this is ``float64``, but it is
    ## platform-dependant in general.

when defined(JS):
  type BiggestUInt* = uint32
    ## is an alias for the biggest unsigned integer type the Nim compiler
    ## supports. Currently this is ``uint32`` for JS and ``uint64`` for other
    ## targets.
else:
  type BiggestUInt* = uint64
    ## is an alias for the biggest unsigned integer type the Nim compiler
    ## supports. Currently this is ``uint32`` for JS and ``uint64`` for other
    ## targets.

when defined(windows):
  type
    clong* {.importc: "long", nodecl.} = int32
      ## This is the same as the type ``long`` in *C*.
    culong* {.importc: "unsigned long", nodecl.} = uint32
      ## This is the same as the type ``unsigned long`` in *C*.
else:
  type
    clong* {.importc: "long", nodecl.} = int
      ## This is the same as the type ``long`` in *C*.
    culong* {.importc: "unsigned long", nodecl.} = uint
      ## This is the same as the type ``unsigned long`` in *C*.

type # these work for most platforms:
  cchar* {.importc: "char", nodecl.} = char
    ## This is the same as the type ``char`` in *C*.
  cschar* {.importc: "signed char", nodecl.} = int8
    ## This is the same as the type ``signed char`` in *C*.
  cshort* {.importc: "short", nodecl.} = int16
    ## This is the same as the type ``short`` in *C*.
  cint* {.importc: "int", nodecl.} = int32
    ## This is the same as the type ``int`` in *C*.
  csize* {.importc: "size_t", nodecl.} = int
    ## This is the same as the type ``size_t`` in *C*.
  clonglong* {.importc: "long long", nodecl.} = int64
    ## This is the same as the type ``long long`` in *C*.
  cfloat* {.importc: "float", nodecl.} = float32
    ## This is the same as the type ``float`` in *C*.
  cdouble* {.importc: "double", nodecl.} = float64
    ## This is the same as the type ``double`` in *C*.
  clongdouble* {.importc: "long double", nodecl.} = BiggestFloat
    ## This is the same as the type ``long double`` in *C*.
    ## This C type is not supported by Nim's code generator.

  cuchar* {.importc: "unsigned char", nodecl.} = char
    ## This is the same as the type ``unsigned char`` in *C*.
  cushort* {.importc: "unsigned short", nodecl.} = uint16
    ## This is the same as the type ``unsigned short`` in *C*.
  cuint* {.importc: "unsigned int", nodecl.} = uint32
    ## This is the same as the type ``unsigned int`` in *C*.
  culonglong* {.importc: "unsigned long long", nodecl.} = uint64
    ## This is the same as the type ``unsigned long long`` in *C*.

  cstringArray* {.importc: "char**", nodecl.} = ptr UncheckedArray[cstring]
    ## This is binary compatible to the type ``char**`` in *C*. The array's
    ## high value is large enough to disable bounds checking in practice.
    ## Use `cstringArrayToSeq proc <#cstringArrayToSeq,cstringArray,Natural>`_
    ## to convert it into a ``seq[string]``.

  PFloat32* = ptr float32    ## An alias for ``ptr float32``.
  PFloat64* = ptr float64    ## An alias for ``ptr float64``.
  PInt64* = ptr int64        ## An alias for ``ptr int64``.
  PInt32* = ptr int32        ## An alias for ``ptr int32``.

proc toFloat*(i: int): float {.noSideEffect, inline.} =
  ## Converts an integer `i` into a ``float``.
  ##
  ## If the conversion fails, `ValueError` is raised.
  ## However, on most platforms the conversion cannot fail.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = 2
  ##     b = 3.7
  ##
  ##   echo a.toFloat + b # => 5.7
  float(i)

proc toBiggestFloat*(i: BiggestInt): BiggestFloat {.noSideEffect, inline.} =
  ## Same as `toFloat <#toFloat,int>`_ but for ``BiggestInt`` to ``BiggestFloat``.
  BiggestFloat(i)

proc toInt*(f: float): int {.noSideEffect.} =
  ## Converts a floating point number `f` into an ``int``.
  ##
  ## Conversion rounds `f` half away from 0, see
  ## `Round half away from zero
  ## <https://en.wikipedia.org/wiki/Rounding#Round_half_away_from_zero>`_.
  ##
  ## Note that some floating point numbers (e.g. infinity or even 1e19)
  ## cannot be accurately converted.
  ##
  ## .. code-block:: Nim
  ##   doAssert toInt(0.49) == 0
  ##   doAssert toInt(0.5) == 1
  ##   doAssert toInt(-0.5) == -1 # rounding is symmetrical
  if f >= 0: int(f+0.5) else: int(f-0.5)

proc toBiggestInt*(f: BiggestFloat): BiggestInt {.noSideEffect.} =
  ## Same as `toInt <#toInt,float>`_ but for ``BiggestFloat`` to ``BiggestInt``.
  if f >= 0: BiggestInt(f+0.5) else: BiggestInt(f-0.5)

proc addQuitProc*(quitProc: proc() {.noconv.}) {.
  importc: "atexit", header: "<stdlib.h>".}
  ## Adds/registers a quit procedure.
  ##
  ## Each call to ``addQuitProc`` registers another quit procedure. Up to 30
  ## procedures can be registered. They are executed on a last-in, first-out
  ## basis (that is, the last function registered is the first to be executed).
  ## ``addQuitProc`` raises an EOutOfIndex exception if ``quitProc`` cannot be
  ## registered.

# Support for addQuitProc() is done by Ansi C's facilities here.
# In case of an unhandled exception the exit handlers should
# not be called explicitly! The user may decide to do this manually though.

when not defined(nimscript) and not defined(JS):
  proc zeroMem*(p: pointer, size: Natural) {.inline, noSideEffect,
    tags: [], locks: 0, raises: [].}
    ## Overwrites the contents of the memory at ``p`` with the value 0.
    ##
    ## Exactly ``size`` bytes will be overwritten. Like any procedure
    ## dealing with raw memory this is **unsafe**.

  proc copyMem*(dest, source: pointer, size: Natural) {.inline, benign,
    tags: [], locks: 0, raises: [].}
    ## Copies the contents from the memory at ``source`` to the memory
    ## at ``dest``.
    ## Exactly ``size`` bytes will be copied. The memory
    ## regions may not overlap. Like any procedure dealing with raw
    ## memory this is **unsafe**.

  proc moveMem*(dest, source: pointer, size: Natural) {.inline, benign,
    tags: [], locks: 0, raises: [].}
    ## Copies the contents from the memory at ``source`` to the memory
    ## at ``dest``.
    ##
    ## Exactly ``size`` bytes will be copied. The memory
    ## regions may overlap, ``moveMem`` handles this case appropriately
    ## and is thus somewhat more safe than ``copyMem``. Like any procedure
    ## dealing with raw memory this is still **unsafe**, though.

  proc equalMem*(a, b: pointer, size: Natural): bool {.inline, noSideEffect,
    tags: [], locks: 0, raises: [].}
    ## Compares the memory blocks ``a`` and ``b``. ``size`` bytes will
    ## be compared.
    ##
    ## If the blocks are equal, `true` is returned, `false`
    ## otherwise. Like any procedure dealing with raw memory this is
    ## **unsafe**.

when not defined(nimscript):
  when hasAlloc:
    proc alloc*(size: Natural): pointer {.noconv, rtl, tags: [], benign, raises: [].}
      ## Allocates a new memory block with at least ``size`` bytes.
      ##
      ## The block has to be freed with `realloc(block, 0) <#realloc,pointer,Natural>`_
      ## or `dealloc(block) <#dealloc,pointer>`_.
      ## The block is not initialized, so reading
      ## from it before writing to it is undefined behaviour!
      ##
      ## The allocated memory belongs to its allocating thread!
      ## Use `allocShared <#allocShared,Natural>`_ to allocate from a shared heap.
      ##
      ## See also:
      ## * `alloc0 <#alloc0,Natural>`_
    proc createU*(T: typedesc, size = 1.Positive): ptr T {.inline, benign, raises: [].} =
      ## Allocates a new memory block with at least ``T.sizeof * size`` bytes.
      ##
      ## The block has to be freed with `resize(block, 0) <#resize,ptr.T,Natural>`_
      ## or `dealloc(block) <#dealloc,pointer>`_.
      ## The block is not initialized, so reading
      ## from it before writing to it is undefined behaviour!
      ##
      ## The allocated memory belongs to its allocating thread!
      ## Use `createSharedU <#createSharedU,typedesc>`_ to allocate from a shared heap.
      ##
      ## See also:
      ## * `create <#create,typedesc>`_
      cast[ptr T](alloc(T.sizeof * size))

    proc alloc0*(size: Natural): pointer {.noconv, rtl, tags: [], benign, raises: [].}
      ## Allocates a new memory block with at least ``size`` bytes.
      ##
      ## The block has to be freed with `realloc(block, 0) <#realloc,pointer,Natural>`_
      ## or `dealloc(block) <#dealloc,pointer>`_.
      ## The block is initialized with all bytes containing zero, so it is
      ## somewhat safer than  `alloc <#alloc,Natural>`_.
      ##
      ## The allocated memory belongs to its allocating thread!
      ## Use `allocShared0 <#allocShared0,Natural>`_ to allocate from a shared heap.
    proc create*(T: typedesc, size = 1.Positive): ptr T {.inline, benign, raises: [].} =
      ## Allocates a new memory block with at least ``T.sizeof * size`` bytes.
      ##
      ## The block has to be freed with `resize(block, 0) <#resize,ptr.T,Natural>`_
      ## or `dealloc(block) <#dealloc,pointer>`_.
      ## The block is initialized with all bytes containing zero, so it is
      ## somewhat safer than `createU <#createU,typedesc>`_.
      ##
      ## The allocated memory belongs to its allocating thread!
      ## Use `createShared <#createShared,typedesc>`_ to allocate from a shared heap.
      cast[ptr T](alloc0(sizeof(T) * size))

    proc realloc*(p: pointer, newSize: Natural): pointer {.noconv, rtl, tags: [],
                                                           benign, raises: [].}
      ## Grows or shrinks a given memory block.
      ##
      ## If `p` is **nil** then a new memory block is returned.
      ## In either way the block has at least ``newSize`` bytes.
      ## If ``newSize == 0`` and `p` is not **nil** ``realloc`` calls ``dealloc(p)``.
      ## In other cases the block has to be freed with
      ## `dealloc(block) <#dealloc,pointer>`_.
      ##
      ## The allocated memory belongs to its allocating thread!
      ## Use `reallocShared <#reallocShared,pointer,Natural>`_ to reallocate
      ## from a shared heap.
    proc resize*[T](p: ptr T, newSize: Natural): ptr T {.inline, benign, raises: [].} =
      ## Grows or shrinks a given memory block.
      ##
      ## If `p` is **nil** then a new memory block is returned.
      ## In either way the block has at least ``T.sizeof * newSize`` bytes.
      ## If ``newSize == 0`` and `p` is not **nil** ``resize`` calls ``dealloc(p)``.
      ## In other cases the block has to be freed with ``free``.
      ##
      ## The allocated memory belongs to its allocating thread!
      ## Use `resizeShared <#resizeShared,ptr.T,Natural>`_ to reallocate
      ## from a shared heap.
      cast[ptr T](realloc(p, T.sizeof * newSize))

    proc dealloc*(p: pointer) {.noconv, rtl, tags: [], benign, raises: [].}
      ## Frees the memory allocated with ``alloc``, ``alloc0`` or
      ## ``realloc``.
      ##
      ## **This procedure is dangerous!**
      ## If one forgets to free the memory a leak occurs; if one tries to
      ## access freed memory (or just freeing it twice!) a core dump may happen
      ## or other memory may be corrupted.
      ##
      ## The freed memory must belong to its allocating thread!
      ## Use `deallocShared <#deallocShared,pointer>`_ to deallocate from a shared heap.

    proc allocShared*(size: Natural): pointer {.noconv, rtl, benign, raises: [].}
      ## Allocates a new memory block on the shared heap with at
      ## least ``size`` bytes.
      ##
      ## The block has to be freed with
      ## `reallocShared(block, 0) <#reallocShared,pointer,Natural>`_
      ## or `deallocShared(block) <#deallocShared,pointer>`_.
      ##
      ## The block is not initialized, so reading from it before writing
      ## to it is undefined behaviour!
      ##
      ## See also:
      ## `allocShared0 <#allocShared0,Natural>`_.
    proc createSharedU*(T: typedesc, size = 1.Positive): ptr T {.inline,
                                                                 benign, raises: [].} =
      ## Allocates a new memory block on the shared heap with at
      ## least ``T.sizeof * size`` bytes.
      ##
      ## The block has to be freed with
      ## `resizeShared(block, 0) <#resizeShared,ptr.T,Natural>`_ or
      ## `freeShared(block) <#freeShared,ptr.T>`_.
      ##
      ## The block is not initialized, so reading from it before writing
      ## to it is undefined behaviour!
      ##
      ## See also:
      ## * `createShared <#createShared,typedesc>`_
      cast[ptr T](allocShared(T.sizeof * size))

    proc allocShared0*(size: Natural): pointer {.noconv, rtl, benign, raises: [].}
      ## Allocates a new memory block on the shared heap with at
      ## least ``size`` bytes.
      ##
      ## The block has to be freed with
      ## `reallocShared(block, 0) <#reallocShared,pointer,Natural>`_
      ## or `deallocShared(block) <#deallocShared,pointer>`_.
      ##
      ## The block is initialized with all bytes
      ## containing zero, so it is somewhat safer than
      ## `allocShared <#allocShared,Natural>`_.
    proc createShared*(T: typedesc, size = 1.Positive): ptr T {.inline.} =
      ## Allocates a new memory block on the shared heap with at
      ## least ``T.sizeof * size`` bytes.
      ##
      ## The block has to be freed with
      ## `resizeShared(block, 0) <#resizeShared,ptr.T,Natural>`_ or
      ## `freeShared(block) <#freeShared,ptr.T>`_.
      ##
      ## The block is initialized with all bytes
      ## containing zero, so it is somewhat safer than
      ## `createSharedU <#createSharedU,typedesc>`_.
      cast[ptr T](allocShared0(T.sizeof * size))

    proc reallocShared*(p: pointer, newSize: Natural): pointer {.noconv, rtl,
                                                                 benign, raises: [].}
      ## Grows or shrinks a given memory block on the heap.
      ##
      ## If `p` is **nil** then a new memory block is returned.
      ## In either way the block has at least ``newSize`` bytes.
      ## If ``newSize == 0`` and `p` is not **nil** ``reallocShared`` calls
      ## ``deallocShared(p)``.
      ## In other cases the block has to be freed with
      ## `deallocShared <#deallocShared,pointer>`_.
    proc resizeShared*[T](p: ptr T, newSize: Natural): ptr T {.inline, raises: [].} =
      ## Grows or shrinks a given memory block on the heap.
      ##
      ## If `p` is **nil** then a new memory block is returned.
      ## In either way the block has at least ``T.sizeof * newSize`` bytes.
      ## If ``newSize == 0`` and `p` is not **nil** ``resizeShared`` calls
      ## ``freeShared(p)``.
      ## In other cases the block has to be freed with
      ## `freeShared <#freeShared,ptr.T>`_.
      cast[ptr T](reallocShared(p, T.sizeof * newSize))

    proc deallocShared*(p: pointer) {.noconv, rtl, benign, raises: [].}
      ## Frees the memory allocated with ``allocShared``, ``allocShared0`` or
      ## ``reallocShared``.
      ##
      ## **This procedure is dangerous!**
      ## If one forgets to free the memory a leak occurs; if one tries to
      ## access freed memory (or just freeing it twice!) a core dump may happen
      ## or other memory may be corrupted.
    proc freeShared*[T](p: ptr T) {.inline, benign, raises: [].} =
      ## Frees the memory allocated with ``createShared``, ``createSharedU`` or
      ## ``resizeShared``.
      ##
      ## **This procedure is dangerous!**
      ## If one forgets to free the memory a leak occurs; if one tries to
      ## access freed memory (or just freeing it twice!) a core dump may happen
      ## or other memory may be corrupted.
      deallocShared(p)

proc swap*[T](a, b: var T) {.magic: "Swap", noSideEffect.}
  ## Swaps the values `a` and `b`.
  ##
  ## This is often more efficient than ``tmp = a; a = b; b = tmp``.
  ## Particularly useful for sorting algorithms.
  ##
  ## .. code-block:: Nim
  ##   var
  ##     a = 5
  ##     b = 9
  ##
  ##   swap(a, b)
  ##
  ##   assert a == 9
  ##   assert b == 5

when not defined(js) and not defined(booting) and defined(nimTrMacros):
  template swapRefsInArray*{swap(arr[a], arr[b])}(arr: openArray[ref], a, b: int) =
    # Optimize swapping of array elements if they are refs. Default swap
    # implementation will cause unsureAsgnRef to be emitted which causes
    # unnecessary slow down in this case.
    swap(cast[ptr pointer](addr arr[a])[], cast[ptr pointer](addr arr[b])[])


# undocumented:
proc getRefcount*[T](x: ref T): int {.importc: "getRefcount", noSideEffect,
  deprecated: "the refcount was never reliable, the GC does not use traditional refcounting".}
proc getRefcount*(x: string): int {.importc: "getRefcount", noSideEffect,
  deprecated: "the refcount was never reliable, the GC does not use traditional refcounting".}
proc getRefcount*[T](x: seq[T]): int {.importc: "getRefcount", noSideEffect,
  deprecated: "the refcount was never reliable, the GC does not use traditional refcounting".}
  ##
  ## Retrieves the reference count of an heap-allocated object. The
  ## value is implementation-dependent.


const
  Inf* = 0x7FF0000000000000'f64
    ## Contains the IEEE floating point value of positive infinity.
  NegInf* = 0xFFF0000000000000'f64
    ## Contains the IEEE floating point value of negative infinity.
  NaN* = 0x7FF7FFFFFFFFFFFF'f64
    ## Contains an IEEE floating point value of *Not A Number*.
    ##
    ## Note that you cannot compare a floating point value to this value
    ## and expect a reasonable result - use the `classify` procedure
    ## in the `math module <math.html>`_ for checking for NaN.

# GC interface:

when not defined(nimscript) and hasAlloc:
  proc getOccupiedMem*(): int {.rtl.}
    ## Returns the number of bytes that are owned by the process and hold data.

  proc getFreeMem*(): int {.rtl.}
    ## Returns the number of bytes that are owned by the process, but do not
    ## hold any meaningful data.

  proc getTotalMem*(): int {.rtl.}
    ## Returns the number of bytes that are owned by the process.

  when hasThreadSupport:
    proc getOccupiedSharedMem*(): int {.rtl.}
      ## Returns the number of bytes that are owned by the process
      ## on the shared heap and hold data. This is only available when
      ## threads are enabled.

    proc getFreeSharedMem*(): int {.rtl.}
      ## Returns the number of bytes that are owned by the
      ## process on the shared heap, but do not hold any meaningful data.
      ## This is only available when threads are enabled.

    proc getTotalSharedMem*(): int {.rtl.}
      ## Returns the number of bytes on the shared heap that are owned by the
      ## process. This is only available when threads are enabled.

proc `|`*(a, b: typedesc): typedesc = discard

when sizeof(int) <= 2:
  type IntLikeForCount = int|int8|int16|char|bool|uint8|enum
else:
  type IntLikeForCount = int|int8|int16|int32|char|bool|uint8|uint16|enum

iterator countdown*[T](a, b: T, step: Positive = 1): T {.inline.} =
  ## Counts from ordinal value `a` down to `b` (inclusive) with the given
  ## step count.
  ##
  ## `T` may be any ordinal type, `step` may only be positive.
  ##
  ## **Note**: This fails to count to ``low(int)`` if T = int for
  ## efficiency reasons.
  ##
  ## .. code-block:: Nim
  ##   for i in countdown(7, 3):
  ##     echo i # => 7; 6; 5; 4; 3
  ##
  ##   for i in countdown(9, 2, 3):
  ##     echo i # => 9; 6; 3
  when T is (uint|uint64):
    var res = a
    while res >= b:
      yield res
      if res == b: break
      dec(res, step)
  elif T is IntLikeForCount:
    var res = int(a)
    while res >= int(b):
      yield T(res)
      dec(res, step)
  else:
    var res = a
    while res >= b:
      yield res
      dec(res, step)

when defined(nimNewRoof):
  iterator countup*[T](a, b: T, step: Positive = 1): T {.inline.} =
    ## Counts from ordinal value `a` to `b` (inclusive) with the given
    ## step count.
    ##
    ## `T` may be any ordinal type, `step` may only be positive.
    ##
    ## **Note**: This fails to count to ``high(int)`` if T = int for
    ## efficiency reasons.
    ##
    ## .. code-block:: Nim
    ##   for i in countup(3, 7):
    ##     echo i # => 3; 4; 5; 6; 7
    ##
    ##   for i in countup(2, 9, 3):
    ##     echo i # => 2; 5; 8
    mixin inc
    when T is IntLikeForCount:
      var res = int(a)
      while res <= int(b):
        yield T(res)
        inc(res, step)
    else:
      var res: T = T(a)
      while res <= b:
        yield res
        inc(res, step)

  iterator `..`*[T](a, b: T): T {.inline.} =
    ## An alias for `countup(a, b, 1)`.
    ##
    ## See also:
    ## * [..<](#..<.i,T,T)
    ##
    ## .. code-block:: Nim
    ##   for i in 3 .. 7:
    ##     echo i # => 3; 4; 5; 6; 7
    mixin inc
    when T is IntLikeForCount:
      var res = int(a)
      while res <= int(b):
        yield T(res)
        inc(res)
    else:
      var res: T = T(a)
      while res <= b:
        yield res
        inc(res)

  template dotdotImpl(t) {.dirty.} =
    iterator `..`*(a, b: t): t {.inline.} =
      ## A type specialized version of ``..`` for convenience so that
      ## mixing integer types works better.
      ##
      ## See also:
      ## * [..<](#..<.i,T,T)
      var res = a
      while res <= b:
        yield res
        inc(res)

  dotdotImpl(int64)
  dotdotImpl(int32)
  dotdotImpl(uint64)
  dotdotImpl(uint32)

  iterator `..<`*[T](a, b: T): T {.inline.} =
    mixin inc
    var i = T(a)
    while i < b:
      yield i
      inc i

  template dotdotLessImpl(t) {.dirty.} =
    iterator `..<`*(a, b: t): t {.inline.} =
      ## A type specialized version of ``..<`` for convenience so that
      ## mixing integer types works better.
      var res = a
      while res < b:
        yield res
        inc(res)

  dotdotLessImpl(int64)
  dotdotLessImpl(int32)
  dotdotLessImpl(uint64)
  dotdotLessImpl(uint32)

else:
  iterator countup*[S, T](a: S, b: T, step = 1): T {.inline.} =
    ## Counts from ordinal value `a` up to `b` (inclusive) with the given
    ## step count.
    ##
    ## `S`, `T` may be any ordinal type, `step` may only be positive.
    ##
    ## **Note**: This fails to count to ``high(int)`` if T = int for
    ## efficiency reasons.
    ##
    ## .. code-block:: Nim
    ##   for i in countup(3, 7):
    ##     echo i # => 3; 4; 5; 6; 7
    ##
    ##   for i in countup(2, 9, 3):
    ##     echo i # => 2; 5; 8
    when T is IntLikeForCount:
      var res = int(a)
      while res <= int(b):
        yield T(res)
        inc(res, step)
    else:
      var res: T = T(a)
      while res <= b:
        yield res
        inc(res, step)

  iterator `..`*[S, T](a: S, b: T): T {.inline.} =
    ## An alias for `countup(a, b, 1)`.
    ##
    ## See also:
    ## * [..<](#..<.i,T,T)
    ##
    ## .. code-block:: Nim
    ##   for i in 3 .. 7:
    ##     echo i # => 3; 4; 5; 6; 7
    mixin inc
    when T is IntLikeForCount:
      var res = int(a)
      while res <= int(b):
        yield T(res)
        inc(res)
    else:
      var res: T = T(a)
      while res <= b:
        yield res
        inc(res)

  iterator `..<`*[S, T](a: S, b: T): T {.inline.} =
    mixin inc
    var i = T(a)
    while i < b:
      yield i
      inc i


iterator `||`*[S, T](a: S, b: T, annotation: static string = "parallel for"): T {.
  inline, magic: "OmpParFor", sideEffect.} =
  ## OpenMP parallel loop iterator. Same as `..` but the loop may run in parallel.
  ##
  ## `annotation` is an additional annotation for the code generator to use.
  ## The default annotation is `parallel for`.
  ## Please refer to the `OpenMP Syntax Reference
  ## <https://www.openmp.org/wp-content/uploads/OpenMP-4.5-1115-CPP-web.pdf>`_
  ## for further information.
  ##
  ## Note that the compiler maps that to
  ## the ``#pragma omp parallel for`` construct of `OpenMP`:idx: and as
  ## such isn't aware of the parallelism in your code! Be careful! Later
  ## versions of ``||`` will get proper support by Nim's code generator
  ## and GC.
  discard

iterator `||`*[S, T](a: S, b: T, step: Positive, annotation: static string = "parallel for"): T {.
  inline, magic: "OmpParFor", sideEffect.} =
  ## OpenMP parallel loop iterator with stepping.
  ## Same as `countup` but the loop may run in parallel.
  ##
  ## `annotation` is an additional annotation for the code generator to use.
  ## The default annotation is `parallel for`.
  ## Please refer to the `OpenMP Syntax Reference
  ## <https://www.openmp.org/wp-content/uploads/OpenMP-4.5-1115-CPP-web.pdf>`_
  ## for further information.
  ##
  ## Note that the compiler maps that to
  ## the ``#pragma omp parallel for`` construct of `OpenMP`:idx: and as
  ## such isn't aware of the parallelism in your code! Be careful! Later
  ## versions of ``||`` will get proper support by Nim's code generator
  ## and GC.
  discard

{.push stackTrace:off.}
proc min*(x, y: int): int {.magic: "MinI", noSideEffect.} =
  if x <= y: x else: y
proc min*(x, y: int8): int8 {.magic: "MinI", noSideEffect.} =
  if x <= y: x else: y
proc min*(x, y: int16): int16 {.magic: "MinI", noSideEffect.} =
  if x <= y: x else: y
proc min*(x, y: int32): int32 {.magic: "MinI", noSideEffect.} =
  if x <= y: x else: y
proc min*(x, y: int64): int64 {.magic: "MinI", noSideEffect.} =
  ## The minimum value of two integers.
  if x <= y: x else: y

proc min*[T](x: openArray[T]): T =
  ## The minimum value of `x`. ``T`` needs to have a ``<`` operator.
  result = x[0]
  for i in 1..high(x):
    if x[i] < result: result = x[i]

proc max*(x, y: int): int {.magic: "MaxI", noSideEffect.} =
  if y <= x: x else: y
proc max*(x, y: int8): int8 {.magic: "MaxI", noSideEffect.} =
  if y <= x: x else: y
proc max*(x, y: int16): int16 {.magic: "MaxI", noSideEffect.} =
  if y <= x: x else: y
proc max*(x, y: int32): int32 {.magic: "MaxI", noSideEffect.} =
  if y <= x: x else: y
proc max*(x, y: int64): int64 {.magic: "MaxI", noSideEffect.} =
  ## The maximum value of two integers.
  if y <= x: x else: y

proc max*[T](x: openArray[T]): T =
  ## The maximum value of `x`. ``T`` needs to have a ``<`` operator.
  result = x[0]
  for i in 1..high(x):
    if result < x[i]: result = x[i]

proc abs*(x: float64): float64 {.noSideEffect, inline.} =
  if x < 0.0: -x else: x
proc abs*(x: float32): float32 {.noSideEffect, inline.} =
  if x < 0.0: -x else: x
proc min*(x, y: float32): float32 {.noSideEffect, inline.} =
  if x <= y or y != y: x else: y
proc min*(x, y: float64): float64 {.noSideEffect, inline.} =
  if x <= y or y != y: x else: y
proc max*(x, y: float32): float32 {.noSideEffect, inline.} =
  if y <= x or y != y: x else: y
proc max*(x, y: float64): float64 {.noSideEffect, inline.} =
  if y <= x or y != y: x else: y
proc min*[T: not SomeFloat](x, y: T): T {.inline.} =
  if x <= y: x else: y
proc max*[T: not SomeFloat](x, y: T): T {.inline.} =
  if y <= x: x else: y
{.pop.}

proc high*(T: typedesc[SomeFloat]): T = Inf
proc low*(T: typedesc[SomeFloat]): T = NegInf

proc clamp*[T](x, a, b: T): T =
  ## Limits the value ``x`` within the interval [a, b].
  ##
  ## .. code-block:: Nim
  ##   assert((1.4).clamp(0.0, 1.0) == 1.0)
  ##   assert((0.5).clamp(0.0, 1.0) == 0.5)
  if x < a: return a
  if x > b: return b
  return x

proc len*[U: Ordinal; V: Ordinal](x: HSlice[U, V]): int {.noSideEffect, inline.} =
  ## Length of ordinal slice. When x.b < x.a returns zero length.
  ##
  ## .. code-block:: Nim
  ##   assert((0..5).len == 6)
  ##   assert((5..2).len == 0)
  result = max(0, ord(x.b) - ord(x.a) + 1)

when defined(nimNoNilSeqs2):
  when not compileOption("nilseqs"):
    {.pragma: nilError, error.}
  else:
    {.pragma: nilError.}
else:
  {.pragma: nilError.}

proc isNil*[T](x: seq[T]): bool {.noSideEffect, magic: "IsNil", nilError.}
proc isNil*[T](x: ref T): bool {.noSideEffect, magic: "IsNil".}
proc isNil*(x: string): bool {.noSideEffect, magic: "IsNil", nilError.}

proc isNil*[T](x: ptr T): bool {.noSideEffect, magic: "IsNil".}
proc isNil*(x: pointer): bool {.noSideEffect, magic: "IsNil".}
proc isNil*(x: cstring): bool {.noSideEffect, magic: "IsNil".}
proc isNil*[T: proc](x: T): bool {.noSideEffect, magic: "IsNil".}
  ## Fast check whether `x` is nil. This is sometimes more efficient than
  ## ``== nil``.

proc `==`*[I, T](x, y: array[I, T]): bool =
  for f in low(x)..high(x):
    if x[f] != y[f]:
      return
  result = true

proc `==`*[T](x, y: openArray[T]): bool =
  if x.len != y.len:
    return false

  for f in low(x)..high(x):
    if x[f] != y[f]:
      return false

  result = true

proc `@`*[T](a: openArray[T]): seq[T] =
  ## Turns an *openArray* into a sequence.
  ##
  ## This is not as efficient as turning a fixed length array into a sequence
  ## as it always copies every element of `a`.
  newSeq(result, a.len)
  for i in 0..a.len-1: result[i] = a[i]

proc `&`*[T](x, y: seq[T]): seq[T] {.noSideEffect.} =
  ## Concatenates two sequences.
  ##
  ## Requires copying of the sequences.
  ##
  ## See also:
  ## * `add(var seq[T], openArray[T]) <#add,seq[T][T],openArray[T]>`_
  ##
  ## .. code-block:: Nim
  ##   assert(@[1, 2, 3, 4] & @[5, 6] == @[1, 2, 3, 4, 5, 6])
  newSeq(result, x.len + y.len)
  for i in 0..x.len-1:
    result[i] = x[i]
  for i in 0..y.len-1:
    result[i+x.len] = y[i]

proc `&`*[T](x: seq[T], y: T): seq[T] {.noSideEffect.} =
  ## Appends element y to the end of the sequence.
  ##
  ## Requires copying of the sequence.
  ##
  ## See also:
  ## * `add(var seq[T], T) <#add,seq[T][T],T>`_
  ##
  ## .. code-block:: Nim
  ##   assert(@[1, 2, 3] & 4 == @[1, 2, 3, 4])
  newSeq(result, x.len + 1)
  for i in 0..x.len-1:
    result[i] = x[i]
  result[x.len] = y

proc `&`*[T](x: T, y: seq[T]): seq[T] {.noSideEffect.} =
  ## Prepends the element x to the beginning of the sequence.
  ##
  ## Requires copying of the sequence.
  ##
  ## .. code-block:: Nim
  ##   assert(1 & @[2, 3, 4] == @[1, 2, 3, 4])
  newSeq(result, y.len + 1)
  result[0] = x
  for i in 0..y.len-1:
    result[i+1] = y[i]

proc `==`*[T](x, y: seq[T]): bool {.noSideEffect.} =
  ## Generic equals operator for sequences: relies on a equals operator for
  ## the element type `T`.
  when nimvm:
    when not defined(nimNoNil):
      if x.isNil and y.isNil:
        return true
    else:
      if x.len == 0 and y.len == 0:
        return true
  else:
    when not defined(JS):
      proc seqToPtr[T](x: seq[T]): pointer {.inline, noSideEffect.} =
        when defined(nimSeqsV2):
          result = cast[NimSeqV2[T]](x).p
        else:
          result = cast[pointer](x)

      if seqToPtr(x) == seqToPtr(y):
        return true
    else:
      var sameObject = false
      asm """`sameObject` = `x` === `y`"""
      if sameObject: return true

  when not defined(nimNoNil):
    if x.isNil or y.isNil:
      return false

  if x.len != y.len:
    return false

  for i in 0..x.len-1:
    if x[i] != y[i]:
      return false

  return true

proc astToStr*[T](x: T): string {.magic: "AstToStr", noSideEffect.}
  ## Converts the AST of `x` into a string representation. This is very useful
  ## for debugging.

proc instantiationInfo*(index = -1, fullPaths = false): tuple[
  filename: string, line: int, column: int] {.magic: "InstantiationInfo", noSideEffect.}
  ## Provides access to the compiler's instantiation stack line information
  ## of a template.
  ##
  ## While similar to the `caller info`:idx: of other languages, it is determined
  ## at compile time.
  ##
  ## This proc is mostly useful for meta programming (eg. ``assert`` template)
  ## to retrieve information about the current filename and line number.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   import strutils
  ##
  ##   template testException(exception, code: untyped): typed =
  ##     try:
  ##       let pos = instantiationInfo()
  ##       discard(code)
  ##       echo "Test failure at $1:$2 with '$3'" % [pos.filename,
  ##         $pos.line, astToStr(code)]
  ##       assert false, "A test expecting failure succeeded?"
  ##     except exception:
  ##       discard
  ##
  ##   proc tester(pos: int): int =
  ##     let
  ##       a = @[1, 2, 3]
  ##     result = a[pos]
  ##
  ##   when isMainModule:
  ##     testException(IndexError, tester(30))
  ##     testException(IndexError, tester(1))
  ##     # --> Test failure at example.nim:20 with 'tester(1)'

proc compiles*(x: untyped): bool {.magic: "Compiles", noSideEffect, compileTime.} =
  ## Special compile-time procedure that checks whether `x` can be compiled
  ## without any semantic error.
  ## This can be used to check whether a type supports some operation:
  ##
  ## .. code-block:: Nim
  ##   when compiles(3 + 4):
  ##     echo "'+' for integers is available"
  discard

when not defined(js) and not defined(nimscript):
  import "system/ansi_c"
  import "system/memory"

when not defined(js):
  {.push stackTrace:off.}

  when hasThreadSupport and hostOS != "standalone":
    const insideRLocksModule = false
    include "system/syslocks"
    include "system/threadlocalstorage"

  when defined(nimV2):
    type
      TNimNode {.compilerproc.} = object # to keep the code generator simple
      DestructorProc = proc (p: pointer) {.nimcall, benign.}
      TNimType {.compilerproc.} = object
        destructor: pointer
        size: int
        name: cstring
      PNimType = ptr TNimType

  when defined(nimSeqsV2) and not defined(nimscript):
    include "core/strs"
    include "core/seqs"

  {.pop.}

when not declared(sysFatal):
  include "system/fatal"

when not defined(JS) and not defined(nimscript):
  {.push stackTrace: off, profiler:off.}

  proc atomicInc*(memLoc: var int, x: int = 1): int {.inline,
    discardable, benign.}
    ## Atomic increment of `memLoc`. Returns the value after the operation.

  proc atomicDec*(memLoc: var int, x: int = 1): int {.inline,
    discardable, benign.}
    ## Atomic decrement of `memLoc`. Returns the value after the operation.

  include "system/atomics"

  {.pop.}

when defined(nimV2):
  include core/runtime_v2

import system/assertions
export assertions

import system/iterators
export iterators


proc find*[T, S](a: T, item: S): int {.inline.}=
  ## Returns the first index of `item` in `a` or -1 if not found. This requires
  ## appropriate `items` and `==` operations to work.
  for i in items(a):
    if i == item: return
    inc(result)
  result = -1

proc contains*[T](a: openArray[T], item: T): bool {.inline.}=
  ## Returns true if `item` is in `a` or false if not found. This is a shortcut
  ## for ``find(a, item) >= 0``.
  ##
  ## This allows the `in` operator: `a.contains(item)` is the same as
  ## `item in a`.
  ##
  ## .. code-block:: Nim
  ##   var a = @[1, 3, 5]
  ##   assert a.contains(5)
  ##   assert 3 in a
  ##   assert 99 notin a
  return find(a, item) >= 0

proc pop*[T](s: var seq[T]): T {.inline, noSideEffect.} =
  ## Returns the last item of `s` and decreases ``s.len`` by one. This treats
  ## `s` as a stack and implements the common *pop* operation.
  runnableExamples:
    var a = @[1, 3, 5, 7]
    let b = pop(a)
    assert b == 7
    assert a == @[1, 3, 5]

  var L = s.len-1
  when defined(nimV2):
    result = move s[L]
    shrink(s, L)
  else:
    result = s[L]
    setLen(s, L)

proc `==`*[T: tuple|object](x, y: T): bool =
  ## Generic ``==`` operator for tuples that is lifted from the components.
  ## of `x` and `y`.
  for a, b in fields(x, y):
    if a != b: return false
  return true

proc `<=`*[T: tuple](x, y: T): bool =
  ## Generic lexicographic ``<=`` operator for tuples that is lifted from the
  ## components of `x` and `y`. This implementation uses `cmp`.
  for a, b in fields(x, y):
    var c = cmp(a, b)
    if c < 0: return true
    if c > 0: return false
  return true

proc `<`*[T: tuple](x, y: T): bool =
  ## Generic lexicographic ``<`` operator for tuples that is lifted from the
  ## components of `x` and `y`. This implementation uses `cmp`.
  for a, b in fields(x, y):
    var c = cmp(a, b)
    if c < 0: return true
    if c > 0: return false
  return false



# ----------------- GC interface ---------------------------------------------

when not defined(nimscript) and hasAlloc:
  type
    GC_Strategy* = enum  ## The strategy the GC should use for the application.
      gcThroughput,      ## optimize for throughput
      gcResponsiveness,  ## optimize for responsiveness (default)
      gcOptimizeTime,    ## optimize for speed
      gcOptimizeSpace    ## optimize for memory footprint

  when not defined(JS) and not defined(gcDestructors):
    proc GC_disable*() {.rtl, inl, benign.}
      ## Disables the GC. If called `n` times, `n` calls to `GC_enable`
      ## are needed to reactivate the GC.
      ##
      ## Note that in most circumstances one should only disable
      ## the mark and sweep phase with
      ## `GC_disableMarkAndSweep <#GC_disableMarkAndSweep>`_.

    proc GC_enable*() {.rtl, inl, benign.}
      ## Enables the GC again.

    proc GC_fullCollect*() {.rtl, benign.}
      ## Forces a full garbage collection pass.
      ## Ordinary code does not need to call this (and should not).

    proc GC_enableMarkAndSweep*() {.rtl, benign.}
    proc GC_disableMarkAndSweep*() {.rtl, benign.}
      ## The current implementation uses a reference counting garbage collector
      ## with a seldomly run mark and sweep phase to free cycles. The mark and
      ## sweep phase may take a long time and is not needed if the application
      ## does not create cycles. Thus the mark and sweep phase can be deactivated
      ## and activated separately from the rest of the GC.

    proc GC_getStatistics*(): string {.rtl, benign.}
      ## Returns an informative string about the GC's activity. This may be useful
      ## for tweaking.

    proc GC_ref*[T](x: ref T) {.magic: "GCref", benign.}
    proc GC_ref*[T](x: seq[T]) {.magic: "GCref", benign.}
    proc GC_ref*(x: string) {.magic: "GCref", benign.}
      ## Marks the object `x` as referenced, so that it will not be freed until
      ## it is unmarked via `GC_unref`.
      ## If called n-times for the same object `x`,
      ## n calls to `GC_unref` are needed to unmark `x`.

    proc GC_unref*[T](x: ref T) {.magic: "GCunref", benign.}
    proc GC_unref*[T](x: seq[T]) {.magic: "GCunref", benign.}
    proc GC_unref*(x: string) {.magic: "GCunref", benign.}
      ## See the documentation of `GC_ref <#GC_ref,string>`_.

    when not defined(JS) and not defined(nimscript) and hasAlloc:
      proc nimGC_setStackBottom*(theStackBottom: pointer) {.compilerRtl, noinline, benign.}
        ## Expands operating GC stack range to `theStackBottom`. Does nothing
        ## if current stack bottom is already lower than `theStackBottom`.

  else:
    template GC_disable* =
      {.warning: "GC_disable is a no-op in JavaScript".}

    template GC_enable* =
      {.warning: "GC_enable is a no-op in JavaScript".}

    template GC_fullCollect* =
      {.warning: "GC_fullCollect is a no-op in JavaScript".}

    template GC_setStrategy* =
      {.warning: "GC_setStrategy is a no-op in JavaScript".}

    template GC_enableMarkAndSweep* =
      {.warning: "GC_enableMarkAndSweep is a no-op in JavaScript".}

    template GC_disableMarkAndSweep* =
      {.warning: "GC_disableMarkAndSweep is a no-op in JavaScript".}

    template GC_ref*[T](x: ref T) =
      {.warning: "GC_ref is a no-op in JavaScript".}

    template GC_ref*[T](x: seq[T]) =
      {.warning: "GC_ref is a no-op in JavaScript".}

    template GC_ref*(x: string) =
      {.warning: "GC_ref is a no-op in JavaScript".}

    template GC_unref*[T](x: ref T) =
      {.warning: "GC_unref is a no-op in JavaScript".}

    template GC_unref*[T](x: seq[T]) =
      {.warning: "GC_unref is a no-op in JavaScript".}

    template GC_unref*(x: string) =
      {.warning: "GC_unref is a no-op in JavaScript".}

    template GC_getStatistics*(): string =
      {.warning: "GC_getStatistics is a no-op in JavaScript".}
      ""

template accumulateResult*(iter: untyped) {.deprecated: "use `sequtils.toSeq` instead (more hygienic, sometimes more efficient)".} =
  ## **Deprecated since v0.19.2:** use `sequtils.toSeq
  ## <sequtils.html#toSeq.t,untyped>`_ instead.
  ##
  ## Helps to convert an iterator to a proc.
  ## `sequtils.toSeq <sequtils.html#toSeq.t,untyped>`_ is more hygienic and efficient.
  ##
  result = @[]
  for x in iter: add(result, x)

# we have to compute this here before turning it off in except.nim anyway ...
const NimStackTrace = compileOption("stacktrace")

template coroutinesSupportedPlatform(): bool =
  when defined(sparc) or defined(ELATE) or compileOption("gc", "v2") or
    defined(boehmgc) or defined(gogc) or defined(nogc) or defined(gcRegions) or
    defined(gcMarkAndSweep):
    false
  else:
    true

when defined(nimCoroutines):
  # Explicit opt-in.
  when not coroutinesSupportedPlatform():
    {.error: "Coroutines are not supported on this architecture and/or garbage collector.".}
  const nimCoroutines* = true
elif defined(noNimCoroutines):
  # Explicit opt-out.
  const nimCoroutines* = false
else:
  # Autodetect coroutine support.
  const nimCoroutines* = false

{.push checks: off.}
# obviously we cannot generate checking operations here :-)
# because it would yield into an endless recursion
# however, stack-traces are available for most parts
# of the code

var
  globalRaiseHook*: proc (e: ref Exception): bool {.nimcall, benign.}
    ## With this hook you can influence exception handling on a global level.
    ## If not nil, every 'raise' statement ends up calling this hook.
    ##
    ## **Warning**: Ordinary application code should never set this hook!
    ## You better know what you do when setting this.
    ##
    ## If ``globalRaiseHook`` returns false, the exception is caught and does
    ## not propagate further through the call stack.

  localRaiseHook* {.threadvar.}: proc (e: ref Exception): bool {.nimcall, benign.}
    ## With this hook you can influence exception handling on a
    ## thread local level.
    ## If not nil, every 'raise' statement ends up calling this hook.
    ##
    ## **Warning**: Ordinary application code should never set this hook!
    ## You better know what you do when setting this.
    ##
    ## If ``localRaiseHook`` returns false, the exception
    ## is caught and does not propagate further through the call stack.

  outOfMemHook*: proc () {.nimcall, tags: [], benign, raises: [].}
    ## Set this variable to provide a procedure that should be called
    ## in case of an `out of memory`:idx: event. The standard handler
    ## writes an error message and terminates the program.
    ##
    ## `outOfMemHook` can be used to raise an exception in case of OOM like so:
    ##
    ## .. code-block:: Nim
    ##
    ##   var gOutOfMem: ref EOutOfMemory
    ##   new(gOutOfMem) # need to be allocated *before* OOM really happened!
    ##   gOutOfMem.msg = "out of memory"
    ##
    ##   proc handleOOM() =
    ##     raise gOutOfMem
    ##
    ##   system.outOfMemHook = handleOOM
    ##
    ## If the handler does not raise an exception, ordinary control flow
    ## continues and the program is terminated.

type
  PFrame* = ptr TFrame  ## Represents a runtime frame of the call stack;
                        ## part of the debugger API.
  TFrame* {.importc, nodecl, final.} = object ## The frame itself.
    prev*: PFrame       ## Previous frame; used for chaining the call stack.
    procname*: cstring  ## Name of the proc that is currently executing.
    line*: int          ## Line number of the proc that is currently executing.
    filename*: cstring  ## Filename of the proc that is currently executing.
    len*: int16         ## Length of the inspectable slots.
    calldepth*: int16   ## Used for max call depth checking.

when defined(JS):
  proc add*(x: var string, y: cstring) {.asmNoStackFrame.} =
    asm """
      if (`x` === null) { `x` = []; }
      var off = `x`.length;
      `x`.length += `y`.length;
      for (var i = 0; i < `y`.length; ++i) {
        `x`[off+i] = `y`.charCodeAt(i);
      }
    """
  proc add*(x: var cstring, y: cstring) {.magic: "AppendStrStr".}

elif hasAlloc:
  {.push stack_trace:off, profiler:off.}
  proc add*(x: var string, y: cstring) =
    var i = 0
    while y[i] != '\0':
      add(x, y[i])
      inc(i)
  {.pop.}

when defined(nimvarargstyped):
  proc echo*(x: varargs[typed, `$`]) {.magic: "Echo", tags: [WriteIOEffect],
    benign, sideEffect.}
    ## Writes and flushes the parameters to the standard output.
    ##
    ## Special built-in that takes a variable number of arguments. Each argument
    ## is converted to a string via ``$``, so it works for user-defined
    ## types that have an overloaded ``$`` operator.
    ## It is roughly equivalent to ``writeLine(stdout, x); flushFile(stdout)``, but
    ## available for the JavaScript target too.
    ##
    ## Unlike other IO operations this is guaranteed to be thread-safe as
    ## ``echo`` is very often used for debugging convenience. If you want to use
    ## ``echo`` inside a `proc without side effects
    ## <manual.html#pragmas-nosideeffect-pragma>`_ you can use `debugEcho
    ## <#debugEcho,varargs[typed,]>`_ instead.

  proc debugEcho*(x: varargs[typed, `$`]) {.magic: "Echo", noSideEffect,
                                            tags: [], raises: [].}
    ## Same as `echo <#echo,varargs[typed,]>`_, but as a special semantic rule,
    ## ``debugEcho`` pretends to be free of side effects, so that it can be used
    ## for debugging routines marked as `noSideEffect
    ## <manual.html#pragmas-nosideeffect-pragma>`_.
else:
  proc echo*(x: varargs[untyped, `$`]) {.magic: "Echo", tags: [WriteIOEffect],
    benign, sideEffect.}
  proc debugEcho*(x: varargs[untyped, `$`]) {.magic: "Echo", noSideEffect,
                                             tags: [], raises: [].}

template newException*(exceptn: typedesc, message: string;
                       parentException: ref Exception = nil): untyped =
  ## Creates an exception object of type ``exceptn`` and sets its ``msg`` field
  ## to `message`. Returns the new exception object.
  when declared(owned):
    var e: owned(ref exceptn)
  else:
    var e: ref exceptn
  new(e)
  e.msg = message
  e.parent = parentException
  e

when hostOS == "standalone" and defined(nogc):
  proc nimToCStringConv(s: NimString): cstring {.compilerproc, inline.} =
    if s == nil or s.len == 0: result = cstring""
    else: result = cstring(addr s.data)

proc getTypeInfo*[T](x: T): pointer {.magic: "GetTypeInfo", benign.}
  ## Get type information for `x`.
  ##
  ## Ordinary code should not use this, but the `typeinfo module
  ## <typeinfo.html>`_ instead.

{.push stackTrace: off.}
proc abs*(x: int): int {.magic: "AbsI", noSideEffect.} =
  if x < 0: -x else: x
proc abs*(x: int8): int8 {.magic: "AbsI", noSideEffect.} =
  if x < 0: -x else: x
proc abs*(x: int16): int16 {.magic: "AbsI", noSideEffect.} =
  if x < 0: -x else: x
proc abs*(x: int32): int32 {.magic: "AbsI", noSideEffect.} =
  if x < 0: -x else: x
proc abs*(x: int64): int64 {.magic: "AbsI", noSideEffect.} =
  ## Returns the absolute value of `x`.
  ##
  ## If `x` is ``low(x)`` (that is -MININT for its type),
  ## an overflow exception is thrown (if overflow checking is turned on).
  result = if x < 0: -x else: x
{.pop.}


when not defined(JS):
  proc likelyProc(val: bool): bool {.importc: "NIM_LIKELY", nodecl, noSideEffect.}
  proc unlikelyProc(val: bool): bool {.importc: "NIM_UNLIKELY", nodecl, noSideEffect.}

template likely*(val: bool): bool =
  ## Hints the optimizer that `val` is likely going to be true.
  ##
  ## You can use this template to decorate a branch condition. On certain
  ## platforms this can help the processor predict better which branch is
  ## going to be run. Example:
  ##
  ## .. code-block:: Nim
  ##   for value in inputValues:
  ##     if likely(value <= 100):
  ##       process(value)
  ##     else:
  ##       echo "Value too big!"
  ##
  ## On backends without branch prediction (JS and the nimscript VM), this
  ## template will not affect code execution.
  when nimvm:
    val
  else:
    when defined(JS):
      val
    else:
      likelyProc(val)

template unlikely*(val: bool): bool =
  ## Hints the optimizer that `val` is likely going to be false.
  ##
  ## You can use this proc to decorate a branch condition. On certain
  ## platforms this can help the processor predict better which branch is
  ## going to be run. Example:
  ##
  ## .. code-block:: Nim
  ##   for value in inputValues:
  ##     if unlikely(value > 100):
  ##       echo "Value too big!"
  ##     else:
  ##       process(value)
  ##
  ## On backends without branch prediction (JS and the nimscript VM), this
  ## template will not affect code execution.
  when nimvm:
    val
  else:
    when defined(JS):
      val
    else:
      unlikelyProc(val)


import system/dollars
export dollars


const
  NimMajor* {.intdefine.}: int = 1
    ## is the major number of Nim's version.

  NimMinor* {.intdefine.}: int = 1
    ## is the minor number of Nim's version.

  NimPatch* {.intdefine.}: int = 0
    ## is the patch number of Nim's version.

  NimVersion*: string = $NimMajor & "." & $NimMinor & "." & $NimPatch
    ## is the version of Nim as a string.


type
  FileSeekPos* = enum ## Position relative to which seek should happen.
                      # The values are ordered so that they match with stdio
                      # SEEK_SET, SEEK_CUR and SEEK_END respectively.
    fspSet            ## Seek to absolute value
    fspCur            ## Seek relative to current position
    fspEnd            ## Seek relative to end


when not defined(JS): #and not defined(nimscript):
  {.push stack_trace: off, profiler:off.}

  when hasAlloc:
    when not defined(gcRegions) and not defined(gcDestructors):
      proc initGC() {.gcsafe.}

    proc initStackBottom() {.inline, compilerproc.} =
      # WARNING: This is very fragile! An array size of 8 does not work on my
      # Linux 64bit system. -- That's because the stack direction is the other
      # way around.
      when declared(nimGC_setStackBottom):
        var locals {.volatile.}: pointer
        locals = addr(locals)
        nimGC_setStackBottom(locals)

    proc initStackBottomWith(locals: pointer) {.inline, compilerproc.} =
      # We need to keep initStackBottom around for now to avoid
      # bootstrapping problems.
      when declared(nimGC_setStackBottom):
        nimGC_setStackBottom(locals)

    when not defined(gcDestructors):
      {.push profiler: off.}
      var
        strDesc = TNimType(size: sizeof(string), kind: tyString, flags: {ntfAcyclic})
      {.pop.}

  when not defined(nimscript):
    proc zeroMem(p: pointer, size: Natural) =
      nimZeroMem(p, size)
      when declared(memTrackerOp):
        memTrackerOp("zeroMem", p, size)
    proc copyMem(dest, source: pointer, size: Natural) =
      nimCopyMem(dest, source, size)
      when declared(memTrackerOp):
        memTrackerOp("copyMem", dest, size)
    proc moveMem(dest, source: pointer, size: Natural) =
      c_memmove(dest, source, size)
      when declared(memTrackerOp):
        memTrackerOp("moveMem", dest, size)
    proc equalMem(a, b: pointer, size: Natural): bool =
      nimCmpMem(a, b, size) == 0

  proc cmp(x, y: string): int =
    when defined(nimscript):
      if x < y: result = -1
      elif x > y: result = 1
      else: result = 0
    else:
      when nimvm:
        if x < y: result = -1
        elif x > y: result = 1
        else: result = 0
      else:
        let minlen = min(x.len, y.len)
        result = int(nimCmpMem(x.cstring, y.cstring, minlen.csize))
        if result == 0:
          result = x.len - y.len

  when declared(newSeq):
    proc cstringArrayToSeq*(a: cstringArray, len: Natural): seq[string] =
      ## Converts a ``cstringArray`` to a ``seq[string]``. `a` is supposed to be
      ## of length ``len``.
      newSeq(result, len)
      for i in 0..len-1: result[i] = $a[i]

    proc cstringArrayToSeq*(a: cstringArray): seq[string] =
      ## Converts a ``cstringArray`` to a ``seq[string]``. `a` is supposed to be
      ## terminated by ``nil``.
      var L = 0
      while a[L] != nil: inc(L)
      result = cstringArrayToSeq(a, L)

  # -------------------------------------------------------------------------

  when declared(alloc0) and declared(dealloc):
    proc allocCStringArray*(a: openArray[string]): cstringArray =
      ## Creates a NULL terminated cstringArray from `a`. The result has to
      ## be freed with `deallocCStringArray` after it's not needed anymore.
      result = cast[cstringArray](alloc0((a.len+1) * sizeof(cstring)))

      let x = cast[ptr UncheckedArray[string]](a)
      for i in 0 .. a.high:
        result[i] = cast[cstring](alloc0(x[i].len+1))
        copyMem(result[i], addr(x[i][0]), x[i].len)

    proc deallocCStringArray*(a: cstringArray) =
      ## Frees a NULL terminated cstringArray.
      var i = 0
      while a[i] != nil:
        dealloc(a[i])
        inc(i)
      dealloc(a)

  when not defined(nimscript):
    type
      PSafePoint = ptr TSafePoint
      TSafePoint {.compilerproc, final.} = object
        prev: PSafePoint # points to next safe point ON THE STACK
        status: int
        context: C_JmpBuf
        hasRaiseAction: bool
        raiseAction: proc (e: ref Exception): bool {.closure.}
      SafePoint = TSafePoint

  when declared(initAllocator):
    initAllocator()
  when hasThreadSupport:
    when hostOS != "standalone": include "system/threads"
  elif not defined(nogc) and not defined(nimscript):
    when not defined(useNimRtl) and not defined(createNimRtl): initStackBottom()
    when declared(initGC): initGC()

  when not defined(nimscript):
    proc setControlCHook*(hook: proc () {.noconv.})
      ## Allows you to override the behaviour of your application when CTRL+C
      ## is pressed. Only one such hook is supported.

    when not defined(noSignalHandler) and not defined(useNimRtl):
      proc unsetControlCHook*()
        ## Reverts a call to setControlCHook.

    proc writeStackTrace*() {.tags: [], gcsafe.}
      ## Writes the current stack trace to ``stderr``. This is only works
      ## for debug builds. Since it's usually used for debugging, this
      ## is proclaimed to have no IO effect!
    when hostOS != "standalone":
      proc getStackTrace*(): string {.gcsafe.}
        ## Gets the current stack trace. This only works for debug builds.

      proc getStackTrace*(e: ref Exception): string {.gcsafe.}
        ## Gets the stack trace associated with `e`, which is the stack that
        ## lead to the ``raise`` statement. This only works for debug builds.

    {.push stackTrace: off, profiler:off.}
    when defined(memtracker):
      include "system/memtracker"

    when hostOS == "standalone":
      include "system/embedded"
    else:
      include "system/excpt"
    include "system/chcks"

    # we cannot compile this with stack tracing on
    # as it would recurse endlessly!
    include "system/arithm"
    {.pop.} # stack trace
  {.pop.} # stack trace

  when hostOS != "standalone" and not defined(nimscript):
    include "system/dyncalls"
  when not defined(nimscript):
    include "system/sets"

    when defined(gogc):
      const GenericSeqSize = (3 * sizeof(int))
    else:
      const GenericSeqSize = (2 * sizeof(int))

    when not defined(nimV2):
      proc getDiscriminant(aa: pointer, n: ptr TNimNode): uint =
        sysAssert(n.kind == nkCase, "getDiscriminant: node != nkCase")
        var d: uint
        var a = cast[uint](aa)
        case n.typ.size
        of 1: d = uint(cast[ptr uint8](a + uint(n.offset))[])
        of 2: d = uint(cast[ptr uint16](a + uint(n.offset))[])
        of 4: d = uint(cast[ptr uint32](a + uint(n.offset))[])
        of 8: d = uint(cast[ptr uint64](a + uint(n.offset))[])
        else: sysAssert(false, "getDiscriminant: invalid n.typ.size")
        return d

      proc selectBranch(aa: pointer, n: ptr TNimNode): ptr TNimNode =
        var discr = getDiscriminant(aa, n)
        if discr < cast[uint](n.len):
          result = n.sons[discr]
          if result == nil: result = n.sons[n.len]
          # n.sons[n.len] contains the ``else`` part (but may be nil)
        else:
          result = n.sons[n.len]

    {.push profiler:off.}
    when hasAlloc: include "system/mmdisp"
    {.pop.}
    {.push stack_trace: off, profiler:off.}
    when hasAlloc:
      when not defined(nimSeqsV2):
        include "system/sysstr"
    {.pop.}
    when hasAlloc: include "system/strmantle"

    when hasThreadSupport:
      when hostOS != "standalone" and not defined(gcDestructors): include "system/channels"

  when not defined(nimscript) and hasAlloc:
    when not defined(gcDestructors):
      include "system/assign"
    when not defined(nimV2):
      include "system/repr"

  when hostOS != "standalone" and not defined(nimscript):
    proc getCurrentException*(): ref Exception {.compilerRtl, inl, benign.} =
      ## Retrieves the current exception; if there is none, `nil` is returned.
      result = currException

    proc getCurrentExceptionMsg*(): string {.inline, benign.} =
      ## Retrieves the error message that was attached to the current
      ## exception; if there is none, `""` is returned.
      var e = getCurrentException()
      return if e == nil: "" else: e.msg

    proc onRaise*(action: proc(e: ref Exception): bool{.closure.}) {.deprecated.} =
      ## **Deprecated since version 0.18.1**: No good usages of this
      ## feature are known.
      ##
      ## Can be used in a ``try`` statement to setup a Lisp-like
      ## `condition system`:idx:\: This prevents the 'raise' statement to
      ## raise an exception but instead calls ``action``.
      ## If ``action`` returns false, the exception has been handled and
      ## does not propagate further through the call stack.
      if not isNil(excHandler):
        excHandler.hasRaiseAction = true
        excHandler.raiseAction = action

    proc setCurrentException*(exc: ref Exception) {.inline, benign.} =
      ## Sets the current exception.
      ##
      ## **Warning**: Only use this if you know what you are doing.
      currException = exc

  {.push stack_trace: off, profiler:off.}
  when (defined(profiler) or defined(memProfiler)) and not defined(nimscript):
    include "system/profiler"
  {.pop.} # stacktrace

  when not defined(nimscript):
    proc rawProc*[T: proc](x: T): pointer {.noSideEffect, inline.} =
      ## Retrieves the raw proc pointer of the closure `x`. This is
      ## useful for interfacing closures with C.
      {.emit: """
      `result` = `x`.ClP_0;
      """.}

    proc rawEnv*[T: proc](x: T): pointer {.noSideEffect, inline.} =
      ## Retrieves the raw environment pointer of the closure `x`. This is
      ## useful for interfacing closures with C.
      {.emit: """
      `result` = `x`.ClE_0;
      """.}

    proc finished*[T: proc](x: T): bool {.noSideEffect, inline.} =
      ## can be used to determine if a first class iterator has finished.
      {.emit: """
      `result` = ((NI*) `x`.ClE_0)[1] < 0;
      """.}

elif defined(JS):
  # Stubs:
  proc getOccupiedMem(): int = return -1
  proc getFreeMem(): int = return -1
  proc getTotalMem(): int = return -1

  proc dealloc(p: pointer) = discard
  proc alloc(size: Natural): pointer = discard
  proc alloc0(size: Natural): pointer = discard
  proc realloc(p: pointer, newsize: Natural): pointer = discard

  proc allocShared(size: Natural): pointer = discard
  proc allocShared0(size: Natural): pointer = discard
  proc deallocShared(p: pointer) = discard
  proc reallocShared(p: pointer, newsize: Natural): pointer = discard

  proc addInt*(result: var string; x: int64) =
    result.add $x

  proc addFloat*(result: var string; x: float) =
    result.add $x

  when defined(JS) and not defined(nimscript):
    include "system/jssys"
    include "system/reprjs"
  elif defined(nimscript):
    proc cmp(x, y: string): int =
      if x == y: return 0
      if x < y: return -1
      return 1


proc quit*(errormsg: string, errorcode = QuitFailure) {.noreturn.} =
  ## A shorthand for ``echo(errormsg); quit(errorcode)``.
  when defined(nimscript) or defined(js) or (hostOS == "standalone"):
    echo errormsg
  else:
    when nimvm:
      echo errormsg
    else:
      cstderr.rawWrite(errormsg)
      cstderr.rawWrite("\n")
  quit(errorcode)

{.pop.} # checks
{.pop.} # hints

proc `/`*(x, y: int): float {.inline, noSideEffect.} =
  ## Division of integers that results in a float.
  ##
  ## See also:
  ## * `div <#div,int,int>`_
  ## * `mod <#mod,int,int>`_
  ##
  ## .. code-block:: Nim
  ##   echo 7 / 5 # => 1.4
  result = toFloat(x) / toFloat(y)

type
  BackwardsIndex* = distinct int ## Type that is constructed by ``^`` for
                                 ## reversed array accesses.
                                 ## (See `^ template <#^.t,int>`_)

template `^`*(x: int): BackwardsIndex = BackwardsIndex(x)
  ## Builtin `roof`:idx: operator that can be used for convenient array access.
  ## ``a[^x]`` is a shortcut for ``a[a.len-x]``.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = [1, 3, 5, 7, 9]
  ##     b = "abcdefgh"
  ##
  ##   echo a[^1] # => 9
  ##   echo b[^2] # => g

template `..^`*(a, b: untyped): untyped =
  ## A shortcut for `.. ^` to avoid the common gotcha that a space between
  ## '..' and '^' is required.
  a .. ^b

template `..<`*(a, b: untyped): untyped =
  ## A shortcut for `a .. pred(b)`.
  ##
  ## .. code-block:: Nim
  ##   for i in 5 ..< 9:
  ##     echo i # => 5; 6; 7; 8
  a .. (when b is BackwardsIndex: succ(b) else: pred(b))

template spliceImpl(s, a, L, b: untyped): untyped =
  # make room for additional elements or cut:
  var shift = b.len - max(0,L)  # ignore negative slice size
  var newLen = s.len + shift
  if shift > 0:
    # enlarge:
    setLen(s, newLen)
    for i in countdown(newLen-1, a+b.len): movingCopy(s[i], s[i-shift])
  else:
    for i in countup(a+b.len, newLen-1): movingCopy(s[i], s[i-shift])
    # cut down:
    setLen(s, newLen)
  # fill the hole:
  for i in 0 ..< b.len: s[a+i] = b[i]

template `^^`(s, i: untyped): untyped =
  (when i is BackwardsIndex: s.len - int(i) else: int(i))

template `[]`*(s: string; i: int): char = arrGet(s, i)
template `[]=`*(s: string; i: int; val: char) = arrPut(s, i, val)

proc `[]`*[T, U](s: string, x: HSlice[T, U]): string {.inline.} =
  ## Slice operation for strings.
  ## Returns the inclusive range `[s[x.a], s[x.b]]`:
  ##
  ## .. code-block:: Nim
  ##    var s = "abcdef"
  ##    assert s[1..3] == "bcd"
  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  result = newString(L)
  for i in 0 ..< L: result[i] = s[i + a]

proc `[]=`*[T, U](s: var string, x: HSlice[T, U], b: string) =
  ## Slice assignment for strings.
  ##
  ## If ``b.len`` is not exactly the number of elements that are referred to
  ## by `x`, a `splice`:idx: is performed:
  ##
  runnableExamples:
    var s = "abcdefgh"
    s[1 .. ^2] = "xyz"
    assert s == "axyzh"

  var a = s ^^ x.a
  var L = (s ^^ x.b) - a + 1
  if L == b.len:
    for i in 0..<L: s[i+a] = b[i]
  else:
    spliceImpl(s, a, L, b)

proc `[]`*[Idx, T, U, V](a: array[Idx, T], x: HSlice[U, V]): seq[T] =
  ## Slice operation for arrays.
  ## Returns the inclusive range `[a[x.a], a[x.b]]`:
  ##
  ## .. code-block:: Nim
  ##    var a = [1, 2, 3, 4]
  ##    assert a[0..2] == @[1, 2, 3]
  let xa = a ^^ x.a
  let L = (a ^^ x.b) - xa + 1
  result = newSeq[T](L)
  for i in 0..<L: result[i] = a[Idx(i + xa)]

proc `[]=`*[Idx, T, U, V](a: var array[Idx, T], x: HSlice[U, V], b: openArray[T]) =
  ## Slice assignment for arrays.
  ##
  ## .. code-block:: Nim
  ##   var a = [10, 20, 30, 40, 50]
  ##   a[1..2] = @[99, 88]
  ##   assert a == [10, 99, 88, 40, 50]
  let xa = a ^^ x.a
  let L = (a ^^ x.b) - xa + 1
  if L == b.len:
    for i in 0..<L: a[Idx(i + xa)] = b[i]
  else:
    sysFatal(RangeError, "different lengths for slice assignment")

proc `[]`*[T, U, V](s: openArray[T], x: HSlice[U, V]): seq[T] =
  ## Slice operation for sequences.
  ## Returns the inclusive range `[s[x.a], s[x.b]]`:
  ##
  ## .. code-block:: Nim
  ##    var s = @[1, 2, 3, 4]
  ##    assert s[0..2] == @[1, 2, 3]
  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  newSeq(result, L)
  for i in 0 ..< L: result[i] = s[i + a]

proc `[]=`*[T, U, V](s: var seq[T], x: HSlice[U, V], b: openArray[T]) =
  ## Slice assignment for sequences.
  ##
  ## If ``b.len`` is not exactly the number of elements that are referred to
  ## by `x`, a `splice`:idx: is performed.
  runnableExamples:
    var s = @"abcdefgh"
    s[1 .. ^2] = @"xyz"
    assert s == @"axyzh"

  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  if L == b.len:
    for i in 0 ..< L: s[i+a] = b[i]
  else:
    spliceImpl(s, a, L, b)

proc `[]`*[T](s: openArray[T]; i: BackwardsIndex): T {.inline.} =
  system.`[]`(s, s.len - int(i))

proc `[]`*[Idx, T](a: array[Idx, T]; i: BackwardsIndex): T {.inline.} =
  a[Idx(a.len - int(i) + int low(a))]
proc `[]`*(s: string; i: BackwardsIndex): char {.inline.} = s[s.len - int(i)]

proc `[]`*[T](s: var openArray[T]; i: BackwardsIndex): var T {.inline.} =
  system.`[]`(s, s.len - int(i))
proc `[]`*[Idx, T](a: var array[Idx, T]; i: BackwardsIndex): var T {.inline.} =
  a[Idx(a.len - int(i) + int low(a))]

proc `[]=`*[T](s: var openArray[T]; i: BackwardsIndex; x: T) {.inline.} =
  system.`[]=`(s, s.len - int(i), x)
proc `[]=`*[Idx, T](a: var array[Idx, T]; i: BackwardsIndex; x: T) {.inline.} =
  a[Idx(a.len - int(i) + int low(a))] = x
proc `[]=`*(s: var string; i: BackwardsIndex; x: char) {.inline.} =
  s[s.len - int(i)] = x

proc slurp*(filename: string): string {.magic: "Slurp".}
  ## This is an alias for `staticRead <#staticRead,string>`_.

proc staticRead*(filename: string): string {.magic: "Slurp".}
  ## Compile-time `readFile <io.html#readFile,string>`_ proc for easy
  ## `resource`:idx: embedding:
  ##
  ## .. code-block:: Nim
  ##     const myResource = staticRead"mydatafile.bin"
  ##
  ## `slurp <#slurp,string>`_ is an alias for ``staticRead``.

proc gorge*(command: string, input = "", cache = ""): string {.
  magic: "StaticExec".} = discard
  ## This is an alias for `staticExec <#staticExec,string,string,string>`_.

proc staticExec*(command: string, input = "", cache = ""): string {.
  magic: "StaticExec".} = discard
  ## Executes an external process at compile-time and returns its text output
  ## (stdout + stderr).
  ##
  ## If `input` is not an empty string, it will be passed as a standard input
  ## to the executed program.
  ##
  ## .. code-block:: Nim
  ##     const buildInfo = "Revision " & staticExec("git rev-parse HEAD") &
  ##                       "\nCompiled on " & staticExec("uname -v")
  ##
  ## `gorge <#gorge,string,string,string>`_ is an alias for ``staticExec``.
  ##
  ## Note that you can use this proc inside a pragma like
  ## `passc <manual.html#implementation-specific-pragmas-passc-pragma>`_ or
  ## `passl <manual.html#implementation-specific-pragmas-passl-pragma>`_.
  ##
  ## If ``cache`` is not empty, the results of ``staticExec`` are cached within
  ## the ``nimcache`` directory. Use ``--forceBuild`` to get rid of this caching
  ## behaviour then. ``command & input & cache`` (the concatenated string) is
  ## used to determine whether the entry in the cache is still valid. You can
  ## use versioning information for ``cache``:
  ##
  ## .. code-block:: Nim
  ##     const stateMachine = staticExec("dfaoptimizer", "input", "0.8.0")

proc gorgeEx*(command: string, input = "", cache = ""): tuple[output: string,
                                                              exitCode: int] =
  ## Similar to `gorge <#gorge,string,string,string>`_ but also returns the
  ## precious exit code.
  discard

proc `+=`*[T: SomeInteger](x: var T, y: T) {.
  magic: "Inc", noSideEffect.}
  ## Increments an integer.

proc `+=`*[T: enum|bool](x: var T, y: T) {.
  magic: "Inc", noSideEffect, deprecated: "use `inc` instead".}
  ## **Deprecated since v0.20**: use `inc` instead.

proc `-=`*[T: SomeInteger](x: var T, y: T) {.
  magic: "Dec", noSideEffect.}
  ## Decrements an integer.

proc `-=`*[T: enum|bool](x: var T, y: T) {.
  magic: "Dec", noSideEffect, deprecated: "0.20.0, use `dec` instead".}
  ## **Deprecated since v0.20**: use `dec` instead.

proc `*=`*[T: SomeInteger](x: var T, y: T) {.
  inline, noSideEffect.} =
  ## Binary `*=` operator for integers.
  x = x * y

proc `+=`*[T: float|float32|float64] (x: var T, y: T) {.
  inline, noSideEffect.} =
  ## Increments in place a floating point number.
  x = x + y

proc `-=`*[T: float|float32|float64] (x: var T, y: T) {.
  inline, noSideEffect.} =
  ## Decrements in place a floating point number.
  x = x - y

proc `*=`*[T: float|float32|float64] (x: var T, y: T) {.
  inline, noSideEffect.} =
  ## Multiplies in place a floating point number.
  x = x * y

proc `/=`*(x: var float64, y: float64) {.inline, noSideEffect.} =
  ## Divides in place a floating point number.
  x = x / y

proc `/=`*[T: float|float32](x: var T, y: T) {.inline, noSideEffect.} =
  ## Divides in place a floating point number.
  x = x / y

proc `&=`*(x: var string, y: string) {.magic: "AppendStrStr", noSideEffect.}
  ## Appends in place to a string.
  ##
  ## .. code-block:: Nim
  ##   var a = "abc"
  ##   a &= "de" # a <- "abcde"

template `&=`*(x, y: typed) =
  ## Generic 'sink' operator for Nim.
  ##
  ## For files an alias for ``write``.
  ## If not specialized further, an alias for ``add``.
  add(x, y)
when declared(File):
  template `&=`*(f: File, x: typed) = write(f, x)

template currentSourcePath*: string = instantiationInfo(-1, true).filename
  ## returns the full file-system path of the current source

when compileOption("rangechecks"):
  template rangeCheck*(cond) =
    ## Helper for performing user-defined range checks.
    ## Such checks will be performed only when the ``rangechecks``
    ## compile-time option is enabled.
    if not cond: sysFatal(RangeError, "range check failed")
else:
  template rangeCheck*(cond) = discard

when not defined(nimhygiene):
  {.pragma: inject.}

proc shallow*[T](s: var seq[T]) {.noSideEffect, inline.} =
  ## Marks a sequence `s` as `shallow`:idx:. Subsequent assignments will not
  ## perform deep copies of `s`.
  ##
  ## This is only useful for optimization purposes.
  if s.len == 0: return
  when not defined(JS) and not defined(nimscript) and not defined(nimSeqsV2):
    var s = cast[PGenericSeq](s)
    s.reserved = s.reserved or seqShallowFlag

proc shallow*(s: var string) {.noSideEffect, inline.} =
  ## Marks a string `s` as `shallow`:idx:. Subsequent assignments will not
  ## perform deep copies of `s`.
  ##
  ## This is only useful for optimization purposes.
  when not defined(JS) and not defined(nimscript) and not defined(nimSeqsV2):
    var s = cast[PGenericSeq](s)
    if s == nil:
      s = cast[PGenericSeq](newString(0))
    # string literals cannot become 'shallow':
    if (s.reserved and strlitFlag) == 0:
      s.reserved = s.reserved or seqShallowFlag

type
  NimNodeObj = object

  NimNode* {.magic: "PNimrodNode".} = ref NimNodeObj
    ## Represents a Nim AST node. Macros operate on this type.

when false:
  template eval*(blk: typed): typed =
    ## Executes a block of code at compile time just as if it was a macro.
    ##
    ## Optionally, the block can return an AST tree that will replace the
    ## eval expression.
    macro payload: typed {.gensym.} = blk
    payload()

when hasAlloc or defined(nimscript):
  proc insert*(x: var string, item: string, i = 0.Natural) {.noSideEffect.} =
    ## Inserts `item` into `x` at position `i`.
    ##
    ## .. code-block:: Nim
    ##   var a = "abc"
    ##   a.insert("zz", 0) # a <- "zzabc"
    var xl = x.len
    setLen(x, xl+item.len)
    var j = xl-1
    while j >= i:
      shallowCopy(x[j+item.len], x[j])
      dec(j)
    j = 0
    while j < item.len:
      x[j+i] = item[j]
      inc(j)

when declared(initDebugger):
  initDebugger()

proc addEscapedChar*(s: var string, c: char) {.noSideEffect, inline.} =
  ## Adds a char to string `s` and applies the following escaping:
  ##
  ## * replaces any ``\`` by ``\\``
  ## * replaces any ``'`` by ``\'``
  ## * replaces any ``"`` by ``\"``
  ## * replaces any ``\a`` by ``\\a``
  ## * replaces any ``\b`` by ``\\b``
  ## * replaces any ``\t`` by ``\\t``
  ## * replaces any ``\n`` by ``\\n``
  ## * replaces any ``\v`` by ``\\v``
  ## * replaces any ``\f`` by ``\\f``
  ## * replaces any ``\c`` by ``\\c``
  ## * replaces any ``\e`` by ``\\e``
  ## * replaces any other character not in the set ``{'\21..'\126'}
  ##   by ``\xHH`` where ``HH`` is its hexadecimal value.
  ##
  ## The procedure has been designed so that its output is usable for many
  ## different common syntaxes.
  ##
  ## **Note**: This is **not correct** for producing Ansi C code!
  case c
  of '\a': s.add "\\a" # \x07
  of '\b': s.add "\\b" # \x08
  of '\t': s.add "\\t" # \x09
  of '\L': s.add "\\n" # \x0A
  of '\v': s.add "\\v" # \x0B
  of '\f': s.add "\\f" # \x0C
  of '\c': s.add "\\c" # \x0D
  of '\e': s.add "\\e" # \x1B
  of '\\': s.add("\\\\")
  of '\'': s.add("\\'")
  of '\"': s.add("\\\"")
  of {'\32'..'\126'} - {'\\', '\'', '\"'}: s.add(c)
  else:
    s.add("\\x")
    const HexChars = "0123456789ABCDEF"
    let n = ord(c)
    s.add(HexChars[int((n and 0xF0) shr 4)])
    s.add(HexChars[int(n and 0xF)])

proc addQuoted*[T](s: var string, x: T) =
  ## Appends `x` to string `s` in place, applying quoting and escaping
  ## if `x` is a string or char.
  ##
  ## See `addEscapedChar <#addEscapedChar,string,char>`_
  ## for the escaping scheme. When `x` is a string, characters in the
  ## range ``{\128..\255}`` are never escaped so that multibyte UTF-8
  ## characters are untouched (note that this behavior is different from
  ## ``addEscapedChar``).
  ##
  ## The Nim standard library uses this function on the elements of
  ## collections when producing a string representation of a collection.
  ## It is recommended to use this function as well for user-side collections.
  ## Users may overload `addQuoted` for custom (string-like) types if
  ## they want to implement a customized element representation.
  ##
  ## .. code-block:: Nim
  ##   var tmp = ""
  ##   tmp.addQuoted(1)
  ##   tmp.add(", ")
  ##   tmp.addQuoted("string")
  ##   tmp.add(", ")
  ##   tmp.addQuoted('c')
  ##   assert(tmp == """1, "string", 'c'""")
  when T is string or T is cstring:
    s.add("\"")
    for c in x:
      # Only ASCII chars are escaped to avoid butchering
      # multibyte UTF-8 characters.
      if c <= 127.char:
        s.addEscapedChar(c)
      else:
        s.add c
    s.add("\"")
  elif T is char:
    s.add("'")
    s.addEscapedChar(x)
    s.add("'")
  # prevent temporary string allocation
  elif T is SomeSignedInt:
    s.addInt(x)
  elif T is SomeFloat:
    s.addFloat(x)
  elif compiles(s.add(x)):
    s.add(x)
  else:
    s.add($x)

when hasAlloc:
  # XXX: make these the default (or implement the NilObject optimization)
  proc safeAdd*[T](x: var seq[T], y: T) {.noSideEffect, deprecated.} =
    ## Adds ``y`` to ``x`` unless ``x`` is not yet initialized; in that case,
    ## ``x`` becomes ``@[y]``.
    when defined(nimNoNilSeqs):
      x.add(y)
    else:
      if x == nil: x = @[y]
      else: x.add(y)

  proc safeAdd*(x: var string, y: char) {.noSideEffect, deprecated.} =
    ## Adds ``y`` to ``x``. If ``x`` is ``nil`` it is initialized to ``""``.
    when defined(nimNoNilSeqs):
      x.add(y)
    else:
      if x == nil: x = ""
      x.add(y)

  proc safeAdd*(x: var string, y: string) {.noSideEffect, deprecated.} =
    ## Adds ``y`` to ``x`` unless ``x`` is not yet initialized; in that
    ## case, ``x`` becomes ``y``.
    when defined(nimNoNilSeqs):
      x.add(y)
    else:
      if x == nil: x = y
      else: x.add(y)

proc locals*(): RootObj {.magic: "Plugin", noSideEffect.} =
  ## Generates a tuple constructor expression listing all the local variables
  ## in the current scope.
  ##
  ## This is quite fast as it does not rely
  ## on any debug or runtime information. Note that in contrast to what
  ## the official signature says, the return type is *not* ``RootObj`` but a
  ## tuple of a structure that depends on the current scope. Example:
  ##
  ## .. code-block:: Nim
  ##   proc testLocals() =
  ##     var
  ##       a = "something"
  ##       b = 4
  ##       c = locals()
  ##       d = "super!"
  ##
  ##     b = 1
  ##     for name, value in fieldPairs(c):
  ##       echo "name ", name, " with value ", value
  ##     echo "B is ", b
  ##   # -> name a with value something
  ##   # -> name b with value 4
  ##   # -> B is 1
  discard

when hasAlloc and not defined(nimscript) and not defined(JS) and
    not defined(gcDestructors):
  # XXX how to implement 'deepCopy' is an open problem.
  proc deepCopy*[T](x: var T, y: T) {.noSideEffect, magic: "DeepCopy".} =
    ## Performs a deep copy of `y` and copies it into `x`.
    ##
    ## This is also used by the code generator
    ## for the implementation of ``spawn``.
    discard

  proc deepCopy*[T](y: T): T =
    ## Convenience wrapper around `deepCopy` overload.
    deepCopy(result, y)

  include "system/deepcopy"

proc procCall*(x: untyped) {.magic: "ProcCall", compileTime.} =
  ## Special magic to prohibit dynamic binding for `method`:idx: calls.
  ## This is similar to `super`:idx: in ordinary OO languages.
  ##
  ## .. code-block:: Nim
  ##   # 'someMethod' will be resolved fully statically:
  ##   procCall someMethod(a, b)
  discard

proc xlen*(x: string): int {.magic: "XLenStr", noSideEffect,
                             deprecated: "use len() instead".} =
  ## **Deprecated since version 0.18.1**. Use `len()` instead.
  discard
proc xlen*[T](x: seq[T]): int {.magic: "XLenSeq", noSideEffect,
                                deprecated: "use len() instead".} =
  ## **Deprecated since version 0.18.1**. Use `len()` instead.
  ##
  ## Returns the length of a sequence or a string without testing for 'nil'.
  ## This is an optimization that rarely makes sense.
  discard


proc `==`*(x, y: cstring): bool {.magic: "EqCString", noSideEffect,
                                   inline.} =
  ## Checks for equality between two `cstring` variables.
  proc strcmp(a, b: cstring): cint {.noSideEffect,
    importc, header: "<string.h>".}
  if pointer(x) == pointer(y): result = true
  elif x.isNil or y.isNil: result = false
  else: result = strcmp(x, y) == 0

when defined(nimNoNilSeqs2):
  when not compileOption("nilseqs"):
    when defined(nimHasUserErrors):
      # bug #9149; ensure that 'type(nil)' does not match *too* well by using 'type(nil) | type(nil)'.
      # Eventually (in 0.20?) we will be able to remove this hack completely.
      proc `==`*(x: string; y: type(nil) | type(nil)): bool {.
          error: "'nil' is now invalid for 'string'; compile with --nilseqs:on for a migration period".} =
        discard
      proc `==`*(x: type(nil) | type(nil); y: string): bool {.
          error: "'nil' is now invalid for 'string'; compile with --nilseqs:on for a migration period".} =
        discard
    else:
      proc `==`*(x: string; y: type(nil) | type(nil)): bool {.error.} = discard
      proc `==`*(x: type(nil) | type(nil); y: string): bool {.error.} = discard

template closureScope*(body: untyped): untyped =
  ## Useful when creating a closure in a loop to capture local loop variables by
  ## their current iteration values. Example:
  ##
  ## .. code-block:: Nim
  ##   var myClosure : proc()
  ##   # without closureScope:
  ##   for i in 0 .. 5:
  ##     let j = i
  ##     if j == 3:
  ##       myClosure = proc() = echo j
  ##   myClosure() # outputs 5. `j` is changed after closure creation
  ##   # with closureScope:
  ##   for i in 0 .. 5:
  ##     closureScope: # Everything in this scope is locked after closure creation
  ##       let j = i
  ##       if j == 3:
  ##         myClosure = proc() = echo j
  ##   myClosure() # outputs 3
  (proc() = body)()

template once*(body: untyped): untyped =
  ## Executes a block of code only once (the first time the block is reached).
  ##
  ## .. code-block:: Nim
  ##
  ##  proc draw(t: Triangle) =
  ##    once:
  ##      graphicsInit()
  ##    line(t.p1, t.p2)
  ##    line(t.p2, t.p3)
  ##    line(t.p3, t.p1)
  ##
  var alreadyExecuted {.global.} = false
  if not alreadyExecuted:
    alreadyExecuted = true
    body

{.pop.} #{.push warning[GcMem]: off, warning[Uninit]: off.}

proc substr*(s: string, first, last: int): string =
  ## Copies a slice of `s` into a new string and returns this new
  ## string.
  ##
  ## The bounds `first` and `last` denote the indices of
  ## the first and last characters that shall be copied. If ``last``
  ## is omitted, it is treated as ``high(s)``. If ``last >= s.len``, ``s.len``
  ## is used instead: This means ``substr`` can also be used to `cut`:idx:
  ## or `limit`:idx: a string's length.
  runnableExamples:
    let a = "abcdefgh"
    assert a.substr(2, 5) == "cdef"
    assert a.substr(2) == "cdefgh"
    assert a.substr(5, 99) == "fgh"

  let first = max(first, 0)
  let L = max(min(last, high(s)) - first + 1, 0)
  result = newString(L)
  for i in 0 .. L-1:
    result[i] = s[i+first]

proc substr*(s: string, first = 0): string =
  result = substr(s, first, high(s))

when defined(nimconfig):
  include "system/nimscript"

when not defined(js):
  proc toOpenArray*[T](x: ptr UncheckedArray[T]; first, last: int): openArray[T] {.
    magic: "Slice".}
  when defined(nimToOpenArrayCString):
    proc toOpenArray*(x: cstring; first, last: int): openArray[char] {.
      magic: "Slice".}
    proc toOpenArrayByte*(x: cstring; first, last: int): openArray[byte] {.
      magic: "Slice".}

proc toOpenArray*[T](x: seq[T]; first, last: int): openArray[T] {.
  magic: "Slice".}
proc toOpenArray*[T](x: openArray[T]; first, last: int): openArray[T] {.
  magic: "Slice".}
proc toOpenArray*[I, T](x: array[I, T]; first, last: I): openArray[T] {.
  magic: "Slice".}
proc toOpenArray*(x: string; first, last: int): openArray[char] {.
  magic: "Slice".}

proc toOpenArrayByte*(x: string; first, last: int): openArray[byte] {.
  magic: "Slice".}
proc toOpenArrayByte*(x: openArray[char]; first, last: int): openArray[byte] {.
  magic: "Slice".}
proc toOpenArrayByte*(x: seq[char]; first, last: int): openArray[byte] {.
  magic: "Slice".}

type
  ForLoopStmt* {.compilerproc.} = object ## \
    ## A special type that marks a macro as a `for-loop macro`:idx:.
    ## See `"For Loop Macro" <manual.html#macros-for-loop-macro>`_.

when defined(genode):
  var componentConstructHook*: proc (env: GenodeEnv) {.nimcall.}
    ## Hook into the Genode component bootstrap process.
    ##
    ## This hook is called after all globals are initialized.
    ## When this hook is set the component will not automatically exit,
    ## call ``quit`` explicitly to do so. This is the only available method
    ## of accessing the initial Genode environment.

  proc nim_component_construct(env: GenodeEnv) {.exportc.} =
    ## Procedure called during ``Component::construct`` by the loader.
    if componentConstructHook.isNil:
      env.quit(programResult)
        # No native Genode application initialization,
        # exit as would POSIX.
    else:
      componentConstructHook(env)
        # Perform application initialization
        # and return to thread entrypoint.


import system/widestrs
export widestrs

import system/io
export io

when not defined(createNimHcr):
  include nimhcr
