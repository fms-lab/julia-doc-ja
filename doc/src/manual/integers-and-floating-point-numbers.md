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

## 浮動小数点数

リテラルな浮動小数点数は必要に応じて[E記法](https://en.wikipedia.org/wiki/Scientific_notation#E-notation)
を使用して標準的なフォーマットで表現されます．

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

上記の結果は全て[`Float64`](@ref)の値です．リテラルな[`Float32`](@ref)は，`e`の代わりに`f`
を書くことで入力することができます．

```jldoctest
julia> 0.5f0
0.5f0

julia> typeof(ans)
Float32

julia> 2.5f-4
0.00025f0
```

値は簡単に[`Float32`](@ref)に変換できます:

```jldoctest
julia> Float32(-1.5)
-1.5f0

julia> typeof(ans)
Float32
```

16進浮動小数点リテラルも有効ですが，基底2指数の前に`p`を持つ[`Float64`](@ref)の値として
のみ有効です:

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

半精度浮動小数点数もサポートされていますが（[`Float16`](@ref)），ソフトウェアで実装
されており，計算には[`Float32`](@ref)を使用します．

```jldoctest
julia> sizeof(Float16(4.))
2

julia> 2*Float16(4.)
Float16(8.0)
```

アンダースコア`_`を桁区切り文字として使用することができます:

```jldoctest
julia> 10_000, 0.000_000_005, 0xdead_beef, 0b1011_0010
(10000, 5.0e-9, 0xdeadbeef, 0xb2)
```

### 浮動小数点数のゼロ

浮動小数点数には，正のゼロと負のゼロの[2つのゼロ](https://en.wikipedia.org/wiki/Signed_zero)
があります．これらは互いに等しいですが，[`bitstring`](@ref)関数を使えばわかるように，
異なる2進数表現がされています．

```jldoctest
julia> 0.0 == -0.0
true

julia> bitstring(0.0)
"0000000000000000000000000000000000000000000000000000000000000000"

julia> bitstring(-0.0)
"1000000000000000000000000000000000000000000000000000000000000000"
```

### [特別な浮動小数点数の値](@id Special-floating-point-values)

実数線上のどの点にも対応しない浮動小数点数の指定された3種類の標準値があります:

| `Float16` | `Float32` | `Float64` | Name              | Description                                                     |
|:--------- |:--------- |:--------- |:----------------- |:--------------------------------------------------------------- |
| `Inf16`   | `Inf32`   | `Inf`     | positive infinity | 全ての有限な浮動小数点数の値よりも大きい値           |
| `-Inf16`  | `-Inf32`  | `-Inf`    | negative infinity | 全ての有限な浮動小数点数の値よりも小さい値              |
| `NaN16`   | `NaN32`   | `NaN`     | not a number      | （自分自身を含む）全ての浮動小数点数の値に対して`==`が成り立たない値 |

これらの非有限浮動小数点数の値が，お互いや他の浮動小数点数に対してどのように順序付けられてい
るかについては，[Numeric Comparisons](@ref)を参照してください．[IEEE 754 standard](https://en.wikipedia.org/wiki/IEEE_754-2008)
では，これらの浮動小数点数の値は特定の演算の結果です:

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

[`typemin`](@ref)および[`typemax`](@ref)関数も浮動小数点型に適用されます:

```jldoctest
julia> (typemin(Float16),typemax(Float16))
(-Inf16, Inf16)

julia> (typemin(Float32),typemax(Float32))
(-Inf32, Inf32)

julia> (typemin(Float64),typemax(Float64))
(-Inf, Inf)
```

### マシンイプシロン

ほとんどの実数は浮動小数点数で正確に表現できないので，多くの場合，隣接する2つの浮動小数点数
の間の距離を知ることが重要です．これは[マシンイプシロン](https://en.wikipedia.org/wiki/Machine_epsilon)として知られています．

Juliaは`1.0`とその次に大きい浮動小数点数との間の距離を与える[`eps`](@ref)を提供しています:

```jldoctest
julia> eps(Float32)
1.1920929f-7

julia> eps(Float64)
2.220446049250313e-16

julia> eps() # same as eps(Float64)
2.220446049250313e-16
```

これらの値は[`Float32`](@ref)と[`Float64`](@ref)の値で各々，`2.0^-23`と`2.0^-52`と
なっています．[`eps`](@ref)関数は引数として浮動小数点数の値を取ることもでき，その値と
次の表現可能な浮動小数点数の値との差の絶対値を与えます．つまり，`eps(x)`は`x + eps(x)`
が`x`よりも大きい次の表現可能な浮動小数点数となるような，`x`と同じ型の値を返します:

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

隣接する2つの表現可能な浮動小数点数の間の距離は一定ではありませんが，値が小さいほど小さく，
値が大きいほど大きくなります．言い換えれば，表現可能な浮動小数点数はゼロ付近の実数線で最も
密であり，ゼロから遠ざかるにつれて指数関数的に疎になります．定義により，`1.0`は64ビットの
浮動小数点数の値なので，`eps(1.0)`は`eps(Float64)`と同じになります．

またJuliaは[`nextfloat`](@ref)と[`prevfloat`](@ref)関数を提供しています．これはそれぞれ，
引数に与えられた数の次の最大または最小の表現可能な浮動小数点数を返します:

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

この例は，隣接する表現可能な浮動小数点数が，隣接する二進整数表現も持つという一般的な
原理を示しています．

### 丸めモード

数値が正確な浮動小数点表現を持たない場合，表現可能な適切な値に丸めなければなりません．
ただしこの丸めの方法は必要に応じて[IEEE 754standard](https://en.wikipedia.org/wiki/IEEE_754-2008)
で提示されている丸めモードにしたがって変更することができます．


デフォルトモードとして使用されるのは常に[`RoundNearest`](@ref)で，最も近い表現可能な
値に丸められ，タイは最も近い値に向かって偶数の最下位ビットで丸められます．

### 背景と参考文献

浮動小数点演算には，低レベルの実装の詳細に慣れていないユーザにとっては驚くような多くの細かな
特徴が含まれています．しかしこうした部分については科学的計算に関する帆とのどの書籍や，以下の
参考文献で詳しく説明されています．

  * 浮動小数点演算の決定的なガイドは[IEEE 754-2008 Standard](https://standards.ieee.org/standard/754-2008.html)ですが，オンラインで無料で手に入れることはできません．
  * 浮動小数点がどのように表現されているのかの簡単ではあるが明確な情報については，John D. Cookの[article](https://www.johndcook.com/blog/2009/04/06/anatomy-of-a-floating-point-number/)や，この表現が実数の理想化された抽象化とどのように動作が異なるかといったところから生じる問題のいくつかを紹介した[introduction](https://www.johndcook.com/blog/2009/04/06/numbers-are-a-leaky-abstraction/)を参照してください．
  * また浮動小数点数に関するBruce Dawsonの[series of blog posts on floating-point numbers](https://randomascii.wordpress.com/2012/05/20/thats-not-normalthe-performance-of-odd-floats/)もお勧めです．
  * 浮動小数点数と浮動小数点数を使った演算を行う際に発生する数値制度の問題についての詳細な議論については，David Goldbergの論文[What Every Computer Scientist Should Know About Floating-Point Arithmetic](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.22.6768&rep=rep1&type=pdf)を参照してください．
  * 浮動小数点数の歴史や根拠，浮動小数点数の問題点，数値計算の他の多くのトピックについては，「浮動小数点の父」として知られる[William Kahan](https://en.wikipedia.org/wiki/William_Kahan)の[collected writings](https://people.eecs.berkeley.edu/~wkahan/)を参照してください．特に興味深いのは，[An Interview with the Old Man of Floating-Point](https://people.eecs.berkeley.edu/~wkahan/ieee754status/754story.html)かもしれません．

## [任意の精度の演算](@id Arbitrary-Precision-Arithmetic)

任意の精度の整数と浮動小数点数の計算を可能にするために，Juliaは[GNU Multiple Precision Arithmetic Library (GMP)](https://gmplib.org)
と[GNU MPFRLibrary](https://www.mpfr.org)をそれぞれラップしています．Juliaでは，[`BigInt`](@ref)型
と[`BigFloat`](@ref)型が，それぞれ任意精度の整数と浮動小数点数の表現に利用できます．

プリミティブな数値型からこれらの型を作成するためのコンストラクタが存在し，
[string literal](@ref non-standard-string-literals)[`@big_str`](@ref)または[`parse`](@ref)
を使用して，`AbstractString`型からこれらの型を作成することができます．一度作成された数値型
は，Juliaの[type promotion and conversion mechanism](@ref conversion-and-promotion)により，
他の全ての数値型と一緒に算術に参加します．

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

ただし，上記のプリミティブ型と[`BigInt`](@ref)/[`BigFloat`](@ref)との間のタイププロモーショ
ンは自動ではなく，明示的に記述する必要があります．

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

[`BigFloat`](@ref)演算のデフォルトの精度（符号のビット数）と丸めモードは，[`setprecision`](@ref)
と[`setrounding`](@ref)を呼び出すことでグローバルに変更することができ，それ以降の全ての計算
はこれらの変更を考慮に入れて行われます．また，精度や丸めは，`do`ブロックで同じ関数を仕様する
ことで，特定のコードブロックの実行内でのみ変更することができます:

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

## [数値リテラル係数](@id man-numeric-literal-coefficients)

一般的な数値式や式をより明確にするために，Juliaでは変数の前に数値リテラルをつけることが
でき，乗算を意味しています．これにより多項式の記述がより簡単になります:

```jldoctest numeric-coefficients
julia> x = 3
3

julia> 2x^2 - 3x + 1
10

julia> 1.5x^2 - .5x + 1
13.0
```

また，指数関数の書き方もよりエレガントになります:

```jldoctest numeric-coefficients
julia> 2^2x
64
```

数値リテラルの係数の優先順位は，否定などの単項演算子よりもわずかに低くなります．
したがって，`-2x`は`(-2) * x`として解析され，`√2x`は`(√2) * x`として解析されます．
しかし，数値リテラル係数は，指数関数と組み合わせた場合，単項演算子と同様に解析されます．
例えば，`2^3x`は`2^(3x)`として解析され，`2x^3`は`2*(x^3)`として解析されます．

数値リテラルは，括弧で囲まれた式の係数としても機能します:

```jldoctest numeric-coefficients
julia> 2(x-1)^2 - 3(x-1) + 1
3
```
!!! note
    暗黙の乗算に使用される数値リテラル係数の優先順位は，乗算(`*`)や除算(`/`, `\`, and `//`)
    などの他の2進演算子よりも高くなります．これは例えば，`1 / 2im`は`-0.5im`に等しく，
    `6 // 2(2 + 1)`は`1 // 1`に等しくなることを意味します．

さらに，括弧で囲まれた式は，変数の係数として使用することができ，変数による式の乗算を意味します:

```jldoctest numeric-coefficients
julia> (x-1)x
6
```

ただし，2つの括弧付き式の並置や，括弧付き式の前に変数を置くことは，乗算を暗示するために使用できません:

```jldoctest numeric-coefficients
julia> (x-1)(x+1)
ERROR: MethodError: objects of type Int64 are not callable

julia> x(x+1)
ERROR: MethodError: objects of type Int64 are not callable
```

どちらの式も関数のアプリケーションとして解釈されます．つまり，数値リテラルではない任意の式は
，その直後に括弧が続く場合には，括弧内の値に適用される関数として解釈されます（関数についての
詳細は[Functions](@ref)を参照してください）．したがって，これらのケースでは，左側の値は関数
ではないため，エラーが発生します．

上記の構文の強化により，一般的な数式を書くときに発生する視覚的なノイズが大幅に削減されまし
た．数値リテラル係数と，それが乗算する識別子または括弧で囲まれた式の間には，空白を入れては
いけないことに注意してください．

### 構文の競合

並置リテラル係数構文は，2つの数値リテラル構文（16進整数リテラルと浮動小数点リテラルの工学的
表記法）と競合することがあります．ここでは構文上の競合が発生する状況をいくつか紹介します:

  * 16進整数リテラル式`0xff`は，数値リテラル`0`に変数`xff`を掛けたものとして解釈される可能性があります．
  * 浮動小数点リテラル式`1e10`は，数値リテラル`1`に変数`e10`を掛けたものとして解釈され，等価な`E`形式と同様に解釈される可能性があります．
  * 32ビット浮動小数点リテラル`1.5f22`は，変数`f22`に`1.5`を掛けた数値リテラルとして解釈できます．

全ての場合において，曖昧さは数値リテラルとして解釈することで解決されます:

  * `0x`で始まる式は常に16進リテラルです．
  * ある数値リテラルの後に`e`または`E`が続くような式は，常に浮動小数点リテラルです．
  * ある数値リテラルの後に`f`が続くような式は，常に32ビット浮動小数点リテラルになります．

歴史的な理由から，数値リテラルでは，`e`と同等である`E`とは異なり，`F`は単なる別の文字で
あり，数値リテラルでは`f`のように動作しません．したがって，数値リテラルの後に`F`が続く式
始まる式は，数値リテラルに変数を掛けたものとして解釈され，例えば`1.5F22`は`1.5 * F22`と
等しいということを意味しています．

## リテラル0と1

Juliaは，指定された型や，与えられた変数の型に対応するリテラル0と1を返す関数を提供しています．

| Function          | Description                                      |
|:----------------- |:------------------------------------------------ |
| [`zero(x)`](@ref) | 型`x`または変数`x`の型のリテラルゼロ |
| [`one(x)`](@ref)  | 型`x`または変数`x`の型のリテラル1  |

これらの関数は，[Numeric Comparisons](@ref)の際に，不要な[type conversion](@ref conversion-and-promotion)
によるオーバーヘッドを回避するのに便利です．


以下に例を示します:

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
