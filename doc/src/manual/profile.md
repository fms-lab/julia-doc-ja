# [プロファイリング](@id Profiling)

`Profile`は開発者に，コードのパフォーマンスを向上させるためのツールを提供します．
使用すると，実行中のコードを測定し，個々の行にどれだけの時間が費やされているかを理解するのに
役立つ出力を生成します．最も一般的な使用法は，最適化の対象となる「ボトルネック」を特定することです．

`Profile`は「サンプリング」や[statistical profiler](https://en.wiki\
pedia.org/wiki/Profiling_(computer_programming))
として知られているものを実装しています．これは任意のタスクの実行中に定期的にバックトレースを
取ることで動作します．各バックトレースは現在実行中の関数と行番号に加えて，その行につながった
関数呼び出しの完全な連鎖をキャプチャし，現在の実行状態の「スナップショット」となります．

実行時間の多くが特定のコード行の実行に費やされている場合，この行は全てのバックトレースの
セットに頻繁に表示されます．つまり，この行を含む一連の関数呼び出しのコストは，その行が
全てのバックトレースのセットの中で表示される頻度に比例します．

サンプリングプロファイラは，バックトレースが感覚をおいて発生するため，行ごとに完全にカバー
することはできません（デフォルトでは，Unixでは1ms，Windowsでは10msとなっていますが，実際の
スケジューリングはOSの負荷に左右されます）．さらに，後述するように，全ての実行ポイントの
疎なサブセットで収集されるため，サンプリングプロファイラによって収集されたデータは統計的
なノイズの影響を受けます．

これらの制約にも拘わらず，サンプリングプロファイラには大きな強みがあります:

  * タイミング測定のためにコードを変更する必要がありません．
  * サンプリングプロファイラは，Juliaのコアコードや，（オプションで）CやFortranのライブラリをプロファイリングすることができます．
  * 頻繁に実行しないことにより，パフォーマンスへのオーバーヘッドはほとんどなく，プロファイリングを行っている間，コードはほぼネイティブなスピードで実行できます．

これらの理由から，他の方法を検討する前に，組み込みのサンプリングプロファイラを使用してみることをお勧めします．

## 基本的な用法

簡単なテストケースを見てみましょう:

```julia-repl
julia> function myfunc()
           A = rand(200, 200, 400)
           maximum(A)
       end
```

（JuliaのJITコンパイラをプロファイリングしたい場合を除いて）プロファイリングするコードを
はじめに少なくとも一度は実行しておくことをお勧めします．

```julia-repl
julia> myfunc() # run once to force compilation
```

さて，この関数をプロファイリングする準備ができました:

```julia-repl
julia> using Profile

julia> @profile myfunc()
```

