# [複素数と有理数](@id Complex-and-Rational-Numbers)

Juliaには複素数と有理数の両方の定義済みの型が含まれており，それらに対する全ての標準的な
[Mathematical Operations and Elementary Functions](@ref)がサポートされています．
[Conversion and Promotion](@ref conversion-and-promotion)が定義されているので，
プリミティブなものでもコンポジットなものでも，定義済みの数値型の任意の組み合わせに対する
操作が期待通りに動作するようになっています．

## 複素数

グローバルな定数[`im`](@ref)は複素数*i*に結びつけられ，-1の平方根を表します（このグローバル
定数に数学者の`i`やエンジニアの`j`を使用することは，一般的なインデックス変数名であるため
却下されました）．Juliaでは数値リテラルを[juxtaposed with identifiers as coefficients](@ref man-numeric-literal-coefficients)
（係数として識別子と並置する）ことができるので，このバインディングは複素数に便利な構文を
提供するのに十分であり，伝統的な数学的記法に似ている形になります:

```jldoctest
julia> 1+2im
1 + 2im
```

複素数を使って全ての標準的な算術演算を行うことができます:

```jldoctest
julia> (1 + 2im)*(2 - 3im)
8 + 1im

julia> (1 + 2im)/(1 - 2im)
-0.6 + 0.8im

julia> (1 + 2im) + (1 - 2im)
2 + 0im

julia> (-3 + 2im) - (5 - 1im)
-8 + 3im

julia> (-1 + 2im)^2
-3 - 4im

julia> (-1 + 2im)^2.5
2.729624464784009 - 6.9606644595719im

julia> (-1 + 2im)^(1 + 1im)
-0.27910381075826657 + 0.08708053414102428im

julia> 3(2 - 5im)
6 - 15im

julia> 3(2 - 5im)^2
-63 - 60im

julia> 3(2 - 5im)^-1.0
0.20689655172413796 + 0.5172413793103449im
```

プロモーションのメカニズムは，異なる方のオペランドの組み合わせが動作することを保証します:

```jldoctest
julia> 2(1 - 1im)
2 - 2im

julia> (2 + 3im) - 1
1 + 3im

julia> (1 + 2im) + 0.5
1.5 + 2.0im

julia> (2 + 3im) - 0.5im
2.0 + 2.5im

julia> 0.75(1 + 2im)
0.75 + 1.5im

julia> (2 + 3im) / 2
1.0 + 1.5im

julia> (1 - 3im) / (2 + 2im)
-0.5 - 1.0im

julia> 2im^2
-2 + 0im

julia> 1 + 3/4im
1.0 - 0.75im
```

リテラル係数の方が除算よりも強く結びつくため，`3/4im == 3/(4*im) == -(3/4*im)`であることに注意してください．

複素数の値を操作するための標準関数が用意されています:

```jldoctest
julia> z = 1 + 2im
1 + 2im

julia> real(1 + 2im) # real part of z
1

julia> imag(1 + 2im) # imaginary part of z
2

julia> conj(1 + 2im) # complex conjugate of z
1 - 2im

julia> abs(1 + 2im) # absolute value of z
2.23606797749979

julia> abs2(1 + 2im) # squared absolute value
5

julia> angle(1 + 2im) # phase angle in radians
1.1071487177940904
```

通常通り，複素数の絶対値([`abs`](@ref))はゼロからの距離です．[`abs2`](@ref)は絶対値の二乗
を与え，平方根を取らずにすむので，複素数には特に有効です．[`angle`](@ref)はラジアン単位の
位相角を返します（*argument*や*arg*関数としても知られています）．他の[Elementary Functions](@ref)
の全ても複素数用に定義されています:

```jldoctest
julia> sqrt(1im)
0.7071067811865476 + 0.7071067811865475im

julia> sqrt(1 + 2im)
1.272019649514069 + 0.7861513777574233im

julia> cos(1 + 2im)
2.0327230070196656 - 3.0518977991518im

julia> exp(1 + 2im)
-1.1312043837568135 + 2.4717266720048188im

julia> sinh(1 + 2im)
-0.4890562590412937 + 1.4031192506220405im
```

