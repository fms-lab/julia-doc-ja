# [非同期プログラミング](@id man-asynchronous)

プログラムが外界と対話する必要がある場合，例えば，インターネットを介して他のマシンと
通信するような場合，プログラム内の操作は予測できない順序で行われる必要がある場合があります．
例えば，プログラムがファイルをダウンロードする必要があるとします．ダウンロード操作を開始し，
それが完了するのを待つ間に他の操作を行い，ダウンロードしたファイルが利用可能になったら
ダウロードしたファイルを必要とするコードを再開したいとします．この種のシナリオは非同期
プログラミングの領域に該当しますが，（概念的には複数のことが同時に起こるので）並行プログラミングと呼ばれることもあります．

これらのシナリオに対応するために，Juliaは[`Task`](@ref)sを提供しています
（対称的コルーチン，軽量スレッド，協調型マルチタスク，あるいはワンショット連続処理
など，他にもいくつかの名前で知られています）．ある計算作業（実際には特定の関数の実行）
が[`Task`](@ref)として指定された場合，別の[`Task`](@ref)に切り替えることで，その作業を中断
することが可能になります．元の[`Task`](@ref)は後で再開することができ，中断したところから再開されます．最初はこれは関数呼び出しと似ているように見えるかもしれません．しかし2つの重要な
違いがあります．第一に，タスクの切り替えはスペースを使わないので，コールスタックを消費せず
に何度でもタスクを切り替えることができます．第二に，タスク間の切り替えは任意の順序で行う
ことができます．関数呼び出しとは異なり，呼び出された関数は呼び出した関数に制御が戻る前に
実行を終了しなければなりません．

## 基本的な`Task`操作

`Task`は実行される計算作業の単位のハンドルと考えることができます．これは作成・開始・
実行・終了のライフサイクルを持っています．タスクは，実行する0引数関数で，`Task`
コンストラクタを呼び出すか，[`@task`](@ref)マクロを使用して作成されます．

```
julia> t = @task begin; sleep(5); println("done"); end
Task (runnable) @0x00007f13a40c0eb0
```

`@task x`は`Task(()->x)`と等価です．

このタスクは5秒間待ったのち，`done`を表示しますが，まだ実行を開始していません．
準備ができたら[`schedule`](@ref)を呼び出すことでいつでも実行できます．

```
julia> schedule(t);
```

これをREPLで試してみると，`schedule`がすぐに戻ってくるのがわかると思います．
これは実行するタスクの内部キューに単純に`t`を追加するだけだからです．
そして，REPLは次のプロンプトを表示して，さらなる入力を待ちます．
キーボード入力を待つことで，他のタスクを実行する機会を提供するので，その時点で`t`
が開始されます．`t`は[`sleep`](@ref)を呼び出し，タイマを設定して実行を停止します．
他のタスクがスケジュールされている場合は，そのタスクを実行することができます．
5秒後，タイマが作動して`t`が再起動されると，`done`が表示されているのを見ることができます．
`t`はこれで終了されます．

[`wait`](@ref)関数は，他のタスクが終了するまで呼び出したタスクをブロックします．
したがって，例えば，`schedule`だけを呼び出す代わりに，以下を入力すると，次の
入力プロンプトが表示される前に5秒間の一時停止が表示されます．

```
julia> schedule(t); wait(t)
```

これはREPLが先に進む前に`t`が終わるのを待っているからです．

タスクを作成してすぐにスケジュールしたいというのはよくあることなので，
そのために[`@async`](@ref)マクロが用意されています．`@async x`は`schedule(@task x)`
と等価です．

## チャネルとの通信

いくつかの問題では，必要とされる作業の様々な部分は，当然のことながら関数の呼び出しによって関連
づけられてはいません，すなわち必要なジョブの間には，明らかな「呼び出し元」や「呼び出し先」は
存在しません．例えば，あるプロシージャが値を生成し，別のプロシージャが値が消費しているような，
プロデューサ-コンシューマ問題があります．コンシューマは，単純にプロデューサ関数を呼び出して値を
取得することはできません，なぜならプロデューサは生成すべき値を更に多く持っている可能性があり，
まだ返す準備ができていない可能性があるためです．タスクでは，プロデューサとコンシューマは必要に
応じて値を前後に渡しながら，必要なだけ実行することができます．

