# [整数と浮動小数点数](@id Integers-and-Floating-Point-Numbers)

整数と浮動小数点数の値は，算術や計算の基本的な構成要素です．このような値の組み込み表現は
数値プリミティブと呼ばれ，コード内の即時値としての整数や浮動小数点数の表現は，数値リテラル
として知られています．例えば，`1`は整数リテラルであり，`1.0`は浮動小数点リテラルです．
オブジェクトとしてのメモリ内のバイナリ表現が数値プリミティブです．

Juliaは広範囲のプリミティブな数値型を提供し，それらの上で標準的な数学関数，および
算術演算子やビット演算子の完全な補完が定義されています．これらは最新のコンピュータで
ネイティブにサポートされている数値型や演算に直接マッピングされているため，Juliaは計算
リソースを最大限に活用することができます．さらに，Juliaは[Arbitrary Precision Arithmetic](@ref)
をソフトウェアでサポートしており，ネイティブのハードウェア表現では効果的に表現できない
数値の演算を扱うことができますが，その引き換えに比較的動作は遅くなってしまいます．

以下がJuliaのプリミティブな数値型です:

  * **整数型:**

| Type              | Signed? | Number of bits | Smallest value | Largest value |
|:----------------- |:------- |:-------------- |:-------------- |:------------- |
| [`Int8`](@ref)    | ✓       | 8              | -2^7           | 2^7 - 1       |
| [`UInt8`](@ref)   |         | 8              | 0              | 2^8 - 1       |
| [`Int16`](@ref)   | ✓       | 16             | -2^15          | 2^15 - 1      |
| [`UInt16`](@ref)  |         | 16             | 0              | 2^16 - 1      |
| [`Int32`](@ref)   | ✓       | 32             | -2^31          | 2^31 - 1      |
| [`UInt32`](@ref)  |         | 32             | 0              | 2^32 - 1      |
| [`Int64`](@ref)   | ✓       | 64             | -2^63          | 2^63 - 1      |
| [`UInt64`](@ref)  |         | 64             | 0              | 2^64 - 1      |
| [`Int128`](@ref)  | ✓       | 128            | -2^127         | 2^127 - 1     |
| [`UInt128`](@ref) |         | 128            | 0              | 2^128 - 1     |
| [`Bool`](@ref)    | N/A     | 8              | `false` (0)    | `true` (1)    |

  * **浮動小数点数型:**