プロファイリング結果を見るために，いくつかのグラフィカルブラウザがあります．
ビジュアライザの「ファミリ」の一つは，[FlameGraphs.jl](https://github.com/timholy/FlameGraphs.jl)に
基づいており，各ファミリのメンバは異なるユーザインタフェースを提供しています:
- [Juno](https://junolab.org/)はプロファイルの可視化をビルトインでサポートする完全なIDEです
- [ProfileView.jl](https://github.com/timholy/ProfileView.jl)はGTKをベースにしたスタンドアロンのビジュアライザです
- [ProfileVega.jl](https://github.com/davidanthoff/ProfileVega.jl)はVegaLightを使用しており，Jupyter notebookとうまく統合されています
- [StatProfilerHTML](https://github.com/tkluck/StatProfilerHTML.jl)はHTMLを生成し，いくつかの追加サマリを表示し，Jupyter notebookとの統合も可能です
- [ProfileSVG](https://github.com/timholy/ProfileSVG.jl)はSVGをレンダリングします

プロファイルの可視化のための完全に独立したアプローチとして，外部ツールである`pprof`を
使用する[PProf.jl](https://github.com/vchuravy/PProf.jl)があります．

しかし，ここでは標準ライブラリに付属のテキストベースの表示を使用します:

```julia-repl
julia> Profile.print()
80 ./event.jl:73; (::Base.REPL.##1#2{Base.REPL.REPLBackend})()
 80 ./REPL.jl:97; macro expansion
  80 ./REPL.jl:66; eval_user_input(::Any, ::Base.REPL.REPLBackend)
   80 ./boot.jl:235; eval(::Module, ::Any)
    80 ./<missing>:?; anonymous
     80 ./profile.jl:23; macro expansion
      52 ./REPL[1]:2; myfunc()
       38 ./random.jl:431; rand!(::MersenneTwister, ::Array{Float64,3}, ::Int64, ::Type{B...
        38 ./dSFMT.jl:84; dsfmt_fill_array_close_open!(::Base.dSFMT.DSFMT_state, ::Ptr{F...
       14 ./random.jl:278; rand
        14 ./random.jl:277; rand
         14 ./random.jl:366; rand
          14 ./random.jl:369; rand
      28 ./REPL[1]:3; myfunc()
       28 ./reduce.jl:270; _mapreduce(::Base.#identity, ::Base.#scalarmax, ::IndexLinear,...
        3  ./reduce.jl:426; mapreduce_impl(::Base.#identity, ::Base.#scalarmax, ::Array{F...
        25 ./reduce.jl:428; mapreduce_impl(::Base.#identity, ::Base.#scalarmax, ::Array{F...
```

この表示の各行は，コード内の特定の場所（行番号）を表しています．インデントは関数呼び出しの
入れ子になったシーケンスを示すために使用され，インデントが大きい行は呼び出しのシーケンスの
中でより深い位置にあることを示します．各行の最初の「フィールド」は，*この行またはその行で*
実行された関数のバックトレース（サンプル）の数です．2番目のフィールドはファイル名と行番号，
3番目のフィールドは関数名です．特定の行番号は，Juliaのコードの変更に伴って変更される可能性
があることに注意してください．この例を自分で実行しながら試してみるのが良いでしょう．

この例では，呼び出された最上位の関数が`event.jl`にあることがわかります．これはJuliaを起動
する時にREPLを実行する関数です．`REPL.jl`の97行目を調べると，関数`eval_user_input()`が呼び
出されていることがわかります．これはREPLで入力した内容を評価する関数で，対話的に作業している
ため，[`@profile`](@ref)マクロで行われたアクションを反映しています．

1行目は，`event.jl`の73行目で80個のバックトレースが取られたことを示していますが，この行
自体が「高コスト」だったわけではありません．3行目を見ると，これら80個のバックトレースの
全てが実際に`eval_user_input`への呼び出しの中でトリガされていることなどがわかります．
実際にどの捜査に時間がかかっているのかを知るためには，コールチェインをもっと深く調べる
必要があります．

この出力の最初の「重要な」行はこの行です:

```
52 ./REPL[1]:2; myfunc()
```

`REPL`は`myfunc`をファイルに入れるのではなく，REPL内で`myfunc`を定義した事実を参照します．
もしファイルを使っていたとしたら，これはファイル名を示すことになります．`[1]`は関数`myfunc`
がこのREPLセッションで評価された最初の式であることを示しています．`myfunc()`の2行目には
`rand`への呼び出しが含まれており，この行で発生したバックトレースは（80個中）52個ありました．
その下には，`dSFMT.jl`内の`dsfmt_fill_array_close_open!`への呼び出しがあります．

もう少し下に行くと，以下のようになっています:

```
28 ./REPL[1]:3; myfunc()
```

`myfunc`の3行目には，`maximum`の呼び出しが含まれており，ここで取られたバックトレースは，
（80個中）28個でした．その下に，このタイプの入力データへの`maximum`関数で時間のかかる
操作を実行している`base/reduce.jl`の特定の箇所を見ることができます．

全体的に，乱数の生成は，最大要素を見つけるのに比べて約2倍のコストがかかると仮に結論づける
ことができます．より多くのサンプルを収集することで，この結果の信頼性を高めることができます:

```julia-repl
julia> @profile (for i = 1:100; myfunc(); end)

julia> Profile.print()
[....]
 3821 ./REPL[1]:2; myfunc()
  3511 ./random.jl:431; rand!(::MersenneTwister, ::Array{Float64,3}, ::Int64, ::Type...
   3511 ./dSFMT.jl:84; dsfmt_fill_array_close_open!(::Base.dSFMT.DSFMT_state, ::Ptr...
  310  ./random.jl:278; rand
   [....]
 2893 ./REPL[1]:3; myfunc()
  2893 ./reduce.jl:270; _mapreduce(::Base.#identity, ::Base.#scalarmax, ::IndexLinea...
   [....]
```

一般的に，ある行で`N`個のサンプルを収集した場合，`sqrt(N)`オーダの不確かさが想定されます
（コンピュータが他のタスクでどれくらいビジーかなど他のノイズ源を除く）．このルールの主要
な例外はガベージコレクションで，実行頻度は低いものの，非常に高コストになる傾向があります
（JuliaのガベージコレクタはCで書かれているので，このようなイベントは後述の`C=true`出力
モードを使うか，[ProfileView.jl](https://github.com/timholy/ProfileView.jl)を使うことで
検出することができます）．

これはデフォルトの「ツリー」ダンプを示しています．別の方法として「フラット」ダンプがあり，
ネスティングに依存せずにカウントを蓄積しています．

```julia-repl
julia> Profile.print(format=:flat)
 Count File          Line Function
  6714 ./<missing>     -1 anonymous
  6714 ./REPL.jl       66 eval_user_input(::Any, ::Base.REPL.REPLBackend)
  6714 ./REPL.jl       97 macro expansion
  3821 ./REPL[1]        2 myfunc()
  2893 ./REPL[1]        3 myfunc()
  6714 ./REPL[7]        1 macro expansion
  6714 ./boot.jl      235 eval(::Module, ::Any)
  3511 ./dSFMT.jl      84 dsfmt_fill_array_close_open!(::Base.dSFMT.DSFMT_s...
  6714 ./event.jl      73 (::Base.REPL.##1#2{Base.REPL.REPLBackend})()
  6714 ./profile.jl    23 macro expansion
  3511 ./random.jl    431 rand!(::MersenneTwister, ::Array{Float64,3}, ::In...
   310 ./random.jl    277 rand
   310 ./random.jl    278 rand
   310 ./random.jl    366 rand
   310 ./random.jl    369 rand
  2893 ./reduce.jl    270 _mapreduce(::Base.#identity, ::Base.#scalarmax, :...
     5 ./reduce.jl    420 mapreduce_impl(::Base.#identity, ::Base.#scalarma...
   253 ./reduce.jl    426 mapreduce_impl(::Base.#identity, ::Base.#scalarma...
  2592 ./reduce.jl    428 mapreduce_impl(::Base.#identity, ::Base.#scalarma...
    43 ./reduce.jl    429 mapreduce_impl(::Base.#identity, ::Base.#scalarma...
```

コードに再帰性がある場合，混乱を招く可能性があるのは，「子」関数のある行がバックトレースの
総数よりも多くのカウントを蓄積する可能性があるということです．以下の関数定義を見てみましょう:

```julia
dumbsum(n::Integer) = n == 1 ? 1 : 1 + dumbsum(n-1)
dumbsum3() = dumbsum(3)
```

`dumbsum3`をプロファイリングし，それが`dumbsum(1)`で実行している間にバックトレースを取得した
とすると，バックトレースは次のようになります:

```julia
dumbsum3
    dumbsum(3)
        dumbsum(2)
            dumbsum(1)
```

結果的に，この子関数は3つのカウントを取得しますが，親関数は1カウントだけ取得します．
「ツリー」表現はこれをより明確にしてくれますし，この理由から，（他のものと比べて）結果を
表示するための最も便利な方法と言うことができるでしょう．

## 蓄積とクリア

[`@profile`](@ref)の結果はバッファに蓄積されます．複数のコードを[`@profile`](@ref)の下で実行
すると，[`Profile.print()`](@ref)はその結果をまとめたものを表示します．これは非常に便利です
が，時には新たにやり直したいこともあるでしょう．そのような時は，[`Profile.clear()`](@ref)を
使うことができます．

## プロファイル結果表示の制御オプション

[`Profile.print`](@ref)には，これまで説明してきた他にもオプションがあります．宣言の全てを見てみましょう:

```julia
function print(io::IO = stdout, data = fetch(); kwargs...)
```

まず初めに2つの位置指定引数を見て，その後キーワード引数を見てみましょう:

  * `io` -- 結果をファイルなどのバッファに保存することができますが，デフォルトでは`stdout`（コンソール）に出力します．
  * `data` -- 分析したいデータを含みます．デフォルトでは[`Profile.fetch()`](@ref)から取得されますが，これはあらかじめ割り当てられたバッファからバックトレースを取り出します．例えば，プロファイラのプロファイルを作成したい場合には以下のようになります:

    ```julia
    data = copy(Profile.fetch())
    Profile.clear()
    @profile Profile.print(stdout, data) # Prints the previous results
    Profile.print()                      # Prints results from Profile.print()
    ```

キーワード引数には，以下の任意の組み合わせを指定することができます:

  * `format` -- 上で紹介したように，バックトレースを，木構造を示すインデントをつけて（デフォルト，`:tree`）表示するか，インデントなし（`:flat`）で表示するかを決定します．
  * `C` -- `true`の場合，CとFortranコードからのバックトレースを表示します（通常は除外されるものです）．例を`Profile.print(C = true)`をつけて実行してみてください．これはボトルネックの原因がJuliaコードなのか，Cコードなのかを判断するのに非常に役立ちます．`C = true`を設定するとネスティングの解釈性が向上しますが，プロファイルダンプが長くかかるようになります．
  * `combine` -- コードの一部の行には，複数の操作が含まれています．例えば，`s += A[i]`には，配列参照（`A[i]`）と，和演算の両方が含まれています．これらは生成されたマシンコードの別々の行に対応しているため，この行のバックトレース中に2つ以上の異なるアドレスがキャプチャされることがあります．`combine = true`はこれらをまとめて出力します．これはおそらく一般的に必要とされるものですが，`combine = false`とすることで，一意な命令ポインタごとに個別に出力を生成することができます．
  * `maxdepth` -- `:tree`フォーマットで`maxdepth`以上の深さにフレームを制限します．
  * `sortedby` -- `:flat`フォーマットの順序を制御します．`:filefuncline`（デフォルト）ではソース行でソートしますが，`:count`では収集したサンプル数の多い順にソートします．
  * `noisefloor` -- サンプルのヒューリスティックノイズフロア以下にフレームを制御します（`:tree`フォーマットにのみ適用されます）．この値の推奨値は2.0です（デフォルトは0）．このパラメータは，`n <= noisefloor * √N`のサンプルを非表示にします（`n`はこの行のサンプル数，`N`は呼び出し先のサンプル数です．
  * `mincount` -- Limits frames with less than `mincount` occurrences.
  * `mincount` -- 発生回数が`mincount`未満のフレームに制限します．

ファイルや関数の名前は時々（`...`で）丸められ，インデントは先頭の`+n`で丸められます．
ここで`n`は，余裕があれば挿入される余分なスペースの数です．深くネストされている
コードの完全なプロファイルが必要な場合は，[`IOContext`](@ref)の広い`displaysize`を
使ってファイルに保存するのが良いアイデアです．

```julia
open("/tmp/prof.txt", "w") do s
    Profile.print(IOContext(s, :displaysize => (24, 500)))
end
```

## コンフィグ

[`@profile`](@ref)は単にバックトレースを蓄積するだけであり，分析は[`Profile.print()`](@ref)
を呼び出すときに行われます．長時間実行される計算では，バックトレースを保存するために予め
割り当てられたバッファがいっぱいになってしまう可能性が十分にあります．そうなると，
バックトレースは停止しますが，計算は続行されます．結果，重要なプロファイリングデータを
見逃してしまう場合があります（その場合は警告は表示されます）．

以下のようにして，関連するパラメータを取得して，設定することができます:

```julia
Profile.init() # returns the current settings
Profile.init(n = 10^7, delay = 0.01)
```

`n`は格納できる命令ポインタの総数で，デフォルトの値は`10^6`です．一般的なバックトレースが
20命令ポインタだとすると，バックトレースを50000個集めることができ，統計的な不確実性は1%未満
となります．ほとんどのアプリケーションではこれで十分でしょう．

そのため，要求された計算を実行するために，Juliaがスナップショット間に取得する時間量を
設定するための，秒単位で表現される`delay`を修正する必要がある可能性が高くなります．
非常に長く実行されているジョブでは，頻繁にバックトレースを行う必要はないかもしれません．
デフォルトの設定は`delay = 0.001`です．もちろん，遅延を増やすことも減らすこともできます．
しかし遅延がバックトレースに必要な時間と同じくらい（筆者のラップトップでは30マイクロ秒程度）
になると，プロファイリングのオーバーヘッドが大きくなります．

# [メモリ割り当ての解析](@id Memory-allocation-analysis)

性能を向上させるための最も一般的なテクニックの一つは，メモリ割り当てを減らすことです．
総割り当て量は，[`@time`](@ref)と[`@allocated`](@ref)で測定でき，割り当てのトリガとなる
特定の行は，これらの行が発生するガベージコレクションのコストを介してプロファイリングから
推測することができます．しかし，コードの各行で割り当てられたメモリ量を直接測定した方が
効率が良い場合もあります．

行ごとに割り当てを測定するには，コマンドラインオプション`--track-allocation=<setting>`を
つけてJuliaを起動します．その際，`none`（デフォルト．割り当てを測定しない），`user`（
Juliaのコアコード以外の全ての場所でメモリ割り当てを測定する），`all`（Juliaコードの各行
でメモリ割り当てを測定する）を選択できます．割り当てはコンパイルされたコードの各行ごとに
測定されます．Juliaを終了すると，累積結果はファイル名の後に`.mem`が付加されたテキスト
ファイルに書き込まれ，ソースファイルと同じディレクトリに置かれます．各行には，割り当て
られたバイト数の合計が表示されます．[`Coverage` package](https://github.com/JuliaCI/Coverage.jl)
パッケージには，割り当てられたバイト数の順に行を並べ替えるなど，いくつかの基本的な解析
ツールが含まれています．

結果を解釈する際には，いくつかの重要な詳細があります．`user`設定下では，REPLから直接呼び出さ
れた関数の最初の行は，REPLコード自体で発生するイベントに起因する割り当てを示します．さらに
重要なことは，Juliaのコンパイラの多くはJuliaで書かれているため（なおかつコンパイルには通常メ
モリ割り当てを必要とするため），JITコンパイルも割り当てカウントに追加されます．推奨される
手順は，解析したいコマンドを全て実行して強制的にコンパイルし，[`Profile.clear_malloc_data()`](@ref)
を呼び出して全ての割り当てカウンタをリセットすることです．最後に，目的のコマンドを実行し，
Juliaを終了して，`.mem`ファイルの生成をトリガします．

# 外部のプロファイリングツール

現在Juliaは外部プロファイリングツールとして，`Intel VTune`，`OProfile`，`perf`をサポートしています．

選択したツールに応じて，`Make.user`内で，`USE_INTEL_JITEVENTS`，`USE_OPROFILE_JITEVENTS`，
`USE_PERF_JITEVENTS`を1に設定してコンパイルしてください．複数のフラグがサポートされています．

Juliaを実行する前に，環境変数`ENABLE_JITPROFILING`を1に設定してください．

これで，これらのツールを使用するための多くの方法が利用できるようになりました．
例えば`OProfile`を使って，単純な記録を試すことができます:

```
>ENABLE_JITPROFILING=1 sudo operf -Vdebug ./julia test/fastmath.jl
>opreport -l `which ./julia`
```

または，`perf`でも同様に以下のようにできます:

```
$ ENABLE_JITPROFILING=1 perf record -o /tmp/perf.data --call-graph dwarf ./julia /test/fastmath.jl
$ perf report --call-graph -G
```

プログラムについて測定できる興味深い項目は他にもたくさんあります．完全なリストを得るためには
[Linuxのperfの例のページ](http://www.brendangregg.com/perf.html)を読んでください．

perfは各実行ごとに`perf.data`ファイルを保存しますが，これは小さなプログラムであっても非常に
大きくなることがあることも覚えておいてください．また，perf LLVMモジュールは`~/.debug/jit`に
一時的にデバッグオブジェクトを保存しますので，こまめにこのフォルダを消去することを覚えて
おいてください．

