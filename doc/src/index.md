```@eval
io = IOBuffer()
release = isempty(VERSION.prerelease)
v = "$(VERSION.major).$(VERSION.minor)"
!release && (v = v*"-$(first(VERSION.prerelease))")
print(io, """
    # Julia $(v) Documentation

    Julia $(v)のドキュメントへようこそ．

    """)
if !release
    print(io,"""
        !!! warning "Work in progress!"
            This documentation is for an unreleased, in-development, version of Julia.
        """)
end
import Markdown
Markdown.parse(String(take!(io)))
```
前回のリリース以降の変更内容については，[リリースノート](NEWS.md)をご覧ください．

```@eval
release = isempty(VERSION.prerelease)
file = release ? "julia-$(VERSION).pdf" :
       "julia-$(VERSION.major).$(VERSION.minor).$(VERSION.patch)-$(first(VERSION.prerelease)).pdf"
url = "https://raw.githubusercontent.com/JuliaLang/docs.julialang.org/assets/$(file)"
import Markdown
Markdown.parse("""
!!! note
    ドキュメントはPDF形式でもご覧いただけます: [$file]($url).

""")
```

### [はじめに](@id man-introduction)

科学技術計算の世界では常に最高の計算性能が要求されてきましたが，これら分野の専門家の多くは静的言語に速度で劣る動的言語を使って日々の仕事を進めています．私たちは動的言語を用いることに多くの利点があることを理解していますし，動的言語を使用する専門家が減ることも期待していません．幸いのことに，最新の言語設計やコンパイラ技術の進歩によって性能と生産性のトレードオフの問題はほとんど解消できており，プロトタイピングに十分な生産性と性能を重視するアプリケーションのデプロイに十分な演算効率を単一の環境で両立することが可能になっています．Juliaは柔軟な動的言語と静的言語に匹敵する性能を両立する科学技術計算に適した言語です．

JuliaのコンパイラはPythonやRなどの言語に使われているインタプリタとは異なるので，最初はJuliaのパフォーマンスは直感に反するかもしれません．もしプログラムの動作が遅いと感じたら他のことを試す前にまずは[Performance Tips](@ref man-performance-tips)セクションを読むことを強くお勧めします．一度Juliaの仕組みを理解すれば，C言語と同等の速さのコードを簡単に書くことができるでしょう．

Juliaはの特徴として，省略可能な型付け，多重ディスパッチ，高パフォーマンスがあります．これらは[Low Level Virtual Machine(LLVM)](https://en.wikipedia.org/wiki/Low_Level_Virtual_Machine)を用いた型推論機能や[Just-In-Time(JIT)コンパイル](https://en.wikipedia.org/wiki/Just-in-time_compilation)により実現されています．また，Juliaは命令型，関数型，オブジェクト指向プログラムの特徴を併せ持つマルチパラダイム言語です．JuliaはRやMATLAB，Pythonなどの言語と同様に高度な数値計算を容易に表現することができます．さらに数値計算だけではなく汎用的なプログラミングもサポートしています．これはJuliaが数学的なプログラミング言語の系譜をベースにしているだけではなく，[Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language))，[Perl](https://en.wikipedia.org/wiki/Perl_(programming_language))，[Python](https://en.wikipedia.org/wiki/Python_(programming_language))，[Lua](https://en.wikipedia.org/wiki/Lua_(programming_language))，[Ruby](https://en.wikipedia.org/wiki/Ruby_(programming_language))などの人気の動的言語の特徴も多く取り入れているからです．

典型的な動的言語とJuliaの主な違いは以下となります．

  * 言語のコア部分は最小限の機能しか提供しません．整数演算のような基本的な処理を含む標準ライブラリもはJulia自身により実装されています．
  * オブジェクトの作成や説明に使用可能な型に関する豊富な機能を提供します．プログラマ自身で型を宣言することもできます．
  * [多重ディスパッチ](https://en.wikipedia.org/wiki/Multiple_dispatch)により，引数の組み合わせごとに関数の振る舞いを定義できます．
  * それぞれの引数の型ごとに効率的されたコードを自動生成します．
  * C言語のような静的にコンパイルされる言語に近い性能を持ちます．

動的言語は「型がない」と言われることがありますがそんなことはありません．プリミティブであろうとユーザー定義であろうと，すべてのオブジェクトは型を持っています．しかしながら，ほとんどの動的言語では型宣言が存在せず，コンパイラに型を指示すること，明示的に型を定義することができません．一方，静的言語ではコンパイラのために型注釈をつけることができますが，型の情報はコンパイル時にしか存在せず，実行時に操作したり表現したりすることはできません．Juliaでは，型自体が実行時のオブジェクトであり，コンパイラに対して情報を伝えるために使用することもできます．

カジュアルなプログラマにとって型や多重ディスパッチを使用することはそれほどないかもしれませんが，これら機能はJuliaの中核を担っています．例えば，関数はさまざまな引数の組み合わせで定義されており，実行時にはそれら組み合わせの中で最も一致する定義が適用されます．この方式は数値計算に適していると言えます．というのも，従来のオブジェクト指向におけるディスパッチのように第一引数が操作を「所有」することは不自然です．Juliaでは演算子は特殊な表記法を持つ単なる関数にすぎません．ユーザー定義のデータ型に可算処理を拡張するには，`+` 関数に新しいメソッドを定義します．こうすることでJuliaでは，既存のコードを新たなデータ型にシームレスに適用させることができます．

実行時型推論の機能やjuliaプロジェクト開始当初から性能へ注力した結果として，Juliaの計算効率は他の動的言語を凌駕し静的にコンパイルされた言語にも匹敵しています．計算機で処理されるデータ量は，過去数十年にわたりムーアの法則に合わせて増え続けており，大規模数値計算における計算性能は，これまでも，これからも，そしておそらく未来においても重要な問題になるでしょう．

Juliaはこれまでの言語では成し得ていない，使いやすさ，力強さ，効率性を1つの言語で実現することを目指しています．
これに加えて，Juliaの利点としては以下のようなものがあります．

  * フリーかつオープンソース ([MIT licensed](https://github.com/JuliaLang/julia/blob/master/LICENSE.md))
  * コンパクトで組み込み型と同等の速度を持つユーザー定義型
  * ベクトル化されていないコードも高速に動作し，コードのベクトル化が不要
  * 並列コンピューティング・分散コンピューティングを意図した設計
  * 軽量で,かつ”greenな”スレッドシステム ([coroutines](https://en.wikipedia.org/wiki/Coroutine))
  * 控えめながらも強力なな型システム
  * 数値およびその他の型に対するエレガントで拡張性のある変換やプロモーション
  * [Unicode](https://en.wikipedia.org/wiki/Unicode)の効率的なサポート
    * [UTF-8](https://en.wikipedia.org/wiki/UTF-8)も含むが，これに限定しません
  * ラッパーや特別なAPIを必要としない，C言語の関数の直接呼び出し
  * プロセスを管理する強力なシェルライクの機能
  * Lispライクなマクロやその他のメタプログラミング機能