| Type              | Precision                                                                      | Number of bits |
|:----------------- |:------------------------------------------------------------------------------ |:-------------- |
| [`Float16`](@ref) | [half](https://en.wikipedia.org/wiki/Half-precision_floating-point_format)     | 16             |
| [`Float32`](@ref) | [single](https://en.wikipedia.org/wiki/Single_precision_floating-point_format) | 32             |
| [`Float64`](@ref) | [double](https://en.wikipedia.org/wiki/Double_precision_floating-point_format) | 64             |

さらに，これらのプリミティブな数値型の上に，[Complex and Rational Numbers](@ref)の完全なサポートが構築
されています．全ての数値型は，柔軟でユーザが拡張可能な[type promotion system](@ref conversion-and-promotion)
のおかげで，明示的なキャストを行わなくても自然に相互運用することができます．


## 整数型

リテラルな整数は標準的な方法で表現されます:

```jldoctest
julia> 1
1

julia> 1234
1234
```

整数リテラルのデフォルトの型は，ターゲットシステムが32ビットアーキテクチャか64ビットアーキ
テクチャかによって異なります:

```julia-repl
# 32-bit system:
julia> typeof(1)
Int32

# 64-bit system:
julia> typeof(1)
Int64
```

Juliaの内部変数[`Sys.WORD_SIZE`](@ref)は，ターゲットシステムが32ビットか64ビットかを示します:

```julia-repl
# 32-bit system:
julia> Sys.WORD_SIZE
32

# 64-bit system:
julia> Sys.WORD_SIZE
64
```

Juliaでは`Int`と`UInt`という型も定義されますが，これはそれぞれ，システムの符号付整数型と
符号なし整数型のエイリアスとなっています:

```julia-repl
# 32-bit system:
julia> Int
Int32
julia> UInt
UInt32

# 64-bit system:
julia> Int
Int64
julia> UInt
UInt64
```

32ビットだけでは表現できないが64ビットあれば表現できるような大きな整数リテラルは，
システムタイプに関係なく，常に64ビットの整数を作成します:

```jldoctest
# 32-bit or 64-bit system:
julia> typeof(3000000000)
Int64
```

符号なし整数は，`0x`接頭辞と16進数の`0-9a-f`を使用して入出力されます（大文字の`A-F`も入力
用に機能します）．符号なしの値のサイズは，使用される16進数によって決まります:

```jldoctest
julia> 0x1
0x01

julia> typeof(ans)
UInt8

julia> 0x123
0x0123

julia> typeof(ans)
UInt16

julia> 0x1234567
0x01234567

julia> typeof(ans)
UInt32

julia> 0x123456789abcdef
0x0123456789abcdef

julia> typeof(ans)
UInt64

julia> 0x11112222333344445555666677778888
0x11112222333344445555666677778888

julia> typeof(ans)
UInt128
```

この動作は整数値に符号なし16進数リテラルを使用する場合，整数値だけではなく固定された数値
バイト列を表すために使用しているという観察に基づいています．

変数[`ans`](@ref)は対話的なセッションで評価された最後の式の値に設定されることを思い出して
ください．これは，Juliaコードが他の方法で実行されている場合には発生しません．

2進リテラルと8進リテラルもサポートされています:

```jldoctest
julia> 0b10
0x02

julia> typeof(ans)
UInt8

julia> 0o010
0x08

julia> typeof(ans)
UInt8

julia> 0x00000000000000001111222233334444
0x00000000000000001111222233334444

julia> typeof(ans)
UInt128
```

16進リテラルと同様に，2進リテラルおよび8進リテラルは符号なし整数型を生成します．2進数データ
アイテムのサイズは，リテラルの先頭の桁が`0`でない場合，必要最小限のサイズです．先頭に0が並ぶ
場合は，サイズは，同じ長さだが先頭の桁に`1`が並んでいるようなリテラルの必要最小限のサイズ
によって決定されます．これにより，ユーザはサイズを制御することができます．`UInt128`に格納
できない値は，そのようなリテラルとして書き込むことはできません．

2進，8進，16進リテラルは，符号なしリテラルの直前に`-`をつけることができます．これらの
リテラルは，符号なしリテラルが，値の2の補数行うのと同じサイズの符号なし整数を生成します．

```jldoctest
julia> -0x2
0xfe

julia> -0x0002
0xfffe
```

整数のようなプリミティブな数値型で表現可能な最小値と最大値は，[`typemin`](@ref)と
[`typemax`](@ref)関数を使って調べることができます．

```jldoctest
julia> (typemin(Int32), typemax(Int32))
(-2147483648, 2147483647)

julia> for T in [Int8,Int16,Int32,Int64,Int128,UInt8,UInt16,UInt32,UInt64,UInt128]
           println("$(lpad(T,7)): [$(typemin(T)),$(typemax(T))]")
       end
   Int8: [-128,127]
  Int16: [-32768,32767]
  Int32: [-2147483648,2147483647]
  Int64: [-9223372036854775808,9223372036854775807]
 Int128: [-170141183460469231731687303715884105728,170141183460469231731687303715884105727]
  UInt8: [0,255]
 UInt16: [0,65535]
 UInt32: [0,4294967295]
 UInt64: [0,18446744073709551615]
UInt128: [0,340282366920938463463374607431768211455]
```

[`typemin`](@ref)と[`typemax`](@ref)によって返される値は，常に与えられた引数の型の値に
なります．（上記の式は[for loops](@ref man-loops)，[Strings](@ref man-strings)や
[Interpolation](@ref string-interpolation)といった，まだ紹介していないいくつかの機能を
使用していますが，プログラミング経験のあるユーザにとっては十分に理解しやすいはずです．）

### オーバーフロー

Juliaでは，指定された型で表現可能な最大値を超えると，ラップアラウンド動作が発生します:

```jldoctest
julia> x = typemax(Int64)
9223372036854775807

julia> x + 1
-9223372036854775808

julia> x + 1 == typemin(Int64)
true
```

このように，Juliaの整数を用いた算術は，実際には[modular arithmetic](https://en.wikipedia.org/wiki/Modular_arithmetic)の
一形態です．これは，現代の計算機に実装されている基本的な整数演算の特性を反映しています．
オーバーフローが起きうるアプリケーションでは，オーバーフローによって生じるラップアラウンド
を明示的にチェックすることが不可欠です．そうでない場合は[Arbitrary Precision Arithmetic](@ref)
の[`BigInt`](@ref)型を使用することを推奨します．

オーバーフローの動作例と，それを解決する可能性のある方法を以下に示します:

```jldoctest
julia> 10^19
-8446744073709551616

julia> big(10)^19
10000000000000000000
```

### 除算エラー

整数の除算（`div`関数）には，2つの例外的なケースがあります．0で除算する場合と，表現できる中
で最も小さい負の数（[`typemin`](@ref)）を-1で除算する場合です．これらのケースはどちらでも，
[`DivideError`](@ref)をスローします．剰余関数とモジュラス関数（`rem`と`mod`）は2番目の
引数が0の場合に[`DivideError`](@ref)をスローします．

## Floating-Point Numbers

Literal floating-point numbers are represented in the standard formats, using
[E-notation](https://en.wikipedia.org/wiki/Scientific_notation#E-notation) when necessary:

```jldoctest
julia> 1.0
1.0

julia> 1.
1.0

julia> 0.5
0.5

julia> .5
0.5

julia> -1.23
-1.23

julia> 1e10
1.0e10

julia> 2.5e-4
0.00025
```

The above results are all [`Float64`](@ref) values. Literal [`Float32`](@ref) values can be
entered by writing an `f` in place of `e`:

```jldoctest
julia> 0.5f0
0.5f0

julia> typeof(ans)
Float32

julia> 2.5f-4
0.00025f0
```

Values can be converted to [`Float32`](@ref) easily:

```jldoctest
julia> Float32(-1.5)
-1.5f0

julia> typeof(ans)
Float32
```

Hexadecimal floating-point literals are also valid, but only as [`Float64`](@ref) values,
with `p` preceding the base-2 exponent:

```jldoctest
julia> 0x1p0
1.0

julia> 0x1.8p3
12.0

julia> 0x.4p-1
0.125

julia> typeof(ans)
Float64
```

Half-precision floating-point numbers are also supported ([`Float16`](@ref)), but they are
implemented in software and use [`Float32`](@ref) for calculations.

```jldoctest
julia> sizeof(Float16(4.))
2

julia> 2*Float16(4.)
Float16(8.0)
```

The underscore `_` can be used as digit separator:

```jldoctest
julia> 10_000, 0.000_000_005, 0xdead_beef, 0b1011_0010
(10000, 5.0e-9, 0xdeadbeef, 0xb2)
```

### Floating-point zero

Floating-point numbers have [two zeros](https://en.wikipedia.org/wiki/Signed_zero), positive zero
and negative zero. They are equal to each other but have different binary representations, as
can be seen using the [`bitstring`](@ref) function:

```jldoctest
julia> 0.0 == -0.0
true

julia> bitstring(0.0)
"0000000000000000000000000000000000000000000000000000000000000000"

julia> bitstring(-0.0)
"1000000000000000000000000000000000000000000000000000000000000000"
```

### Special floating-point values

There are three specified standard floating-point values that do not correspond to any point on
the real number line:

| `Float16` | `Float32` | `Float64` | Name              | Description                                                     |
|:--------- |:--------- |:--------- |:----------------- |:--------------------------------------------------------------- |
| `Inf16`   | `Inf32`   | `Inf`     | positive infinity | a value greater than all finite floating-point values           |
| `-Inf16`  | `-Inf32`  | `-Inf`    | negative infinity | a value less than all finite floating-point values              |
| `NaN16`   | `NaN32`   | `NaN`     | not a number      | a value not `==` to any floating-point value (including itself) |

For further discussion of how these non-finite floating-point values are ordered with respect
to each other and other floats, see [Numeric Comparisons](@ref). By the [IEEE 754 standard](https://en.wikipedia.org/wiki/IEEE_754-2008),
these floating-point values are the results of certain arithmetic operations:

```jldoctest
julia> 1/Inf
0.0

julia> 1/0
Inf

julia> -5/0
-Inf

julia> 0.000001/0
Inf

julia> 0/0
NaN

julia> 500 + Inf
Inf

julia> 500 - Inf
-Inf

julia> Inf + Inf
Inf

julia> Inf - Inf
NaN

julia> Inf * Inf
Inf

julia> Inf / Inf
NaN

julia> 0 * Inf
NaN
```

The [`typemin`](@ref) and [`typemax`](@ref) functions also apply to floating-point types:

```jldoctest
julia> (typemin(Float16),typemax(Float16))
(-Inf16, Inf16)

julia> (typemin(Float32),typemax(Float32))
(-Inf32, Inf32)

julia> (typemin(Float64),typemax(Float64))
(-Inf, Inf)
```

### Machine epsilon

Most real numbers cannot be represented exactly with floating-point numbers, and so for many purposes
it is important to know the distance between two adjacent representable floating-point numbers,
which is often known as [machine epsilon](https://en.wikipedia.org/wiki/Machine_epsilon).

Julia provides [`eps`](@ref), which gives the distance between `1.0` and the next larger representable
floating-point value:

```jldoctest
julia> eps(Float32)
1.1920929f-7

julia> eps(Float64)
2.220446049250313e-16

julia> eps() # same as eps(Float64)
2.220446049250313e-16
```

These values are `2.0^-23` and `2.0^-52` as [`Float32`](@ref) and [`Float64`](@ref) values,
respectively. The [`eps`](@ref) function can also take a floating-point value as an
argument, and gives the absolute difference between that value and the next representable
floating point value. That is, `eps(x)` yields a value of the same type as `x` such that
`x + eps(x)` is the next representable floating-point value larger than `x`:

```jldoctest
julia> eps(1.0)
2.220446049250313e-16

julia> eps(1000.)
1.1368683772161603e-13

julia> eps(1e-27)
1.793662034335766e-43

julia> eps(0.0)
5.0e-324
```

The distance between two adjacent representable floating-point numbers is not constant, but is
smaller for smaller values and larger for larger values. In other words, the representable floating-point
numbers are densest in the real number line near zero, and grow sparser exponentially as one moves
farther away from zero. By definition, `eps(1.0)` is the same as `eps(Float64)` since `1.0` is
a 64-bit floating-point value.

Julia also provides the [`nextfloat`](@ref) and [`prevfloat`](@ref) functions which return
the next largest or smallest representable floating-point number to the argument respectively:

```jldoctest
julia> x = 1.25f0
1.25f0

julia> nextfloat(x)
1.2500001f0

julia> prevfloat(x)
1.2499999f0

julia> bitstring(prevfloat(x))
"00111111100111111111111111111111"

julia> bitstring(x)
"00111111101000000000000000000000"

julia> bitstring(nextfloat(x))
"00111111101000000000000000000001"
```

This example highlights the general principle that the adjacent representable floating-point numbers
also have adjacent binary integer representations.

### Rounding modes

If a number doesn't have an exact floating-point representation, it must be rounded to an
appropriate representable value. However, the manner in which this rounding is done can be
changed if required according to the rounding modes presented in the [IEEE 754
standard](https://en.wikipedia.org/wiki/IEEE_754-2008).

The default mode used is always [`RoundNearest`](@ref), which rounds to the nearest representable
value, with ties rounded towards the nearest value with an even least significant bit.

### Background and References

Floating-point arithmetic entails many subtleties which can be surprising to users who are unfamiliar
with the low-level implementation details. However, these subtleties are described in detail in
most books on scientific computation, and also in the following references:

  * The definitive guide to floating point arithmetic is the [IEEE 754-2008 Standard](https://standards.ieee.org/standard/754-2008.html);
    however, it is not available for free online.
  * For a brief but lucid presentation of how floating-point numbers are represented, see John D.
    Cook's [article](https://www.johndcook.com/blog/2009/04/06/anatomy-of-a-floating-point-number/)
    on the subject as well as his [introduction](https://www.johndcook.com/blog/2009/04/06/numbers-are-a-leaky-abstraction/)
    to some of the issues arising from how this representation differs in behavior from the idealized
    abstraction of real numbers.
  * Also recommended is Bruce Dawson's [series of blog posts on floating-point numbers](https://randomascii.wordpress.com/2012/05/20/thats-not-normalthe-performance-of-odd-floats/).
  * For an excellent, in-depth discussion of floating-point numbers and issues of numerical accuracy
    encountered when computing with them, see David Goldberg's paper [What Every Computer Scientist Should Know About Floating-Point Arithmetic](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.22.6768&rep=rep1&type=pdf).
  * For even more extensive documentation of the history of, rationale for, and issues with floating-point
    numbers, as well as discussion of many other topics in numerical computing, see the [collected writings](https://people.eecs.berkeley.edu/~wkahan/)
    of [William Kahan](https://en.wikipedia.org/wiki/William_Kahan), commonly known as the "Father
    of Floating-Point". Of particular interest may be [An Interview with the Old Man of Floating-Point](https://people.eecs.berkeley.edu/~wkahan/ieee754status/754story.html).

## Arbitrary Precision Arithmetic

To allow computations with arbitrary-precision integers and floating point numbers, Julia wraps
the [GNU Multiple Precision Arithmetic Library (GMP)](https://gmplib.org) and the [GNU MPFR Library](https://www.mpfr.org),
respectively. The [`BigInt`](@ref) and [`BigFloat`](@ref) types are available in Julia for arbitrary
precision integer and floating point numbers respectively.

Constructors exist to create these types from primitive numerical types, and the [string literal](@ref non-standard-string-literals) [`@big_str`](@ref) or [`parse`](@ref)
can be used to construct them from `AbstractString`s.  Once created, they participate in arithmetic
with all other numeric types thanks to Julia's [type promotion and conversion mechanism](@ref conversion-and-promotion):

```jldoctest
julia> BigInt(typemax(Int64)) + 1
9223372036854775808

julia> big"123456789012345678901234567890" + 1
123456789012345678901234567891

julia> parse(BigInt, "123456789012345678901234567890") + 1
123456789012345678901234567891

julia> big"1.23456789012345678901"
1.234567890123456789010000000000000000000000000000000000000000000000000000000004

julia> parse(BigFloat, "1.23456789012345678901")
1.234567890123456789010000000000000000000000000000000000000000000000000000000004

julia> BigFloat(2.0^66) / 3
2.459565876494606882133333333333333333333333333333333333333333333333333333333344e+19

julia> factorial(BigInt(40))
815915283247897734345611269596115894272000000000
```

However, type promotion between the primitive types above and [`BigInt`](@ref)/[`BigFloat`](@ref)
is not automatic and must be explicitly stated.

```jldoctest
julia> x = typemin(Int64)
-9223372036854775808

julia> x = x - 1
9223372036854775807

julia> typeof(x)
Int64

julia> y = BigInt(typemin(Int64))
-9223372036854775808

julia> y = y - 1
-9223372036854775809

julia> typeof(y)
BigInt
```

The default precision (in number of bits of the significand) and rounding mode of [`BigFloat`](@ref)
operations can be changed globally by calling [`setprecision`](@ref) and [`setrounding`](@ref),
and all further calculations will take these changes in account.  Alternatively, the precision
or the rounding can be changed only within the execution of a particular block of code by using
the same functions with a `do` block:

```jldoctest
julia> setrounding(BigFloat, RoundUp) do
           BigFloat(1) + parse(BigFloat, "0.1")
       end
1.100000000000000000000000000000000000000000000000000000000000000000000000000003

julia> setrounding(BigFloat, RoundDown) do
           BigFloat(1) + parse(BigFloat, "0.1")
       end
1.099999999999999999999999999999999999999999999999999999999999999999999999999986

julia> setprecision(40) do
           BigFloat(1) + parse(BigFloat, "0.1")
       end
1.1000000000004
```

## [Numeric Literal Coefficients](@id man-numeric-literal-coefficients)

To make common numeric formulae and expressions clearer, Julia allows variables to be immediately
preceded by a numeric literal, implying multiplication. This makes writing polynomial expressions
much cleaner:

```jldoctest numeric-coefficients
julia> x = 3
3

julia> 2x^2 - 3x + 1
10

julia> 1.5x^2 - .5x + 1
13.0
```

It also makes writing exponential functions more elegant:

```jldoctest numeric-coefficients
julia> 2^2x
64
```

The precedence of numeric literal coefficients is slightly lower than that of
unary operators such as negation.
So `-2x` is parsed as `(-2) * x` and `√2x` is parsed as `(√2) * x`.
However, numeric literal coefficients parse similarly to unary operators when
combined with exponentiation.
For example `2^3x` is parsed as `2^(3x)`, and `2x^3` is parsed as `2*(x^3)`.

Numeric literals also work as coefficients to parenthesized expressions:

```jldoctest numeric-coefficients
julia> 2(x-1)^2 - 3(x-1) + 1
3
```
!!! note
    The precedence of numeric literal coefficients used for implicit
    multiplication is higher than other binary operators such as multiplication
    (`*`), and division (`/`, `\`, and `//`).  This means, for example, that
    `1 / 2im` equals `-0.5im` and `6 // 2(2 + 1)` equals `1 // 1`.

Additionally, parenthesized expressions can be used as coefficients to variables, implying multiplication
of the expression by the variable:

```jldoctest numeric-coefficients
julia> (x-1)x
6
```

Neither juxtaposition of two parenthesized expressions, nor placing a variable before a parenthesized
expression, however, can be used to imply multiplication:

```jldoctest numeric-coefficients
julia> (x-1)(x+1)
ERROR: MethodError: objects of type Int64 are not callable

julia> x(x+1)
ERROR: MethodError: objects of type Int64 are not callable
```

Both expressions are interpreted as function application: any expression that is not a numeric
literal, when immediately followed by a parenthetical, is interpreted as a function applied to
the values in parentheses (see [Functions](@ref) for more about functions). Thus, in both of these
cases, an error occurs since the left-hand value is not a function.

The above syntactic enhancements significantly reduce the visual noise incurred when writing common
mathematical formulae. Note that no whitespace may come between a numeric literal coefficient
and the identifier or parenthesized expression which it multiplies.

### Syntax Conflicts

Juxtaposed literal coefficient syntax may conflict with two numeric literal syntaxes: hexadecimal
integer literals and engineering notation for floating-point literals. Here are some situations
where syntactic conflicts arise:

  * The hexadecimal integer literal expression `0xff` could be interpreted as the numeric literal
    `0` multiplied by the variable `xff`.
  * The floating-point literal expression `1e10` could be interpreted as the numeric literal `1` multiplied
    by the variable `e10`, and similarly with the equivalent `E` form.
  * The 32-bit floating-point literal expression `1.5f22` could be interpreted as the numeric literal
    `1.5` multiplied by the variable `f22`.

In all cases the ambiguity is resolved in favor of interpretation as numeric literals:

  * Expressions starting with `0x` are always hexadecimal literals.
  * Expressions starting with a numeric literal followed by `e` or `E` are always floating-point literals.
  * Expressions starting with a numeric literal followed by `f` are always 32-bit floating-point literals.

Unlike `E`, which is equivalent to `e` in numeric literals for historical reasons, `F` is just another
letter and does not behave like `f` in numeric literals. Hence, expressions starting with a numeric literal
followed by `F` are interpreted as the numerical literal multiplied by a variable, which means that, for
example, `1.5F22` is equal to `1.5 * F22`.

## Literal zero and one

Julia provides functions which return literal 0 and 1 corresponding to a specified type or the
type of a given variable.

| Function          | Description                                      |
|:----------------- |:------------------------------------------------ |
| [`zero(x)`](@ref) | Literal zero of type `x` or type of variable `x` |
| [`one(x)`](@ref)  | Literal one of type `x` or type of variable `x`  |

These functions are useful in [Numeric Comparisons](@ref) to avoid overhead from unnecessary
[type conversion](@ref conversion-and-promotion).

Examples:

```jldoctest
julia> zero(Float32)
0.0f0

julia> zero(1.0)
0.0

julia> one(Int32)
1

julia> one(BigFloat)
1.0
```
