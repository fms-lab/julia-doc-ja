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

While the casual programmer need not explicitly use types or multiple dispatch, they are the core
unifying features of Julia: functions are defined on different combinations of argument types,
and applied by dispatching to the most specific matching definition. This model is a good fit
for mathematical programming, where it is unnatural for the first argument to "own" an operation
as in traditional object-oriented dispatch. Operators are just functions with special notation
-- to extend addition to new user-defined data types, you define new methods for the `+` function.
Existing code then seamlessly applies to the new data types.

Partly because of run-time type inference (augmented by optional type annotations), and partly
because of a strong focus on performance from the inception of the project, Julia's computational
efficiency exceeds that of other dynamic languages, and even rivals that of statically-compiled
languages. For large scale numerical problems, speed always has been, continues to be, and probably
always will be crucial: the amount of data being processed has easily kept pace with Moore's Law
over the past decades.

Julia aims to create an unprecedented combination of ease-of-use, power, and efficiency in a single
language. In addition to the above, some advantages of Julia over comparable systems include:

  * Free and open source ([MIT licensed](https://github.com/JuliaLang/julia/blob/master/LICENSE.md))
  * User-defined types are as fast and compact as built-ins
  * No need to vectorize code for performance; devectorized code is fast
  * Designed for parallelism and distributed computation
  * Lightweight "green" threading ([coroutines](https://en.wikipedia.org/wiki/Coroutine))
  * Unobtrusive yet powerful type system
  * Elegant and extensible conversions and promotions for numeric and other types
  * Efficient support for [Unicode](https://en.wikipedia.org/wiki/Unicode), including but not limited
    to [UTF-8](https://en.wikipedia.org/wiki/UTF-8)
  * Call C functions directly (no wrappers or special APIs needed)
  * Powerful shell-like capabilities for managing other processes
  * Lisp-like macros and other metaprogramming facilities
