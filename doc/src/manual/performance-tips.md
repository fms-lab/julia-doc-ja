# [パフォーマンスのヒント](@id man-performance-tips)

以下のセクションでは，Juliaのコードをできるだけ高速に動作させるためのいくつかのテクニックを
簡単に説明します．

## グローバル変数を避ける

グローバル変数の値と型はいつでも変更される可能性があります．これはグローバル変数を使用した
コードをコンパイラが最適化するのを困難にします．変数は可能な限りローカルに定義するか，関数の
引数として渡すようにしてください．

パフォーマンスが重要なコードやベンチマークを行うコードは関数の中に入れるべきです．

グローバルな名前を持つものは定数であることが多く，定数であることを宣言することで，
パフォーマンスが大幅に向上することがわかりました:

```julia
const DEFAULT_VAL = 0
```

定数ではないグローバル変数の使用は，使用時に型をアノテーションすることで最適化できます:

```julia
global x = rand(1000)

function loop_over_global()
    s = 0.0
    for i in x::Vector{Float64}
        s += i
    end
    return s
end
```

関数に引数を渡すのは，より良いスタイルです．関数に引数を渡すことは，コードの再利用性を高め，
入出力が何であるかを明確にします．

!!! note
    REPL内の全てのコードはグローバルスコープで評価されるので，トップレベルで定義され，代入
    された変数は**グローバル**変数になります．モジュール内部のトップレベルスコープで定義さ
    れた変数もグローバルになります．

以下のREPLセッションの例では一つ目の式:

```julia-repl
julia> x = 1.0
```

と以下の2つ目の式は等価です:

```julia-repl
julia> global x = 1.0
```

ゆえに，上で議論された全てのパフォーマンスの問題が適用されます．

## [`@time`](@ref)によるパフォーマンスの計測とメモリ割り当てへの注意

パフォーマンスの測定に便利なツールとして，[`@time`](@ref)マクロがあります．ここでは上記の
グローバル変数を使用した例を繰り返しますが，今回は型アノテーションを削除しています:

```jldoctest; setup = :(using Random; Random.seed!(1234)), filter = r"[0-9\.]+ seconds \(.*?\)"
julia> x = rand(1000);

julia> function sum_global()
           s = 0.0
           for i in x
               s += i
           end
           return s
       end;

julia> @time sum_global()
  0.017705 seconds (15.28 k allocations: 694.484 KiB)
496.84883432553846

julia> @time sum_global()
  0.000140 seconds (3.49 k allocations: 70.313 KiB)
496.84883432553846
```

最初に`@time sum_global()`を呼び出したときに，関数がコンパイルされます．（このセクションで
[`@time`](@ref)を使用していない場合は，計測に必要な関数もコンパイルされます．）この実行結果
を深刻に受け止めるべきではありません．2回目の実行では，時間を報告するだけでなく，かなりの量
のメモリが割り当てられていることに注意してください．ここでは64ビットの浮動小数点数のベクトル
内の全ての要素の和を計算しているだけなので，メモリを割り当てる必要がありません（少なくとも
`@time`が報告するヒープ上での割り当ては必要ありません）．

予期せぬメモリ割り当ては，ほとんどの場合において，コードに何らかの問題があることを示していま
す．これは通常，型の安定性に問題があったり，小さな一時的な配列をたくさん生成したりするような
問題です．その結果割り当て自体に加えて，関数のために生成されたコードが最適化されていない可能
性が非常に高いです．このような兆候は真剣に受け止めて，以下のアドバイスに従ってください．

上述の例で，`x`を引数として渡すように変更すると，メモリが割り当てられなくなり（以下で
報告されている割り当てはグローバルスコープで`@time`マクロを実行したことによるものです），
最初の呼び出しの後には非常に高速に動作します:

```jldoctest sumarg; setup = :(using Random; Random.seed!(1234)), filter = r"[0-9\.]+ seconds \(.*?\)"
julia> x = rand(1000);

julia> function sum_arg(x)
           s = 0.0
           for i in x
               s += i
           end
           return s
       end;

julia> @time sum_arg(x)
  0.007701 seconds (821 allocations: 43.059 KiB)
496.84883432553846

julia> @time sum_arg(x)
  0.000006 seconds (5 allocations: 176 bytes)
496.84883432553846
```

例の中で5つ割り当てられているのは，グローバルスコープで`@time`を実行したことによるものです．
関数内で計測を行うように変更してから実行すると，確かにアロケーションが行われていないことが
わかります:

```jldoctest sumarg; filter = r"[0-9\.]+ seconds"
julia> time_sum(x) = @time sum_arg(x);

julia> time_sum(x)
  0.000001 seconds
496.84883432553846
```

状況によっては，関数がその操作の一部としてメモリを割り当てる必要がある場合があり，上記の
単純な状況を複雑にしてしまいます．そのような場合は，問題を診断するために以下の[tools](@ref tools)
のいずれかを使用するか，アルゴリズム的な側面から割り当てを分離したバージョンの関数を書くこと
を検討してください（[出力の事前割り当て](@ref Pre-allocating-outputs)を参照してください．

!!! note
    より本格的なベンチマークを行うには，[BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)
    パッケージの利用を検討してください．これはノイズを減らすために関数を複数回評価します．

## [ツール](@id tools)

