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
前回のリリース以降の変更点については，[リリースノート](NEWS.md)をご覧ください．

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

　科学技術計算では常に高速に動作することが求められてる一方で，この分野の専門家の多くは静的型付け言語より低速に動作する動的型付け言語を使って仕事をしています．私達は動的型付け言語を用いることに多くの利点があることを理解していますし，動的型付け言語が使われないようにしたいわけでもありません．幸いなことに，最新の言語設計やコンパイラ技術の進歩により，性能と生産性のトレードオフの問題をほとんど解決することができ，「プロトタイピングに十分な生産性」と「性能を重視するアプリケーションのデプロイに十分な効率性」を単一の環境で両立することが可能になっています．Juliaは「柔軟な動的型付け言語」と「静的型付け言語と同等の性能」を両立する科学技術計算に適した言語です．

JuliaのコンパイラはPythonやRなどの言語に使われているインタプリタとは異なるので，最初はJuliaのパフォーマンスは直感に反するかもしれません．もし何か遅いと感じたら他のことを試す前にまずは[Performance Tips](@ref man-performance-tips)を読むことを強くお勧めします．一度Juliaの仕組みを理解すれば，C言語とほぼ同じ速さのコードを簡単に書くことができるでしょう．

Juliaは省略可能な型付け，多重ディスパッチ，高パフォーマンスを特徴としています．これらは[Low Level Virtual Machine(LLVM)](https://en.wikipedia.org/wiki/Low_Level_Virtual_Machine)を用いた型推論機能や[Just-In-Time(JIT)コンパイル](https://en.wikipedia.org/wiki/Just-in-time_compilation)を実装することにより実現されています．また，Juliaは命令型，関数型，オブジェクト指向プログラムの特徴を組み合わせたマルチパラダイム言語です．JuliaはRやMATLAB，Pythonなどの言語と同様に高度な数値計算を容易に表現することができます．さらに数値計算だけではなく汎用的なプログラミングもサポートしています．これはJuliaが数学的なプログラミング言語の系譜をベースにしているだけではなく，[Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language))，[Perl](https://en.wikipedia.org/wiki/Perl_(programming_language))，[Python](https://en.wikipedia.org/wiki/Python_(programming_language))，[Lua](https://en.wikipedia.org/wiki/Lua_(programming_language))，[Ruby](https://en.wikipedia.org/wiki/Ruby_(programming_language))などの人気な動的型付け言語の特徴も多く取り入れているからです．

The most significant departures of Julia from typical dynamic languages are:

  * The core language imposes very little; Julia Base and the standard library are written in Julia itself, including
    primitive operations like integer arithmetic
  * A rich language of types for constructing and describing objects, that can also optionally be
    used to make type declarations
  * The ability to define function behavior across many combinations of argument types via [multiple dispatch](https://en.wikipedia.org/wiki/Multiple_dispatch)
  * Automatic generation of efficient, specialized code for different argument types
  * Good performance, approaching that of statically-compiled languages like C

Although one sometimes speaks of dynamic languages as being "typeless", they are definitely not:
every object, whether primitive or user-defined, has a type. The lack of type declarations in
most dynamic languages, however, means that one cannot instruct the compiler about the types of
values, and often cannot explicitly talk about types at all. In static languages, on the other
hand, while one can -- and usually must -- annotate types for the compiler, types exist only at
compile time and cannot be manipulated or expressed at run time. In Julia, types are themselves
run-time objects, and can also be used to convey information to the compiler.

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
