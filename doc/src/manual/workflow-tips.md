# [ワークフローのTips](@id man-workflow-tips)

Juliaを効率的に動作させるためのTipsをご紹介します．

## REPL(Read-Eval-Print Loop)ベースのワークフロー

[The Julia REPL](@ref)で詳しく説明されているように，JuliaのREPLは効率的な対話型ワークフローを促進する様々な機能を提供しています．ここではコマンドラインでの操作を便利にするいくつかのTipsをご紹介します．

### 基本的なエディタ/REPLワークフロー

最も基本的なJuliaのワークフローでは， `julia`のコマンドラインと組み合わせてテキストエディタを使用します． ワークフローの一般的なパターンには以下の要素が含まれます．

  * **Put code under development in a temporary module.** Create a file, say `Tmp.jl`, and include
    within it

    ```julia
    module Tmp
    export say_hello

    say_hello() = println("Hello!")

    # your other definitions here

    end
    ```
  * **Put your test code in another file.** Create another file, say `tst.jl`, which looks like

    ```julia
    include("Tmp.jl")
    import .Tmp
    # using .Tmp # we can use `using` to bring the exported symbols in `Tmp` into our namespace

    Tmp.say_hello()
    # say_hello()

    # your other test code here
    ```

    and includes tests for the contents of `Tmp`.
    Alternatively, you can wrap the contents of your test file in a module, as

    ```julia
    module Tst
        include("Tmp.jl")
        import .Tmp
        #using .Tmp

        Tmp.say_hello()
        # say_hello()

        # your other test code here
    end
    ```

    The advantage is that your testing code is now contained in a module and does not use the global scope in `Main` for
    definitions, which is a bit more tidy.

  * `include` the `tst.jl` file in the Julia REPL with `include("tst.jl")`.

  * **Lather. Rinse. Repeat.** Explore ideas at the `julia` command prompt. Save good ideas in `tst.jl`. To execute `tst.jl` after it has been changed, just `include` it again.

## ブラウザベースのワークフロー

[IJulia](https://github.com/JuliaLang/IJulia.jl)を介して，ブラウザ上からでJulia REPLと対話することも可能です．詳細についてはIJuliaのパッケージをご参照ください．

## Reviseベースのワークフロー

REPLの場合でもIJuliaの場合でも[Revise](https://github.com/timholy/Revise.jl)を用いることで開発体験を向上させることができます．[Reviseのドキュメント](https://timholy.github.io/Revise.jl/stable/)の手順に従い，juliaを起動した際にReviseを起動するように設定するのが一般的です．一度Reviseを設定すると，Reviseは読み込まれたモジュール内のファイルや`includet`でREPLに読み込まれたファイルの変更を追跡します．(`includet`ではなく`include`の場合は追跡しません)．これら追跡されたファイルは編集可能で，変更した内容はjuliaセッションを再起動することなく有効になります．標準的なワークフローはREPLベースのワークフローに似ていますがReviseベースのワークフローでは以下の変更点があります．

1. ロードパスのどこかにあるモジュールにあなたのコードを配置してください．これを実現するためにはいくつかの選択肢がありますが，その中でも特におすすめなのが以下の2つの方法です．

   a. For long-term projects, use
      [PkgTemplates](https://github.com/invenia/PkgTemplates.jl):

      ```julia
      using PkgTemplates
      t = Template()
      generate("MyPkg", t)
      ```
      This will create a blank package, `"MyPkg"`, in your `.julia/dev` directory.
      Note that PkgTemplates allows you to control many different options
      through its `Template` constructor.

      In step 2 below, edit `MyPkg/src/MyPkg.jl` to change the source code, and
      `MyPkg/test/runtests.jl` for the tests.

   b. For "throw-away" projects, you can avoid any need for cleanup
      by doing your work in your temporary directory (e.g., `/tmp`).

      Navigate to your temporary directory and launch Julia, then do the following:

      ```julia
      pkg> generate MyPkg              # type ] to enter pkg mode
      julia> push!(LOAD_PATH, pwd())   # hit backspace to exit pkg mode
      ```
      If you restart your Julia session you'll have to re-issue that command
      modifying `LOAD_PATH`.

      In step 2 below, edit `MyPkg/src/MyPkg.jl` to change the source code, and create any
      test file of your choosing.

2. Develop your package

   *Before* loading any code, make sure you're running Revise: say
   `using Revise` or follow its documentation on configuring it to run
   automatically.

   Then navigate to the directory containing your test file (here
   assumed to be `"runtests.jl"`) and do the following:

   ```julia
   julia> using MyPkg

   julia> include("runtests.jl")
   ```

   You can iteratively modify the code in MyPkg in your editor and re-run the
   tests with `include("runtests.jl")`.  You generally should not need to restart
   your Julia session to see the changes take effect (subject to a few limitations,
   see https://timholy.github.io/Revise.jl/stable/limitations/).