Juliaはこの問題を解決するために[`Channel`](@ref)メカニズムを提供します．[`Channel`](@ref)とは
FIFOの待ち行列で，複数のタスクが読み書きできるようになっています．

[`put!`](@ref)呼び出しで値を生成するプロデューサタスクを定義してみましょう．値をコンシューム
するには，新しいタスクを実行するようにプロデューサをスケジュールする必要があります．
1-引数関数を引数として受け付ける特殊な[`Channel`](@ref)コンストラクタを使用して，チャネルに
バインドされたタスクを実行することができます．そして，チャネルオブジェクトから繰り返し[`take!`](@ref)することができます．

```jldoctest producer
julia> function producer(c::Channel)
           put!(c, "start")
           for n=1:4
               put!(c, 2n)
           end
           put!(c, "stop")
       end;

julia> chnl = Channel(producer);

julia> take!(chnl)
"start"

julia> take!(chnl)
2

julia> take!(chnl)
4

julia> take!(chnl)
6

julia> take!(chnl)
8

julia> take!(chnl)
"stop"
```

この動作を考える一つの方法は，`producer`が複数回返すことができたということです．
[`put!`](@ref)の呼び出しの間に，プロデューサの実行は中断され，コンシューマが制御を持ちます．

返された[`Channel`](@ref)は，`for`ループ内で反復可能なオブジェクトとして使用することができ，
その場合，ループ変数は生成された全ての値を引き継ぎます．チャネルがクローズされると，ループが終了します．

```jldoctest producer
julia> for x in Channel(producer)
           println(x)
       end
start
2
4
6
8
stop
```

プロデューサでチャネルを明示的に閉じる必要はありませんでした．これは[`Channel`](@ref)を
[`Task`](@ref)にバインドするという行為が，チャネルのオープンライフタイムとタスクのオープンライフタイム
を関連付けているからです．タスクが終了すると，チャネルオブジェクトは自動的に閉じられます．
複数のチャネルをタスクにバインドすることもできますし，その逆も可能です．

[`Task`](@ref)のコンストラクタは，0-引数の関数を期待しますが，タスクにバインドされたチャネルを
生成する[`Channel`](@ref)メソッドは，[`Channel`](@ref)型の1つの引数を受け入れる関数を期待します．
一般的なパターンは，プロデューサがパラメータ化されている場合で，この場合0または1引数の
[anonymous function](@ref man-anonymous-functions)を作成するために，部分的な関数アプリケーションが
必要になります．

[`Task`](@ref)オブジェクトの場合，これは直接または便利なマクロを使用して行うことができます:

```julia
function mytask(myarg)
    ...
end

taskHdl = Task(() -> mytask(7))
# or, equivalently
taskHdl = @task mytask(7)
```

より高度な処理分配パターンを編成するために，[`bind`](@ref)と[`schedule`](@ref)は，
[`Task`](@ref)と[`Channel`](@ref)のコンストラクタと組み合わせて使用し，チャネルのセットと
プロデューサ/コンシューマのタスクのセットを明示的にリンクさせることができます．

### チャネルの詳細

