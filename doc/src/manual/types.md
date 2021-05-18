# [型](@id man-types)

型システムは伝統的に2つの異なる陣営に分類されてきました．静的型システムでは，プログラム
の実行前に全てのプログラム式が計算可能な型を持たねばならず，動的型システムでは，プログラム
によって操作される実際の値が利用可能になる実行時まで型については何も知らされていません．
オブジェクト指向は，コンパイル時に値の正確な値を知らなくてもコードを書けるようにすることで，
静的型付け言語にある程度の柔軟性を持たせることができます．異なる型で動作するコードが書ける
ことをポリモーフィズム（多態性）と呼びます．古典的な動的型付け言語のコードは全て多態性を
持ちます．明示的に型をチェックするか，または実行時にオブジェクトが操作をサポートしていない
場合にのみ，値の型が制限されることがあります．

Juliaの型システムは動的ですが，特定の値が特定の型であることを示すことを可能にすることで，
静的型システムの利点をいくつか得ることができます．これは効率的なコードを生成する上で大きな
助けとなりますが，それ以上に重要なことは，関数引数の型に対するメソッドディスパッチを言語に
深く統合することができるということです．メソッドのディスパッチについては，[Methods](@ref)で
詳しく説明されていますが，ここで紹介する型システムに根ざしています．

型が省略された場合のJuliaのデフォルトの動作は，任意の型の値を許容することです．このため，
明示的に型を指定しなくても，多くの有用なJuliaの関数を書くことができます．しかし，さらなる
表現力が必要な場合には，以前に「型を使わない」で書いたコードに，明示的な型アノテーションを
徐々に導入していくことが簡単にできます．アノテーションを追加することは，Juliaの強力な多重
ディスパッチ機構を利用すること，人間の可読性を向上させること，そしてプログラマのエラーを
検出することの3つの主要な目的に役立ちます．