数学的な関数は通常，実数に適用した場合にはじっすを返し，複素数に適用した場合には複素数を
返すことに注意してください．例えば，[`sqrt`](@ref)は，`-1 == -1 + 0im`ではありますが，
`-1`に適用した場合と`-1 + 0im`に適用した場合とでは挙動が異なります:

```jldoctest
julia> sqrt(-1)
ERROR: DomainError with -1.0:
sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
Stacktrace:
[...]

julia> sqrt(-1 + 0im)
0.0 + 1.0im
```

変数から複素数を構築する場合，[literal numeric coefficient notation](@ref man-numeric-literal-coefficients)
は機能しません．代わりに，乗算を明示的に書き出す必要あがあります:

```jldoctest
julia> a = 1; b = 2; a + b*im
1 + 2im
```

しかしこれは*非推奨*です．代わりに，より効率的な[`complex`](@ref)関数を利用して，実部と
虚部から直接複素数を構築してください:

```jldoctest
julia> a = 1; b = 2; complex(a, b)
1 + 2im
```

個の構築方法では乗算と加算の操作をしなくてすみます．

[`Inf`](@ref)と[`NaN`](@ref)は，[Special floating-point values](@ref)セクションで
説明されているように，複素数の実部と虚部で複素数を伝搬します．

```jldoctest
julia> 1 + Inf*im
1.0 + Inf*im

julia> 1 + NaN*im
1.0 + NaN*im
```

## [有理数](@id Rational-Numbers)

Juliaは整数の正確な比を表現するために，有理数型を持っています．有理数は[`//`](@ref)演算子
を使って構築されます:

```jldoctest
julia> 2//3
2//3
```

有理数の分子と分母が共通の因子を持つ場合，分母が非負であるような最小の値まで約分されます:

```jldoctest
julia> 6//9
2//3

julia> -4//8
-1//2

julia> 5//-15
-1//3

julia> -4//-12
1//3
```

整数の比のこの正規化された値は一意なので，分子と分母が等しいかどうかをチェックすることで，
有理数の値が等しいかどうかをテストすることができます．有理数の正規化された分子と分母は，
[`numerator`](@ref)関数と[`denominator`](@ref)関数を用いて抽出することができます:

```jldoctest
julia> numerator(2//3)
2

julia> denominator(2//3)
3
```

有理数に対して標準的な算術や比較演算が定義されているため，分子と分母の直接的な比較は
一般的には必要ありません:

```jldoctest
julia> 2//3 == 6//9
true

julia> 2//3 == 9//27
false

julia> 3//7 < 1//2
true

julia> 3//4 > 2//3
true

julia> 2//4 + 1//6
2//3

julia> 5//12 - 1//4
1//6

julia> 5//8 * 3//12
5//32

julia> 6//5 / 10//7
21//25
```

有理数は簡単に浮動小数点数に変換できます:

```jldoctest
julia> float(3//4)
0.75
```

有理数から浮動小数点数への変換は，`a == 0`かつ`b == 0`の場合を除いて，任意の整数値`a`，`b`
に対して以下の等式を尊重します:

```jldoctest
julia> a = 1; b = 2;

julia> isequal(float(a//b), a/b)
true
```

無限な有理数を構築することは可能です:

```jldoctest
julia> 5//0
1//0

julia> -3//0
-1//0

julia> typeof(ans)
Rational{Int64}
```

一方，有理数で[`NaN`](@ref)を構築することはできません:

```jldoctest
julia> 0//0
ERROR: ArgumentError: invalid rational: zero(Int64)//zero(Int64)
Stacktrace:
[...]
```

通常通り，プロモーションシステムは，他の数値型との相互作用を楽にします:

```jldoctest
julia> 3//5 + 1
8//5

julia> 3//5 - 0.5
0.09999999999999998

julia> 2//7 * (1 + 2im)
2//7 + 4//7*im

julia> 2//7 * (1.5 + 2im)
0.42857142857142855 + 0.5714285714285714im

julia> 3//2 / (1 + 2im)
3//10 - 3//5*im

julia> 1//2 + 2im
1//2 + 2//1*im

julia> 1 + 2//3im
1//1 - 2//3*im

julia> 0.5 == 1//2
true

julia> 0.33 == 1//3
false

julia> 0.33 < 1//3
true

julia> 1//3 - 0.33
0.0033333333333332993
```