チャネルはパイプとして可視化することができます．言い換えれば書き込み側と読み込み側があります:

  * 異なるタスクの複数のライタが同じチャネルに対して，[`put!`](@ref)を呼び出して，並行に書き込みを行うことができます
  * 異なるタスクの複数のリーダが[`take!`](@ref)を呼び出して，並行にデータを読み込めます．
  * 以下は例です:

    ```julia
    # Given Channels c1 and c2,
    c1 = Channel(32)
    c2 = Channel(32)

    # and a function `foo` which reads items from c1, processes the item read
    # and writes a result to c2,
    function foo()
        while true
            data = take!(c1)
            [...]               # process data
            put!(c2, result)    # write out result
        end
    end

    # we can schedule `n` instances of `foo` to be active concurrently.
    for _ in 1:n
        @async foo()
    end
    ```
  * チャネルは`Channel{T}(sz)`コンストラクタで作成されます．チャネルは`T`型のオブジェクトのみを保持します．タイプが指定されていない場合は，任意のタイプのオブジェクトを保持することができます．`sz`はチャネルに保持できる要素の最大数を指定します．例えば，`Channel(32)`は任意の型のオブジェクトを最大32個保持できるチャネルを作成します．`Channel{MyType}(64)`は`MyType`型のオブジェクトをいつでも最大64個まで保持することができます．
  * [`Channel`](@ref)が空であれば，データが利用可能になるまで，（[`take!`](@ref)呼び出し内の）リーダはブロックします．
  * [`Channel`](@ref)がいっぱいのとき，利用可能なスペースができるまで，（[`put!`](@ref)呼び出し内の）ライタはブロックします．
  * [`isready`](@ref)はチャネル内にオブジェクトが存在するかどうかをテストし，[`wait`](@ref)はオブジェクトが利用可能になるのを待ちます．
  * [`Channel`](@ref)は初期状態ではオープン状態になっています．これは[`take!`](@ref)や[`put!`](@ref)の呼び出しで自由に読み書きできることを意味します．[`close`](@ref)で[`Channel`](@ref)をクローズします．クローズされた[`Channel`](@ref)では，[`put!`](@ref)は失敗します．例えば:

    ```julia-repl
    julia> c = Channel(2);

    julia> put!(c, 1) # `put!` on an open channel succeeds
    1

    julia> close(c);

    julia> put!(c, 2) # `put!` on a closed channel throws an exception.
    ERROR: InvalidStateException("Channel is closed.",:closed)
    Stacktrace:
    [...]
    ```

  * クローズされたチャネル上の[`take!`](@ref)と（値を取得するが削除はしない）[`fetch`](@ref)は，それが空になるまで既存の値を返すことに成功しています．以下は上記の例の続きです:

    ```julia-repl
    julia> fetch(c) # Any number of `fetch` calls succeed.
    1

    julia> fetch(c)
    1

    julia> take!(c) # The first `take!` removes the value.
    1

    julia> take!(c) # No more data available on a closed channel.
    ERROR: InvalidStateException("Channel is closed.",:closed)
    Stacktrace:
    [...]
    ```

タスク間通信にチャネルを使用した簡単な例を考えてみましょう．単一の`jobs`チャネルからデータを処理
するために4つのタスクを開始します．id (`job_id`)で識別されたジョブがチャネルに書き込まれます．
このシミュレーションでは，各タスクは`job_id`を読み込み，ランダムな時間だけ待機し，`job_id`と
シミュレートされた時間のタプルを結果チャネルに書き戻します．最後に全ての`results`が出力されます．

```julia-repl
julia> const jobs = Channel{Int}(32);

julia> const results = Channel{Tuple}(32);

julia> function do_work()
           for job_id in jobs
               exec_time = rand()
               sleep(exec_time)                # simulates elapsed time doing actual work
                                               # typically performed externally.
               put!(results, (job_id, exec_time))
           end
       end;

julia> function make_jobs(n)
           for i in 1:n
               put!(jobs, i)
           end
       end;

julia> n = 12;

julia> @async make_jobs(n); # feed the jobs channel with "n" jobs

julia> for i in 1:4 # start 4 tasks to process requests in parallel
           @async do_work()
       end

julia> @elapsed while n > 0 # print out results
           job_id, exec_time = take!(results)
           println("$job_id finished in $(round(exec_time; digits=2)) seconds")
           global n = n - 1
       end
4 finished in 0.22 seconds
3 finished in 0.45 seconds
1 finished in 0.5 seconds
7 finished in 0.14 seconds
2 finished in 0.78 seconds
5 finished in 0.9 seconds
9 finished in 0.36 seconds
6 finished in 0.87 seconds
8 finished in 0.79 seconds
10 finished in 0.64 seconds
12 finished in 0.5 seconds
11 finished in 0.97 seconds
0.029772311
```

