# [文字列](@id man-strings)

文字列とは有限の文字列を意味します．当然ながら，ここで問題になるのは「文字とは何か」ということです．英語圏の人がよく知っている文字は，アルファベットの「A」「B」「C」などのほか，数字や一般的な句読点などであり，これらの文字は[ASCII](https://en.wikipedia.org/wiki/ASCII) 規格による 0 ～ 127 の整数値への写像に合わせて規格化されています．確かに，ASCII 文字にアクセントなどの修飾を加えたものやキリル文字やギリシャ文字など英語に関連する script，アラビア語，中国語，ヘブライ語，ヒンディー語，日本語，韓国語などの ASCII や英語とは全く関係のない script など，英語以外の言語で使われている文字は他にもたくさんあります．[Unicode](https://en.wikipedia.org/wiki/Unicode) 規格は'文字とは何か'という複雑な問題に取り組んでおり，この問題を扱う決定的な規格として一般に受け入れられています．必要に応じて，これらの複雑さを完全に無視して ASCII 文字だけが存在すると考えることもできますし，非 ASCII テキストを扱う際に遭遇する可能性のある文字やエンコーディングを処理できるコードを書くこともできます．Julia ではプレーンな ASCII テキストをシンプルかつ効率的に扱うことができ，また Unicode の取り扱いも可能な限りシンプルかつ効率的です．特に，C スタイルの文字列コードを書いて ASCII 文字列を処理すると性能面でもセマンティクス面でも期待通りに動作します．そのようなコードは，非 ASCII テキストに遭遇した場合，誤った結果を黙って渡されるのではなく，明確なエラーメッセージを表示して潔く失敗するようになっています．このような場合には，非 ASCII データを扱うようにコードを修正することが容易にできます．

Julia の文字列には，注目すべきハイレベルな特徴がいくつかあります:

- Julia で文字列（および文字列リテラル）に使われる組み込みの具象型は，[`String`](@ref)です．これは，[UTF-8](https://en.wikipedia.org/wiki/UTF-8) エンコーディングによる[Unicode](https://en.wikipedia.org/wiki/Unicode) 文字の全範囲をサポートしています．(他の Unicode エンコーディングとの間で変換するための[`transcode`](@ref)関数が提供されています．)
- すべての文字列型は抽象型である `AbstractString` のサブタイプであり，外部パッケージではさらに `AbstractString` サブタイプが定義されています (他のエンコーディング用など)．関数で文字列の引数を取る場合，任意の文字列型を受け付けるためにその型を `AbstractString` と宣言する必要があります．
- C 言語や Java のように，多くの動的型付け言語とは違い，Julia は単一の文字を表す[`AbstractChar`](@ref)というファーストクラスの型があります．`AbstractChar`の組み込みのサブタイプである [`Char`](@ref) は任意の Unicode 文字を表すことのできる 32-bit のプリミティブな型です．(UTF-8 エンコーディングに基づいています)
- Java のように文字列はイミュータブルです． `AbstractString` 型のオブジェクトは変更不可能です．異なる文字列の値を生成するには他の文字列から新たに生成します．
- 概念的に言えば，文字列はインデックスから文字への _部分写像_ です．即ちインデックスの値によっては，文字の値が返されず，例外が発生してしまいます．このためエンコード表現のバイトインデックスも利用でき、効率的な文字列のインデックス呼び出しが可能になります。 文字によるインデックスだと、ユニコード文字列はエンコーディングの変数の幅が変わるので、効率的かつ単純とはならないのです。

## [文字](@id man-characters)

`Char`は１つの文字を表します．これは，特別なリテラル表現と適切な算術動作を持つ 32 ビットのプリミティブ型であり，[Unicode code point](https://en.wikipedia.org/wiki/Code_point) を表す数値に変換することができます．(Julia のパッケージでは他の [テキストエンコーディング](https://en.wikipedia.org/wiki/Character_encoding) に対する操作を最適化するために`AbstractChar`などの他のサブタイプを定義することができます．)
以下は，`Char` の値がどのようなものかを示しています．

入力と表示:

```jldoctest
julia> 'x'
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)

julia> typeof(ans)
Char
```

`Char`は整数値に容易に変換することができます．:

```jldoctest
julia> Int('x')
120

julia> typeof(ans)
Int64
```

32-bit アーキテクチャでは[`typeof(ans)`](@ref)は[`Int32`](@ref)になります．整数値を`Char`に戻すことも容易です．:

```jldoctest
julia> Char(120)
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)
```

パフォーマンスのために，任意の整数値が Unicode の符号位置というわけではありませんが，`Char`変換では文字の値が有効であるかはチェックしません．変換された値が有効な符号位置であるかチェックしたい場合は[`isvalid`](@ref)関数を使用します．:

```jldoctest
julia> Char(0x110000)
'\U110000': Unicode U+110000 (category In: Invalid, too high)

julia> isvalid(Char, 0x110000)
false
```

この記事を書いている時点で，有効な Unicode 符号位置は，`U+0000`から`U+D7FF` および`U+E000`から`U+10FFFF`です．これらの符号位置全てに明瞭な意味が与えられたわけではなく，またそれらをアプリケーションが必ずしも解釈できるわけでもありません．しかし，これらの値は全て有効な Unicode 文字であると考えられます．

任意の Unicode 文字を一重引用符で囲んで入力するには，`\u`に続けて 4 桁までの 16 進数を入力するか，`\U`に続けて 8 桁までの 16 進数を入力します（最長の有効値は 6 桁まで）．:

```jldoctest
julia> '\u0'
'\0': ASCII/Unicode U+0000 (category Cc: Other, control)

julia> '\u78'
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)

julia> '\u2200'
'∀': Unicode U+2200 (category Sm: Symbol, math)

julia> '\U10ffff'
'\U10ffff': Unicode U+10FFFF (category Cn: Other, not assigned)
```

Julia はシステムのロケールと言語設定を用いてどの文字がそのまま表示可能で，どの文字が一般的なエスケープされた`\u`や`\U`を用いた入力形式を用いなければならないかを決定します．
それに加え，全ての[C の従来のエスケープされた入力フォーム](https://en.wikipedia.org/wiki/C_syntax#Backslash_escapes)も使用することができます．：

```jldoctest
julia> Int('\0')
0

julia> Int('\t')
9

julia> Int('\n')
10

julia> Int('\e')
27

julia> Int('\x7f')
127

julia> Int('\177')
127
```

`Char`の値で比較や限られた範囲の算術演算ををすることができます．:

```jldoctest
julia> 'A' < 'a'
true

julia> 'A' <= 'a' <= 'Z'
false

julia> 'A' <= 'X' <= 'Z'
true

julia> 'x' - 'a'
23

julia> 'A' + 1
'B': ASCII/Unicode U+0042 (category Lu: Letter, uppercase)
```

## [文字列の基本](@id String Basics)

文字列リテラルはタブルクォートやトリプルクォートで区切られます:

```jldoctest helloworldstring
julia> str = "Hello, world.\n"
"Hello, world.\n"

julia> """Contains "quote" characters"""
"Contains \"quote\" characters"
```

文字列から 1 文字を取り出したい場合はインデックスで取り出せます．

```jldoctest helloworldstring
julia> str[begin]
'H': ASCII/Unicode U+0048 (category Lu: Letter, uppercase)

julia> str[1]
'H': ASCII/Unicode U+0048 (category Lu: Letter, uppercase)

julia> str[6]
',': ASCII/Unicode U+002C (category Po: Punctuation, other)

julia> str[end]
'\n': ASCII/Unicode U+000A (category Cc: Other, control)
```

文字列を含む多くの Julia のオブジェクトは整数でインデックスをつけることができます．最初の要素(文字列の最初の文字)のインデックスは[`firstindex(str)`](@ref)で最後の要素(文字)のインデックスは[`lastindex(str)`](@ref)で返されます．キーワード `begin`と`end`は，インデックス操作の中で，与えられた次元に沿ったそれぞれの最初と最後のインデックスを表す略語として使用できます．文字列インデックスのような Julia におけるほとんどのインデックスは 1 から始まり，`firstindex`はどの`AbscractString`に対しても常に`1`を返します．しかしながら，後述するように，一般的には`lastindex(str)`は文字列の`length(str)`とは違うものです．なぜなら，Unicode 文字は複数の「符号」を占めることがあるからです．

[`end`](@ref)では通常の値と同じように算術演算やその他の操作を行うことができます．:

```jldoctest helloworldstring
julia> str[end-1]
'.': ASCII/Unicode U+002E (category Po: Punctuation, other)

julia> str[end÷2]
' ': ASCII/Unicode U+0020 (category Zs: Separator, space)
```

インデックスが `begin` (`1`) より小さいか，`end` より大きいと，エラーになります．:

```jldoctest helloworldstring
julia> str[begin-1]
ERROR: BoundsError: attempt to access String
  at index [0]
[...]

julia> str[end+1]
ERROR: BoundsError: attempt to access String
  at index [15]
[...]
```

レンジインデックスを用いて部分文字列を取り出すことができます．:

```jldoctest helloworldstring
julia> str[4:9]
"lo, wo"
```

`str[k]` と `str[k:k]` は同じ結果にならないことに注意してください．:

```jldoctest helloworldstring
julia> str[6]
',': ASCII/Unicode U+002C (category Po: Punctuation, other)

julia> str[6:6]
","
```

前者は `Char` 型の 1 文字の値で，後者は 1 文字しか含まない文字列の値です．
後者は，たまたま 1 文字しか含まれていない文字列値です．Julia ではこれらは全く異なるものです．

範囲指定では下の文字列の選択された部分をコピーします．また，[`SubString`](@ref)型を使って文字列へのビューを作成することもできます．

例:

```jldoctest
julia> str = "long string"
"long string"

julia> substr = SubString(str, 1, 4)
"long"

julia> typeof(substr)
SubString{String}
```

[`chop`](@ref)，[`chomp`](@ref)，[`strip`](@ref)のようないくつかの標準的な関数は，[`SubString`](@ref)を返します．

## [Unicode と UTF-8](@id Unicode and UTF-8)

Julia は Unicode 文字とその文字列を完全に対応しています．[`上述`](@ref man-characters)のように，文字リテラルでは，Unicode の符号位置は，Unicode の`\u`と`\U`のエスケープシーケンスや，C 標準のエスケープシーケンスを使って表現することができます．これらは，文字列リテラルを記述する際にも同様に使用できます．:

```jldoctest unicodestring
julia> s = "\u2200 x \u2203 y"
"∀ x ∃ y"
```

これらの Unicode 文字がエスケープされて表示されるか，特殊文字として表示されるかは，ターミナルのロケール設定と Unicode の対応状況に依存します．文字列リテラルのエンコードには UTF-8 エンコーディングを使用してエンコードされます．UTF-8 は可変幅のエンコーディングなので，つまりすべての文字が同じバイト数（「符号」）でエンコードされるわけではありません．UTF-8 では，ASCII 文字，つまり符号位置が 0x80（128）未満の文字は，ASCII と同じように 1 バイトでエンコードされますが，符号位置が 0x80 以上の文字は 1 文字あたり最大 4 バイトまでの複数バイトでエンコードされます.

Julia の文字列インデックスは，任意の文字（符号位置）をエンコードするための固定幅の構成要素である符号（＝ UTF-8 ではバイト）を指します．つまり，`String`へのすべてのインデックスが，必ずしも文字に対して有効なインデックスではないということです．このような無効なバイトインデックスで文字列を入力した場合，エラーが発生します．:

```jldoctest unicodestring
julia> s[1]
'∀': Unicode U+2200 (category Sm: Symbol, math)

julia> s[2]
ERROR: StringIndexError("∀ x ∃ y", 2)
[...]

julia> s[3]
ERROR: StringIndexError("∀ x ∃ y", 3)
Stacktrace:
[...]

julia> s[4]
' ': ASCII/Unicode U+0020 (category Zs: Separator, space)
```

この場合，文字`∀`は 3 バイト文字なので，インデックス 2 と 3 は無効で，次の文字のインデックスは 4 となります．この次の有効なインデックスは[`nextind(s,1)`](@ref)で計算でき，その次のインデックスは`nextind(s,4)`となります．

`end`は常にコレクションの最後の有効なインデックスなので、最後から 2 番目の文字がマルチバイトの場合、`end-1`は無効なバイトインデックスを参照します。

```jldoctest unicodestring
julia> s[end-1]
' ': ASCII/Unicode U+0020 (category Zs: Separator, space)

julia> s[end-2]
ERROR: StringIndexError("∀ x ∃ y", 9)
Stacktrace:
[...]

julia> s[prevind(s, end, 2)]
'∃': Unicode U+2203 (category Sm: Symbol, math)
```

最初のケースは，最後の文字 `y` とスペースが 1 バイト文字であるので動作するのに対し，インデックス`end-2` は `∃` のマルチバイト表現の中央にインデックスを置くので，動作しません．
この場合の正しい方法は，`prevind(s, lastindex(s), 2)`を使うか，`s`へのインデックスにその値を使うのであれば`s[prevind(s, end, 2)]`と書き，`end`は`lastindex(s)`に展開されます．

レンジインデックスを使用した部分文字列の抽出でも有効なバイトインデックスは必要であり，そうでない場合はエラーが発生します．:

```jldoctest unicodestring
julia> s[1:1]
"∀"

julia> s[1:2]
ERROR: StringIndexError("∀ x ∃ y", 2)
Stacktrace:
[...]

julia> s[1:4]
"∀ "
```

可変長エンコーディングのため，（[`length(s)`](@ref)で与えられる）文字列の文字数は，最後のインデックスと同じとは限りません． 1 から[`lastindex(s)`](@ref)までのインデックスを反復して`s`の文字を参照すると，エラーが発生しなかったときに返される文字列は文字列`s`を構成する文字列となります．このように文字列の各文字にはそれぞれインデックスが必要なので，`length(s) <= lastindex(s)`という恒等式が成り立ちます．以下は，`s`の文字を反復する非効率的で冗長な方法です．

```jldoctest unicodestring
julia> for i = firstindex(s):lastindex(s)
           try
               println(s[i])
           catch
               # ignore the index error
           end
       end
∀

x

∃

y
```

空白行は実際にはスペースが入っています．幸いなことに，文字列内の文字を反復処理する際には，上記のような厄介なイディオムは必要ありません．文字列を反復可能なオブジェクトとして使用するだけで，例外処理は必要ありません．:

```jldoctest unicodestring
julia> for c in s
           println(c)
       end
∀

x

∃

y
```

文字列の有効なインデックスを取得する必要がある場合には，前述のように，[`nextind`](@ref) および [`prevind`](@ref) 関数を使って，有効な次/前のインデックスにインクリメント/デクリメントすることができます．また，[`eachindex`](@ref)関数を使って，有効な文字列インデックスを繰り返し処理することもできます．:

```jldoctest unicodestring
julia> collect(eachindex(s))
7-element Array{Int64,1}:
  1
  4
  5
  6
  7
 10
 11
```

エンコーディングの未加工の符号（UTF-8 の場合はバイト）にアクセスするには，[`codeunit(s,i)`](@ref)関数を使います．ここで，インデックス`i`は`1`から[`ncodeunits(s)`](@ref)まで連続しています．[`codeunits(s)`](@ref)関数は`AbstractVector{UInt8}`というラッパーを返すので，これらの未加工の符号（バイト）を配列として利用することができます．

Julia の文字列には，無効な UTF-8 符号列が含まれることがあります．この規約により，任意のバイト列を `String` として扱うことができます．このような状況では，符号列を左から右に解析する際に，文字は以下のビットパターン（各 `x` は `0` または `1`）のいずれかの開始に一致する，最長の 8 ビットの符号列によって形成されるというルールがあります．

- `0xxxxxxx`;
- `110xxxxx` `10xxxxxx`;
- `1110xxxx` `10xxxxxx` `10xxxxxx`;
- `11110xxx` `10xxxxxx` `10xxxxxx` `10xxxxxx`;
- `10xxxxxx`;
- `11111xxx`.

特に，冗長すぎたり値が大きすぎたりする符号列とその接頭辞は、複数の無効な文字ではなく，単一の無効な文字として扱われます．このルールは，例を挙げて説明するのが一番わかりやすいでしょう．

```julia-repl
julia> s = "\xc0\xa0\xe2\x88\xe2|"
"\xc0\xa0\xe2\x88\xe2|"

julia> foreach(display, s)
'\xc0\xa0': [overlong] ASCII/Unicode U+0020 (category Zs: Separator, space)
'\xe2\x88': Malformed UTF-8 (category Ma: Malformed, bad data)
'\xe2': Malformed UTF-8 (category Ma: Malformed, bad data)
'|': ASCII/Unicode U+007C (category Sm: Symbol, math)

julia> isvalid.(collect(s))
4-element BitArray{1}:
 0
 0
 0
 1

julia> s2 = "\xf7\xbf\xbf\xbf"
"\U1fffff"

julia> foreach(display, s2)
'\U1fffff': Unicode U+1FFFFF (category In: Invalid, too high)
```

文字列 `s` の最初の 2 つの符号が，空白文字の冗長すぎるエンコーディングを形成していることがわかります．これは無効ですが，文字列では 1 文字として受け入れられます．次の 2 つの符号は，3 バイトの UTF-8 の列の有効な開始を形成します．しかし、5 番目の符号(`\xe2`)は有効な値ではありません．したがって，3 番目と 4 番目の符号もこの文字列では不正な文字として解釈されます．同様に，5 番目の符号は不正な文字を形成します．最後に，文字列 `s2` には 高すぎる符号位置が 1 つ含まれています．

Julia はデフォルトでは UTF-8 エンコーディングを使用しますが，新しいエンコーディングのサポートはパッケージによって追加することができます．例えば，[LegacyStrings.jl](https://github.com/JuliaStrings/LegacyStrings.jl)パッケージでは，`UTF16String`型と`UTF32String`型を実装しています．他のエンコーディングやそのサポートの実装方法についての詳しい説明はこのドキュメントの範囲外となります．また UTF-8 エンコーディングの問題については，以下の[`byte array literals`](@ref man-byte-array-literals)の節を参照してください．様々な UTF-xx エンコーディングの間でデータを変換するために，[`transcode`](@ref) 関数が提供されています．主に外部のデータやライブラリを扱うためのものです．

## [Concatenation](@id man-concatenation)

One of the most common and useful string operations is concatenation:
最も一般的で便利な文字列操作の一つが連結です．

```jldoctest stringconcat
julia> greet = "Hello"
"Hello"

julia> whom = "world"
"world"

julia> string(greet, ", ", whom, ".\n")
"Hello, world.\n"
```

無効な UTF-8 文字列の連結など，潜在的に危険な状況に注意することが重要です．結果として得られる文字列には，入力文字列とは異なる文字が含まれている可能性があり，その文字数は，連結された文字列の文字数の合計よりも少ない可能性があります．

例:

```julia-repl
julia> a, b = "\xe2\x88", "\x80"
("\xe2\x88", "\x80")

julia> c = a*b
"∀"

julia> collect.([a, b, c])
3-element Array{Array{Char,1},1}:
 ['\xe2\x88']
 ['\x80']
 ['∀']

julia> length.([a, b, c])
3-element Array{Int64,1}:
 1
 1
 1
```

この状況は，無効な UTF-8 文字列に対してのみ発生します．有効な UTF-8 文字列の場合，連結は文字列内のすべての文字と文字列長の加法性を保持します．

また，Julia には文字列連結のための[`*`](@ref)が用意されています．:

```jldoctest stringconcat
julia> greet * ", " * whom * ".\n"
"Hello, world.\n"
```

一方，文字列の連結に `+` を提供している言語のユーザーにとっては、`*` は意外な選択に思えるかもしれませんが，`*` の使用は，数学，特に抽象代数では前例があります．

数学では，`+`は通常、被演算子の順序が問題にならない，*可換*の演算を表します．この例として，行列の加算があります．同じ形の行列 `A` と `B` に対して，`A + B == B + A` となります．対照的に，`*` は一般的に _非可換_ 演算を表し，演算子の順序が _重要になります．この例としては，行列の乗算があり，一般的には `A _ B != B _ A` となります．行列の乗算と同様に，文字列の連結も非可換です．例えば，`greet _ whom != whom _ greet`となります．このように， 中置記法の文字列連結演算子としては `_` がより自然な選択であり，一般的な数学的使用と一致しています．

より正確には，すべての有限長の文字列*S*と文字列連結演算子`*`の集合は、[自由モノイド](https://en.wikipedia.org/wiki/Free_monoid) (_S_, `*`)を形成します．この集合の恒等要素は空文字列 `""` です．自由モノイドが可換でない場合，その演算は通常 `+` ではなく``cdot`, `*`, または同様の記号で表されます．

## [文字列補間](@id string-interpolation)

連結で文字列を構築するのは少々面倒な作業です．そこで，[`string`](@ref)のくどい呼び出しや繰り返しの乗算を減らすために，Julia では Perl のように，`$`を用いて文字列リテラルに補間することができます．:

```jldoctest stringconcat
julia> "$greet, $whom.\n"
"Hello, world.\n"
```

こちらはより読みやすく便利で，上記の文字列連結と同値です．システムは，この見かけ上の単一の文字列リテラルを呼び出し`string(greet, ", ", whom, ".\n")`に書き換えます．

$`の後の最も短い完全な式が，文字列に値を補うべき式とみなされます．このように，括弧を使えば，どんな式でも文字列に補間することができます．:

```jldoctest
julia> "1 + 2 = $(1 + 2)"
"1 + 2 = 3"
```

連結や文字列補間では，オブジェクトを文字列に変換するために [`string`](@ref) を呼び出します．しかし，`string`は実際には [`print`](@ref) の出力を返すだけなので，新しい型では`string`の代わりに [`print`](@ref) や [`show`](@ref) のメソッドを追加する必要があります．

多くの`AbstractString`ではないオブジェクトは，リテラル式として入力された様式に近い形で文字列に変換されます．

```jldoctest
julia> v = [1,2,3]
3-element Array{Int64,1}:
 1
 2
 3

julia> "v: $v"
"v: [1, 2, 3]"
```

[`string`](@ref)は`AbstractString`や`AbstractChar`の値と恒等であり，これらは引用符やエスケープされずにそのまま文字列に補間されます．

```jldoctest
julia> c = 'x'
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)

julia> "hi, $c"
"hi, x"
```

リテラル `$` を文字列リテラルに含めるには，バックスラッシュでエスケープします．:

```jldoctest
julia> print("I have \$100 in my account.\n")
I have $100 in my account.
```

## [トリプルクォーテーション付きの文字列リテラル](@id Triple-Quoted String Literals)

トリプルクォーテーション（`"""...""`）を使って文字列を作成すると，長いテキストブロックを作成するのに便利ないくつかの特別な動作をします．

まず，トリプルクォーテーションで囲まれた文字列も、インデントされていない行のレベルに合わせてディデントされます．これは，インデントされたコードの中で文字列を定義するのに便利です．例えば，以下のようになります．:

```jldoctest
julia> str = """
           Hello,
           world.
         """
"  Hello,\n  world.\n"
```

この場合，閉じる側の`"""`の直前の(空白)行がインデントレベルを設定します．

冒頭の `"""` に続く行と，スペースまたはタブだけを含む行を除いた，すべての行のうち，最も長い先頭のスペースまたはタブ数によってディデンテーション レベルが決定されます（最後の `"""` を含む行は常に含まれます）．
次に，冒頭の `"""` に続く行を除いたすべての行について，各行先頭の空白やタブが削除されます（スペースとタブだけを含む行を含む），

例:

```jldoctest
julia> """    This
         is
           a test"""
"    This\nis\n  a test"
```

次に，冒頭の `"""` の後に改行がある場合は結果の文字列から改行が取り除かれます．

```julia
"""hello"""
```

これは以下と等価です．

```julia
"""
hello"""
```

しかし

```julia
"""

hello"""
```

は先頭に改行リテラルを含みます．

改行の除去は，ディテンデーションの後に行われます．例えば以下のようになります:

```jldoctest
julia> """
         Hello,
         world."""
"Hello,\nworld."
```

末尾のホワイトスペースはそのまま残されます.

トリプルクォーテーションで囲まれた文字列リテラルには、エスケープせずに `"` 文字を含めることができます．

リテラル文字列の改行はリテラルがシングルクオーテーション，トリプルクオーテーションどちらで囲まれていても返り値の改行部分は改行（LF）文字`\n`が入ります．これはエディタが CR 文字や CRLF の組み合わせで行を終わらせている場合でも同様です．文字列に CR 文字を含めるには，明示的なエスケープを使用します，例えば/リテラル文字列 `"a CRLF line ending\r\n"` を入力します．

## [よくある操作](@id Common Operations)

標準的な比較演算子を使って，文字列を辞書的に比較することができます．

```jldoctest
julia> "abracadabra" < "xylophone"
true

julia> "abracadabra" == "xylophone"
false

julia> "Hello, world." != "Goodbye, world."
true

julia> "1 + 2 = 3" == "1 + 2 = $(1 + 2)"
true
```

[`findfirst`](@ref)および[`findlast`](@ref)関数を使って，特定の文字のインデックスを検索することができます．

```jldoctest
julia> findfirst(isequal('o'), "xylophone")
4

julia> findlast(isequal('o'), "xylophone")
7

julia> findfirst(isequal('z'), "xylophone")
```

関数[`findnext`](@ref)や[`findprev`](@ref)を使えば，指定したオフセットで文字の検索を開始することができます．

```jldoctest
julia> findnext(isequal('o'), "xylophone", 1)
4

julia> findnext(isequal('o'), "xylophone", 5)
7

julia> findprev(isequal('o'), "xylophone", 5)
4

julia> findnext(isequal('o'), "xylophone", 8)
```

文字列の中に部分文字列があるかどうかを調べるには[`occursin`](@ref)関数を使います．

```jldoctest
julia> occursin("world", "Hello, world.")
true

julia> occursin("o", "Xylophon")
true

julia> occursin("a", "Xylophon")
false

julia> occursin('o', "Xylophon")
true
```

最後の例では，[`occursin`](@ref)が文字リテラルを探すこともできることを示しています．

他にも便利な文字列関数として[`repeat`](@ref)や[`join`](@ref)があります．

```jldoctest
julia> repeat(".:Z:.", 10)
".:Z:..:Z:..:Z:..:Z:..:Z:..:Z:..:Z:..:Z:..:Z:..:Z:."

julia> join(["apples", "bananas", "pineapples"], ", ", " and ")
"apples, bananas and pineapples"
```

他にも便利な関数があります:

- [`firstindex(str)`](@ref)は`str` へのインデックスに使用できる最小の（バイト）インデックスを返します（文字列の場合は常に 1 ですが，他のコンテナの場合は必ずしもそうではありません）．
- [`lastindex(str)`](@ref)は，`str` のインデックスに使用できる最大の（バイト）インデックスを返します．
- [`length(str)`](@ref) は`str`の文字数です．
- [`length(str, i, j)`](@ref) は`str` の中の `i` から `j` までの有効な文字インデックスの数です．
- [`ncodeunits(str)`](@ref) は文字列中の[code units](https://en.wikipedia.org/wiki/Character_encoding#Terminology)の数です．
- [`codeunit(str, i)`](@ref) は文字列 `str` のインデックス `i` にコードユニットの値を返します．
- [`thisind(str, i)`](@ref) は文字列に任意のインデックスを与えると，そのインデックスが指し示す文字の最初のインデックスを返します．
- [`nextind(str, i, n=1)`](@ref) は添字 `i` から始まる `n` 番目の文字の先頭を見つけます．
- [`prevind(str, i, n=1)`](@ref) は添字 `i` より前の `n` 番目の文字の始まりを見つけます．

## [非標準文字列リテラル](@id non-standard-string-literals)

文字列を作成したり文字列セマンティクスを使用したりしたいが，標準的な文字列構築の動作が必要とされるものとは全く異なる場合があります．このような状況のために，Julia は[`非標準文字列リテラル`](@ref non-standard-string-literals)を提供しています．
非標準文字列リテラルは通常のダブルクオーテーションで囲まれた文字列リテラルのように見えますが，識別子として接頭辞がつけられ，通常の文字列リテラルのようには動作しません．
具体的には後述の正規表現，バイト配列リテラル，バージョン番号リテラルなどが非標準文字列リテラルなどが挙げられます．
その他の例 は[`メタプログラミング`](@ref Metaprogramming)のセクションで説明しています。

## [正規表現](@id Regular Expressions)

Julia は，[PCRE](http://www.pcre.org/)ライブラリが提供する Perl 互換の正規表現(regexes)を備えています。（構文の説明は[こちら](http://www.pcre.org/current/doc/html/pcre2syntax.html)にあります．正規表現は文字列と 2 つの点で関連しています．まず明らかな関連性として，正規表現が文字列の正規パターンを見つけるために使用される点が挙げられます．もう一つの関連性は，正規表現はそれ自体が文字列として入力され，文字列内のパターンを効率的に検索するために使用される状態機械(ステートマシン)に解析されるということです．Julia では，正規表現は `r`で始まる様々な識別子を前置した非標準の文字列リテラルを使って入力されます．最も基本的な正規表現リテラルは，オプションを何もつけずに`r"..."`を使うだけです．:

```jldoctest
julia> r"^\s*(?:#|$)"
r"^\s*(?:#|$)"

julia> typeof(ans)
Regex
```

正規表現が文字列にマッチするかどうかを調べるには、[`occursin`](@ref)を使います:

```jldoctest
julia> occursin(r"^\s*(?:#|$)", "not a comment")
false

julia> occursin(r"^\s*(?:#|$)", "# a comment")
true
```

ここで見られるように，[`occursin`](@ref)は単純に true または false を返し，与えられた正規表現にマッチするものが文字列の中に存在するかどうかを示します．しかし，一般的には文字列がマッチしたかどうかだけでなく，どのようにマッチしたかを知りたい場合があります．このようなマッチに関する情報を取得するには，代わりに [`match`](@ref) 関数を使用します:

```jldoctest
julia> match(r"^\s*(?:#|$)", "not a comment")

julia> match(r"^\s*(?:#|$)", "# a comment")
RegexMatch("#")
```

正規表現が与えられた文字列にマッチしなかった場合，[`match`](@ref)は [`nothing`](@ref)を返します．これは，対話型プロンプトに何も表示しない特別な値です．何も表示されないだけであり，正常な値であるのでプログラムは正常に動作します．

```julia
m = match(r"^\s*(?:#|$)", line)
if m === nothing
    println("not a comment")
else
    println("blank or comment")
end
```

正規表現にマッチした場合，[match`](@ref)は `RegexMatch` オブジェクトを返します．これらのオブジェクトはパターンがマッチした部分文字列やキャプチャされた部分文字列に対して正規表現がどのようにマッチしたかを記録したものです．この例では，マッチした部分文字列のみをキャプチャしていますが，コメントの後の空白でないテキストもキャプチャしたい場合があります．
その場合は次のようにします:

```jldoctest
julia> m = match(r"^\s*(?:#\s*(.*?)\s*$|$)", "# a comment ")
RegexMatch("# a comment ", 1="a comment")
```

[`match`](@ref)を呼び出す際には検索を開始するインデックスを指定できるオプションがあります．

例:

```jldoctest
julia> m = match(r"[0-9]","aaaa1aaaa2aaaa3",1)
RegexMatch("1")

julia> m = match(r"[0-9]","aaaa1aaaa2aaaa3",6)
RegexMatch("2")

julia> m = match(r"[0-9]","aaaa1aaaa2aaaa3",11)
RegexMatch("3")
```

`RegexMatch`オブジェクトからは以下の情報を抽出することができます:

- マッチした部分文字列全体: `m.match`
- キャプチャされた部分文字列が文字列の配列になったもの: `m.captures`
- マッチした文字列の開始位置(オフセット): `m.offset`
- キャプチャされた部分文字列のオフセットをベクトルで表したもの: `m.offsets`

キャプチャがマッチしない場合，`m.captures`にはその位置に`nothing`が含まれ，`m.offsets`にはゼロのオフセットが含まれます(Julia のインデックスは 1 ベースなので、文字列へのゼロの 文字列へのゼロオフセットは無効です）．以下では，やや作為的な例を 2 つ示します:

```jldoctest acdmatch
julia> m = match(r"(a|b)(c)?(d)", "acd")
RegexMatch("acd", 1="a", 2="c", 3="d")

julia> m.match
"acd"

julia> m.captures
3-element Array{Union{Nothing, SubString{String}},1}:
 "a"
 "c"
 "d"

julia> m.offset
1

julia> m.offsets
3-element Array{Int64,1}:
 1
 2
 3

julia> m = match(r"(a|b)(c)?(d)", "ad")
RegexMatch("ad", 1="a", 2=nothing, 3="d")

julia> m.match
"ad"

julia> m.captures
3-element Array{Union{Nothing, SubString{String}},1}:
 "a"
 nothing
 "d"

julia> m.offset
1

julia> m.offsets
3-element Array{Int64,1}:
 1
 0
 2
```

キャプチャを配列として返すと分割代入を使ってローカル変数にバインドすることができます:

```jldoctest acdmatch
julia> first, second, third = m.captures; first
"a"
```

キャプチャは`RegexMatch`のインデックス番号か，名前付きキャプチャグループをインデックスすることでアクセスできます:

```jldoctest
julia> m=match(r"(?<hour>\d+):(?<minute>\d+)","12:45")
RegexMatch("12:45", hour="12", minute="45")

julia> m[:minute]
"45"

julia> m[2]
"45"
```

[`replace`](@ref)を使った置換文字列でキャプチャーを参照するには，`\n`を使って n 番目のキャプチャグループを参照し，置換文字列の前に`s`を付けます．キャプチャグループ 0 はマッチオブジェクト全体を指します．名前付きキャプチャグループは，置換文字列の中で `\g<groupname>` を使って参照できます．たとえば，以下のようになります:

```jldoctest
julia> replace("first second", r"(\w+) (?<agroup>\w+)" => s"\g<agroup> \1")
"second first"
```

番号の付いたキャプチャーグループは，曖昧さ回避のために`g<n>`として参照することもでき，以下のようになります:

```jldoctest
julia> replace("a", r"." => s"\g<0>1")
"a1"
```

ダブルクォーテーションマークの後のフラグ`i`、`m`、`s`、`x`の組み合わせによって，正規表現の動作を変更することができます．これらのフラグは，[perlre manpage](http://perldoc.perl.org/perlre.html#Modifiers)からの抜粋で説明されているように，Perl におけるフラグと同じ意味を持っています．

```
i   大文字小文字を区別しないパターンマッチング

    ロケール照合規則が有効な場合，符号位置が255未満の場合は現在のロケールから，それ以上の場合はUnicode規則から，ケースマップを取得します．ただし，Unicode規則と非Unicode規則の境界（コード番号255/256）を超えるようなマッチは (ords 255/256)を超えるマッチは成功しません．

m   文字列を複数行として扱います．つまり，"^"と"$"は文字列の開始または終了にマッチするのではなく文字列内の任意の行の開始または終了に一致するように変更します．

s   文字列を一行として扱います．つまり，"."を任意の文字や通常はマッチしない"改行"にもマッチするように変更されます．

    r""msのようにmとsを一緒に使うと". “は任意の文字にマッチする一方で，"^" and “$"はそれぞれ任意の行の開始と終了文字にマッチします．

x   正規表現パーサーは，バックスラッシュでも文字クラスにも含まれないほとんどの空白を無視します．これを使うと，正規表現を（少し）読みやすいパーツに分割することができます．また、'#'文字は，通常のコードと同様に，コメントを表すメタ文字として扱われます．
```

例えば、次の正規表現は 3 つのフラグがすべてオンになっています:

```jldoctest　　　　　　　
julia> r"a+.*b+.*?d$"ism
r"a+.*b+.*?d$"ims

julia> match(r"a+.*b+.*?d$"ism, "Goodbye,\nOh, angry,\nBad world\n")
RegexMatch("angry,\nBad world")
```

`r"...` リテラルは，補間やエスケープを行わずに構築されます（ただし，引用符 `"` はエスケープが必要です）．以下は標準的な文字列リテラルとの違いを示した例です:

```julia-repl
julia> x = 10
10

julia> r"$x"
r"$x"

julia> "$x"
"10"

julia> r"\x"
r"\x"

julia> "\x"
ERROR: syntax: invalid escape sequence
```

`r"""..."""`のようにトリプルクォーテーションで囲まれた正規表現の文字列もサポートされています(クオーテーションや改行文字を含む正規表現には便利です)．

`Regex()`コンストラクタを使うと，プログラムで有効な正規表現の文字列を作成することができます．これにより，正規表現文字列を作成する際に文字列変数の内容や他の文字列操作を使用することができます．上記の正規表現コードのいずれも，`Regex()`の文字列引数の中で使用することができます．以下にその例を示します:

```jldoctest
julia> using Dates

julia> d = Date(1962,7,10)
1962-07-10

julia> regex_d = Regex("Day " * string(day(d)))
r"Day 10"

julia> match(regex_d, "It happened on Day 10")
RegexMatch("Day 10")

julia> name = "Jon"
"Jon"

julia> regex_name = Regex("[\"( ]$name[\") ]")  # interpolate value of name
r"[\"( ]Jon[\") ]"

julia> match(regex_name," Jon ")
RegexMatch(" Jon ")

julia> match(regex_name,"[Jon]") === nothing
true
```

## [バイト列リテラル](@id man-byte-array-literals)

もう一つの便利な非標準の文字列リテラルは，バイト配列の文字列リテラルである`b"..."`です．この形式では文字列記法を用いて，読み取り専用のバイト配列リテラルを表現することができます．すなわち，[`UInt8`](@ref)値の配列です．これらのオブジェクトのタイプは，`CodeUnits{UInt8, String}`です．バイト配列リテラルのルールは以下の通りです:

- ASCII 文字と ASCII エスケープは 1 バイトを生成します．
- `\x`と 8 進数のエスケープシーケンスでは，エスケープ値に対応する _byte_ が生成されます．
- Unicode のエスケープシーケンスは，その符号位置を UTF-8 でエンコードしたバイト列を生成します．

`\x`と 0x80(128)以下の 8 進数エスケープの動作は，最初の 2 つのルールの両方でカバーされているため，これらのルールには重複がありますが，ここではこれらのルールは一致しています。これらのルールを合わせるとその規則により，ASCII 文字，任意のバイト値，UTF-8 シーケンスを使ってバイト配列を簡単に作成することができます．この 3 つを使った例を示します:

```jldoctest
julia> b"DATA\xff\u2200"
8-element Base.CodeUnits{UInt8,String}:
 0x44
 0x41
 0x54
 0x41
 0xff
 0xe2
 0x88
 0x80
```

ASCII 文字列 "DATA "は、バイト 68、65、84、65 に対応します．`\xff`はシングルバイト 255 になります．Unicode のエスケープである`\u2200`は，UTF-8 では 226, 136, 128 の 3 バイトになります．なお，結果として得られるバイト配列は，有効な UTF-8 文字列には対応していないことに注意してください．

```jldoctest
julia> isvalid("DATA\xff\u2200")
false
```

前述したように，`CodeUnits{UInt8,String}`型は`UInt8`の読み取り専用の配列のように動作します．標準的なベクトルが必要な場合は，`Vector{UInt8}`を使って変換できます:

```jldoctest
julia> x = b"123"
3-element Base.CodeUnits{UInt8,String}:
 0x31
 0x32
 0x33

julia> x[1]
0x31

julia> x[1] = 0x32
ERROR: setindex! not defined for Base.CodeUnits{UInt8,String}
[...]

julia> Vector{UInt8}(x)
3-element Array{UInt8,1}:
 0x31
 0x32
 0x33
```

また，`xff`と`uff`の大きな違いにも注目してください．前者のエスケープシーケンスは _byte 255_ をエンコードしているのに対し、後者のエスケープシーケンスは _符号位置 255_ を表しており，UTF-8 では 2 バイトでエンコードされています．

```jldoctest
julia> b"\xff"
1-element Base.CodeUnits{UInt8,String}:
 0xff

julia> b"\uff"
2-element Base.CodeUnits{UInt8,String}:
 0xc3
 0xbf
```

文字リテラルも同様の動作をします．

`\u80`未満の符号位置では，各符号位置の UTF-8 エンコーディングは`\x`に対応したエスケープからが生成されるシングルバイトであるため，この区別は安全に無視できます．しかしながら`\x80` 〜`\xff`エスケープと`\u80` 〜 `\uff`のエスケープでは大きな違いがあります．前者のエスケープは、すべてシングルバイトをエンコードしており、特定の継続バイトが続かない限り、有効な UTF-8 データを形成しませんが，後者はすべて 2 バイトエンコードの Unicode の符号位置を表しています．

これだけではよくわからないという方は，["The Absolute Minimum Every Software Developer Absolutely, Positively Must Know About Unicode and Character Sets”](https://www.joelonsoftware.com/2003/10/08/the-absolute-minimum-every-software-developer-absolutely-positively-must-know-about-unicode-and-character-sets-no-excuses/)を読んでみてください．
これは Unicode と UTF-8 に関する優れた入門書で，この問題に役立つかもしれません．

## [Version Number Literals](@id man-version-number-literals)

Version numbers can easily be expressed with non-standard string literals of the form [`v"..."`](@ref @v_str).
Version number literals create [`VersionNumber`](@ref) objects which follow the
specifications of [semantic versioning](https://semver.org/),
and therefore are composed of major, minor and patch numeric values, followed by pre-release and
build alpha-numeric annotations. For example, `v"0.2.1-rc1+win64"` is broken into major version
`0`, minor version `2`, patch version `1`, pre-release `rc1` and build `win64`. When entering
a version literal, everything except the major version number is optional, therefore e.g. `v"0.2"`
is equivalent to `v"0.2.0"` (with empty pre-release/build annotations), `v"2"` is equivalent to
`v"2.0.0"`, and so on.

`VersionNumber` objects are mostly useful to easily and correctly compare two (or more) versions.
For example, the constant [`VERSION`](@ref) holds Julia version number as a `VersionNumber` object, and
therefore one can define some version-specific behavior using simple statements as:

```julia
if v"0.2" <= VERSION < v"0.3-"
    # do something specific to 0.2 release series
end
```

Note that in the above example the non-standard version number `v"0.3-"` is used, with a trailing
`-`: this notation is a Julia extension of the standard, and it's used to indicate a version which
is lower than any `0.3` release, including all of its pre-releases. So in the above example the
code would only run with stable `0.2` versions, and exclude such versions as `v"0.3.0-rc1"`. In
order to also allow for unstable (i.e. pre-release) `0.2` versions, the lower bound check should
be modified like this: `v"0.2-" <= VERSION`.

Another non-standard version specification extension allows one to use a trailing `+` to express
an upper limit on build versions, e.g. `VERSION > v"0.2-rc1+"` can be used to mean any version
above `0.2-rc1` and any of its builds: it will return `false` for version `v"0.2-rc1+win64"` and
`true` for `v"0.2-rc2"`.

It is good practice to use such special versions in comparisons (particularly, the trailing `-`
should always be used on upper bounds unless there's a good reason not to), but they must not
be used as the actual version number of anything, as they are invalid in the semantic versioning
scheme.

Besides being used for the [`VERSION`](@ref) constant, `VersionNumber` objects are widely used
in the `Pkg` module, to specify packages versions and their dependencies.

## [Raw String Literals](@id man-raw-string-literals)

Raw strings without interpolation or unescaping can be expressed with
non-standard string literals of the form `raw"..."`. Raw string literals create
ordinary `String` objects which contain the enclosed contents exactly as
entered with no interpolation or unescaping. This is useful for strings which
contain code or markup in other languages which use `$` or `\` as special
characters.

The exception is that quotation marks still must be escaped, e.g. `raw"\""` is equivalent
to `"\""`.
To make it possible to express all strings, backslashes then also must be escaped, but
only when appearing right before a quote character:

```jldoctest
julia> println(raw"\\ \\\"")
\\ \"
```

Notice that the first two backslashes appear verbatim in the output, since they do not
precede a quote character.
However, the next backslash character escapes the backslash that follows it, and the
last backslash escapes a quote, since these backslashes appear before a quote.