Juliaを[型システム](https://en.wikipedia.org/wiki/Type_system)の専門用語で表現すると，
動的な方，指名的な型，パラメトリックな型です．一般的な型はパラメータ化することができ，型間
の階層的な関係は[互換性のある構造によって暗示される](https://en.wikipedia.org/wiki/Structural_type_system)のではなく，
[明示的に宣言](https://en.wikipedia.org/wiki/Nominal_type_system)されます．
Juliaの型システムの特に特徴的な点は，具象型が互いにサブタイプしてはならないということです．
全ての具象型は最終型であり，抽象型のみをスーパータイプとして持つことができます．これは
最初は過度に制限されているように見えるかもしれませんが，多くの有益な結果をもたらし，欠点は
驚くほど少ないのです．構造を継承できることよりも，動作を継承できることの方がはるかに重要
であり，両方を継承することは従来のオブジェクト指向言語では大きな問題を引き起こしています．
Juliaの型システムの他の高レベルな側面としては，以下のようなものがあります:

  * オブジェクトと非オブジェクトの間には分け隔てがありません．Juliaの全ての値は，完全に接続された単一の型グラフに属する型を持つ真のオブジェクトであり，全てのノードは型として等しくファーストクラスのものです．
  * 「コンパイル時の型」という意味のある概念はありません．値が持つ唯一の型は，プログラムが実行されている時の実際の型です．これはオブジェクト指向言語では「ランタイム型」と呼ばれ，静的コンパイルと多態性の組み合わせにより，この区別が重要になります．
  * 変数ではなく，値だけが型をもちます．変数は単に値に結びつけられた名前です．
  * 抽象型も具象型も，他の型によってパラメータ化することができます．また，シンボルや，[`isbits`](@ref)が真を返す任意の型の値（基本的には，Cの型や他のオブジェクトへのポインタを持たない`struct`のように格納されている数値やboolのようなもの），およびそれらのタプルによってもパラメータ化することができます．型のパラメータは，参照や制限が不要な場合には省略することができます．

Juliaの型システムは，パワフルで表現力豊かでありながら，明確で直観的で控えめな設計になっています．
多くのJuliaプログラマは，明示的に型を使用するコードを書く必要性を感じないかもしれません．
しかし，ある種のプログラミングでは，宣言された型を使うことで，より明確に，よりシンプルに，
より早く，より堅牢になります．

## 型宣言

`::`演算子を使用して，プログラム内の式や変数に型アノテーションを付けることができます．
これには主に2つの理由があります:

1. プログラムが期待通りに動作することを確認するためのアサーション
2. コンパイラに追加で型情報を提供することで，場合によってはパフォーマンスを向上させることができます

値を計算する式に追加された場合，`::`演算子は"is a instance of"と読まれます．これは，左の
式の値が右の型のインスタンスであることをアサートするために，どこでも使用できます．右側の
型が具象型の場合，左側の値はその型の実装でなければなりません．具象型は全て最終型であり，
実装は他の型のサブタイプではないことを思い出してください．型が抽象型の場合，値は抽象型の
サブタイプである具象型によって実装されていれば十分です．型のアサーションが真でない場合には
例外がスローされ，そうでない場合には左辺の値が返されます:

```jldoctest
julia> (1+2)::AbstractFloat
ERROR: TypeError: in typeassert, expected AbstractFloat, got a value of type Int64

julia> (1+2)::Int
3
```

これにより，任意の式に型のアサーションをその場でアタッチすることができます．

代入の左側にある変数に追加された場合，あるいはローカル宣言の一部として追加された場合には，
`::`演算子は少し違った意味を持ちます．Cのような静的型付け言語の型宣言のように，変数が常に
指定された型を持つことを宣言します．変数に代入された全ての値は，[`convert`](@ref)を使用して
宣言された型に変換されます:

```jldoctest
julia> function foo()
           x::Int8 = 100
           x
       end
foo (generic function with 1 method)

julia> foo()
100

julia> typeof(ans)
Int8
```

この機能は，変数への代入の1つが予期せず型を変更した場合に発生する可能性のある，
パフォーマンスへの「瑕疵」を回避するのに便利です．

この「宣言」動作は特定のコンテキストでのみ発生します:

```julia
local x::Int8  # in a local declaration
x::Int8 = 10   # as the left-hand side of an assignment
```

またこの宣言動作は宣言が行われる前であっても現在のスコープ全体に適用されます．現在のところ，
Juliaにはまだ定数型のグローバルがないため，REPLなどのグローバルスコープでは型宣言を使用する
ことができません．

宣言は関数定義にも付けることができます:

```julia
function sinc(x)::Float64
    if x == 0
        return 1
    end
    return sin(pi*x)/(pi*x)
end
```

この関数からの戻り値は，宣言された型を持つ変数への代入と同じように動作します．値は常に，
`Float64`に変換されます．

## [抽象型](@id man-abstract-types)

抽象型はインスタンス化することができず，型グラフのノードとしてしか機能せず，それによって
関連する具象型の集合，つまりそれらの子孫である具象型を記述します．抽象型は型システムの
バックボーンであり，Juliaの型システムを単なるオブジェクト実装の集合以上のものにする
概念的な階層を形成しているので，インスタンス化できないですが，抽象型から話を始めます．

[Integers and Floating-Point Numbers](@ref)で数値の様々な具象型を紹介したことを思い
出してください．[`Int8`](@ref)， [`UInt8`](@ref)， [`Int16`](@ref)， [`UInt16`](@ref)，
[`Int32`](@ref)， [`UInt32`](@ref)， [`Int64`](@ref)， [`UInt64`](@ref)， [`Int128`](@ref)，
[`UInt128`](@ref)， [`Float16`](@ref)， [`Float32`](@ref)，[`Float64`](@ref)です．
表現サイズは異なりますが，`Int8`， `Int16`， `Int32`， `Int64`，`Int128`は全て符号付き
整数型であるという共通点があります．同様に，`UInt8`， `UInt16`， `UInt32`，`UInt64`，
`UInt128`は全て符号なし整数型です．一方で，`Float16`，`Float32`，`Float64`は整数型
ではなく浮動小数点型であるという点で区別されています．コードの一部が意味を持つのは，
例えば，その引数がある種の整数である場合だけで，実際にはどのような特定の*種類*の整数
であるかに依存しないのが一般的です．例えば，最大公約数アルゴリズムはあらゆる種類の整数
に対して動作しますが，浮動小数点数に対しては動作しません．抽象型を使用すると，型の階層
を構築することができ，具体的な型が収まるコンテキストを提供します．これにより，例えば，
アルゴリズムを特定の整数型に制限することなく，任意の整数型に簡単にプログラムすることが
できます．

抽象型は，[`abstract type`](@ref)キーワードを使用して宣言されます．抽象型を宣言する
ための一般的な構文は以下の通りです:

```
abstract type «name» end
abstract type «name» <: «supertype» end
```

`abstract type`キーワードは，新しい抽象型を導入し，その名前は`«name»`で与えられます．
この名前の後には，オプションで[`<:`](@ref)と既存の型を付けることができ，新しく宣言
された抽象型がこの「親」型のサブタイプであることを示します．

スーパータイプが与えられていない場合，デフォルトのスーパータイプは`Any`になります．
`Any`は全てのオブジェクトがそのインスタンスであり，全ての型がそのサブタイプである
ような，定義済みの抽象型です．型理論では，`Any`は型グラフの頂点にあるので，一般的に
「トップ」と呼ばれています．また，Juliaには，型グラフの一番下にある定義済みの抽象的な
「ボトム」型があり，`Union{}`と書かれています．これは`Any`とは正反対で，全ての
オブジェクトは`Union{}`のインスタンスではなく，全ての型は`Union{}`のスーパータイプです．

Juliaの数値階層を構成する抽象型のいくつかを考えてみましょう:

```julia
abstract type Number end
abstract type Real     <: Number end
abstract type AbstractFloat <: Real end
abstract type Integer  <: Real end
abstract type Signed   <: Integer end
abstract type Unsigned <: Integer end
```

[`Number`](@ref)型は`Any`の直接の子孫であり，[`Real`](@ref)はその子です．また，
`Real`には2つの子があります（もっとたくさんいますが，ここでは2つだけを示しています．
他の者には後に触れます）．[`Integer`](@ref)と[`AbstractFloat`](@ref)で，世界を整数
の表現と実数の表現に分けています．実数の世界にはもちろん浮動小数点型が含まれています
が，それ以外にも有理数などの他の方も含まれています．したがって，`AbstractFloat`は
`Real`の適切なサブタイプであり，実数の浮動小数点表現のみを含みます．整数は更に
[`Signed`](@ref)と[`Unsigned`](@ref)に細分化されています．

一般的に`<:`演算子は，"is a subtype of"を意味し，このような宣言で使用すると，右手の
型が，新しく宣言された型の直接のスーパータイプであることを宣言します．また左の
オペランドが右のオペランドのサブタイプである場合に`true`を返すサブタイプ演算子として
式の中で使用することもできます．

```jldoctest
julia> Integer <: Number
true

julia> Integer <: AbstractFloat
false
```

抽象型の重要な使用法は，具象型のデフォルト実装を提供することです．簡単な例を挙げると，
次のようになります:

```julia
function myplus(x,y)
    x+y
end
```

まず注意すべき点は，上記の引数宣言が`x::Any`と`y::Any`と同等であるということです．
この関数が`myplus(2,5)`のように呼び出されると，ディスパッチャは与えられた引数に
マッチする`myplus`という名前の最も具体的なメソッドを選択します．（複数のディスパッチ
についての詳細は[Methods](@ref)を参照してください．）

上記よりも特定のメソッドが見つからないと仮定して，次にJuliaは上で与えられた汎用
関数に基づいて，二つの`Int`引数に対して特別に`myplus`と呼ばれるメソッドを内部的に定義
してコンパイルします．つまり暗黙的に定義してコンパイルするのです:

```julia
function myplus(x::Int,y::Int)
    x+y
end
```

そして最後に，この特定のメソッドを呼び出します．

このように，抽象型は，プログラマが後に具象型の多くの組み合わせによってデフォルト
メソッドとして使用できる汎用関数を書くことを可能にします．複数ディスパッチのおかげで，
プログラマはデフォルトのメソッドが使用されるか，より具体的なメソッドが使用されるかを
完全に制御することができます．

注意すべき重要な点は，プログラマが，引数が抽象型である関数に依存していても，その関数が
呼び出される引数の具象型のタプルごとに再コンパイルされるため，パフォーマンスが低下する
ことはないということです（だたし関数の引数が抽象型のコンテナの場合には，パフォーマンス
の問題がある場合があります．[Performance Tips](@ref man-performance-abstract-container)
を参照してください．）

## プリミティブ型

!!! 注意
    ほとんどの場合，独自のプリミティブ型を定義するよりも，既存のプリミティブ型を
    新しい複合型でラップする方が望ましいです．

    この機能は，LLVMがサポートする標準のプリミティブ型をJuliaがブートストラップする
    できるようにするために存在します．一度定義されれば，それ以上定義する理由はほとんど
    ありません．

プリミティブ型とは，データが古いビットで構成される具体的な型のことです．プリミティブ型の
典型的な例は，整数と浮動小数点です．多くの言語とは異なり，Juliaでは，組み込みの固定された
型のセットだけを提供するのではなく，独自のプリミティブ型を宣言することができます．実際，
標準的なプリミティブ型は全てこの言語自身で定義されています:

```julia
primitive type Float16 <: AbstractFloat 16 end
primitive type Float32 <: AbstractFloat 32 end
primitive type Float64 <: AbstractFloat 64 end

primitive type Bool <: Integer 8 end
primitive type Char <: AbstractChar 32 end

primitive type Int8    <: Signed   8 end
primitive type UInt8   <: Unsigned 8 end
primitive type Int16   <: Signed   16 end
primitive type UInt16  <: Unsigned 16 end
primitive type Int32   <: Signed   32 end
primitive type UInt32  <: Unsigned 32 end
primitive type Int64   <: Signed   64 end
primitive type UInt64  <: Unsigned 64 end
primitive type Int128  <: Signed   128 end
primitive type UInt128 <: Unsigned 128 end
```

プリミティブ型を宣言する一般的な構文は以下のようになります:

```
primitive type «name» «bits» end
primitive type «name» <: «supertype» «bits» end
```

ビット数はその型が必要とするストレージの量を示し，nameは新しい方に名前を与えます．
プリミティブ型は，オプションでスーパータイプのサブタイプであることを宣言することができます．
スーパータイプが省略された場合，その型はデフォルトで`Any`をその直接のスーパータイプとして
持つことになります．したがって，上記の[`Bool`](@ref)の宣言は，ブール値の格納に8ビットを
必要とし，直接のスーパータイプとして[`Integer`](@ref)を持つことを意味します．現在のところ，
8ビットの倍数のサイズのみがサポートされており，上記以外のサイズではLLVMのバグが発生する
可能性があります．したがって，ブーリアン値は，実際には1ビットしか必要ありませんが，8ビット
よりも小さいサイズを宣言することはできません．

[`Bool`](@ref)，[`Int8`](@ref)，[`UInt8`](@ref)の型は全て同じ表現で，8ビットのメモリチャンク
です．しかし，Juliaの型システムは命名型なので，同じ構造を持っているにも拘わらず，これらの
型には互換性がありません．両社の根本的な違いは，スーパータイプが異なることです．
[`Bool`](@ref)の直接のスーパータイプは[`Integer`](@ref)，[`Int8`](@ref)のスーパータイプは
[`Signed`](@ref)，[`UInt8`](@ref)のスーパータイプは[`Unsigned`](@ref)です．
[`Bool`](@ref)，[`Int8`](@ref)，[`UInt8`](@ref)の間のその他の違いは全て動作，すなわち
これらの型のオブジェクトを引数として与えられた時に関数がどのように動作するかの定義の問題
です．これが命名型システムが必要な理由です．もし構造体が型を決定し，それが動作を決定する
のであれば，[`Bool`](@ref)に[`Int8`](@ref)や[`UInt8`](@ref)と異なる動作をさせることは
不可能でしょう．


## 複合型

[Composite types（複合型）](https://en.wikipedia.org/wiki/Composite_data_type)は，様々な言語で，
レコード，構造体，またはオブジェクトと呼ばれます．複合型は名前付きフィールドの集合で，
そのインスタンスは単一の値として扱うことができます．多くの言語では，複合型は唯一の
ユーザ定義可能な型であり，Juliaでもユーザ定義型としては最も一般的に使用されています．

C++，Java，Python，Rubyなどの主流のオブジェクト指向言語では，複合型に名前付き関数も含まれて
おり，その組み合わせは「オブジェクト」と呼ばれます．RubyやSmalltalkのような純粋なオブジェクト
指向言語では，複合型であるかどうかに関わらず，全ての値がオブジェクトになります．C++やJava
などのやや純粋でないオブジェクト指向言語では，整数や浮動小数点数などの一部の値はオブジェクト
ではありませんが，ユーザ定義の複合型のインスタンスは，関連するメソッドを持つ真のオブジェクト
です．Juliaでは，全ての値はオブジェクトですが，関数は操作するオブジェクトにバンドルされて
いません．これはJuliaが関数のどのメソッドを使用するかを，複数回のディスパッチによって選択
するために必要なことで，つまりはメソッドを選択する際には，最初のメソッドだけではなく，関数
の*全て*の引数の型が考慮されることを意味します（メソッドとディスパッチについての詳細は，
[Methods](@ref)を参照してください）．このように，関数が最初の引数だけに「属する」のは不適切
です．それぞれのオブジェクトの「中」にメソッドの名前付きの袋を持つのではなく，メソッドを
関数オブジェクトに整理することは，最終的には言語設計の非常に有益な側面となります．

複合型は，[`struct`](@ref)キーワードの後にフィールド名のブロックを付けて導入され，
オプションで`::`オペレータを使用して，型のアノテーションを付けることができます:

```jldoctest footype
julia> struct Foo
           bar
           baz::Int
           qux::Float64
       end
```

型のアノテーションがないフィールドのデフォルトは`Any`型なので，任意の型の値を保持することができます．

`Foo`型の新しいオブジェクトは，`Foo`型のオブジェクトを，関数のようにフィールドの値
に適用することで作成されます:

```jldoctest footype
julia> foo = Foo("Hello, world.", 23, 1.5)
Foo("Hello, world.", 23, 1.5)

julia> typeof(foo)
Foo
```

型が関数のように適用される場合，それは*コンストラクタ*と呼ばれます．2つのコンストラクタが
自動的に生成されます（これらを*デフォルトコンストラクタ*と呼びます）．1つは任意の引数を
受け取り，フィールドの値に変換するために[`convert`](@ref)を呼び出し，もう一つはフィールド
の型に正確に一致する引数を受け取ります．これらの両方が生成される理由は，デフォルトの
コンストラクタを何気なく置き換えることなく，新しい定義を簡単に追加できるようにするためです．

`bar`フィールドは型に制約がないので，どのような型でも構いません．しかし，`baz`の値は，
`Int`に変換可能でなければなりません:

```jldoctest footype
julia> Foo((), 23.5, 1)
ERROR: InexactError: Int64(23.5)
Stacktrace:
[...]
```

[`fieldnames`](@ref)関数を使ってフィールド名のリストを参照できます．

```jldoctest footype
julia> fieldnames(Foo)
(:bar, :baz, :qux)
```

複合オブジェクトのフィールド値には，伝統的な`foo.bar`記法を使ってアクセスすることができます:

```jldoctest footype
julia> foo.bar
"Hello, world."

julia> foo.baz
23

julia> foo.qux
1.5
```

`struct`で作られた複合オブジェクトは*不変*です．つまり構築後に変更することはできません．
これは最初は奇妙に思えるかもしれませんが，いくつか利点があります:

  * より効率的になります．構造体の中には，効率的に配列にまとめることができるものもありますし，コンパイラによっては不変オブジェクトの割り当てを完全に回避できる場合もあります．
  * 型のコンストラクタが提供する不変量に違反することができません．
  * 不変オブジェクトを使用したコードは，推論が容易になります．

不変オブジェクトには，フィールドとして，配列などの変異可能なオブジェクトが含まれているかも
しれません．それらは変更可能なままであり，不変オブジェクトのフィールドだけが異なる
オブジェクトを指すように変更されることはない，というものです．

必要に応じて，次のセクションで説明するように，キーワード[`mutable struct`](@ref)を使用して
宣言することができます．

フィールドを持たない不変複合型はシングルトンです．このような型のインスタンスは1つだけ存在できます:

```jldoctest
julia> struct NoFields
       end

julia> NoFields() === NoFields()
true
```

 [`===`](@ref)関数は，構築された`NoFields`の「2つ」のインスタンスが，実際には1つだけで，
 同じものであることを確認します．シングルトン型に関しては，[下記](@ref man-singleton-types)
 で更に詳しく説明していきます．

複合型のインスタンスがどのようにして生成されるかについては，もっと多く書くことがありますが，
この議論は[Parametric Types](@ref)と [Methods](@ref)の両方に依存しており，それ自身のセクション
[Constructors](@ref man-constructors)で説明するのに十分なほど重要です．

## ミュータブルな複合型

複合型が`struct`ではなく，`mutable struct`で宣言されている場合は，そのインスタンスを変更することができます:

```jldoctest bartype
julia> mutable struct Bar
           baz
           qux::Float64
       end

julia> bar = Bar("Hello", 1.5);

julia> bar.qux = 2.0
2.0

julia> bar.baz = 1//2
1//2
```

変異をサポートするために，このようなオブジェクトは一般的にヒープ上に割り当てられ，
安定したメモリアドレスを持ちます．変異可能なオブジェクトは小さな容器のようなもので，
時間の経過とともに異なる値を保持する可能性があり，そのアドレスによってのみ確実に
識別することができます．対照的に，不変型のインスタンスは特定のフィールド値に関連付けられて
います．フィールドの値だけでそのオブジェクトについての全てを知ることができます．
型を変異可能にするかを決めるには，同じフィールド値を持つ二つのインスタンスが同一と
みなされるのか，それとも時間の経過とともに独立して変化する必要があるのかを尋ねてみましょう．
もしそれらが同一とみなされるならば，その型はおそらく不変であるべきです．

繰り返しになりますが，Juliaでは2つの本質的な性質が不変性を定義しています:

  * 不変型の値を変更することは許されない．
    * ビット型の場合，これは一度設定された値のビットパターンは決して変化しないことを意味し，その値はビット型の同一性を表します．
    * 複合型の場合，これはそのフィールドの値の同一性が変わることがないことを意味します．フィールドがビット型の場合は，そのビットが変更されないことを意味し，値が配列のような可変型であるフィールドの場合は，可変型の値が変更されても，フィールドは常に同じ可変型の値を参照することを意味します．
  * 不変型を持つオブジェクトは，その不変性により，プログラム上で元のオブジェクトとコピーを区別することができないため，コンパイラによって自由にコピーすることができます．
    * 特に，整数や浮動小数点数のような十分に小さい不変型の値は，一般的にレジスタ内の関数に渡されます（またはスタックに割り当てられます）．
    * 一方，可変値は，ヒープ割り当てされており，コンパイラがこれが起こっていないことを伝える方法がないと確信している場合を除いて，ヒープ割り当てされた値へのポインタとして関数に渡されます．

## 宣言された型

前のセクションで説明した3種類の型（抽象型，プリミティブ型，複合型）は，実は全て密接に
関連しています．これらは同じ主要な特性を共有しています:

  * 明示的に宣言されている．
  * 名前がある．
  * 明示的に宣言されたスーパータイプを持つ．
  * パラメータを持つことができる．

これらの共有プロパティのため，これらの型は内部的には同じ概念である`DataType`のインスタンス
として表現されます:

```jldoctest
julia> typeof(Real)
DataType

julia> typeof(Int)
DataType
```

`DataType`には抽象型と具象型があります．具象型の場合は，指定されたサイズ，記憶レイアウト，
および（オプションで）フィールド名を持ちます．したがって，プリミティブ型は，ゼロではない
サイズを持つ`DataType`ですが，フィールド名はありません．複合型は，フィールド名を持つか，
あるいは空（ゼロサイズ）である`DataType`です．

システム内の全ての具体的な値は，ある`DataType`のインスタンスです．

## 型ユニオン

型ユニオンとは，特殊な抽象型で，その引数型のインスタンスを全てオブジェクトとして含むもので，
特殊な[`Union`](@ref)キーワードを使って構築されます:

```jldoctest
julia> IntOrString = Union{Int,AbstractString}
Union{Int64, AbstractString}

julia> 1 :: IntOrString
1

julia> "Hello!" :: IntOrString
"Hello!"

julia> 1.0 :: IntOrString
ERROR: TypeError: in typeassert, expected Union{Int64, AbstractString}, got a value of type Float64
```

多くの言語のコンパイラは型を推論するための内部的なユニオン構造を持っていますが，Juliaでは
それをプログラマに公開しています．Juliaのコンパイラは，ありうる型ごとに別々のブランチで特化
したコードを生成することで，少数のがたを持つ`Union`型が存在する場合でも効率的なコードを生成
することができます[^1]．

`Union`型の特に有用なケースは，`Union{T, Nothing}`です．ここで`T`は任意の型であり，
[`Nothing`](@ref)はその唯一のインスタンスがオブジェクト[`nothing`](@ref)であるシングルトン型
です．このパターンは，他の言語の[`Nullable`, `Option` or `Maybe`](https://en.wikipedia.org/wiki/Nullable_type)
に相当します．関数の引数やフィールドを`Union{T, Nothing}`として宣言すると，`T`型の値を設定
するか，値をしないことを示す`nothing`を設定することができます．より詳しくは，
この[FAQエントリ](@ref faq-nothing)を参照してください．

## パラメトリック型

Juliaの型システムの重要かつ強力な特徴は，パラメトリック型であるということです．型は
パラメータを取ることができるので，型宣言は実際に新しい型のファミリ全体を，パラメータ値
の可能な組み合わせごとに一つずつ導入することになります．多くの言語が，
[generic programming](https://en.wikipedia.org/wiki/Generic_programming)をサポートしており，
データ構造やそれを操作するアルゴリズムを，正確な型を指定することなく指定することができます．
例えば，ML，Haskell，Ada，Effel，C++，Java，C#，F#，Scalaなどがジェネリックプログラミング
をサポートしています．これらの言語の中には，真のパラメトリックポリモーフィズムをサポート
しているもの（例えば，ML，Haskell，Scala）もあれば，アドホックなテンプレートベースの
ジェネリックプログラミングスタイルをサポートしているもの（例えば，C++，Java）もあります．
このように，様々な言語でジェネリックプログラミングやパラメトリック型の種類があるため，
ここではJuliaのパラメトリック型を他の言語と比較しようとはせず，Juliaのシステムを説明
することに専念することとします．しかし，Juliaは動的型付け言語であり，コンパイル時に全ての
型を決定する必要がないため，静的なパラメトリック型システムで遭遇する多くの伝統的な問題を
比較的容易に処理できることに注意します．

全ての宣言された型（`DataType`の種類）は，同じ構文でパラメータ化することができます．
ここでは，最初にパラメトリック複合型，次にパラメトリック抽象型，最後にパラメトリック
プリミティブ型の順に説明します．

### パラメトリック複合型

型パラメータは，型名の直後に中括弧で囲まれて導入されます:

```jldoctest pointtype
julia> struct Point{T}
           x::T
           y::T
       end
```

この宣言は，`T`型の「座標」を保持する新しいパラメトリック型である`Point{T}`を定義しています．
`T`とは何なのかと聞かれるかもしれません．それこそがパラメトリック型のポイントです．
Tはどのような型でも良いのです（ここでは明らかに型として使用されていますが，実際
には，任意のビット型の値でも良いです）．`Point{Float64}`は，`Point`の定義の`T`を[`Float64`](@ref)
に置き換えて定義した型と同等の具象型です．したがって，この1つの宣言は，実際には無制限の数の
型を宣言しています．`Point{Float64}`, `Point{AbstractString}`, `Point{Int64}`などです．
これらはそれぞれ使用可能な具象型となります．

```jldoctest pointtype
julia> Point{Float64}
Point{Float64}

julia> Point{AbstractString}
Point{AbstractString}
```

`Point{Float64}`は64ビット浮動小数点数値を座標とする点であり，`Point{AbstractString}`は
文字列オブジェクトを「座標」とする「点」です（[Strings](@ref)を参照のこと）．

`Point`自身も有効な型オブジェクトであり，全てのインスタンス`Point{Float64}`，`Point{AbstractString}`
などをサブタイプとして含みます:

```jldoctest pointtype
julia> Point{Float64} <: Point
true

julia> Point{AbstractString} <: Point
true
```

もちろん，他のタイプはそのサブタイプではありません:

```jldoctest pointtype
julia> Float64 <: Point
false

julia> AbstractString <: Point
false
```

`T`の値が異なる具象型の`Point`型は，決してお互いのサブタイプではありません:

```jldoctest pointtype
julia> Point{Float64} <: Point{Int64}
false

julia> Point{Float64} <: Point{Real}
false
```

!!! 警告
    この最後の点は*非常に*重要です．`Float64 <: Real`であっても，`Point{Float64} <: Point{Real}`では*ありません*．

言い換えれば，型理論の用語では，Juliaのパラメータは，[covariant (or even contravariant)](https://en.wikipedia.org/wiki/Covariance_and_contravariance_%28computer_science%29)
ではなく，*不変*です．これには実用的な理由があります．`Point{Float64}`のインスタンスは概念的
には`Point{Real}`のインスタンスに似ていますが，この2つの型はメモリ上では異なる表現をします．

  * `Point{Float64}`のインスタンスは，コンパクトかつ効率的に64ビット値の即時ペアとして表現できます．
  * `Point{Real}`は[`Real`](@ref)のインスタンスの任意のペアを保持できなければなりません．`Real`のインスタンスであるオブジェクトは，任意のサイズと構造を持つことができるため，実際には`Point{Real}`のインスタンスは，個別に割り当てられた`Real`オブジェクトへのポインタのペアとして表現する必要があります．

`Point{Float64}`オブジェクトを即時値で格納できることで得られる効率は，配列の場合には非常に
大きくなります．`Array{Float64}`は，64ビット浮動小数点数値の連続したメモリブロックとして
格納することができますが，`Array{Real}`は個別に割り当てられた[`Real`](@ref)オブジェクトへの
ポインタ配列でなければなりません．これは[ボックス化された](https://en.wikipedia.org/wiki/Object_type_%28object-oriented_programming%29#Boxing)
64ビットの浮動小数点数値である場合もありますが，`Real`抽象型の実装であると宣言された，
任意の大きさの複雑なオブジェクトである場合もあります．

`Point{Float64}`は`Point{Real}`のサブタイプではないので，以下のメソッドでは`Point{Float64}`
の引数には適用できません:

```julia
function norm(p::Point{Real})
    sqrt(p.x^2 + p.y^2)
end
```

`T`が[`Real`](@ref)のサブタイプであるような`Point{T}`型の全ての引数を受け入れるメソッドを
定義する正しい方法は，次の通りです:

```julia
function norm(p::Point{<:Real})
    sqrt(p.x^2 + p.y^2)
end
```

（同様に， `function norm(p::Point{T} where T<:Real)`や
`function norm(p::Point{T}) where T<:Real`と定義することもできます．[UnionAll Types](@ref)
を参照してください．）

その他の例については，[Methods](@ref)で後述します．

`Point`オブジェクトはどのようにして構築するのでしょうか？複合型に対するカスタムコンストラクタ
を定義することは，[Constructors](@ref man-constructors)で詳述するように可能ですが，特別な
コンストラクタが宣言されていない場合，新しい複合オブジェクトを作成するデフォルトの方法は
2つ存在します．1つは型のパラメータが明示的に与えられる方法，もう一つはオブジェクト
コンストラクタへの引数によって暗黙的に示される方法です．

`Point{Float64}`は`T`の代わりに，[`Float64`](@ref)を用いて宣言された`Point`と同等の具象型
であるため，これをコンストラクタとして適用することができます:

```jldoctest pointtype
julia> Point{Float64}(1.0, 2.0)
Point{Float64}(1.0, 2.0)

julia> typeof(ans)
Point{Float64}
```

デフォルトのコンストラクタでは，各フィールドに対して1つだけ引数を指定する必要があります:

```jldoctest pointtype
julia> Point{Float64}(1.0)
ERROR: MethodError: no method matching Point{Float64}(::Float64)
[...]

julia> Point{Float64}(1.0,2.0,3.0)
ERROR: MethodError: no method matching Point{Float64}(::Float64, ::Float64, ::Float64)
[...]
```

デフォルトコンストラクタをオーバライドすることはできないので，パラメトリック型には1つだけ
デフォルトコンストラクタが生成されます．このコンストラクタは，任意の引数を受け取り，それらを
フィールドの型に変換します．

多くの場合，コンストラクタ呼び出しの引数の型が既に暗黙的に型情報を提供しているので，構築
したい`Point`オブジェクトの型を提供することは冗長です．そのため，パラメータ型`T`の暗黙の
値が明確であれば，`Point`自身をコンストラクタとして適用することもできます:

```jldoctest pointtype
julia> Point(1.0,2.0)
Point{Float64}(1.0, 2.0)

julia> typeof(ans)
Point{Float64}

julia> Point(1,2)
Point{Int64}(1, 2)

julia> typeof(ans)
Point{Int64}
```

`Point`の場合，`T`の型は，`Point`の2つの引数が同じ型である場合に限り，曖昧さなく暗黙のもの
とされます．そうでない場合，コンストラクタは，[`MethodError`](@ref)で失敗します:

```jldoctest pointtype
julia> Point(1,2.5)
ERROR: MethodError: no method matching Point(::Int64, ::Float64)
Closest candidates are:
  Point(::T, !Matched::T) where T at none:2
```

このような混在したケースを適切に処理するコンストラクタのメソッドを定義することもできますが，
それについては[Constructors](@ref man-constructors)で後程説明します．

### パラメトリック抽象型

パラメトリック抽象型宣言は，ほとんど同じ方法で抽象型の集まりを宣言します:

```jldoctest pointytype
julia> abstract type Pointy{T} end
```

この宣言により，`Pointy{T}`は，`T`の型や整数値ごとに，異なる抽象型となります．
パラメトリック合成型と同様に，このようなインスタンスは，それぞれ`Pointy`のサブタイプとなります:

```jldoctest pointytype
julia> Pointy{Int64} <: Pointy
true

julia> Pointy{1} <: Pointy
true
```

パラメトリック抽象型は，パラメトリックな複合型と同様に不変です:

```jldoctest pointytype
julia> Pointy{Float64} <: Pointy{Real}
false

julia> Pointy{Real} <: Pointy{Float64}
false
```

`Pointy{<:Real}`という表記は，Juliaの*共変*型の類似性を表現するために使われ，
`Pointy{>:Int}`は*逆変*型の類似性を表現されるために使われますが，技術的には
これらは型の*集合*を表します（[UnionAll Types](@ref)を参照してください）．
```jldoctest pointytype
julia> Pointy{Float64} <: Pointy{<:Real}
true

julia> Pointy{Real} <: Pointy{>:Int}
true
```

従来の抽象型が具象型の上に便利な型階層を作る役割を果たしていたように，パラメトリック抽象型
はパラメトリック複合型に関しても同じ役割を果たします．例えば次のように，`Point{T}`を
`Pointy{T}`のサブタイプであると宣言することができました:

```jldoctest pointytype
julia> struct Point{T} <: Pointy{T}
           x::T
           y::T
       end
```

このような宣言があれば，`T`の各選択に対して，`Point{T}`を`Pointy{T}`のサブタイプとすることができます:

```jldoctest pointytype
julia> Point{Float64} <: Pointy{Float64}
true

julia> Point{Real} <: Pointy{Real}
true

julia> Point{AbstractString} <: Pointy{AbstractString}
true
```

この関係性も不変です:

```jldoctest pointytype
julia> Point{Float64} <: Pointy{Real}
false

julia> Point{Float64} <: Pointy{<:Real}
true
```

`Pointy`のようなパラメトリックな抽象型はどのような目的で使われるのでしょうか？
ここでは，点が対角線*x = y*上にあり，単一の座標値のみを必要とする点のようなものの実装を
作成した場合をい考えてみましょう:

```jldoctest pointytype
julia> struct DiagPoint{T} <: Pointy{T}
           x::T
       end
```

これにより，`Point{Float64}`も`DiagPoint{Float64}`も共に`Pointy{Float64}`抽象型の実装となり
，他の可能な型`T`の選択についても同様になります．これにより，`Point`と`DiagPoint`の両方で
実装された，全ての`Pointy`オブジェクトで共有される共通のインタフェースへのプログラミングが
可能になります．ただしこのことは，次のセクション[Methods](@ref)で，メソッドとディスパッチを
紹介するまでは，完全には実証できません．

型のパラメータが可能なすべての型の間を自由に行き来することに意味がない場合があります．
このような場合には，`T`の範囲を次のように制限することができます:

```jldoctest realpointytype
julia> abstract type Pointy{T<:Real} end
```

このように宣言すると，`T`の代わりに[`Real`](@ref)のサブタイプである型を使用することが
できますが，`Real`のサブタイプでない型は使用できません:

```jldoctest realpointytype
julia> Pointy{Float64}
Pointy{Float64}

julia> Pointy{Real}
Pointy{Real}

julia> Pointy{AbstractString}
ERROR: TypeError: in Pointy, in T, expected T<:Real, got Type{AbstractString}

julia> Pointy{1}
ERROR: TypeError: in Pointy, in T, expected T<:Real, got a value of type Int64
```

パラメトリック複合型の型パラメータも，同様に制限することができます:

```julia
struct Point{T<:Real} <: Pointy{T}
    x::T
    y::T
end
```

このようなパメトリック型の仕組みがどのように役立つのかを示す実例として，Juliaの
[`Rational`](@ref)不変型の実際の定義（整数の正確な比を表すもの）を以下に示します
（ただし，ここでは簡単のために，コンストラクタを省略しています）:

```julia
struct Rational{T<:Integer} <: Real
    num::T
    den::T
end
```

整数値の比を取ることには意味があるので，パラメータ型`T`は[`Integer`](@ref)のサブタイプに
制約されます．また，整数の比は実数線上の値を表すので，全ての[`Rational`](@ref)は，
[`Real`](@ref)抽象型のインスタンスとなります．

### タプル型

タプルは関数の引数を抽象化したもので，関数自体は含まれていません．関数の引数の重要な点は，
その順序と型です．したがってタプル型は，パラメータ化された増えhん型に似ており，各パラメータ
は1つのフィールドの型となります．例えば，2要素のタプル型は以下のような不変型に似ています:

```julia
struct Tuple2{A,B}
    a::A
    b::B
end
```

しかし，3つの重要な違いがあります:

  * タプル型は任意の数のパラメータを持つことができます．
  * タプル型はパラメータが*共変*します．`Tuple{Int}`は`Tuple{Any}`のサブタイプです．したがって，`Tuple{Any}`は抽象型と見なされ，タプル型はパラメータが具体型である場合にのみ具体型になります．
  * タプルはフィールド名を持たず，フィールドにはインデックスによってのみアクセスされます．

タプルの値は括弧とコンマで記述されます．タプルが構築されると，必要に応じて適切なタプル型が生成されます:

```jldoctest
julia> typeof((1,"foo",2.5))
Tuple{Int64,String,Float64}
```

*共変*の意味合いに注意してください:

```jldoctest
julia> Tuple{Int,AbstractString} <: Tuple{Real,Any}
true

julia> Tuple{Int,AbstractString} <: Tuple{Real,Real}
false

julia> Tuple{Int,AbstractString} <: Tuple{Real,}
false
```

直感的には，これは関数の引数の型が関数のシグネチャのサブタイプであることに対応します（シグネチャが一致する場合）．

### Vararg(可変長引数の）タプル型

タプル型の最後のパラメータは，特殊な型である[`Vararg`](@ref)にすることができ，これは任意の数の末尾の要素を規定します:

```jldoctest
julia> mytupletype = Tuple{AbstractString,Vararg{Int}}
Tuple{AbstractString,Vararg{Int64,N} where N}

julia> isa(("1",), mytupletype)
true

julia> isa(("1",1), mytupletype)
true

julia> isa(("1",1,2), mytupletype)
true

julia> isa(("1",1,2,3.0), mytupletype)
false
```

`Vararg{T}`型は`T`型の0個以上の要素に対応することに注意してください．Varargタプル型は，
varargsメソッドが受け取る引数を表すのに使われます（[Varargs Functions](@ref)を参照してください）．

`Vararg{T,N}`型は，`T`型のちょうど`N`個の要素に対応します．`NTuple{N,T}`は`Tuple{Vararg{T,N}}`
の便利なエイリアスで，`T`型のちょうど`N`個の要素を含むタプル型です．

### 名前付きタプル型

名前付きタプルは[`NamedTuple`](@ref)型のインスタンスで，2つのパラメータを持ちます．
1つはフィールド名を表すシンボルのタプルで，もう一つはフィールドタイプを表すタプルタイプです．

```jldoctest
julia> typeof((a=1,b="hello"))
NamedTuple{(:a, :b),Tuple{Int64,String}}
```

[`@NamedTuple`](@ref)マクロは，`NamedTuple`型を`key::Type`宣言を介して宣言するための`構造体`のような便利な構文を提供しており，ここでは`::Type`を省略することは，`::Any`を付けることにに対応します．

```jldoctest
julia> @NamedTuple{a::Int, b::String}
NamedTuple{(:a, :b),Tuple{Int64,String}}

julia> @NamedTuple begin
           a::Int
           b::String
       end
NamedTuple{(:a, :b),Tuple{Int64,String}}
```

`NamedTuple`型は，1つのタプル引数を受け付けるコンストラクタとして使用できます．
構築された`NamedTuple`型は，両方のパラメータを指定した具象型か，フィールド名のみを指定した
型のいずれかになります:

```jldoctest
julia> @NamedTuple{a::Float32,b::String}((1,""))
(a = 1.0f0, b = "")

julia> NamedTuple{(:a, :b)}((1,""))
(a = 1, b = "")
```

フィールドの型が指定されている場合は，引数は変換されます．そうでない場合は，引数の型が
そのまま使用されます．

### [シングルトン型](@id man-singleton-types)

ここで言及しなければならない特別な種類の抽象パラメトリック型があります．シングルトン型です．
各型`T`に対して，「シングルトン型」`Type{T}`は唯一のインスタンスがオブジェクト`T`である
ような抽象型でｋす．定義は少し難しいので，いくつか例を見てみましょう:

```jldoctest
julia> isa(Float64, Type{Float64})
true

julia> isa(Real, Type{Float64})
false

julia> isa(Real, Type{Real})
true

julia> isa(Float64, Type{Real})
false
```

言い換えれば[`isa(A,Type{B})`](@ref)は，`A`と`B`が同じオブジェクトであり，そのオブジェクト
が型である場合に限り真になります．パラメータがない場合，`Type`は単なる抽象型で，
シングルトン型を含むすべての型オブジェクトをそのインスタンスとして持ちます:

```jldoctest
julia> isa(Type{Float64}, Type)
true

julia> isa(Float64, Type)
true

julia> isa(Real, Type)
true
```

型でないオブジェクトは，`Type`のインスタンスではありません:

```jldoctest
julia> isa(1, Type)
false

julia> isa("foo", Type)
false
```

[Parametric Methods](@ref)や，[conversions](@ref conversion-and-promotion)について説明
するまでは，シングルトン型の構造の有用性を説明するのは難しいのですが，簡単に言うと，
特定の型の*値*に対して関数の動作を特殊化することができます．これは，メソッド（特に
パラメトリックなもの）を書く際に，その動作が，引数の型に暗示されるのではなく，明示的な
引数として与えられる型に依存する場合に有用です．

Haskell，Scala，Rubyなど，シングルトン型を持つ人気の高い言語がいくつかあります．
一般的な用法では，「シングルトン型」という言葉は，唯一のインスタンスが1つの値である型を
指します．この意味は，Juliaのシングルトン型にも当てはまりますが，シングルトン型を持つのは
型オブジェクトだけであるという注意点があります．

### パラメトリックプリミティブ型

プリミティブ型はパラメトリックに宣言することもできます．例えば，ポインタはプリミティブ型
として表現され，Juliaでは次のように宣言されます:

```julia
# 32-bit system:
primitive type Ptr{T} 32 end

# 64-bit system:
primitive type Ptr{T} 64 end
```

典型的なパラメトリック複合型と比較して，これらの宣言の少し変わった特徴は，型パラメータ`T`
が型自体の定義に使用されていないことです．これは単なる抽象的なタグであり，本質的に，
型パラメータによってのみ区別される，同一の構造を持つ型ファミリ全体を定義します．ゆえに，
`Ptr{Float64}`と`Ptr{Int64}`は，表現が同じであっても，別の型です．そしてもちろん，
全ての特定のポインタ型は，[`Ptr`](@ref)型のサブタイプです:

```jldoctest
julia> Ptr{Float64} <: Ptr
true

julia> Ptr{Int64} <: Ptr
true
```

## UnionAll Types

We have said that a parametric type like `Ptr` acts as a supertype of all its instances
(`Ptr{Int64}` etc.). How does this work? `Ptr` itself cannot be a normal data type, since without
knowing the type of the referenced data the type clearly cannot be used for memory operations.
The answer is that `Ptr` (or other parametric types like `Array`) is a different kind of type called a
[`UnionAll`](@ref) type. Such a type expresses the *iterated union* of types for all values of some parameter.

`UnionAll` types are usually written using the keyword `where`. For example `Ptr` could be more
accurately written as `Ptr{T} where T`, meaning all values whose type is `Ptr{T}` for some value
of `T`. In this context, the parameter `T` is also often called a "type variable" since it is
like a variable that ranges over types.
Each `where` introduces a single type variable, so these expressions are nested for types with
multiple parameters, for example `Array{T,N} where N where T`.

The type application syntax `A{B,C}` requires `A` to be a `UnionAll` type, and first substitutes `B`
for the outermost type variable in `A`.
The result is expected to be another `UnionAll` type, into which `C` is then substituted.
So `A{B,C}` is equivalent to `A{B}{C}`.
This explains why it is possible to partially instantiate a type, as in `Array{Float64}`: the first
parameter value has been fixed, but the second still ranges over all possible values.
Using explicit `where` syntax, any subset of parameters can be fixed. For example, the type of all
1-dimensional arrays can be written as `Array{T,1} where T`.

Type variables can be restricted with subtype relations.
`Array{T} where T<:Integer` refers to all arrays whose element type is some kind of
[`Integer`](@ref).
The syntax `Array{<:Integer}` is a convenient shorthand for `Array{T} where T<:Integer`.
Type variables can have both lower and upper bounds.
`Array{T} where Int<:T<:Number` refers to all arrays of [`Number`](@ref)s that are able to
contain `Int`s (since `T` must be at least as big as `Int`).
The syntax `where T>:Int` also works to specify only the lower bound of a type variable,
and `Array{>:Int}` is equivalent to `Array{T} where T>:Int`.

Since `where` expressions nest, type variable bounds can refer to outer type variables.
For example `Tuple{T,Array{S}} where S<:AbstractArray{T} where T<:Real` refers to 2-tuples
whose first element is some [`Real`](@ref), and whose second element is an `Array` of any
kind of array whose element type contains the type of the first tuple element.

The `where` keyword itself can be nested inside a more complex declaration. For example,
consider the two types created by the following declarations:

```jldoctest
julia> const T1 = Array{Array{T,1} where T, 1}
Array{Array{T,1} where T,1}

julia> const T2 = Array{Array{T,1}, 1} where T
Array{Array{T,1},1} where T
```

Type `T1` defines a 1-dimensional array of 1-dimensional arrays; each
of the inner arrays consists of objects of the same type, but this type may vary from one inner array to the next.
On the other hand, type `T2` defines a 1-dimensional array of 1-dimensional arrays all of whose inner arrays must have the
same type.  Note that `T2` is an abstract type, e.g., `Array{Array{Int,1},1} <: T2`, whereas `T1` is a concrete type. As a consequence, `T1` can be constructed with a zero-argument constructor `a=T1()` but `T2` cannot.

There is a convenient syntax for naming such types, similar to the short form of function
definition syntax:

```julia
Vector{T} = Array{T,1}
```

This is equivalent to `const Vector = Array{T,1} where T`.
Writing `Vector{Float64}` is equivalent to writing `Array{Float64,1}`, and the umbrella type
`Vector` has as instances all `Array` objects where the second parameter -- the number of array
dimensions -- is 1, regardless of what the element type is. In languages where parametric types
must always be specified in full, this is not especially helpful, but in Julia, this allows one
to write just `Vector` for the abstract type including all one-dimensional dense arrays of any
element type.

## Type Aliases

Sometimes it is convenient to introduce a new name for an already expressible type.
This can be done with a simple assignment statement.
For example, `UInt` is aliased to either [`UInt32`](@ref) or [`UInt64`](@ref) as is
appropriate for the size of pointers on the system:

```julia-repl
# 32-bit system:
julia> UInt
UInt32

# 64-bit system:
julia> UInt
UInt64
```

This is accomplished via the following code in `base/boot.jl`:

```julia
if Int === Int64
    const UInt = UInt64
else
    const UInt = UInt32
end
```

Of course, this depends on what `Int` is aliased to -- but that is predefined to be the correct
type -- either [`Int32`](@ref) or [`Int64`](@ref).

(Note that unlike `Int`, `Float` does not exist as a type alias for a specific sized
[`AbstractFloat`](@ref). Unlike with integer registers, where the size of `Int`
reflects the size of a native pointer on that machine, the floating point register sizes
are specified by the IEEE-754 standard.)

## Operations on Types

Since types in Julia are themselves objects, ordinary functions can operate on them. Some functions
that are particularly useful for working with or exploring types have already been introduced,
such as the `<:` operator, which indicates whether its left hand operand is a subtype of its right
hand operand.

The [`isa`](@ref) function tests if an object is of a given type and returns true or false:

```jldoctest
julia> isa(1, Int)
true

julia> isa(1, AbstractFloat)
false
```

The [`typeof`](@ref) function, already used throughout the manual in examples, returns the type
of its argument. Since, as noted above, types are objects, they also have types, and we can ask
what their types are:

```jldoctest
julia> typeof(Rational{Int})
DataType

julia> typeof(Union{Real,String})
Union
```

What if we repeat the process? What is the type of a type of a type? As it happens, types are
all composite values and thus all have a type of `DataType`:

```jldoctest
julia> typeof(DataType)
DataType

julia> typeof(Union)
DataType
```

`DataType` is its own type.

Another operation that applies to some types is [`supertype`](@ref), which reveals a type's
supertype. Only declared types (`DataType`) have unambiguous supertypes:

```jldoctest
julia> supertype(Float64)
AbstractFloat

julia> supertype(Number)
Any

julia> supertype(AbstractString)
Any

julia> supertype(Any)
Any
```

If you apply [`supertype`](@ref) to other type objects (or non-type objects), a [`MethodError`](@ref)
is raised:

```jldoctest; filter = r"Closest candidates.*"s
julia> supertype(Union{Float64,Int64})
ERROR: MethodError: no method matching supertype(::Type{Union{Float64, Int64}})
Closest candidates are:
[...]
```

## [Custom pretty-printing](@id man-custom-pretty-printing)

Often, one wants to customize how instances of a type are displayed.  This is accomplished by
overloading the [`show`](@ref) function.  For example, suppose we define a type to represent
complex numbers in polar form:

```jldoctest polartype
julia> struct Polar{T<:Real} <: Number
           r::T
           Θ::T
       end

julia> Polar(r::Real,Θ::Real) = Polar(promote(r,Θ)...)
Polar
```

Here, we've added a custom constructor function so that it can take arguments of different
[`Real`](@ref) types and promote them to a common type (see [Constructors](@ref man-constructors)
and [Conversion and Promotion](@ref conversion-and-promotion)).
(Of course, we would have to define lots of other methods, too, to make it act like a
[`Number`](@ref), e.g. `+`, `*`, `one`, `zero`, promotion rules and so on.) By default,
instances of this type display rather simply, with information about the type name and
the field values, as e.g. `Polar{Float64}(3.0,4.0)`.

If we want it to display instead as `3.0 * exp(4.0im)`, we would define the following method to
print the object to a given output object `io` (representing a file, terminal, buffer, etcetera;
see [Networking and Streams](@ref)):

```jldoctest polartype
julia> Base.show(io::IO, z::Polar) = print(io, z.r, " * exp(", z.Θ, "im)")
```

More fine-grained control over display of `Polar` objects is possible. In particular, sometimes
one wants both a verbose multi-line printing format, used for displaying a single object in the
REPL and other interactive environments, and also a more compact single-line format used for
[`print`](@ref) or for displaying the object as part of another object (e.g. in an array). Although
by default the `show(io, z)` function is called in both cases, you can define a *different* multi-line
format for displaying an object by overloading a three-argument form of `show` that takes the
`text/plain` MIME type as its second argument (see [Multimedia I/O](@ref)), for example:

```jldoctest polartype
julia> Base.show(io::IO, ::MIME"text/plain", z::Polar{T}) where{T} =
           print(io, "Polar{$T} complex number:\n   ", z)
```

(Note that `print(..., z)` here will call the 2-argument `show(io, z)` method.) This results in:

```jldoctest polartype
julia> Polar(3, 4.0)
Polar{Float64} complex number:
   3.0 * exp(4.0im)

julia> [Polar(3, 4.0), Polar(4.0,5.3)]
2-element Array{Polar{Float64},1}:
 3.0 * exp(4.0im)
 4.0 * exp(5.3im)
```

where the single-line `show(io, z)` form is still used for an array of `Polar` values.   Technically,
the REPL calls `display(z)` to display the result of executing a line, which defaults to `show(stdout, MIME("text/plain"), z)`,
which in turn defaults to `show(stdout, z)`, but you should *not* define new [`display`](@ref)
methods unless you are defining a new multimedia display handler (see [Multimedia I/O](@ref)).

Moreover, you can also define `show` methods for other MIME types in order to enable richer display
(HTML, images, etcetera) of objects in environments that support this (e.g. IJulia).   For example,
we can define formatted HTML display of `Polar` objects, with superscripts and italics, via:

```jldoctest polartype
julia> Base.show(io::IO, ::MIME"text/html", z::Polar{T}) where {T} =
           println(io, "<code>Polar{$T}</code> complex number: ",
                   z.r, " <i>e</i><sup>", z.Θ, " <i>i</i></sup>")
```

A `Polar` object will then display automatically using HTML in an environment that supports HTML
display, but you can call `show` manually to get HTML output if you want:

```jldoctest polartype
julia> show(stdout, "text/html", Polar(3.0,4.0))
<code>Polar{Float64}</code> complex number: 3.0 <i>e</i><sup>4.0 <i>i</i></sup>
```

```@raw html
<p>An HTML renderer would display this as: <code>Polar{Float64}</code> complex number: 3.0 <i>e</i><sup>4.0 <i>i</i></sup></p>
```

As a rule of thumb, the single-line `show` method should print a valid Julia expression for creating
the shown object.  When this `show` method contains infix operators, such as the multiplication
operator (`*`) in our single-line `show` method for `Polar` above, it may not parse correctly when
printed as part of another object.  To see this, consider the expression object (see [Program
representation](@ref)) which takes the square of a specific instance of our `Polar` type:

```jldoctest polartype
julia> a = Polar(3, 4.0)
Polar{Float64} complex number:
   3.0 * exp(4.0im)

julia> print(:($a^2))
3.0 * exp(4.0im) ^ 2
```

Because the operator `^` has higher precedence than `*` (see [Operator Precedence and Associativity](@ref)), this
output does not faithfully represent the expression `a ^ 2` which should be equal to `(3.0 *
exp(4.0im)) ^ 2`.  To solve this issue, we must make a custom method for `Base.show_unquoted(io::IO,
z::Polar, indent::Int, precedence::Int)`, which is called internally by the expression object when
printing:

```jldoctest polartype
julia> function Base.show_unquoted(io::IO, z::Polar, ::Int, precedence::Int)
           if Base.operator_precedence(:*) <= precedence
               print(io, "(")
               show(io, z)
               print(io, ")")
           else
               show(io, z)
           end
       end

julia> :($a^2)
:((3.0 * exp(4.0im)) ^ 2)
```

The method defined above adds parentheses around the call to `show` when the precedence of the
calling operator is higher than or equal to the precedence of multiplication.  This check allows
expressions which parse correctly without the parentheses (such as `:($a + 2)` and `:($a == 2)`) to
omit them when printing:

```jldoctest polartype
julia> :($a + 2)
:(3.0 * exp(4.0im) + 2)

julia> :($a == 2)
:(3.0 * exp(4.0im) == 2)
```

In some cases, it is useful to adjust the behavior of `show` methods depending
on the context. This can be achieved via the [`IOContext`](@ref) type, which allows
passing contextual properties together with a wrapped IO stream.
For example, we can build a shorter representation in our `show` method
when the `:compact` property is set to `true`, falling back to the long
representation if the property is `false` or absent:
```jldoctest polartype
julia> function Base.show(io::IO, z::Polar)
           if get(io, :compact, false)
               print(io, z.r, "ℯ", z.Θ, "im")
           else
               print(io, z.r, " * exp(", z.Θ, "im)")
           end
       end
```

This new compact representation will be used when the passed IO stream is an `IOContext`
object with the `:compact` property set. In particular, this is the case when printing
arrays with multiple columns (where horizontal space is limited):
```jldoctest polartype
julia> show(IOContext(stdout, :compact=>true), Polar(3, 4.0))
3.0ℯ4.0im

julia> [Polar(3, 4.0) Polar(4.0,5.3)]
1×2 Array{Polar{Float64},2}:
 3.0ℯ4.0im  4.0ℯ5.3im
```

See the [`IOContext`](@ref) documentation for a list of common properties which can be used
to adjust printing.

## "Value types"

In Julia, you can't dispatch on a *value* such as `true` or `false`. However, you can dispatch
on parametric types, and Julia allows you to include "plain bits" values (Types, Symbols, Integers,
floating-point numbers, tuples, etc.) as type parameters.  A common example is the dimensionality
parameter in `Array{T,N}`, where `T` is a type (e.g., [`Float64`](@ref)) but `N` is just an `Int`.

You can create your own custom types that take values as parameters, and use them to control dispatch
of custom types. By way of illustration of this idea, let's introduce a parametric type, `Val{x}`,
and a constructor `Val(x) = Val{x}()`, which serves as a customary way to exploit this technique
for cases where you don't need a more elaborate hierarchy.

[`Val`](@ref) is defined as:

```jldoctest valtype
julia> struct Val{x}
       end

julia> Val(x) = Val{x}()
Val
```

There is no more to the implementation of `Val` than this.  Some functions in Julia's standard
library accept `Val` instances as arguments, and you can also use it to write your own functions.
 For example:

```jldoctest valtype
julia> firstlast(::Val{true}) = "First"
firstlast (generic function with 1 method)

julia> firstlast(::Val{false}) = "Last"
firstlast (generic function with 2 methods)

julia> firstlast(Val(true))
"First"

julia> firstlast(Val(false))
"Last"
```

For consistency across Julia, the call site should always pass a `Val` *instance* rather than using
a *type*, i.e., use `foo(Val(:bar))` rather than `foo(Val{:bar})`.

It's worth noting that it's extremely easy to mis-use parametric "value" types, including `Val`;
in unfavorable cases, you can easily end up making the performance of your code much *worse*.
 In particular, you would never want to write actual code as illustrated above.  For more information
about the proper (and improper) uses of `Val`, please read [the more extensive discussion in the performance tips](@ref man-performance-value-type).

[^1]: "Small" is defined by the `MAX_UNION_SPLITTING` constant, which is currently set to 4.