## より多くのタスク操作

タスク操作は[`yieldto`](@ref)と呼ばれる低レベルのプリミティブで構築されています．
`yieldto(task, value)`は現在のタスクを一時停止し，指定された`task`に切り替え，その最後の
[`yieldto`](@ref)呼び出しで指定された`value`を返します．[`yieldto`](@ref)はタスクスタイルの
制御フローをしようするために必要な唯一の操作であることに注意してください，すなわち呼び出して
返すのではなく，常に別のタスクに切り替えているだけなのです．これが，この機能が「対称型コルーチン」
と呼ばれる理由です．それぞれのタスクは同じメカニズムを使って別のタスクへ切り替えたり，別のタスクからきりかえられたりしているということです．

[`yieldto`](@ref)は強力ですが，タスクのほとんどの用途では直接呼び出されません．その理由を考えて
みましょう．現在のタスクから離れて切り替えた場合，どこかの時点で元のタスクに戻りたいと思うでしょうが，
いつ元のタスクに悖るのか，どのタスクが元のタスクに戻るのかを知るには，かなりの調整が必要になります．
例えば，[`put!`](@ref)や[`take!`](@ref)はブロッキング操作で，チャネルのコンテキストで使用される場合，
コンシューマが誰であるのかを記憶するために状態を維持します．[`put!`](@ref)が低レベルの[`yieldto`](@ref)
よりも使いやすいのは，手動でコンシューマタスクを追跡する必要がないからです．

[`yieldto`](@ref)に加えて，タスクを効率的に使うためには，いくつかの基本的な機能が必要です．

  * [`current_task`](@ref)は現在実行されているタスクの参照を取得します．
  * [`istaskdone`](@ref)はタスクが終了したかどうかを検索します．
  * [`istaskstarted`](@ref)はタスクがまだ実行されているかを検索します．
  * [`task_local_storage`](@ref)は現在のタスクに固有のキーバリューストアを操作します．

## タスクとイベント

ほとんどのタスクの切り替えはI/Oリクエストなどのイベントを待つ結果として発生し，Julia Baseに含まれる
スケジューラによって実行されます．スケジューラは実行可能なタスクのキューを保持し，メッセージ到着など
の外部イベントに基づいてタスクを再起動するイベントループを実行します．

イベントを待つための基本的な関数は[`wait`](@ref)です．いくつかのオブジェクトが[`wait`](@ref)を
実装しています．例えば，`Process`オブジェクトが与えらえた時，[`wait`](@ref)はそれが終了するのを
待ちます．[`wait`](@ref)は暗黙の裡に実装されることが多く，例えばデータが利用可能になるのを待つ
ための[`read`](@ref)呼び出しの中で，[`wait`](@ref)が発生することがあります．

これら全ての場合において，[`wait`](@ref)は最終的に，キューイングとタスクの再起動を担当している
[`Condition`](@ref)オブジェクト上で動作します．タスクが[`Condition`](@ref)上で[`wait`](@ref)を
呼び出すと，そのタスクは実行不可能とマークされ，コンディションのキューに追加され，スケジューラに
切り替わります．スケジューラは実行する別のタスクを選択したり，外部イベントの待ち受けをブロックしたり
します．全てがうまくいけば，最終的にはイベントハンドラがその条件の[`notify`](@ref)を呼び出し，
その条件を待っているタスクが再び実行可能になります．

[`Task`](@ref)を呼び出して明示的に作成されたタスクは，はじめはスケジューラに知られていません．
これにより必要に応じて[`yieldto`](@ref)を使って手動でタスクを管理することができます．
しかし，このようなタスクがイベントを待っていても，イベントが発生すると，想定通りに自動的に再起動されます．
