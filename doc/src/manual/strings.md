# [文字列](@id man-strings)

<!-- Strings are finite sequences of characters. Of course, the real trouble comes when one asks what a character is. The characters that English speakers are familiar with are the letters A, B, C, etc., together with numerals and common punctuation symbols. These characters are standardized together with a mapping to integer values between 0 and 127 by the ASCII standard. There are, of course, many other characters used in non-English languages, including variants of the ASCII characters with accents and other modifications, related scripts such as Cyrillic and Greek, and scripts completely unrelated to ASCII and English, including Arabic, Chinese, Hebrew, Hindi, Japanese, and Korean. The Unicode standard tackles the complexities of what exactly a character is, and is generally accepted as the definitive standard addressing this problem. Depending on your needs, you can either ignore these complexities entirely and just pretend that only ASCII characters exist, or you can write code that can handle any of the characters or encodings that one may encounter when handling non-ASCII text. Julia makes dealing with plain ASCII text simple and efficient, and handling Unicode is as simple and efficient as possible. In particular, you can write C-style string code to process ASCII strings, and they will work as expected, both in terms of performance and semantics. If such code encounters non-ASCII text, it will gracefully fail with a clear error message, rather than silently introducing corrupt results. When this happens, modifying the code to handle non-ASCII data is straightforward. -->
Stringsとは有限の文字列を意味します．当然ながら，ここで問題になるのは「文字とは何か」ということです．英語圏の人がよく知っている文字は，アルファベットの「A」「B」「C」などのほか，数字や一般的な句読点などであり，これらの文字は[ASCII](https://en.wikipedia.org/wiki/ASCII) 規格による0～127の整数値への写像に合わせて規格化されています．確かに，ASCII文字にアクセントなどの修飾を加えたものやキリル文字やギリシャ文字など英語に関連するscript，アラビア語，中国語，ヘブライ語，ヒンディー語，日本語，韓国語などのASCIIや英語とは全く関係のないscriptなど，英語以外の言語で使われている文字は他にもたくさんあります．[Unicode](https://en.wikipedia.org/wiki/Unicode) 規格は'文字とは何か'という複雑な問題に取り組んでおり，この問題を扱う決定的な規格として一般に受け入れられています．必要に応じて，これらの複雑さを完全に無視してASCII文字だけが存在すると考えることもできますし，非ASCIIテキストを扱う際に遭遇する可能性のある文字やエンコーディングを処理できるコードを書くこともできます．JuliaではプレーンなASCIIテキストをシンプルかつ効率的に扱うことができ，またUnicodeの取り扱いも可能な限りシンプルかつ効率的です．特に，Cスタイルの文字列コードを書いてASCII文字列を処理すると性能面でもセマンティクス面でも期待通りに動作します．そのようなコードは，非ASCIIテキストに遭遇した場合，誤った結果を黙って渡されるのではなく，明確なエラーメッセージを表示して潔く失敗するようになっています．このような場合には，非ASCIIデータを扱うようにコードを修正することが容易にできます．

<!-- There are a few noteworthy high-level features about Julia's strings: -->
Juliaの文字列には，注目すべきハイレベルな特徴がいくつかあります:

  <!-- * The built-in concrete type used for strings (and string literals) in Julia is [`String`](@ref). -->
  * Juliaで文字列（および文字列リテラル）に使われる組み込みの具象型は，[`String`](@ref)です．
    <!-- This supports the full range of [Unicode](https://en.wikipedia.org/wiki/Unicode) characters via
    the [UTF-8](https://en.wikipedia.org/wiki/UTF-8) encoding. (A [`transcode`](@ref) function is
    provided to convert to/from other Unicode encodings.) -->
    これは，[UTF-8](https://en.wikipedia.org/wiki/UTF-8) エンコーディングによる[Unicode](https://en.wikipedia.org/wiki/Unicode) 文字の全範囲をサポートしています．(他のUnicodeエンコーディングとの間で変換するための[`transcode`](@ref)関数が提供されています．)
  <!-- * All string types are subtypes of the abstract type `AbstractString`, and external packages define additional `AbstractString` subtypes (e.g. for other encodings).  If you define a function expecting a string argument, you should declare the type as `AbstractString` in order to accept any string type. -->
  * すべての文字列型は抽象型である `AbstractString` のサブタイプであり，外部パッケージではさらに `AbstractString` サブタイプが定義されています (他のエンコーディング用など)．関数で文字列の引数を取る場合，任意の文字列型を受け付けるためにその型を `AbstractString` と宣言する必要があります．
  <!-- * Like C and Java, but unlike most dynamic languages, Julia has a first-class type for representing a single character, called [`AbstractChar`](@ref). The built-in [`Char`](@ref) subtype of `AbstractChar` is a 32-bit primitive type that can represent any Unicode character (and which is based on the UTF-8 encoding). -->
  * C言語やJavaのように，多くの動的型付け言語とは違い，Juliaは単一の文字を表す[`AbstractChar`](@ref)というファーストクラスの型があります．`AbstractChar`の組み込みのサブタイプである [`Char`](@ref) は任意のUnicode文字を表すことのできる32-bitのプリミティブな型です．(UTF-8エンコーディングに基づいています)
  <!-- * As in Java, strings are immutable: the value of an `AbstractString` object cannot be changed. To construct a different string value, you construct a new string from parts of other strings. -->
  * Javaのように文字列はイミュータブルです． `AbstractString` 型のオブジェクトは変更不可能です．異なる文字列の値を生成するには他の文字列から新たに生成します．
  <!-- * Conceptually, a string is a *partial function* from indices to characters: for some index values,no character value is returned, and instead an exception is thrown. This allows for efficient indexing into strings by the byte index of an encoded representation rather than by a character index, which cannot be implemented both efficiently and simply for variable-width encodings of Unicode strings. -->
  * 概念的に言えば，文字列はインデックスから文字への部分写像です．即ちインデックスの値によっては，文字の値が返されず，例外が発生してしまいます．これにより，Unicode文字列の可変幅エンコーディングを効率的かつシンプルに実装することができない文字インデックスではなく，エンコードされた表現のバイトインデックスで文字列を効率的にインデックスすることができます．

## [文字](@id man-characters)

<!-- A `Char` value represents a single character: it is just a 32-bit primitive type with a special literal
representation and appropriate arithmetic behaviors, and which can be converted
to a numeric value representing a
[Unicode code point](https://en.wikipedia.org/wiki/Code_point).  (Julia packages may define
other subtypes of `AbstractChar`, e.g. to optimize operations for other
[text encodings](https://en.wikipedia.org/wiki/Character_encoding).) Here is how `Char` values are -->
`Char`は１つの文字を表します．これは，特別なリテラル表現と適切な算術動作を持つ32ビットのプリミティブ型であり，[Unicode code point](https://en.wikipedia.org/wiki/Code_point) を表す数値に変換することができます．(Juliaのパッケージでは他の [テキストエンコーディング](https://en.wikipedia.org/wiki/Character_encoding) に対する操作を最適化するために`AbstractChar`などの他のサブタイプを定義することができます．)
以下は，`Char` の値がどのようなものかを示しています．
<!-- input and shown: -->
入力と表示: 

```jldoctest
julia> 'x'
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)

julia> typeof(ans)
Char
```

<!-- You can easily convert a `Char` to its integer value, i.e. code point: -->
`Char`は整数値に容易に変換することができます．:

```jldoctest
julia> Int('x')
120

julia> typeof(ans)
Int64
```

<!-- On 32-bit architectures, [`typeof(ans)`](@ref) will be [`Int32`](@ref). You can convert an
integer value back to a `Char` just as easily: -->
32-bitアーキテクチャでは[`typeof(ans)`](@ref)は[`Int32`](@ref)になります．整数値を`Char`に戻すことも容易です．:

```jldoctest
julia> Char(120)
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)
```

<!-- Not all integer values are valid Unicode code points, but for performance, the `Char` conversion
does not check that every character value is valid. If you want to check that each converted value
is a valid code point, use the [`isvalid`](@ref) function: -->
パフォーマンスのために，任意の整数値がUnicodeのコードポイントというわけではありませんが，`Char`変換では文字の値が有効であるかはチェックしません．変換された値が有効なコードポイントであるかチェックしたい場合は[`isvalid`](@ref)関数を使用します．:

```jldoctest
julia> Char(0x110000)
'\U110000': Unicode U+110000 (category In: Invalid, too high)

julia> isvalid(Char, 0x110000)
false
```
<!-- 
As of this writing, the valid Unicode code points are `U+0000` through `U+D7FF` and `U+E000` through
`U+10FFFF`. These have not all been assigned intelligible meanings yet, nor are they necessarily
interpretable by applications, but all of these values are considered to be valid Unicode characters. -->
この記事を書いている時点で，有効なUnicodeコードポイントは，`U+0000`から`U+D7FF` および`U+E000`から`U+10FFFF`です．これらのコードポイント全てに明瞭な意味が与えられたわけではなく，またそれらをアプリケーションが必ずしも解釈できるわけでもありません．しかし，これらの値は全て有効なUnicode文字であると考えられます．

<!-- You can input any Unicode character in single quotes using `\u` followed by up to four hexadecimal
digits or `\U` followed by up to eight hexadecimal digits (the longest valid value only requires six): -->
任意のUnicode文字を一重引用符で囲んで入力するには，`\u`に続けて4桁までの16進数を入力するか，`\U`に続けて8桁までの16進数を入力します（最長の有効値は6桁まで）．:

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
<!-- 
Julia uses your system's locale and language settings to determine which characters can be printed
as-is and which must be output using the generic, escaped `\u` or `\U` input forms. In addition
to these Unicode escape forms, all of [C's traditional escaped input forms](https://en.wikipedia.org/wiki/C_syntax#Backslash_escapes)
can also be used: -->
Juliaはシステムのロケールと言語設定を用いてどの文字がそのまま表示可能で，どの文字が一般的なエスケープされた`\u`や`\U`を用いた入力形式を用いなければならないかを決定します．
それに加え，全ての[Cの従来のエスケープされた入力フォーム](https://en.wikipedia.org/wiki/C_syntax#Backslash_escapes)も使用することができます．：

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

<!-- You can do comparisons and a limited amount of arithmetic with `Char` values: -->
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

<!-- String literals are delimited by double quotes or triple double quotes: -->
文字列リテラルはタブルクォートやトリプルクォートで区切られます:

```jldoctest helloworldstring
julia> str = "Hello, world.\n"
"Hello, world.\n"

julia> """Contains "quote" characters"""
"Contains \"quote\" characters"
```

<!-- If you want to extract a character from a string, you index into it: -->
文字列から1文字を取り出したい場合はインデックスで取り出せます．

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

<!-- Many Julia objects, including strings, can be indexed with integers. The index of the first
element (the first character of a string) is returned by [`firstindex(str)`](@ref), and the index of the last element (character)
with [`lastindex(str)`](@ref). The keywords `begin` and `end` can be used inside an indexing
operation as shorthand for the first and last indices, respectively, along the given dimension.
String indexing, like most indexing in Julia, is 1-based: `firstindex` always returns `1` for any `AbstractString`.
As we will see below, however, `lastindex(str)` is *not* in general the same as `length(str)` for a string,
because some Unicode characters can occupy multiple "code units". -->
文字列を含む多くのJuliaのオブジェクトは整数でインデックスをつけることができます．最初の要素(文字列の最初の文字)のインデックスは[`firstindex(str)`](@ref)で最後の要素(文字)のインデックスは[`lastindex(str)`](@ref)で返されます．キーワード `begin`と`end`は，インデックス操作の中で，与えられた次元に沿ったそれぞれの最初と最後のインデックスを表す略語として使用できます．文字列インデックスのようなJuliaにおけるほとんどのインデックスは1から始まり，`firstindex`はどの`AbscractString`に対しても常に`1`を返します．しかしながら，後述するように，一般的には`lastindex(str)`は文字列の`length(str)`とは違うものです．なぜなら，Unicode文字は複数の「符号」を占めることがあるからです．

<!-- You can perform arithmetic and other operations with [`end`](@ref), just like
a normal value: -->
[`end`](@ref)では通常の値と同じように算術演算やその他の操作を行うことができます．:

```jldoctest helloworldstring
julia> str[end-1]
'.': ASCII/Unicode U+002E (category Po: Punctuation, other)

julia> str[end÷2]
' ': ASCII/Unicode U+0020 (category Zs: Separator, space)
```

<!-- Using an index less than `begin` (`1`) or greater than `end` raises an error: -->
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

<!-- You can also extract a substring using range indexing: -->
レンジインデックスを用いて部分文字列を取り出すことができます．:

```jldoctest helloworldstring
julia> str[4:9]
"lo, wo"
```

<!-- Notice that the expressions `str[k]` and `str[k:k]` do not give the same result: -->
`str[k]` と `str[k:k]` は同じ結果にならないことに注意してください．:

```jldoctest helloworldstring
julia> str[6]
',': ASCII/Unicode U+002C (category Po: Punctuation, other)

julia> str[6:6]
","
```

<!-- The former is a single character value of type `Char`, while the latter is a string value that
happens to contain only a single character. In Julia these are very different things. -->
前者は `Char` 型の1文字の値で，後者は1文字しか含まない文字列の値です．
後者は，たまたま1文字しか含まれていない文字列値です．Juliaではこれらは全く異なるものです．

<!-- Range indexing makes a copy of the selected part of the original string.
Alternatively, it is possible to create a view into a string using the type [`SubString`](@ref),
for example: -->
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
<!-- 
Several standard functions like [`chop`](@ref), [`chomp`](@ref) or [`strip`](@ref)
return a [`SubString`](@ref). -->
[`chop`](@ref)，[`chomp`](@ref)，[`strip`](@ref)のようないくつかの標準的な関数は，[`SubString`](@ref)を返します．

## [Unicode と UTF-8](@id Unicode and UTF-8)

<!-- Julia fully supports Unicode characters and strings. As [discussed above](@ref man-characters), in character
literals, Unicode code points can be represented using Unicode `\u` and `\U` escape sequences,
as well as all the standard C escape sequences. These can likewise be used to write string literals: -->
JuliaはUnicode文字とその文字列を完全に対応しています．[`上述`](@ref man-characters)のように，文字リテラルでは，Unicodeのコードポイントは，Unicodeの`\u`と`\U`のエスケープシーケンスや，C標準のエスケープシーケンスを使って表現することができます．これらは，文字列リテラルを記述する際にも同様に使用できます．:

```jldoctest unicodestring
julia> s = "\u2200 x \u2203 y"
"∀ x ∃ y"
```

<!-- Whether these Unicode characters are displayed as escapes or shown as special characters depends on your terminal's locale settings and its support for Unicode. String literals are encoded using
the UTF-8 encoding. UTF-8 is a variable-width encoding, meaning that not all characters are encoded in the same number of bytes ("code units"). In UTF-8, ASCII characters — i.e. those with code points less than 0x80 (128) -- are encoded as they are in ASCII, using a single byte, while code points 0x80 and above are encoded using multiple bytes — up to four per character. -->
これらのUnicode文字がエスケープされて表示されるか，特殊文字として表示されるかは，ターミナルのロケール設定とUnicodeの対応状況に依存します．文字列リテラルのエンコードには UTF-8エンコーディングを使用してエンコードされます．UTF-8は可変幅のエンコーディングなので，つまりすべての文字が同じバイト数（「符号」）でエンコードされるわけではありません．UTF-8では，ASCII文字，つまりコードポイントが0x80（128）未満の文字は，ASCIIと同じように1バイトでエンコードされますが，コードポイントが0x80以上の文字は1文字あたり最大4バイトまでの複数バイトでエンコードされます.


<!-- String indices in Julia refer to code units (= bytes for UTF-8), the fixed-width building blocks that
are used to encode arbitrary characters (code points). This means that not every
index into a `String` is necessarily a valid index for a character. If you index into
a string at such an invalid byte index, an error is thrown: -->
Juliaの文字列インデックスは，任意の文字（コードポイント）をエンコードするための固定幅の構成要素である符号（＝UTF-8ではバイト）を指します．つまり，`String`へのすべてのインデックスが，必ずしも文字に対して有効なインデックスではないということです．このような無効なバイトインデックスで文字列を入力した場合，エラーが発生します．:

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

<!-- In this case, the character `∀` is a three-byte character, so the indices 2 and 3 are invalid
and the next character's index is 4; this next valid index can be computed by [`nextind(s,1)`](@ref),
and the next index after that by `nextind(s,4)` and so on. -->
この場合，文字`∀`は3バイト文字なので，インデックス2と3は無効で，次の文字のインデックスは4となります．この次の有効なインデックスは[`nextind(s,1)`](@ref)で計算でき，その次のインデックスは`nextind(s,4)`となります．


<!-- Since `end` is always the last valid index into a collection, `end-1` references an invalid
byte index if the second-to-last character is multibyte. -->
`end`は常にコレクションの最後の有効なインデックスなので、最後から2番目の文字がマルチバイトの場合、`end-1`は無効なバイトインデックスを参照します。


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

<!-- The first case works, because the last character `y` and the space are one-byte characters,
whereas `end-2` indexes into the middle of the `∃` multibyte representation. The correct
way for this case is using `prevind(s, lastindex(s), 2)` or, if you're using that value to index
into `s` you can write `s[prevind(s, end, 2)]` and `end` expands to `lastindex(s)`. -->
最初のケースは，最後の文字 `y` とスペースが1バイト文字であるので動作するのに対し，インデックス`end-2` は `∃` のマルチバイト表現の中央にインデックスを置くので，動作しません．
この場合の正しい方法は，`prevind(s, lastindex(s), 2)`を使うか，`s`へのインデックスにその値を使うのであれば`s[prevind(s, end, 2)]`と書き，`end`は`lastindex(s)`に展開されます．


<!-- Extraction of a substring using range indexing also expects valid byte indices or an error is thrown: -->
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

<!-- Because of variable-length encodings, the number of characters in a string (given by [`length(s)`](@ref))
is not always the same as the last index. If you iterate through the indices 1 through [`lastindex(s)`](@ref)
and index into `s`, the sequence of characters returned when errors aren't thrown is the sequence
of characters comprising the string `s`. Thus we have the identity that `length(s) <= lastindex(s)`,
since each character in a string must have its own index. The following is an inefficient and
verbose way to iterate through the characters of `s`: -->
可変長エンコーディングのため，（[`length(s)`](@ref)で与えられる）文字列の文字数は，最後のインデックスと同じとは限りません． 1から[`lastindex(s)`](@ref)までのインデックスを反復して`s`の文字を参照すると，エラーが発生しなかったときに返される文字列は文字列`s`を構成する文字列となります．このように文字列の各文字にはそれぞれインデックスが必要なので，`length(s) <= lastindex(s)`という恒等式が成り立ちます．以下は，`s`の文字を反復する非効率的で冗長な方法です．


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

<!-- The blank lines actually have spaces on them. Fortunately, the above awkward idiom is unnecessary
for iterating through the characters in a string, since you can just use the string as an iterable
object, no exception handling required: -->
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

<!-- If you need to obtain valid indices for a string, you can use the [`nextind`](@ref) and
[`prevind`](@ref) functions to increment/decrement to the next/previous valid index, as mentioned above.
You can also use the [`eachindex`](@ref) function to iterate over the valid character indices: -->
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

<!-- To access the raw code units (bytes for UTF-8) of the encoding, you can use the [`codeunit(s,i)`](@ref)
function, where the index `i` runs consecutively from `1` to [`ncodeunits(s)`](@ref).  The [`codeunits(s)`](@ref)
function returns an `AbstractVector{UInt8}` wrapper that lets you access these raw codeunits (bytes) as an array. -->
エンコーディングの未加工の符号（UTF-8の場合はバイト）にアクセスするには，[`codeunit(s,i)`](@ref)関数を使います．ここで，インデックス`i`は`1`から[`ncodeunits(s)`](@ref)まで連続しています．[`codeunits(s)`](@ref)関数は`AbstractVector{UInt8}`というラッパーを返すので，これらの未加工の符号（バイト）を配列として利用することができます．

<!-- Strings in Julia can contain invalid UTF-8 code unit sequences. This convention allows to
treat any byte sequence as a `String`. In such situations a rule is that when parsing
a sequence of code units from left to right characters are formed by the longest sequence of
8-bit code units that matches the start of one of the following bit patterns
(each `x` can be `0` or `1`): -->
Juliaの文字列には，無効なUTF-8符号列が含まれることがあります．この規約により，任意のバイト列を `String` として扱うことができます．このような状況では，符号列を左から右に解析する際に，文字は以下のビットパターン（各 `x` は `0` または `1`）のいずれかの開始に一致する，最長の8ビットの符号列によって形成されるというルールがあります．

* `0xxxxxxx`;
* `110xxxxx` `10xxxxxx`;
* `1110xxxx` `10xxxxxx` `10xxxxxx`;
* `11110xxx` `10xxxxxx` `10xxxxxx` `10xxxxxx`;
* `10xxxxxx`;
* `11111xxx`.

<!-- In particular this means that overlong and too-high code unit sequences and prefixes thereof are treated
as a single invalid character rather than multiple invalid characters.
This rule may be best explained with an example: -->
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
<!-- 
We can see that the first two code units in the string `s` form an overlong encoding of
space character. It is invalid, but is accepted in a string as a single character.
The next two code units form a valid start of a three-byte UTF-8 sequence. However, the fifth
code unit `\xe2` is not its valid continuation. Therefore code units 3 and 4 are also
interpreted as malformed characters in this string. Similarly code unit 5 forms a malformed
character because `|` is not a valid continuation to it. Finally the string `s2` contains
one too high code point. -->
文字列 `s` の最初の2つの符号が，空白文字の冗長すぎるエンコーディングを形成していることがわかります．これは無効ですが，文字列では1文字として受け入れられます．次の2つの符号は，3バイトのUTF-8の列の有効な開始を形成します．しかし、5番目の符号(`\xe2`)は有効な値ではありません．したがって，3番目と4番目の符号もこの文字列では不正な文字として解釈されます．同様に，5番目の符号は不正な文字を形成します．最後に，文字列 `s2` には 高すぎるコードポイントが1つ含まれています．

<!-- Julia uses the UTF-8 encoding by default, and support for new encodings can be added by packages.
For example, the [LegacyStrings.jl](https://github.com/JuliaStrings/LegacyStrings.jl) package
implements `UTF16String` and `UTF32String` types. Additional discussion of other encodings and
how to implement support for them is beyond the scope of this document for the time being. For
further discussion of UTF-8 encoding issues, see the section below on [byte array literals](@ref man-byte-array-literals).
The [`transcode`](@ref) function is provided to convert data between the various UTF-xx encodings,
primarily for working with external data and libraries. -->
JuliaはデフォルトではUTF-8エンコーディングを使用しますが，新しいエンコーディングのサポートはパッケージによって追加することができます．例えば，[LegacyStrings.jl](https://github.com/JuliaStrings/LegacyStrings.jl)パッケージでは，`UTF16String`型と`UTF32String`型を実装しています．他のエンコーディングやそのサポートの実装方法についての詳しい説明はこのドキュメントの範囲外となります．またUTF-8エンコーディングの問題については，以下の[`byte array literals`](@ref man-byte-array-literals)の節を参照してください．様々なUTF-xxエンコーディングの間でデータを変換するために，[`transcode`](@ref) 関数が提供されています．主に外部のデータやライブラリを扱うためのものです．

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

<!-- It's important to be aware of potentially dangerous situations such as concatenation of invalid UTF-8 strings.
The resulting string may contain different characters than the input strings,
and its number of characters may be lower than sum of numbers of characters
of the concatenated strings, e.g.: -->
無効なUTF-8文字列の連結など，潜在的に危険な状況に注意することが重要です．結果として得られる文字列には，入力文字列とは異なる文字が含まれている可能性があり，その文字数は，連結された文字列の文字数の合計よりも少ない可能性があります．

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

<!-- This situation can happen only for invalid UTF-8 strings. For valid UTF-8 strings
concatenation preserves all characters in strings and additivity of string lengths. -->
この状況は，無効なUTF-8文字列に対してのみ発生します．有効なUTF-8文字列の場合，連結は文字列内のすべての文字と文字列長の加法性を保持します．

<!-- Julia also provides [`*`](@ref) for string concatenation: -->
また，Juliaには文字列連結のための[`*`](@ref)が用意されています．:

```jldoctest stringconcat
julia> greet * ", " * whom * ".\n"
"Hello, world.\n"
```

<!-- While `*` may seem like a surprising choice to users of languages that provide `+` for string
concatenation, this use of `*` has precedent in mathematics, particularly in abstract algebra. -->
一方，文字列の連結に `+` を提供している言語のユーザーにとっては、`*` は意外な選択に思えるかもしれませんが，`*` の使用は，数学，特に抽象代数では前例があります．

<!-- In mathematics, `+` usually denotes a *commutative* operation, where the order of the operands does
not matter. An example of this is matrix addition, where `A + B == B + A` for any matrices `A` and `B`
that have the same shape. In contrast, `*` typically denotes a *noncommutative* operation, where the
order of the operands *does* matter. An example of this is matrix multiplication, where in general
`A * B != B * A`. As with matrix multiplication, string concatenation is noncommutative:
`greet * whom != whom * greet`. As such, `*` is a more natural choice for an infix string concatenation
operator, consistent with common mathematical use. -->
数学では，`+`は通常、被演算子の順序が問題にならない，*可換*の演算を表します．この例として，行列の加算があります．同じ形の行列 `A` と `B` に対して，`A + B == B + A` となります．対照的に，`*` は一般的に *非可換* 演算を表し，演算子の順序が *重要になります．この例としては，行列の乗算があり，一般的には `A * B != B * A` となります．行列の乗算と同様に，文字列の連結も非可換です．例えば，`greet * whom != whom * greet`となります．このように， 中置記法の文字列連結演算子としては `*` がより自然な選択であり，一般的な数学的使用と一致しています．

<!-- More precisely, the set of all finite-length strings *S* together with the string concatenation operator
`*` forms a [free monoid](https://en.wikipedia.org/wiki/Free_monoid) (*S*, `*`). The identity element
of this set is the empty string, `""`. Whenever a free monoid is not commutative, the operation is
typically represented as `\cdot`, `*`, or a similar symbol, rather than `+`, which as stated usually
implies commutativity. -->
より正確には，すべての有限長の文字列*S*と文字列連結演算子`*`の集合は、[自由モノイド](https://en.wikipedia.org/wiki/Free_monoid) (*S*, `*`)を形成します．この集合の恒等要素は空文字列 `""` です．自由モノイドが可換でない場合，その演算は通常 `+` ではなく``cdot`, `*`, または同様の記号で表されます．


## [文字列補間](@id string-interpolation)
<!-- 
Constructing strings using concatenation can become a bit cumbersome, however. To reduce the need for these
verbose calls to [`string`](@ref) or repeated multiplications, Julia allows interpolation into string literals
using `$`, as in Perl: -->
連結で文字列を構築するのは少々面倒な作業です．そこで，[`string`](@ref)のくどい呼び出しや繰り返しの乗算を減らすために，JuliaではPerlのように，`$`を用いて文字列リテラルに補間することができます．:

```jldoctest stringconcat
julia> "$greet, $whom.\n"
"Hello, world.\n"
```

<!-- This is more readable and convenient and equivalent to the above string concatenation -- the system
rewrites this apparent single string literal into the call `string(greet, ", ", whom, ".\n")`. -->
こちらはより読みやすく便利で，上記の文字列連結と同値です．システムは，この見かけ上の単一の文字列リテラルを呼び出し`string(greet, ", ", whom, ".\n")`に書き換えます．

<!-- The shortest complete expression after the `$` is taken as the expression whose value is to be
interpolated into the string. Thus, you can interpolate any expression into a string using parentheses: -->
$`の後の最も短い完全な式が，文字列に値を補うべき式とみなされます．このように，括弧を使えば，どんな式でも文字列に補間することができます．:

```jldoctest
julia> "1 + 2 = $(1 + 2)"
"1 + 2 = 3"
```

<!-- Both concatenation and string interpolation call [`string`](@ref) to convert objects into string
form. However, `string` actually just returns the output of [`print`](@ref), so new types
should add methods to [`print`](@ref) or [`show`](@ref) instead of `string`. -->
連結や文字列補間では，オブジェクトを文字列に変換するために [`string`](@ref) を呼び出します．しかし，`string`は実際には [`print`](@ref) の出力を返すだけなので，新しい型では`string`の代わりに [`print`](@ref) や [`show`](@ref) のメソッドを追加する必要があります．

<!-- Most non-`AbstractString` objects are converted to strings closely corresponding to how
they are entered as literal expressions: -->
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

<!-- [`string`](@ref) is the identity for `AbstractString` and `AbstractChar` values, so these are interpolated
into strings as themselves, unquoted and unescaped: -->
[`string`](@ref)は`AbstractString`や`AbstractChar`の値と恒等であり，これらは引用符やエスケープされずにそのまま文字列に補間されます．

```jldoctest
julia> c = 'x'
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)

julia> "hi, $c"
"hi, x"
```

<!-- To include a literal `$` in a string literal, escape it with a backslash: -->
リテラル `$` を文字列リテラルに含めるには，バックスラッシュでエスケープします．:

```jldoctest
julia> print("I have \$100 in my account.\n")
I have $100 in my account.
```

## [トリプルクォーテーション付きの文字列リテラル](@id Triple-Quoted String Literals)

<!-- When strings are created using triple-quotes (`"""..."""`) they have some special behavior that
can be useful for creating longer blocks of text. -->
トリプルクォーテーション（`"""...""`）を使って文字列を作成すると，長いテキストブロックを作成するのに便利ないくつかの特別な動作をします．

<!-- First, triple-quoted strings are also dedented to the level of the least-indented line.
This is useful for defining strings within code that is indented. For example: -->
まず，トリプルクォーテーションで囲まれた文字列も、インデントされていない行のレベルに合わせてディデントされます．これは，インデントされたコードの中で文字列を定義するのに便利です．例えば，以下のようになります．:


```jldoctest
julia> str = """
           Hello,
           world.
         """
"  Hello,\n  world.\n"
```

<!-- In this case the final (empty) line before the closing `"""` sets the indentation level. -->
この場合，閉じる側の`"""`の直前の(空白)行がインデントレベルを設定します．

<!-- The dedentation level is determined as the longest common starting sequence of spaces or
tabs in all lines, excluding the line following the opening `"""` and lines containing
only spaces or tabs (the line containing the closing `"""` is always included).
Then for all lines, excluding the text following the opening `"""`, the common starting
sequence is removed (including lines containing only spaces and tabs if they start with
this sequence), e.g.: -->
冒頭の `"""` に続く行と，スペースまたはタブだけを含む行を除いた，すべての行のうち，最も長い先頭のスペースまたはタブ数によってディデンテーション レベルが決定されます（最後の `"""` を含む行は常に含まれます）．<!-- longestではなく,shortestでは？ -->
次に，冒頭の `"""` に続く行を除いたすべての行について，各行先頭の空白やタブが削除されます（スペースとタブだけを含む行を含む），
<!-- 難あり -->

例:

```jldoctest
julia> """    This
         is
           a test"""
"    This\nis\n  a test"
```

<!-- Next, if the opening `"""` is followed by a newline,
the newline is stripped from the resulting string. -->
次に，冒頭の `"""` の後に改行がある場合は結果の文字列から改行が取り除かれます．

```julia
"""hello"""
```

<!-- is equivalent to -->
これは以下と等価です．

```julia
"""
hello"""
```
<!-- but -->
しかし

```julia
"""

hello"""
```

<!-- will contain a literal newline at the beginning. -->
は先頭に改行リテラルを含みます．

Stripping of the newline is performed after the dedentation. For example:
改行の除去は，ディテンデーションの後に行われます．例えば以下のようになります:

```jldoctest
julia> """
         Hello,
         world."""
"Hello,\nworld."
```

Trailing whitespace is left unaltered.
末尾のホワイトスペースはそのまま残されます.

Triple-quoted string literals can contain `"` characters without escaping.
トリプルクォーテーションで囲まれた文字列リテラルには、エスケープせずに `"` 文字を含めることができます．

Note that line breaks in literal strings, whether single- or triple-quoted, result in a newline
(LF) character `\n` in the string, even if your editor uses a carriage return `\r` (CR) or CRLF
combination to end lines. To include a CR in a string, use an explicit escape `\r`; for example,
you can enter the literal string `"a CRLF line ending\r\n"`.
リテラル文字列の改行はリテラルがシングルクオーテーション，トリプルクオーテーションどちらで囲まれていても返り値の改行部分は改行（LF）文字`\n`が入ります．これはエディタがCR文字やCRLFの組み合わせで行を終わらせている場合でも同様です．文字列にCR文字を含めるには，明示的なエスケープを使用します，例えば/リテラル文字列 `"a CRLF line ending\r\n"` を入力します．


## [Common Operations](@id Common Operations)

You can lexicographically compare strings using the standard comparison operators:

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

You can search for the index of a particular character using the
[`findfirst`](@ref) and [`findlast`](@ref) functions:

```jldoctest
julia> findfirst(isequal('o'), "xylophone")
4

julia> findlast(isequal('o'), "xylophone")
7

julia> findfirst(isequal('z'), "xylophone")
```

You can start the search for a character at a given offset by using
the functions [`findnext`](@ref) and [`findprev`](@ref):

```jldoctest
julia> findnext(isequal('o'), "xylophone", 1)
4

julia> findnext(isequal('o'), "xylophone", 5)
7

julia> findprev(isequal('o'), "xylophone", 5)
4

julia> findnext(isequal('o'), "xylophone", 8)
```

You can use the [`occursin`](@ref) function to check if a substring is found within a string:

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

The last example shows that [`occursin`](@ref) can also look for a character literal.

Two other handy string functions are [`repeat`](@ref) and [`join`](@ref):

```jldoctest
julia> repeat(".:Z:.", 10)
".:Z:..:Z:..:Z:..:Z:..:Z:..:Z:..:Z:..:Z:..:Z:..:Z:."

julia> join(["apples", "bananas", "pineapples"], ", ", " and ")
"apples, bananas and pineapples"
```

Some other useful functions include:

  * [`firstindex(str)`](@ref) gives the minimal (byte) index that can be used to index into `str` (always 1 for strings, not necessarily true for other containers).
  * [`lastindex(str)`](@ref) gives the maximal (byte) index that can be used to index into `str`.
  * [`length(str)`](@ref) the number of characters in `str`.
  * [`length(str, i, j)`](@ref) the number of valid character indices in `str` from `i` to `j`.
  * [`ncodeunits(str)`](@ref) number of [code units](https://en.wikipedia.org/wiki/Character_encoding#Terminology) in a string.
  * [`codeunit(str, i)`](@ref) gives the code unit value in the string `str` at index `i`.
  * [`thisind(str, i)`](@ref) given an arbitrary index into a string find the first index of the character into which the index points.
  * [`nextind(str, i, n=1)`](@ref) find the start of the `n`th character starting after index `i`.
  * [`prevind(str, i, n=1)`](@ref) find the start of the `n`th character starting before index `i`.

## [Non-Standard String Literals](@id non-standard-string-literals)

There are situations when you want to construct a string or use string semantics, but the behavior
of the standard string construct is not quite what is needed. For these kinds of situations, Julia
provides [non-standard string literals](@ref). A non-standard string literal looks like a regular
double-quoted string literal, but is immediately prefixed by an identifier, and doesn't behave
quite like a normal string literal.  Regular expressions, byte array literals and version number
literals, as described below, are some examples of non-standard string literals. Other examples
are given in the [Metaprogramming](@ref) section.

## [Regular Expressions](@id Regular Expressions)

Julia has Perl-compatible regular expressions (regexes), as provided by the [PCRE](http://www.pcre.org/)
library (a description of the syntax can be found [here](http://www.pcre.org/current/doc/html/pcre2syntax.html)). Regular expressions are related to strings in two ways: the obvious connection is that
regular expressions are used to find regular patterns in strings; the other connection is that
regular expressions are themselves input as strings, which are parsed into a state machine that
can be used to efficiently search for patterns in strings. In Julia, regular expressions are input
using non-standard string literals prefixed with various identifiers beginning with `r`. The most
basic regular expression literal without any options turned on just uses `r"..."`:

```jldoctest
julia> r"^\s*(?:#|$)"
r"^\s*(?:#|$)"

julia> typeof(ans)
Regex
```

To check if a regex matches a string, use [`occursin`](@ref):

```jldoctest
julia> occursin(r"^\s*(?:#|$)", "not a comment")
false

julia> occursin(r"^\s*(?:#|$)", "# a comment")
true
```

As one can see here, [`occursin`](@ref) simply returns true or false, indicating whether a
match for the given regex occurs in the string. Commonly, however, one wants to know not
just whether a string matched, but also *how* it matched. To capture this information about
a match, use the [`match`](@ref) function instead:

```jldoctest
julia> match(r"^\s*(?:#|$)", "not a comment")

julia> match(r"^\s*(?:#|$)", "# a comment")
RegexMatch("#")
```

If the regular expression does not match the given string, [`match`](@ref) returns [`nothing`](@ref)
-- a special value that does not print anything at the interactive prompt. Other than not printing,
it is a completely normal value and you can test for it programmatically:

```julia
m = match(r"^\s*(?:#|$)", line)
if m === nothing
    println("not a comment")
else
    println("blank or comment")
end
```

If a regular expression does match, the value returned by [`match`](@ref) is a `RegexMatch`
object. These objects record how the expression matches, including the substring that the pattern
matches and any captured substrings, if there are any. This example only captures the portion
of the substring that matches, but perhaps we want to capture any non-blank text after the comment
character. We could do the following:

```jldoctest
julia> m = match(r"^\s*(?:#\s*(.*?)\s*$|$)", "# a comment ")
RegexMatch("# a comment ", 1="a comment")
```

When calling [`match`](@ref), you have the option to specify an index at which to start the
search. For example:

```jldoctest
julia> m = match(r"[0-9]","aaaa1aaaa2aaaa3",1)
RegexMatch("1")

julia> m = match(r"[0-9]","aaaa1aaaa2aaaa3",6)
RegexMatch("2")

julia> m = match(r"[0-9]","aaaa1aaaa2aaaa3",11)
RegexMatch("3")
```

You can extract the following info from a `RegexMatch` object:

  * the entire substring matched: `m.match`
  * the captured substrings as an array of strings: `m.captures`
  * the offset at which the whole match begins: `m.offset`
  * the offsets of the captured substrings as a vector: `m.offsets`

For when a capture doesn't match, instead of a substring, `m.captures` contains `nothing` in that
position, and `m.offsets` has a zero offset (recall that indices in Julia are 1-based, so a zero
offset into a string is invalid). Here is a pair of somewhat contrived examples:

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

It is convenient to have captures returned as an array so that one can use destructuring syntax
to bind them to local variables:

```jldoctest acdmatch
julia> first, second, third = m.captures; first
"a"
```

Captures can also be accessed by indexing the `RegexMatch` object with the number or name of the
capture group:

```jldoctest
julia> m=match(r"(?<hour>\d+):(?<minute>\d+)","12:45")
RegexMatch("12:45", hour="12", minute="45")

julia> m[:minute]
"45"

julia> m[2]
"45"
```

Captures can be referenced in a substitution string when using [`replace`](@ref) by using `\n`
to refer to the nth capture group and prefixing the substitution string with `s`. Capture group
0 refers to the entire match object. Named capture groups can be referenced in the substitution
with `\g<groupname>`. For example:

```jldoctest
julia> replace("first second", r"(\w+) (?<agroup>\w+)" => s"\g<agroup> \1")
"second first"
```

Numbered capture groups can also be referenced as `\g<n>` for disambiguation, as in:

```jldoctest
julia> replace("a", r"." => s"\g<0>1")
"a1"
```

You can modify the behavior of regular expressions by some combination of the flags `i`, `m`,
`s`, and `x` after the closing double quote mark. These flags have the same meaning as they do
in Perl, as explained in this excerpt from the [perlre manpage](http://perldoc.perl.org/perlre.html#Modifiers):

```
i   Do case-insensitive pattern matching.

    If locale matching rules are in effect, the case map is taken
    from the current locale for code points less than 255, and
    from Unicode rules for larger code points. However, matches
    that would cross the Unicode rules/non-Unicode rules boundary
    (ords 255/256) will not succeed.

m   Treat string as multiple lines.  That is, change "^" and "$"
    from matching the start or end of the string to matching the
    start or end of any line anywhere within the string.

s   Treat string as single line.  That is, change "." to match any
    character whatsoever, even a newline, which normally it would
    not match.

    Used together, as r""ms, they let the "." match any character
    whatsoever, while still allowing "^" and "$" to match,
    respectively, just after and just before newlines within the
    string.

x   Tells the regular expression parser to ignore most whitespace
    that is neither backslashed nor within a character class. You
    can use this to break up your regular expression into
    (slightly) more readable parts. The '#' character is also
    treated as a metacharacter introducing a comment, just as in
    ordinary code.
```

For example, the following regex has all three flags turned on:

```jldoctest
julia> r"a+.*b+.*?d$"ism
r"a+.*b+.*?d$"ims

julia> match(r"a+.*b+.*?d$"ism, "Goodbye,\nOh, angry,\nBad world\n")
RegexMatch("angry,\nBad world")
```

The `r"..."` literal is constructed without interpolation and unescaping (except for
quotation mark `"` which still has to be escaped). Here is an example
showing the difference from standard string literals:

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

Triple-quoted regex strings, of the form `r"""..."""`, are also supported (and may be convenient
for regular expressions containing quotation marks or newlines).

The `Regex()` constructor may be used to create a valid regex string programmatically.  This permits using the contents of string variables and other string operations when constructing the regex string. Any of the regex codes above can be used within the single string argument to `Regex()`. Here are some examples:

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

## [Byte Array Literals](@id man-byte-array-literals)

Another useful non-standard string literal is the byte-array string literal: `b"..."`. This
form lets you use string notation to express read only literal byte arrays -- i.e. arrays of
[`UInt8`](@ref) values. The type of those objects is `CodeUnits{UInt8, String}`.
The rules for byte array literals are the following:

  * ASCII characters and ASCII escapes produce a single byte.
  * `\x` and octal escape sequences produce the *byte* corresponding to the escape value.
  * Unicode escape sequences produce a sequence of bytes encoding that code point in UTF-8.

There is some overlap between these rules since the behavior of `\x` and octal escapes less than
0x80 (128) are covered by both of the first two rules, but here these rules agree. Together, these
rules allow one to easily use ASCII characters, arbitrary byte values, and UTF-8 sequences to
produce arrays of bytes. Here is an example using all three:

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

The ASCII string "DATA" corresponds to the bytes 68, 65, 84, 65. `\xff` produces the single byte 255.
The Unicode escape `\u2200` is encoded in UTF-8 as the three bytes 226, 136, 128. Note that the
resulting byte array does not correspond to a valid UTF-8 string:

```jldoctest
julia> isvalid("DATA\xff\u2200")
false
```

As it was mentioned `CodeUnits{UInt8,String}` type behaves like read only array of `UInt8` and
if you need a standard vector you can convert it using `Vector{UInt8}`:

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

Also observe the significant distinction between `\xff` and `\uff`: the former escape sequence
encodes the *byte 255*, whereas the latter escape sequence represents the *code point 255*, which
is encoded as two bytes in UTF-8:

```jldoctest
julia> b"\xff"
1-element Base.CodeUnits{UInt8,String}:
 0xff

julia> b"\uff"
2-element Base.CodeUnits{UInt8,String}:
 0xc3
 0xbf
```

Character literals use the same behavior.

For code points less than `\u80`, it happens that the
UTF-8 encoding of each code point is just the single byte produced by the corresponding `\x` escape,
so the distinction can safely be ignored. For the escapes `\x80` through `\xff` as compared to
`\u80` through `\uff`, however, there is a major difference: the former escapes all encode single
bytes, which -- unless followed by very specific continuation bytes -- do not form valid UTF-8
data, whereas the latter escapes all represent Unicode code points with two-byte encodings.

If this is all extremely confusing, try reading ["The Absolute Minimum Every
Software Developer Absolutely, Positively Must Know About Unicode and Character
Sets"](https://www.joelonsoftware.com/2003/10/08/the-absolute-minimum-every-software-developer-absolutely-positively-must-know-about-unicode-and-character-sets-no-excuses/).
It's an excellent introduction to Unicode and UTF-8, and may help alleviate
some confusion regarding the matter.

## [Version Number Literals](@id man-version-number-literals)

Version numbers can easily be expressed with non-standard string literals of the form [`v"..."`](@ref @v_str).
Version number literals create [`VersionNumber`](@ref) objects which follow the
specifications of [semantic versioning](https://semver.org/),
and therefore are composed of major, minor and patch numeric values, followed by pre-release and
build alpha-numeric annotations. For example, `v"0.2.1-rc1+win64"` is broken into major version
`0`, minor version `2`, patch version `1`, pre-release `rc1` and build `win64`. When entering
a version literal, everything except the major version number is optional, therefore e.g.  `v"0.2"`
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
an upper limit on build versions, e.g.  `VERSION > v"0.2-rc1+"` can be used to mean any version
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