Juliaとそのパッケージエコシステムには，問題を診断してコードのパフォーマンスを向上させるのに
役立つツールが含まれています:

  * [Profiling](@ref)により，実行中のコードのパフォーマンスを測定し，ボトルネックとなる行を特定することができます．複雑なプロジェクトでは，[ProfileView](https://github.com/timholy/ProfileView.jl)パッケージを使用sるうと，プロファイリング結果を可視化することができます．
  * [Traceur](https://github.com/JunoLab/Traceur.jl)パッケージは，コード内の一般的なパフォーマンスの問題を見つけるのに役立ちます．
  * [`@time`](@ref)や[`@allocated`](@ref)，あるいは（ガベージコレクションルーチンへの呼び出しを通じた）プロファイラが報告するような予想外に大きなメモリ割り当ては，コードに問題があるかもしれないことを示唆しています．割り当てで他の問題が見つからない場合は，型の問題を疑ってください．また，Juliaを`--track-allocation=user`オプションをつけて起動し，結果として得られた`*.mem`ファイルを調べて，どこで割り当てが行われているかの情報を確認することもできます．[Memory allocation analysis](@ref)を参照してください．
  * `@code_warntype`はコードの表現を生成し，型の不確実性をもたらす式を見つけるのに役立ちます．以下の[`@code_warntype`](@ref)を参照してください．

## [抽象型のパラメータを持つコンテナを避ける](@id man-performance-abstract-container)

配列を含む，パラメータ化された型を扱う際には，可能な限り抽象型でのパラメータ化は避けた方が良いでしょう．

以下を考えてみましょう:

```jldoctest
julia> a = Real[]
Real[]

julia> push!(a, 1); push!(a, 2.0); push!(a, π)
3-element Array{Real,1}:
 1
 2.0
 π = 3.1415926535897...
```

`a`は抽象型[`Real`](@ref)の配列なので，任意の`Real`型の値を保持できなければなりません．
`Real`オブジェクトは任意のサイズと構造を持つことができるので，`a`は個別に割り当てられた
`Real`オブジェクトへのポインタの配列として表現されなければなりません．しかし，代わりに
同じ型の数値，例えば[`Float64`](@ref)などの数値だけを`a`に格納できるようにすれば，これら
の数値をより効率的に格納することができます:

```jldoctest
julia> a = Float64[]
Float64[]

julia> push!(a, 1); push!(a, 2.0); push!(a,  π)
3-element Array{Float64,1}:
 1.0
 2.0
 3.141592653589793
```

`a`に数値を代入すると`Float64`に変換され，`a`は64ビット浮動小数点数値の連続したブロックと
して格納され，効率的に操作できるようになります．

以下の[Parametric Types](@ref)の説明も参照してください．

## 型宣言

型宣言がオプションとしてある多くの言語では，宣言を追加することがコードを高速に実行するため
の主要な方法です．しかし，Juliaでは*そうではありません*．Juliaではコンパイラは通常，全ての
関数引数，ローカル変数，式の型を知っています．しかし，宣言な有用な例はいくつか存在します．

### 抽象型のフィールドを避ける

型は，フィールドの型を指定せずに宣言することができます:

```jldoctest myambig
julia> struct MyAmbiguousType
           a
       end
```

これにより`a`に任意の型を指定することができます．これは便利ですが欠点もあります`MyAmbiguousType`
型のオブジェクトの場合，コンパイラは高性能なコードを生成できません．その理由は，コンパイラが
コードのビルド方法を決定するために，値ではなくオブジェクトの型を使用するからです．残念ながら
`MyAmbiguousType`型のオブジェクトについてはほとんど推論できません:

```jldoctest myambig
julia> b = MyAmbiguousType("Hello")
MyAmbiguousType("Hello")

julia> c = MyAmbiguousType(17)
MyAmbiguousType(17)

julia> typeof(b)
MyAmbiguousType

julia> typeof(c)
MyAmbiguousType
```

`b`と`c`は同じ型を持っていますが，メモリ上のデータの基本的な表現は全く異なっています．
フィールド`a`に数値だけを格納したとしても，[`UInt8`](@ref)のメモリ表現は[`Float64`](@ref)
とは異なるという事実は，CPUが2種類の異なる命令を使用してそれらを処理する必要があることを
意味します．この型では必要な情報が得られないため，このような判断は実行時に行わなければ
なりません．これがパフォーマンスを低下させます．

`a`の型を宣言することによるより良い方法があります．ここでは`a`がいくつかの型のうちいずれか
であるような場合に焦点を当てていますが，この場合の自然な解決策はパラメータを使うことです．
例えば:

```jldoctest myambig2
julia> mutable struct MyType{T<:AbstractFloat}
           a::T
       end
```

これは以下よりも優れています:

```jldoctest myambig2
julia> mutable struct MyStillAmbiguousType
           a::AbstractFloat
       end
```

これは，最初のバージョンではラッパーオブジェクトの型から`a`の型を指定しているからです．例えば:

```jldoctest myambig2
julia> m = MyType(3.2)
MyType{Float64}(3.2)

julia> t = MyStillAmbiguousType(3.2)
MyStillAmbiguousType(3.2)

julia> typeof(m)
MyType{Float64}

julia> typeof(t)
MyStillAmbiguousType
```

フィールド`a`の型は，`m`の型から容易に決定できますが，`t`の型からは決定できません．
実際，`t`では，フィールド`a`の型を変更することができます:

```jldoctest myambig2
julia> typeof(t.a)
Float64

julia> t.a = 4.5f0
4.5f0

julia> typeof(t.a)
Float32
```

これに対して，一度`m`が構成されると，`m.a`の型を変えることはできません:

```jldoctest myambig2
julia> m.a = 4.5f0
4.5f0

julia> typeof(m.a)
Float64
```

`m.a`の型が`m`の型からわかっているという事実と，関数の途中で型が変更できないという事実が
組み合わさって，コンパイラは`m`のようなオブジェクトに対しては最適化されたコードを生成でき
ますが，`t`のようばオブジェクトに対しては最適化されていません．

もちろん，これらは`m`を具体的な型で構築した場合にのみ有効です．明示的に抽象的な型で構成する
ことでこれを破ることができます:

```jldoctest myambig2
julia> m = MyType{AbstractFloat}(3.2)
MyType{AbstractFloat}(3.2)

julia> typeof(m.a)
Float64

julia> m.a = 4.5f0
4.5f0

julia> typeof(m.a)
Float32
```

現実的には，このようなオブジェクトは`MyStillAmbiguousType`のものと同じように動作します．

単純な関数

```julia
func(m::MyType) = m.a+1
```

のために生成されるコードの量を，以下を用いて比較するのは非常に有益です:

```julia
code_llvm(func, Tuple{MyType{Float64}})
code_llvm(func, Tuple{MyType{AbstractFloat}})
```

長くなるのでここでは結果を示しませんが，ご自身で試してみたくなるかもしれません．
最初のケースでは型が完全に指定されているため，コンパイラは実行時に型を解決するコードを
生成する必要がありません．その結果，短く高速なコードが生成されます．

### [抽象的なコンテナを持つフィールドを避ける](@id Avoid-fields-with-abstract-containers)

同じベストプラクティスはコンテナ型でも機能します:

```jldoctest containers
julia> struct MySimpleContainer{A<:AbstractVector}
           a::A
       end

julia> struct MyAmbiguousContainer{T}
           a::AbstractVector{T}
       end
```

例えば:

```jldoctest containers
julia> c = MySimpleContainer(1:3);

julia> typeof(c)
MySimpleContainer{UnitRange{Int64}}

julia> c = MySimpleContainer([1:3;]);

julia> typeof(c)
MySimpleContainer{Array{Int64,1}}

julia> b = MyAmbiguousContainer(1:3);

julia> typeof(b)
MyAmbiguousContainer{Int64}

julia> b = MyAmbiguousContainer([1:3;]);

julia> typeof(b)
MyAmbiguousContainer{Int64}
```

`MySimpleContainer`の場合，オブジェクトは型とパラメータで完全に指定されているので，コンパイ
ラは最適化された関数を生成することができます．ほとんどの場合はこれで十分でしょう．

コンパイラはこれで完璧に仕事をこなせるようになりましたが，`a`の*要素の型*に応じてコードを
変えたい場合もあるかもしれません．通常これを実現する最良の方法は，特定の操作（ここでは`foo`
）を別の関数でラップすることです:


```jldoctest containers
julia> function sumfoo(c::MySimpleContainer)
           s = 0
           for x in c.a
               s += foo(x)
           end
           s
       end
sumfoo (generic function with 1 method)

julia> foo(x::Integer) = x
foo (generic function with 1 method)

julia> foo(x::AbstractFloat) = round(x)
foo (generic function with 2 methods)
```

これにより，シンプルさを保ちながら，全てのケースでコンパイラが最適化されたコードを生成できるようになります．

しかし，異なる要素の型や，`MySimpleContainer`のフィールド`a`の`AbstractVector`の型ごとに
異なるバージョンの外部関数を宣言する必要が場合もあるでしょう．それは以下のようにできます:

```jldoctest containers
julia> function myfunc(c::MySimpleContainer{<:AbstractArray{<:Integer}})
           return c.a[1]+1
       end
myfunc (generic function with 1 method)

julia> function myfunc(c::MySimpleContainer{<:AbstractArray{<:AbstractFloat}})
           return c.a[1]+2
       end
myfunc (generic function with 2 methods)

julia> function myfunc(c::MySimpleContainer{Vector{T}}) where T <: Integer
           return c.a[1]+3
       end
myfunc (generic function with 3 methods)
```

```jldoctest containers
julia> myfunc(MySimpleContainer(1:3))
2

julia> myfunc(MySimpleContainer(1.0:3))
3.0

julia> myfunc(MySimpleContainer([1:3;]))
4
```

### 型付けされていない場所から取得した値をアノテーションする

任意の型の値を含むデータ構造体（`Array{Any}`型の配列）を扱うのは便利です．しかし，これらの
構造体を使用していて，たまたま要素の型を知っている場合は，その知識をコンパイラと共有するのに役立ちます:

```julia
function foo(a::Array{Any,1})
    x = a[1]::Int32
    b = x+1
    ...
end
```

ここでは，`a`の最初の要素が[`Int32`](@ref)であることを知っているものとします．このような
アノテーションを作成することで，値が期待される型でない場合にランタイムエラーを発生させ，
特定のバグを早期に発見できる可能性があるという利点があります．

`a[1]`の型が正確にわからない場合は，`x = convert(Int32, a[1])::Int32`で`x`を宣言することが
できます．[`convert`](@ref)関数を使用することで，`a[1]`は`Int32`に変換可能な任意のオブジェ
クト（`UInt8`など）になり，型の要件を緩くすることでコードの汎用性が高まります．型の安定性
を実現するために，この文脈では`convert`自体に型アノテーションが必要であることに注意してくだ
さい．これはある関数の全ての引数の型が既知でなければ，たとえ`convert`関数であっても，コンパ
イラが関数の戻り値の型を推測することができないためです．

型のアノテーションは実行時に型が構築されている場合，パフォーマンスを向上させることはできませ
ん（実際には妨げになることもあります）．これは，コンパイラがアノテーションを使用して後続の
コードを特殊化することができず，型チェック自体に時間がかかるからです．例えばコードの中では:

```julia
function nr(a, prec)
    ctype = prec == 32 ? Float32 : Float64
    b = Complex{ctype}(a)
    c = (b + 1.0f0)::Complex{ctype}
    abs(c)
end
```

`c`のアノテーションはパフォーマンスに悪影響を与えます．実行時に構築された型を含むパフォーマ
ンスの高いコードを書くには，後述する[function-barrier technique](@ref kernel-functions)を
使用し，カーネル関数の引数型の中に構築された型が現れるようにして，コンパイラがカーネル操作を
適切に特殊化できるようにします．例えば，上のスニペットでは，`b`が構築されるとすぐに，それを
カーネルである別の関数`k`に渡すことができます．例えば，関数`k`が`b`を`Complex{T}`型の引数と
して宣言し，`T`が型パラメータである場合，`k`内の代入文に現れる型アノテーションは次のような
形になります:

```julia
c = (b + 1.0f0)::Complex{T}
```

これは`k`がコンパイルされた時点でコンパイラが`c`の型を決定することができるため，性能に
支障をきたすことはありません（が，助けにもなりません）．

### Juliaが特殊化を避ける場合に注意する

ヒューリスティックな方法として，Juliaは3つの特定のケースで引数の型パラメータを自動的に特殊化
することを避けます．`Type`，`Function`と`Vararg`です．引数がメソッド内で使用される場合，
Juliaは常に特殊化しますが，引数が他の関数に渡されただけの場合は特殊化しません．これは通常，
実行時のパフォーマンスへの影響はなく，[コンパイラのパフォーマンスを向上させます](@ref compiler-efficiency-issues)．
実行時にパフォーマンスに影響があることがわかった場合は，メソッド宣言に型パラメータを追加する
ことで，特殊化をトリガすることができます．以下にいくつかの例を示します:

これは特殊化しません:

```julia
function f_type(t)  # or t::Type
    x = ones(t, 10)
    return sum(map(sin, x))
end
```

これは特殊化します:

```julia
function g_type(t::Type{T}) where T
    x = ones(T, 10)
    return sum(map(sin, x))
end
```

これは特殊化しません:

```julia
f_func(f, num) = ntuple(f, div(num, 2))
g_func(g::Function, num) = ntuple(g, div(num, 2))
```

これは特殊化します:

```julia
h_func(h::H, num) where {H} = ntuple(h, div(num, 2))
```

これは特殊化しません:

```julia
f_vararg(x::Int...) = tuple(x...)
```

これは特殊化します:

```julia
g_vararg(x::Vararg{Int, N}) where {N} = tuple(x...)
```

他の型が制約されていない場合でも強制的に特殊化を行うためには，1つの型のパラメータを導入する
だけでよいです．例えば，これも特殊化され，引数が全て同じ型ではない場合にも便利です．
```julia
h_vararg(x::Vararg{Any, N}) where {N} = tuple(x...)
```

Juliaが通常そのメソッド呼び出しを特殊化しない場合でも，[`@code_typed`](@ref)とフレンドは
常に特殊化されたコードを表示することに注意してください．引数の型が変更された時に特殊化が
生成されるかどうか，つまり`(@which f(...)).specializations`に問題の引数の特殊化が含まれて
いるかどうかを確認したい場合は，[メソッド内部](@ref ast-lowered-method)をチェックする必要
があります．

## 関数を複数の定義に分ける

関数を多くの小さな定義として書くことで，コンパイラが直接最も適用可能なコードを呼び出すことが
できますし，インライン化することもできます．

ここでは実際には複数の定義として記述されるべき「複合関数」の例を示します:

```julia
using LinearAlgebra

function mynorm(A)
    if isa(A, Vector)
        return sqrt(real(dot(A,A)))
    elseif isa(A, Matrix)
        return maximum(svdvals(A))
    else
        error("mynorm: invalid argument")
    end
end
```

これは以下のように書くと，より簡潔かつ効率的に書くことができます:

```julia
norm(x::Vector) = sqrt(real(dot(x, x)))
norm(A::Matrix) = maximum(svdvals(A))
```

ただし，コンパイラは`mynorm`の例のように記述されたコードのデッドブランチを最適化するのに
非常に効率的であることに注意してください．

## 「型が安定している」関数を書く

可能な場合，関数が常に同じ型の値を返すようにするのが役立ちます．次の定義を考えてみましょう:

```julia
pos(x) = x < 0 ? 0 : x
```

これは十分に悪くないように見えますが，問題は`0`が整数型（`Int`型）であり，`x`が任意型である
可能性があるということです．したがって`x`の値によっては，この関数は2つの型のどちらかの値を
返すことになります．この動作は許容されており，いくつかのケースでは望ましいかもしれません．
しかし，以下のように簡単に修正することができます:

```julia
pos(x) = x < 0 ? zero(x) : x
```

また[`oneunit`](@ref)関数や，より一般的な[`oftype(x, y)`](@ref)関数もあり，これは`x`の型に
変換された`y`を返します．

## 変数の型を変更することを避ける

関数内で繰り返し使用される変数には，類似の「型安定性」の問題が存在します:

```julia
function foo()
    x = 1
    for i = 1:10
        x /= rand()
    end
    return x
end
```

ローカル変数`x`は整数で始まり，1回ループした後には浮動小数点数（[`/`](@ref)演算子の結果）に
なります．これによりコンパイラがループの本体を最適化するのが難しくなります．いくつかの修正
方法が考えられます:

  * `x`を`x = 1.0`で初期化する
  * `x`の型を明示的に`x::Float64 = 1`として宣言する
  * `x = oneunit(Float64)`による明示的な変換を使用する
  * 最初のループの際に`x = 1 / rand()`で初期化してから，`for i = 2:10`をループします

## [カーネル関数を分離する（別名，関数バリア）](@id kernel-functions)

多くの関数は，いくつかの設定を実行した後，コア計算を実行するために何度も繰り返しを実行する
というパターンに従っています．可能であれば，これらのコア計算は別の関数で行うことをお勧め
します．例えば次のように不自然な関数は，ランダムに選ばれた型の配列を返します:

```jldoctest; setup = :(using Random; Random.seed!(1234))
julia> function strange_twos(n)
           a = Vector{rand(Bool) ? Int64 : Float64}(undef, n)
           for i = 1:n
               a[i] = 2
           end
           return a
       end;

julia> strange_twos(3)
3-element Array{Float64,1}:
 2.0
 2.0
 2.0
```

これは次のように書くべきです:

```jldoctest; setup = :(using Random; Random.seed!(1234))
julia> function fill_twos!(a)
           for i = eachindex(a)
               a[i] = 2
           end
       end;

julia> function strange_twos(n)
           a = Vector{rand(Bool) ? Int64 : Float64}(undef, n)
           fill_twos!(a)
           return a
       end;

julia> strange_twos(3)
3-element Array{Float64,1}:
 2.0
 2.0
 2.0
```

Juliaのコンパイラは関数の境界で引数の型のコードを特殊化しているので，オリジナルの実装では
ループの間の`a`の型を知りません（ランダムに選ばれているので）．そのため，異なる型の`a`に
対して，内側のループを`fill_twos!`の一部として再コンパイルできるため，2番目のバージョンは
一般的に高速になります．

また，2番目の形式の方がスタイルがよく，コードの再利用性が高まります．

このパターンはJulia Baseのいくつかの場所で使われています．例えば，[`abstractarray.jl`](https://github.com/JuliaLang/julia/blob/40fe264f4ffaa29b749bcf42239a89abdcbba846/base/abstractarray.jl#L1205-L1206)の
`vcat`や`hcat`，あるいは[`fill!`](@ref)関数を見てください．[`fill!`](@ref)関数は，上で独自に
書いた`fill_twos!`の代わりに使うことができます．

`strange_twos`のような関数は，例えば入力ファイルから読み込まれたデータが整数，浮動小数点数，
文字列，その他の何らかの型のものを含んでいるような，型が不確かなデータを扱うときに発生します．

## [パラメータとしての値を持つ型](@id man-performance-value-type)

各軸に沿ったサイズが3の`N`次元配列を作成したいとしましょう．このような配列は以下のように作成できます:

```jldoctest
julia> A = fill(5.0, (3, 3))
3×3 Array{Float64,2}:
 5.0  5.0  5.0
 5.0  5.0  5.0
 5.0  5.0  5.0
```

このアプローチは非常にうまく機能します．コンパイラはfill値（`5.0::Float64`）と次元数（
`(3, 3)::NTuple{2,Int}`）を知っているので，`A`が`Array{Float64,2}`であることがわかります．
このことは，コンパイラが将来同じ関数で`A`を使用する際に，非常に効率的なコードを生成できる
ことを意味しています．

しかしここで，任意の次元の3×3×...配列を作成する関数を書きたいとしましょう．次のような
関数を書きたくなるかもしれません:

```jldoctest
julia> function array3(fillval, N)
           fill(fillval, ntuple(d->3, N))
       end
array3 (generic function with 1 method)

julia> array3(5.0, 2)
3×3 Array{Float64,2}:
 5.0  5.0  5.0
 5.0  5.0  5.0
 5.0  5.0  5.0
```

これは動作しますが，（`@code_warntype array3(5.0, 2)`を使って確認できるように，）問題は出力
の型を推測できないことです．引数`N`は`Int`型の*値*であり，型推論ではその値を事前に予測する
ことはしませんし，できません．これは，この関数の出力を使用するコードは`A`へアクセスするたび
に型をチェックするような保守的なものでなければならないことを意味します．このようなコードは
非常に遅くなります．

["Value types"](@ref)):
さて，このような問題を解決するための非常に良い方法の一つが[関数バリアテクニック](@ref kernel-functions)です．
しかし場合によっては，型の不安定性を完全に排除したいとい思うかもしれません．そのような場合，
1つの方法として，例えば`Val{T}()`を通して次元性をパラメータを渡すものがあります（["Value types"](@ref)を参照してください）．

```jldoctest
julia> function array3(fillval, ::Val{N}) where N
           fill(fillval, ntuple(d->3, Val(N)))
       end
array3 (generic function with 1 method)

julia> array3(5.0, Val(2))
3×3 Array{Float64,2}:
 5.0  5.0  5.0
 5.0  5.0  5.0
 5.0  5.0  5.0
```

Juliaには，2番目のパラメータとして`Val{::Int}`インスタンスを受け付ける特殊なバージョンの
`ntuple`があります．`N`を型パラメータとして渡すことで，その「値」をコンパイラに知らせること
ができます．その結果，このバージョンの`array3`では，コンパイラが戻り値の型を予測することが
できます．

しかし，このようなテクニックを利用することは，驚くほど微妙なことです．例えば，次のような関数
から`array3`を呼び出しても何の役にも立ちません:

```julia
function call_array3(fillval, n)
    A = array3(fillval, Val(n))
end
```

この場合，同じ問題を繰り返してしまいます．コンパイラは`n`が何であるかを推測できないので，
`Val(n)`の*型*を知りません．`Val`を使おうとしても，それを誤って行うと，多くの状況でパフォーマンス
が悪化します．（カーネル関数をより効率にするために，`Val`と関数バリアのトリックを効果的に
組み合わせている状況でのみ，上記のようなコードを使うべきです．）

`Val`の正しい使い方の例は次のようになります:

```julia
function filter3(A::AbstractArray{T,N}) where {T,N}
    kernel = array3(1, Val(N))
    filter(A, kernel)
end
```

この例では，`N`はパラメータとして渡されるので，その「値」はコンパイラに知られます．基本的に
`Val(T)`は，`T`がハードコーディングされているか，リテラル（`Val(3)`）であるか，あるいは既に
タイプドメインで指定されている場合にのみ動作します．

## 複数のディスパッチを悪用する危険性（別名，パラメータとしての値を持つ型についての詳細）

一度複数のディスパッチのありがたみを知ると，行き過ぎて全てのことに使おうとする傾向があるのは
理解できます．例えば，以下の例のような情報を格納するためにこれを使い，
`Car{:Honda,:Accord}(year, args...)`のようなオブジェクトにディスパッチすることを想像してみて
ください:

```
struct Car{Make, Model}
    year::Int
    ...more fields...
end
```

以下のいずれかに当てはまる場合には，この方法は価値があるかもしれません:

  * `Car`ごとにCPU負荷の高い処理を必要とし，コンパイル時に`Make`と`Model`がわかっていて，使用される`Make`と`Model`の総数が多すぎない場合は，はるかに効率的になります．
  * 同じ種類の`Car`を処理するための均質なリストを持っているので，それらを全て`Array{Car{:Honda,:Accord},N}`に格納することができます．

後者の場合，このような均質な配列を処理する関数は生産的に特殊化することができます．Juliaは各
要素の型を事前に知っているので（コンテナ内のオブジェクトは全て同じ具体的な型を持つ），
関数のコンパイル時に正しいメソッド呼び出しを「検索」することができ（実行時のチェックが不要に
なる），リスト全体を処理するための効率的なコードを出すことができます．

これらが保持されない場合には，何の利益も得られない可能性が高いです．さらに悪いことに，
結果として生じる「型の組み合わせ爆発」は逆効果となります．`items[i+1]`が`items[i]`と異なる
型を持っている場合，Juliaは実行時にそれらの型を調べ，メソッドテーブルから適切なメソッドを
検索し，（型の共通部分を介して）どれがマッチするかを判断し，それが既にJITコンパイルされて
いるかどうかを判断し（されていない場合はそうします），そして呼び出しをしなければなりません．
要するに，完全な型システムとJITコンパイル機構に，基本的にはスイッチ文や辞書検索に相当する
ものを，自分のコードで実行するように頼んでいることになります．

(1)型のディスパッチ，(2)辞書検索，(3)「スイッチ」文を比較したランタイムベンチマークが
[メーリングリスト](https://groups.google.com/forum/#!msg/julia-users/jUMu9A3QKQQ/qjgVWr7vAwAJ)
で公開されています．

おそらく実行時の影響よりもさらに悪いのはコンパイル時の影響です．Juliaは`Car{Make, Model}`
ごとに専用の関数をコンパイルします．もしそのような型を何百，何千も持っている場合，そのような
オブジェクトをパラメータとして受け取る全ての関数（自分で書いたカスタムの`get_year`関数から
Julia Baseの一般的な`push!`関数まで）は，何百，何千ものバリエーションをコンパイルしなければ
なりません．これらはそれぞれ，コンパイルされたコードのキャッシュサイズやメソッドの内部リスト
の長さなどを増加させます．パラメータとしての値に過度に熱中すると，膨大なリソースを簡単に浪費
してしまいます．

## [列に沿ってメモリ順に配列にアクセスする](@id man-performance-column-major)

Juliaの多次元配列は，列メジャーな順序で格納されます．これは配列が一度に一列ずつ積み重ね
られることを意味します．これは次のように`vec`関数や`[:]`構文を使って確認できます（配列の
順番は`[1 2 3 4]`ではなく，`[1 3 2 4]`であることに注意してください）:

```jldoctest
julia> x = [1 2; 3 4]
2×2 Array{Int64,2}:
 1  2
 3  4

julia> x[:]
4-element Array{Int64,1}:
 1
 3
 2
 4
```

この配列の順序付けの規則は，Fortran，Matlab，Rなど多くの言語で共通しています．列メジャー
順序の代替として，行メジャー順序があります．これは，他の言語の中でもC言語やPython(`numpy`）
で採用されている規則です．配列の順序を覚えておくと，配列をループする際にパフォーマンスに
大きな影響を与えることがあります．覚えておくべき経験則としては，列メジャー配列の場合，最初
のインデックスが最も速く変化するということです．これは基本的に，ループインデックスの一番内側
がスライス式の最初のインデックスである場合，ループ処理が速くなることを意味します．配列に`:`
でインデックスをつけることは，特定の次元内の全ての要素に反復的にアクセスする暗黙のループで
あることを覚えておいてください．例えば，行よりも列を抽出する方が速くなることがあります．

次の例を考えてみましょう．[`Vector`](@ref)を受け取り，入力ベクトルのコピーで行または列を
埋めた正方[`Matrix`](@ref)を返す関数を書きたいとします．行または列がコピーで埋められているか
どうかは，重要ではないと仮定します（おそらく，コードの残りの部分はそれに応じて簡単に適応
させることができます）．少なくとも4つの方法でこれを行うことができます（推奨されている
組み込みの[`repeat`](@ref)の呼び出しに加えて）:

```julia
function copy_cols(x::Vector{T}) where T
    inds = axes(x, 1)
    out = similar(Array{T}, inds, inds)
    for i = inds
        out[:, i] = x
    end
    return out
end

function copy_rows(x::Vector{T}) where T
    inds = axes(x, 1)
    out = similar(Array{T}, inds, inds)
    for i = inds
        out[i, :] = x
    end
    return out
end

function copy_col_row(x::Vector{T}) where T
    inds = axes(x, 1)
    out = similar(Array{T}, inds, inds)
    for col = inds, row = inds
        out[row, col] = x[row]
    end
    return out
end

function copy_row_col(x::Vector{T}) where T
    inds = axes(x, 1)
    out = similar(Array{T}, inds, inds)
    for row = inds, col = inds
        out[row, col] = x[col]
    end
    return out
end
```

今，我々は同じランダム`10000 x 1`の入力ベクトルを使用して，これらの関数のそれぞれの時間を計測します:

```julia-repl
julia> x = randn(10000);

julia> fmt(f) = println(rpad(string(f)*": ", 14, ' '), @elapsed f(x))

julia> map(fmt, [copy_cols, copy_rows, copy_col_row, copy_row_col]);
copy_cols:    0.331706323
copy_rows:    1.799009911
copy_col_row: 0.415630047
copy_row_col: 1.721531501
```

`copy_cols`は`copy_rows`よりもとても高速であることに注目してください．これは，`copy_cols`が
行列の列ベースのメモリレイアウトを尊重し，一度に一列ずつ埋めていくからです．さらに，`copy_col_row`は
`copy_row_col`よりもはるかに高速です．これはスライス式に最初に現れる要素は最も内側のループに
結合されるべきであるという経験則にしたがっているからです．

## [出力の事前割り当て](@id Pre-allocating-outputs)

関数が`Array`やその他の複雑な型を返す場合，メモリを確保する必要があるかもしれません．
残念なことに，メモリの割り当てとその逆であるガベージコレクションがボトルネックになることが
よくあります．

場合によっては出力を事前に確保することで，関数の呼び出しごとにメモリを確保する必要性を
回避できることもあります．簡単な例として，次の2つの例を比較してみましょう:

```jldoctest prealloc
julia> function xinc(x)
           return [x, x+1, x+2]
       end;

julia> function loopinc()
           y = 0
           for i = 1:10^7
               ret = xinc(i)
               y += ret[2]
           end
           return y
       end;
```

と

```jldoctest prealloc
julia> function xinc!(ret::AbstractVector{T}, x::T) where T
           ret[1] = x
           ret[2] = x+1
           ret[3] = x+2
           nothing
       end;

julia> function loopinc_prealloc()
           ret = Vector{Int}(undef, 3)
           y = 0
           for i = 1:10^7
               xinc!(ret, i)
               y += ret[2]
           end
           return y
       end;
```

です．計測の結果は以下のようになります:

```jldoctest prealloc; filter = r"[0-9\.]+ seconds \(.*?\)"
julia> @time loopinc()
  0.529894 seconds (40.00 M allocations: 1.490 GiB, 12.14% gc time)
50000015000000

julia> @time loopinc_prealloc()
  0.030850 seconds (6 allocations: 288 bytes)
50000015000000
```

例えば，呼び出し元がアルゴリズムからの「出力」の型を制御できるようになるなど，他にも事前
割り当ての利点があります．上の例では，必要に応じて，[`Array`](@ref)ではなく，`SubArray`を
渡すことができました．

極端に言えば，事前割り当てはコードを醜くする可能性があるので，パフォーマンスの測定やある程度
の判断が必要になるかもしれません．しかし，「ベクトル化された」（要素ごとの）関数の場合，
便利な構文`x .= f.(y)`は融合ループと一時的な配列を使わないインプレース操作に使用できます
（[関数をベクトル化するためのドット構文](@ref man-vectorized)を参照してください）．

## さらなるドット: ベクトル化された操作の融合

Juliaには特別な[ドット構文](@ref man-vectorized)があり，これはスカラ関数を
「ベクトル化された」関数呼び出しに変換し，演算子を「ベクトル化された」演算子に
変換するもので，入れ子になった「ドット呼び出し」が*融合*するという特別な性質
を持っています．これらは一般的な配列を確保することなく，構文レベルで単一の
ループに結合されます．`.=`や同様の代入演算子を使用した場合，結果は事前に割り当て
られた配列にその場で保存することもできます（上述）．

線形代数の文脈では，`vector + vector`や`vector * scalar`のような演算が定義されて
いても，結果のループを周りの計算と融合させることができるため，代わりに`vector .+ vector`
や`vector .* scalar`を使用することが有利になることを意味しています．例えば，
以下の2つの関数を考えてみましょう:

```jldoctest dotfuse
julia> f(x) = 3x.^2 + 4x + 7x.^3;

julia> fdot(x) = @. 3x^2 + 4x + 7x^3 # equivalent to 3 .* x.^2 .+ 4 .* x .+ 7 .* x.^3;
```

`f`と`fdot`はいずれも同じことを計算します．しかし，配列を使用した場合，
`fdot`（[`@.`](@ref @__dot__)マクロの助けを借りて定義されたもの）の方が
はるかに高速に動作します:

```jldoctest dotfuse; filter = r"[0-9\.]+ seconds \(.*?\)"
julia> x = rand(10^6);

julia> @time f(x);
  0.019049 seconds (16 allocations: 45.777 MiB, 18.59% gc time)

julia> @time fdot(x);
  0.002790 seconds (6 allocations: 7.630 MiB)

julia> @time f.(x);
  0.002626 seconds (8 allocations: 7.630 MiB)
```

つまり，`fdot(x)`は10倍速く，`f(x)`の1/6のメモリしか確保しません．これは，
`f(x)`の`*`と`+`の各操作が新しい一時的な配列を確保し，別のループで実行される
からです．（もちろん，単に`f.(x)`を実行するだけならば，この例の`fdot(x)`と同じ
くらい高速ですが，多くの文脈では，ベクトル化された各演算のために個別の関数を
定義するよりも，式の中にドットをちりばめるだけの方が便利です）．

## [スライスのビューを使用することを検討する](@id man-performance-views)

Juliaでは，`array[1:5, :]`のような配列の「スライス」式は，そのデータのコピー
を作成します（代入の左側に書かれるような場合，すなわち`array[1:5, :] = ...`が
`array`のその部分にインプレースで代入されるような場合を除く）．スライスに対して
多くの操作を行っている場合，元の配列にインデックスを作成するよりも，より小さい
連続コピーを使用した方が効率的に作業ができるため，これはパフォーマンスの面で
良いことがあります．一方で，スライスに対していくつかの単純な作業を行うだけの
場合は，割り当てとコピー操作のコストが大きくなってしまう可能性もあります．

別の方法として，配列の「ビュー」を作成する方法があります．これは
配列オブジェクト（`SubArray`）で，コピーを行わずに元の配列のデータ
をその場で実際に参照します．（ビューに書き込むと，元の配列のデータ
も変更されます．）これは個々のスライスに対しては[`view`](@ref)を呼び
出すことによって行うことができますし，より単純に式全体やコードブロックに
対しては，式の前に[`@views`](@ref)を置くことで行うことができます．
例えば以下のようになります:

```jldoctest; filter = r"[0-9\.]+ seconds \(.*?\)"
julia> fcopy(x) = sum(x[2:end-1]);

julia> @views fview(x) = sum(x[2:end-1]);

julia> x = rand(10^6);

julia> @time fcopy(x);
  0.003051 seconds (7 allocations: 7.630 MB)

julia> @time fview(x);
  0.001020 seconds (6 allocations: 224 bytes)
```

この関数の`fview`バージョンが，3倍の高速化と，メモリ割り当て量の
減少の双方を達成していることに注目してください．

## データをコピーすることは必ずしも悪いことではない

配列はメモリ内に連続して格納されているため，CPUのベクトル化やキャッシュによるメモリアクセス
が少なくなります．これらの理由は，配列に列メジャー順でアクセスすることが推奨されているのと
同じです（上記参照）．不規則なアクセスパターンと非連続ビューは，非連続メモリアクセスのため，
配列上の計算を大幅に遅くする可能性があります．

不規則にアクセスされたデータを連続する配列にコピーしてから操作すると，以下の例のように，
大幅な高速化が得られます．ここでは行列とベクトルが乗算される前に，ランダムにシャッフル
された800,000個のインデックスでアクセスされています．ビューをプレーンな配列にコピーする
ことで，コピー操作のコストを払ってでも乗算を高速化することができます．

```julia-repl
julia> using Random

julia> x = randn(1_000_000);

julia> inds = shuffle(1:1_000_000)[1:800000];

julia> A = randn(50, 1_000_000);

julia> xtmp = zeros(800_000);

julia> Atmp = zeros(50, 800_000);

julia> @time sum(view(A, :, inds) * view(x, inds))
  0.412156 seconds (14 allocations: 960 bytes)
-4256.759568345458

julia> @time begin
           copyto!(xtmp, view(x, inds))
           copyto!(Atmp, view(A, :, inds))
           sum(Atmp * xtmp)
       end
  0.285923 seconds (14 allocations: 960 bytes)
-4256.759568345134
```

コピーするのに十分なメモリがあれば，ビューを配列にコピーするコストよりも，連続する配列上で
行列の乗算を行うことによる速度の向上の方が勝ります．

## I/Oのための文字列補間を避ける

When writing data to a file (or other I/O device), forming extra intermediate strings is a source
of overhead. Instead of:
ファイル（または他のI/Oデバイス）にデータを書き込む際，余分な中間文字列を形成することは
オーバーヘッドの原因となります．以下の式:

```julia
println(file, "$a $b")
```

の代わりに，以下の式を使用してください:

```julia
println(file, a, " ", b)
```

最初のバージョンのコードは文字列を形成してからファイルに書き込み，2番目のバージョンは値を
直接ファイルに書き込みます．また場合によっては文字列の補間が読みにくくなることにも注意
してください．以下の2つを比べてみましょう:

```julia
println(file, "$(f(a))$(f(b))")
```

と:

```julia
println(file, f(a), f(b))
```

## 並列実行時のネットワークI/Oの最適化

リモート関数を並列に実行する場合，初めの例:

```julia
using Distributed

responses = Vector{Any}(undef, nworkers())
@sync begin
    for (idx, pid) in enumerate(workers())
        @async responses[idx] = remotecall_fetch(foo, pid, args...)
    end
end
```

の方が次の例よりも高速です:

```julia
using Distributed

refs = Vector{Any}(undef, nworkers())
for (idx, pid) in enumerate(workers())
    refs[idx] = @spawnat pid foo(args...)
end
responses = [fetch(r) for r in refs]
```

前者は全てのワーカへのネットワークランドトリップが1回になるのに対し，後者は2回のネットワーク
コールが発生します．この2回のうち最初は[`@spawnat`](@ref)によるもの，2回目は[`fetch`](@ref)
（あるいは[`wait`](@ref)）によるものです．[`fetch`](@ref)/[`wait`](@ref)もシリアルに実行
されているため，全体的にパフォーマンスが低下してしまいます．

## 非推奨の警告を修正する

非推奨の関数は，関連する警告を一度だけ表示するために内部的にルックアップを実行します．
この余分なルックアップは大幅な速度低下を引き起こす可能性があるため，非推奨関数の使用は
全て，警告で示唆されているように修正しなければなりません．

## 調整

これらはタイトなインナループに役立つかもしれない細かなポイントです．

  * 不要な配列を避ける．例えば[`sum([x,y,z])`](@ref)の代わりに`x+y+z`を使う．
  * 複素数`z`の場合は，[`abs(z)^2`](@ref)ではなく[`abs2(z)`](@ref)を使う．一般的には，複素数引数に[`abs`](@ref)の代わりに[`abs2`](@ref)を使うようにコードを書き換える．
  * 整数の切り捨て除算には[`trunc(x/y)`](@ref)の代わりに[`div(x,y)`](@ref)を，[`floor(x/y)`](@ref)の代わりに[`fld(x,y)`](@ref)を，[`ceil(x/y)`](@ref)の代わりに[`cld(x,y)`](@ref)を使うようにする．

## [パフォーマンスアノテーション](@id man-performance-annotations)

特定のプログラムのプロパティを約束することで，より良い最適化が可能になることがあります．

  * [`@inbounds`](@ref)を使用して，式内の配列の境界チェックを排除することができます．これを行う前に確認してください．添え字が範囲外になるようなことがあると，クラッシュやサイレント故障が発生する可能性があります．
  * [`@fastmath`](@ref)を使用すると，実数では正しい浮動小数点最適化が可能になりますが，IEEE数では違いが生じます．これを行う際には，数値結果が変化する可能性があるので注意してください．これはclangの`-ffast-math`オプションに相当します．
  * `for`ループの前に[`@simd`](@ref)を書くことで，反復が独立しており，順序を変えても良いことを約束します．多くの場合，Juliaは`@simd`マクロを使わなくても自動的にコードをベクトル化できることに注意してください．それは，浮動小数点の再関連付けを許可したり依存するメモリアクセスを無視したり（`@simd ivdep`）するような場合など，そのような変換がイリーガルな場合にのみ有効です．繰り返しになりますが，`@simd`をアサートする際には非常に注意が必要で，依存関係のあるループに間違ってアノテートしてしまうと予期せぬ結果につながる場合があります．特に，いくつかの`AbstractArray`サブタイプの`setindex!`は本質的に反復順序に依存していることに注意してください．**この機能は実験的なもの**であり，将来のJuliaのバージョンでは変更されたり消えたりする可能性があります．

1:nを使用してAbstractArrayにインデックスを作成するという一般的な慣用句は，配列が一般的でない
インデックスを使用している場合には安全ではなく，境界チェックがオフになっている場合にセグメン
テーションエラーを引き起こす可能性があります．代わりに`LinearIndices(x)`または`eachindex(x)`
を使用してください（[カスタムインデックスを持つ配列](@ref man-custom-indices)も参照してください）．

!!! note
    `@simd`は一番内側の`for`ループの前に直接配置する必要がありますが，`@inbounds`や`@fastmath`はいずれも単一の式，またはコードの入れ子になったブロック内に現れる全ての式に適用できます．（例えば，`@inbounds begin`や`@inbounds for ...`を使用するなど）

ここでは，`@inbounds`と`@simd`の両方をマークアップした例を示します（ここではオプティマイザが
賢くなりすぎてベンチマークを破ろうとするのを防ぐために`@noinline`を使用しています）:

```julia
@noinline function inner(x, y)
    s = zero(eltype(x))
    for i=eachindex(x)
        @inbounds s += x[i]*y[i]
    end
    return s
end

@noinline function innersimd(x, y)
    s = zero(eltype(x))
    @simd for i = eachindex(x)
        @inbounds s += x[i] * y[i]
    end
    return s
end

function timeit(n, reps)
    x = rand(Float32, n)
    y = rand(Float32, n)
    s = zero(Float64)
    time = @elapsed for j in 1:reps
        s += inner(x, y)
    end
    println("GFlop/sec        = ", 2n*reps / time*1E-9)
    time = @elapsed for j in 1:reps
        s += innersimd(x, y)
    end
    println("GFlop/sec (SIMD) = ", 2n*reps / time*1E-9)
end

timeit(1000, 1000)
```

2.4GHz Intel Core i5プロセッサを搭載したコンピュータでは，以下のような結果が得られます:

```
GFlop/sec        = 1.9467069505224963
GFlop/sec (SIMD) = 17.578554163920018
```

(`GFlop/sec` で性能を測定しており，大きいほど良いです．)

ここでは3種類のマークアップを用いた例を示します．このプログラムはまず一次元配列の有限差分を
計算し，その結果のL2ノルムを評価します:

```julia
function init!(u::Vector)
    n = length(u)
    dx = 1.0 / (n-1)
    @fastmath @inbounds @simd for i in 1:n #by asserting that `u` is a `Vector` we can assume it has 1-based indexing
        u[i] = sin(2pi*dx*i)
    end
end

function deriv!(u::Vector, du)
    n = length(u)
    dx = 1.0 / (n-1)
    @fastmath @inbounds du[1] = (u[2] - u[1]) / dx
    @fastmath @inbounds @simd for i in 2:n-1
        du[i] = (u[i+1] - u[i-1]) / (2*dx)
    end
    @fastmath @inbounds du[n] = (u[n] - u[n-1]) / dx
end

function mynorm(u::Vector)
    n = length(u)
    T = eltype(u)
    s = zero(T)
    @fastmath @inbounds @simd for i in 1:n
        s += u[i]^2
    end
    @fastmath @inbounds return sqrt(s)
end

function main()
    n = 2000
    u = Vector{Float64}(undef, n)
    init!(u)
    du = similar(u)

    deriv!(u, du)
    nu = mynorm(du)

    @time for i in 1:10^6
        deriv!(u, du)
        nu = mynorm(du)
    end

    println(nu)
end

main()
```

2.7GHz Intel Core i7プロセッサ上で実行すると，次のような結果になります:

```
$ julia wave.jl;
  1.207814709 seconds
4.443986180758249

$ julia --math-mode=ieee wave.jl;
  4.487083643 seconds
4.443986180758249
```

ここでは，オプション`--math-mode=ieee`は`@fastmath`マクロを無効にしているため，我々は結果を比較することができます．

この場合，`@fastmath`による高速化は約3.7倍になります．これは異常に大きいです．一般的には
スピードアップはもっと小さくなります．（この特定の例では，ベンチマークの作業セットは
プロセッサのL1キャッシュに収まるほど小さいため，メモリアクセスのレイテンシは役割を果たさず，
計算時間はCPU使用率に支配されます．多くの実世界のプログラムではこのようなことはありません．）
また，この場合，この最適化を行っても計算結果は変わりません．一般的には，結果はわずかに異なます．場合によっては，特に数値的に不安定なアルゴリズムの場合，結果が大きく異なることがあります．

`@fastmath`は浮動小数点式を再配置します．例えば評価の順序を変更したり，特定の特殊なケース
（inf, nan）が発生しないと仮定したりします．この場合（そしてこの特定のコンピュータでは），
主な違いは関数`deriv`の式`1 / (2*dx)`が，まるで`idx = 1 / (2*dx)`と書いたかのように，
ループの外に持ち出される（つまり，ループの外で計算される）ということです．ループ内では，
式`... / (2*dx)`は`... * idx`となり，評価がより速くなり．もちろん，コンパイラによって
適用される実際の最適化とその結果の高速化は，ハードウェアに大きく依存します．生成された
コードの変化はJuliaの[`code_native`](@ref)関数を使って調べることができます．

また，`@fastmath`は計算中に`NaN`sが発生しないことを前提としているため，驚くような動作をする
可能性があることに注意してください．

```julia-repl
julia> f(x) = isnan(x);

julia> f(NaN)
true

julia> f_fast(x) = @fastmath isnan(x);

julia> f_fast(NaN)
false
```

## 非正規化数をゼロとして扱う

以前は[denormal numbers](https://en.wikipedia.org/ことがwiki/Denormal_number)と呼ばれていた
非正規化数（原文subnormal numbers）は，多くの文脈で有用ですが，ハードウェアによっては
パフォーマンスが低下します．[`set_zero_subnormals(true)`](@ref)をコールすると，浮動小数点
演算で非正規化数の入力または出力をゼロとして扱うことができるようになります．
[`set_zero_subnormals(false)`](@ref)を呼び出すと，正規化数以下の数値に対しては厳格なIEEEの
動作が強制されます．

以下に非正規化数が一部のハードウェアで顕著にパフォーマンスに影響を与える例を示します:

```julia
function timestep(b::Vector{T}, a::Vector{T}, Δt::T) where T
    @assert length(a)==length(b)
    n = length(b)
    b[1] = 1                            # Boundary condition
    for i=2:n-1
        b[i] = a[i] + (a[i-1] - T(2)*a[i] + a[i+1]) * Δt
    end
    b[n] = 0                            # Boundary condition
end

function heatflow(a::Vector{T}, nstep::Integer) where T
    b = similar(a)
    for t=1:div(nstep,2)                # Assume nstep is even
        timestep(b,a,T(0.1))
        timestep(a,b,T(0.1))
    end
end

heatflow(zeros(Float32,10),2)           # Force compilation
for trial=1:6
    a = zeros(Float32,1000)
    set_zero_subnormals(iseven(trial))  # Odd trials use strict IEEE arithmetic
    @time heatflow(a,1000)
end
```

これにより以下のような結果が得られます．

```
  0.002202 seconds (1 allocation: 4.063 KiB)
  0.001502 seconds (1 allocation: 4.063 KiB)
  0.002139 seconds (1 allocation: 4.063 KiB)
  0.001454 seconds (1 allocation: 4.063 KiB)
  0.002115 seconds (1 allocation: 4.063 KiB)
  0.001455 seconds (1 allocation: 4.063 KiB)
```

偶数回の繰り返しの度に速くなっていることに注目してください．

この例では，`a`の値が指数関数的に減少する曲線となり時間の経過とともにゆっくりと平らになるため，
多くの非正規化数が生成されます．

非正規化数をゼロとして扱うのには注意が必要です．なぜなら`x-y == 0`が`x == y`を意味している
というような，いくつかの等式関係を破ることになるからです:

```jldoctest
julia> x = 3f-38; y = 2f-38;

julia> set_zero_subnormals(true); (x - y, x == y)
(0.0f0, false)

julia> set_zero_subnormals(false); (x - y, x == y)
(1.0000001f-38, false)
```

アプリケーションによっては，非正規化数をゼロにする代わりに，わずかなノイズを注入する
こともあります．例えば，`a`をゼロで初期化する代わりに，以下のようにします:

```julia
a = rand(Float32,1000) * 1.f-9
```

## [[`@code_warntype`](@ref)マクロ](@id man-code-warntype)

マクロ[`@code_warntype`](@ref)（またはその関数版[`code_warntype`](@ref)）は，型関連の
問題を診断するのに役立つことがあります．ここでは例を示します:

```julia-repl
julia> @noinline pos(x) = x < 0 ? 0 : x;

julia> function f(x)
           y = pos(x)
           return sin(y*x + 1)
       end;

julia> @code_warntype f(3.2)
Variables
  #self#::Core.Compiler.Const(f, false)
  x::Float64
  y::UNION{FLOAT64, INT64}

Body::Float64
1 ─      (y = Main.pos(x))
│   %2 = (y * x)::Float64
│   %3 = (%2 + 1)::Float64
│   %4 = Main.sin(%3)::Float64
└──      return %4
```

[`@code_llvm`](@ref)，[`@code_native`](@ref)の出力と同様に解釈するには，少し練習が必要です．
あなたのコードは，コンパイルされたマシンコードを生成する途中で大きく要約された形で表示され
ます．ほとんどの式は型によってアノテーションされており，`::T`で表されています（ここで，Tは
例えば[`Float64`](@ref)のようなものです）．[`@code_warntype`](@ref)の最も重要な特徴は，
具体的でない(non-concrete)型が赤で表示されることです．このドキュメント自体はMarkdownで書かれ
ているので，このドキュメントでは赤文字は大見字で書いています．

上部には，関数の推測される戻り値の型が`Body::Float64`として表示されています．次の行は，
JuliaのSSA IRフォームにおける`f`のボディを表しています．番号のついたボックスはラベルであり，
コード内のジャンプ（`goto`経由）のターゲットを表しています．ボディを見てみると，まず`pos`が
呼び出され，戻り値はnon-concrete型であるため，大文字で示された`Union`型の`UNION{FLOAT64, INT64}`
と推論されていることがわかります．つまり入力された型から`pos`の正確な戻り値の型を知ることは
できません．しかし`y*x`の結果は，`y`が`Float64`であろうと`Int64`であろうと，関係なく`Float64`
となります．結果として，`f(x::Float64)`の出力は，たとえ中間の計算の一部が型不安定であったと
しても型不安定にはなりません．

この情報をどのように使うかはあなた次第です．明らかに，`pos`を型安定な形に直すのが断然最善
です．そうすれば`f`の全ての変数が具体的(concrete)になり，その性能は最適になります．
しかし，このような*一時的な*型の不安定があまり重要でない状況もあります．例えば，`pos`を
単独で使用することがない場合，`f`の出力が（[`Float64`](@ref)入力に対して）型安定である
という事実は，型の不安定性の影響が伝搬することから後のコードを保護します．これは，型の不安定
性を修正することが難しい，あるいは不可能な場合に特に重要です．このような場合には，上記の
ヒント（例えば，型のアノテーションを追加したり，関数を分割したりする）が，型の不安定性に
よる「ダメージ」をおさえるための最良のツールとなります．また，Julia Baseにも型が不安定な
関数があることにも注意してください．例えば，関数[`findfirst`](@ref)は，キーが見つかった配列
のインデックスまたは見つからなければ`nothing`を返しますが，これは明らかに型不安定です．
重要である可能性の高い型の不安定性を見つけやすくするために，`missing`か`nothing`を含む
`Union`は赤ではなく黄色で色分けされています．

以下の例は非リーフ(non-leaf)型を含むとマークされた式を解釈するのに役立つかもしれません:

  * `Body::UNION{T1,T2})`で始まる関数のボディ
      * 解釈: 不安定な戻り値を持つ関数
      * 提案: 返り値を型が安定しているものにします

  * `invoke Main.g(%%x::Int64)::UNION{FLOAT64, INT64}`
      * 解釈: 型不安定な関数`g`の呼び出し
      * 提案: 関数を修正するか，必要であれば戻り値にアノテーションをつけます
  
  * `invoke Base.getindex(%%x::Array{Any,1}, 1::Int64)::ANY`
      * 解釈: 型付けの悪い配列の要素へのアクセス
      * 提案: より良い定義の型を持つ配列を使用するか，必要に応じて個々の要素のアクセスの型をアノテーションします

  * `Base.getfield(%%x, :(:data))::ARRAY{FLOAT64,N} WHERE N`
      * 解釈: non-leaf型のフィールドを取得しています．この場合`ArrayContainer`はフィールド`data::Array{T}`を持っていました．しかし，`Array`がconcreteな型であるためには次元`N`も必要です
      * 提案: `Array{T,3}`や`Array{T,N}`（`N`はここでは`ArrayContainer`のパラメータです）のようなconcreteな型を使用してください

## [キャプチャされた変数の性能](@id man-performance-captured)

内部関数を定義する次の例を考えてみましょう:
```julia
function abmult(r::Int)
    if r < 0
        r = -r
    end
    f = x -> x * r
    return f
end
```

関数`abmult`は，引数に`r`の絶対値を乗算する関数`f`を返します．`f`に割り当てられた
内部関数は「クロージャ」と呼ばれます．内部関数は`do`ブロックやジェネレータ式にも
使用されます．

このコードスタイルは，言語のパフォーマンスに課題があります．パーサは，これを低レベル命令
に変換する際に，内部関数を別のコードブロックに抽出することで，上記のコード大幅に再編成
します．内部関数とそれを囲むスコープで共有されている`r`のような「キャプチャ」された変数
もまた，ヒープに割り当てられた「ボックス」に抽出され，内部スコープ内の`r`は外部スコープ
（または別の内部関数）が`r`を変更した後でも，外部スコープ内の`r`と同一でならなければ
ならないことが言語で指定されているため，内部関数と外部関数の両方からアクセス可能です．

前の段ランクの議論では「パーサ」，つまり`abmult`を含むモジュールが最初にロードされた時に
行われるコンパイルの段階について言及しましたが，それは最初に呼び出されたときの後の段階とは
対照的です．パーサは`Int`が固定された型であることや，`r = -r`が`Int`を別の`Int`に変換する
ことを「知っている」わけではありません．型推論の魔法はコンパイルの後の段階で行われます．

したがって，パーサは`r`が固定型（`Int`)であることを知りませんし，（ボックスが不要になるように）
内部関数が作成されても`r`が値を変更しないことも知りません．したがって，パーサは`Any`などの
`r`の出現ごとにランタイム型ディスパッチが必要になるような抽象型を持つオブジェクトを保持して
いるボックスのコードを出力します．これは上記の関数に`@code_warntype`を適用することで検証
できます．ボックス化とランタイム型ディスパッチの両方がパフォーマンスの低下を引き起こす可能性
があります．

キャプチャされた変数がコードのパフォーマンスクリティカルなセクションで使用されている場合，
以下のヒントはそれらの使用がパフォーマンスを発揮することの保証に役立ちます．最初に，
キャプチャされた変数がその方を変更しないことがわかっている場合，これは型アノテーションで
明示的に宣言することができます（変数の右側ではなく，変数の上で）:
```julia
function abmult2(r0::Int)
    r::Int = r0
    if r < 0
        r = -r
    end
    f = x -> x * r
    return f
end
```
型アノテーションは，パーサがボックス内のオブジェクトにconcreteな型を関連付けることができる
ので，キャプチャによるパフォーマンスの低下を部分的に回復します．さらに，キャプチャされた
変数をボックスに入れる必要がない場合，（クロージャが作成された後に再割り当てされないため），
次のように`let`ブロックを使用して表示することができます．
```julia
function abmult3(r::Int)
    if r < 0
        r = -r
    end
    f = let r = r
            x -> x * r
    end
    return f
end
```
`let`ブロックは，スコープが内部関数のみである新しい変数`r`を作成します．2番目のテクニック
は，キャプチャされた変数の存在下で完全な言語性能を回復します．これはコンパイラの急速に進化
している側面であり，将来のリリースではし恵能を達成するためにプログラムがこの程度の
アノテーションを必要としなくなる可能性があることに注意してください．その間に，
[FastClosures](https://github.com/c42f/FastClosures.jl)のようなユーザが貢献している
パッケージでは，`abmult3`のように`let`文の挿入を自動化しています．

# シングルトンでの同等性のチェック

ある値がシングルトンと等しいかどうかをチェックする時は，イコール(`==`)ではなく
同一性(`===`)をチェックした方が性能的に良い場合があります．同じアドバイスが，
`!=`よりも`!==`を使う場合にも当てはまります．この種のチェックは，例えば，反復
処理プロトコルを実装していて，[`iterate`](@ref)から`nothing`が返ってくるかどうか
をチェックするときなどに頻繁に発生します．
