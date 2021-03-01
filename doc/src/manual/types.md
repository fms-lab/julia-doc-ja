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

[Composite types](https://en.wikipedia.org/wiki/Composite_data_type)は，様々な言語で，
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

## Mutable Composite Types

If a composite type is declared with `mutable struct` instead of `struct`, then instances of
it can be modified:

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

In order to support mutation, such objects are generally allocated on the heap, and have
stable memory addresses.
A mutable object is like a little container that might hold different values over time,
and so can only be reliably identified with its address.
In contrast, an instance of an immutable type is associated with specific field values ---
the field values alone tell you everything about the object.
In deciding whether to make a type mutable, ask whether two instances
with the same field values would be considered identical, or if they might need to change independently
over time. If they would be considered identical, the type should probably be immutable.

To recap, two essential properties define immutability in Julia:

  * It is not permitted to modify the value of an immutable type.
    * For bits types this means that the bit pattern of a value once set will never change
      and that value is the identity of a bits type.
    * For composite  types, this means that the identity of the values of its fields will
      never change. When the fields are bits types, that means their bits will never change,
      for fields whose values are mutable types like arrays, that means the fields will
      always refer to the same mutable value even though that mutable value's content may
      itself be modified.
  * An object with an immutable type may be copied freely by the compiler since its
    immutability makes it impossible to programmatically distinguish between the original
    object and a copy.
    * In particular, this means that small enough immutable values like integers and floats
      are typically passed to functions in registers (or stack allocated).
    * Mutable values, on the other hand are heap-allocated and passed to
      functions as pointers to heap-allocated values except in cases where the compiler
      is sure that there's no way to tell that this is not what is happening.

## Declared Types

The three kinds of types (abstract, primitive, composite) discussed in the previous
sections are actually all closely related. They share the same key properties:

  * They are explicitly declared.
  * They have names.
  * They have explicitly declared supertypes.
  * They may have parameters.

Because of these shared properties, these types are internally represented as instances of the
same concept, `DataType`, which is the type of any of these types:

```jldoctest
julia> typeof(Real)
DataType

julia> typeof(Int)
DataType
```

A `DataType` may be abstract or concrete. If it is concrete, it has a specified size, storage
layout, and (optionally) field names. Thus a primitive type is a `DataType` with nonzero size, but
no field names. A composite type is a `DataType` that has field names or is empty (zero size).

Every concrete value in the system is an instance of some `DataType`.

## Type Unions

A type union is a special abstract type which includes as objects all instances of any of its
argument types, constructed using the special [`Union`](@ref) keyword:

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

The compilers for many languages have an internal union construct for reasoning about types; Julia
simply exposes it to the programmer. The Julia compiler is able to generate efficient code in the
presence of `Union` types with a small number of types [^1], by generating specialized code
in separate branches for each possible type.

A particularly useful case of a `Union` type is `Union{T, Nothing}`, where `T` can be any type and
[`Nothing`](@ref) is the singleton type whose only instance is the object [`nothing`](@ref). This pattern
is the Julia equivalent of [`Nullable`, `Option` or `Maybe`](https://en.wikipedia.org/wiki/Nullable_type)
types in other languages. Declaring a function argument or a field as `Union{T, Nothing}` allows
setting it either to a value of type `T`, or to `nothing` to indicate that there is no value.
See [this FAQ entry](@ref faq-nothing) for more information.

## Parametric Types

An important and powerful feature of Julia's type system is that it is parametric: types can take
parameters, so that type declarations actually introduce a whole family of new types -- one for
each possible combination of parameter values. There are many languages that support some version
of [generic programming](https://en.wikipedia.org/wiki/Generic_programming), wherein data structures
and algorithms to manipulate them may be specified without specifying the exact types involved.
For example, some form of generic programming exists in ML, Haskell, Ada, Eiffel, C++, Java, C#,
F#, and Scala, just to name a few. Some of these languages support true parametric polymorphism
(e.g. ML, Haskell, Scala), while others support ad-hoc, template-based styles of generic programming
(e.g. C++, Java). With so many different varieties of generic programming and parametric types
in various languages, we won't even attempt to compare Julia's parametric types to other languages,
but will instead focus on explaining Julia's system in its own right. We will note, however, that
because Julia is a dynamically typed language and doesn't need to make all type decisions at compile
time, many traditional difficulties encountered in static parametric type systems can be relatively
easily handled.

All declared types (the `DataType` variety) can be parameterized, with the same syntax in each
case. We will discuss them in the following order: first, parametric composite types, then parametric
abstract types, and finally parametric primitive types.

### Parametric Composite Types

Type parameters are introduced immediately after the type name, surrounded by curly braces:

```jldoctest pointtype
julia> struct Point{T}
           x::T
           y::T
       end
```

This declaration defines a new parametric type, `Point{T}`, holding two "coordinates" of type
`T`. What, one may ask, is `T`? Well, that's precisely the point of parametric types: it can be
any type at all (or a value of any bits type, actually, although here it's clearly used as a type).
`Point{Float64}` is a concrete type equivalent to the type defined by replacing `T` in the definition
of `Point` with [`Float64`](@ref). Thus, this single declaration actually declares an unlimited
number of types: `Point{Float64}`, `Point{AbstractString}`, `Point{Int64}`, etc. Each of these
is now a usable concrete type:

```jldoctest pointtype
julia> Point{Float64}
Point{Float64}

julia> Point{AbstractString}
Point{AbstractString}
```

The type `Point{Float64}` is a point whose coordinates are 64-bit floating-point values, while
the type `Point{AbstractString}` is a "point" whose "coordinates" are string objects (see [Strings](@ref)).

`Point` itself is also a valid type object, containing all instances `Point{Float64}`, `Point{AbstractString}`,
etc. as subtypes:

```jldoctest pointtype
julia> Point{Float64} <: Point
true

julia> Point{AbstractString} <: Point
true
```

Other types, of course, are not subtypes of it:

```jldoctest pointtype
julia> Float64 <: Point
false

julia> AbstractString <: Point
false
```

Concrete `Point` types with different values of `T` are never subtypes of each other:

```jldoctest pointtype
julia> Point{Float64} <: Point{Int64}
false

julia> Point{Float64} <: Point{Real}
false
```

!!! warning
    This last point is *very* important: even though `Float64 <: Real` we **DO NOT** have `Point{Float64} <: Point{Real}`.

In other words, in the parlance of type theory, Julia's type parameters are *invariant*, rather
than being [covariant (or even contravariant)](https://en.wikipedia.org/wiki/Covariance_and_contravariance_%28computer_science%29). This is for practical reasons: while any instance
of `Point{Float64}` may conceptually be like an instance of `Point{Real}` as well, the two types
have different representations in memory:

  * An instance of `Point{Float64}` can be represented compactly and efficiently as an immediate pair
    of 64-bit values;
  * An instance of `Point{Real}` must be able to hold any pair of instances of [`Real`](@ref).
    Since objects that are instances of `Real` can be of arbitrary size and structure, in
    practice an instance of `Point{Real}` must be represented as a pair of pointers to
    individually allocated `Real` objects.

The efficiency gained by being able to store `Point{Float64}` objects with immediate values is
magnified enormously in the case of arrays: an `Array{Float64}` can be stored as a contiguous
memory block of 64-bit floating-point values, whereas an `Array{Real}` must be an array of pointers
to individually allocated [`Real`](@ref) objects -- which may well be
[boxed](https://en.wikipedia.org/wiki/Object_type_%28object-oriented_programming%29#Boxing)
64-bit floating-point values, but also might be arbitrarily large, complex objects, which are
declared to be implementations of the `Real` abstract type.

Since `Point{Float64}` is not a subtype of `Point{Real}`, the following method can't be applied
to arguments of type `Point{Float64}`:

```julia
function norm(p::Point{Real})
    sqrt(p.x^2 + p.y^2)
end
```

A correct way to define a method that accepts all arguments of type `Point{T}` where `T` is
a subtype of [`Real`](@ref) is:

```julia
function norm(p::Point{<:Real})
    sqrt(p.x^2 + p.y^2)
end
```

(Equivalently, one could define `function norm(p::Point{T} where T<:Real)` or
`function norm(p::Point{T}) where T<:Real`; see [UnionAll Types](@ref).)

More examples will be discussed later in [Methods](@ref).

How does one construct a `Point` object? It is possible to define custom constructors for composite
types, which will be discussed in detail in [Constructors](@ref man-constructors), but in the absence of any special
constructor declarations, there are two default ways of creating new composite objects, one in
which the type parameters are explicitly given and the other in which they are implied by the
arguments to the object constructor.

Since the type `Point{Float64}` is a concrete type equivalent to `Point` declared with [`Float64`](@ref)
in place of `T`, it can be applied as a constructor accordingly:

```jldoctest pointtype
julia> Point{Float64}(1.0, 2.0)
Point{Float64}(1.0, 2.0)

julia> typeof(ans)
Point{Float64}
```

For the default constructor, exactly one argument must be supplied for each field:

```jldoctest pointtype
julia> Point{Float64}(1.0)
ERROR: MethodError: no method matching Point{Float64}(::Float64)
[...]

julia> Point{Float64}(1.0,2.0,3.0)
ERROR: MethodError: no method matching Point{Float64}(::Float64, ::Float64, ::Float64)
[...]
```

Only one default constructor is generated for parametric types, since overriding it is not possible.
This constructor accepts any arguments and converts them to the field types.

In many cases, it is redundant to provide the type of `Point` object one wants to construct, since
the types of arguments to the constructor call already implicitly provide type information. For
that reason, you can also apply `Point` itself as a constructor, provided that the implied value
of the parameter type `T` is unambiguous:

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

In the case of `Point`, the type of `T` is unambiguously implied if and only if the two arguments
to `Point` have the same type. When this isn't the case, the constructor will fail with a [`MethodError`](@ref):

```jldoctest pointtype
julia> Point(1,2.5)
ERROR: MethodError: no method matching Point(::Int64, ::Float64)
Closest candidates are:
  Point(::T, !Matched::T) where T at none:2
```

Constructor methods to appropriately handle such mixed cases can be defined, but that will not
be discussed until later on in [Constructors](@ref man-constructors).

### Parametric Abstract Types

Parametric abstract type declarations declare a collection of abstract types, in much the same
way:

```jldoctest pointytype
julia> abstract type Pointy{T} end
```

With this declaration, `Pointy{T}` is a distinct abstract type for each type or integer value
of `T`. As with parametric composite types, each such instance is a subtype of `Pointy`:

```jldoctest pointytype
julia> Pointy{Int64} <: Pointy
true

julia> Pointy{1} <: Pointy
true
```

Parametric abstract types are invariant, much as parametric composite types are:

```jldoctest pointytype
julia> Pointy{Float64} <: Pointy{Real}
false

julia> Pointy{Real} <: Pointy{Float64}
false
```

The notation `Pointy{<:Real}` can be used to express the Julia analogue of a
*covariant* type, while `Pointy{>:Int}` the analogue of a *contravariant* type,
but technically these represent *sets* of types (see [UnionAll Types](@ref)).
```jldoctest pointytype
julia> Pointy{Float64} <: Pointy{<:Real}
true

julia> Pointy{Real} <: Pointy{>:Int}
true
```

Much as plain old abstract types serve to create a useful hierarchy of types over concrete types,
parametric abstract types serve the same purpose with respect to parametric composite types. We
could, for example, have declared `Point{T}` to be a subtype of `Pointy{T}` as follows:

```jldoctest pointytype
julia> struct Point{T} <: Pointy{T}
           x::T
           y::T
       end
```

Given such a declaration, for each choice of `T`, we have `Point{T}` as a subtype of `Pointy{T}`:

```jldoctest pointytype
julia> Point{Float64} <: Pointy{Float64}
true

julia> Point{Real} <: Pointy{Real}
true

julia> Point{AbstractString} <: Pointy{AbstractString}
true
```

This relationship is also invariant:

```jldoctest pointytype
julia> Point{Float64} <: Pointy{Real}
false

julia> Point{Float64} <: Pointy{<:Real}
true
```

What purpose do parametric abstract types like `Pointy` serve? Consider if we create a point-like
implementation that only requires a single coordinate because the point is on the diagonal line
*x = y*:

```jldoctest pointytype
julia> struct DiagPoint{T} <: Pointy{T}
           x::T
       end
```

Now both `Point{Float64}` and `DiagPoint{Float64}` are implementations of the `Pointy{Float64}`
abstraction, and similarly for every other possible choice of type `T`. This allows programming
to a common interface shared by all `Pointy` objects, implemented for both `Point` and `DiagPoint`.
This cannot be fully demonstrated, however, until we have introduced methods and dispatch in the
next section, [Methods](@ref).

There are situations where it may not make sense for type parameters to range freely over all
possible types. In such situations, one can constrain the range of `T` like so:

```jldoctest realpointytype
julia> abstract type Pointy{T<:Real} end
```

With such a declaration, it is acceptable to use any type that is a subtype of
[`Real`](@ref) in place of `T`, but not types that are not subtypes of `Real`:

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

Type parameters for parametric composite types can be restricted in the same manner:

```julia
struct Point{T<:Real} <: Pointy{T}
    x::T
    y::T
end
```

To give a real-world example of how all this parametric type machinery can be useful, here is
the actual definition of Julia's [`Rational`](@ref) immutable type (except that we omit the
constructor here for simplicity), representing an exact ratio of integers:

```julia
struct Rational{T<:Integer} <: Real
    num::T
    den::T
end
```

It only makes sense to take ratios of integer values, so the parameter type `T` is restricted
to being a subtype of [`Integer`](@ref), and a ratio of integers represents a value on the
real number line, so any [`Rational`](@ref) is an instance of the [`Real`](@ref) abstraction.

### Tuple Types

Tuples are an abstraction of the arguments of a function -- without the function itself. The salient
aspects of a function's arguments are their order and their types. Therefore a tuple type is similar
to a parameterized immutable type where each parameter is the type of one field. For example,
a 2-element tuple type resembles the following immutable type:

```julia
struct Tuple2{A,B}
    a::A
    b::B
end
```

However, there are three key differences:

  * Tuple types may have any number of parameters.
  * Tuple types are *covariant* in their parameters: `Tuple{Int}` is a subtype of `Tuple{Any}`. Therefore
    `Tuple{Any}` is considered an abstract type, and tuple types are only concrete if their parameters
    are.
  * Tuples do not have field names; fields are only accessed by index.

Tuple values are written with parentheses and commas. When a tuple is constructed, an appropriate
tuple type is generated on demand:

```jldoctest
julia> typeof((1,"foo",2.5))
Tuple{Int64,String,Float64}
```

Note the implications of covariance:

```jldoctest
julia> Tuple{Int,AbstractString} <: Tuple{Real,Any}
true

julia> Tuple{Int,AbstractString} <: Tuple{Real,Real}
false

julia> Tuple{Int,AbstractString} <: Tuple{Real,}
false
```

Intuitively, this corresponds to the type of a function's arguments being a subtype of the function's
signature (when the signature matches).

### Vararg Tuple Types

The last parameter of a tuple type can be the special type [`Vararg`](@ref), which denotes any number
of trailing elements:

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

Notice that `Vararg{T}` corresponds to zero or more elements of type `T`. Vararg tuple types are
used to represent the arguments accepted by varargs methods (see [Varargs Functions](@ref)).

The type `Vararg{T,N}` corresponds to exactly `N` elements of type `T`.  `NTuple{N,T}` is a convenient
alias for `Tuple{Vararg{T,N}}`, i.e. a tuple type containing exactly `N` elements of type `T`.

### Named Tuple Types

Named tuples are instances of the [`NamedTuple`](@ref) type, which has two parameters: a tuple of
symbols giving the field names, and a tuple type giving the field types.

```jldoctest
julia> typeof((a=1,b="hello"))
NamedTuple{(:a, :b),Tuple{Int64,String}}
```

The [`@NamedTuple`](@ref) macro provides a more convenient `struct`-like syntax for declaring
`NamedTuple` types via `key::Type` declarations, where an omitted `::Type` corresponds to `::Any`.

```jldoctest
julia> @NamedTuple{a::Int, b::String}
NamedTuple{(:a, :b),Tuple{Int64,String}}

julia> @NamedTuple begin
           a::Int
           b::String
       end
NamedTuple{(:a, :b),Tuple{Int64,String}}
```

A `NamedTuple` type can be used as a constructor, accepting a single tuple argument.
The constructed `NamedTuple` type can be either a concrete type, with both parameters specified,
or a type that specifies only field names:

```jldoctest
julia> @NamedTuple{a::Float32,b::String}((1,""))
(a = 1.0f0, b = "")

julia> NamedTuple{(:a, :b)}((1,""))
(a = 1, b = "")
```

If field types are specified, the arguments are converted. Otherwise the types of the arguments
are used directly.

### [Singleton Types](@id man-singleton-types)

There is a special kind of abstract parametric type that must be mentioned here: singleton types.
For each type, `T`, the "singleton type" `Type{T}` is an abstract type whose only instance is
the object `T`. Since the definition is a little difficult to parse, let's look at some examples:

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

In other words, [`isa(A,Type{B})`](@ref) is true if and only if `A` and `B` are the same object
and that object is a type. Without the parameter, `Type` is simply an abstract type which has
all type objects as its instances, including, of course, singleton types:

```jldoctest
julia> isa(Type{Float64}, Type)
true

julia> isa(Float64, Type)
true

julia> isa(Real, Type)
true
```

Any object that is not a type is not an instance of `Type`:

```jldoctest
julia> isa(1, Type)
false

julia> isa("foo", Type)
false
```

Until we discuss [Parametric Methods](@ref) and [conversions](@ref conversion-and-promotion), it is difficult to explain
the utility of the singleton type construct, but in short, it allows one to specialize function
behavior on specific type *values*. This is useful for writing methods (especially parametric
ones) whose behavior depends on a type that is given as an explicit argument rather than implied
by the type of one of its arguments.

A few popular languages have singleton types, including Haskell, Scala and Ruby. In general usage,
the term "singleton type" refers to a type whose only instance is a single value. This meaning
applies to Julia's singleton types, but with that caveat that only type objects have singleton
types.

### Parametric Primitive Types

Primitive types can also be declared parametrically. For example, pointers are represented as
primitive types which would be declared in Julia like this:

```julia
# 32-bit system:
primitive type Ptr{T} 32 end

# 64-bit system:
primitive type Ptr{T} 64 end
```

The slightly odd feature of these declarations as compared to typical parametric composite types,
is that the type parameter `T` is not used in the definition of the type itself -- it is just
an abstract tag, essentially defining an entire family of types with identical structure, differentiated
only by their type parameter. Thus, `Ptr{Float64}` and `Ptr{Int64}` are distinct types, even though
they have identical representations. And of course, all specific pointer types are subtypes of
the umbrella [`Ptr`](@ref) type:

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
