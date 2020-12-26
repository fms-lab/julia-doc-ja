# [Multi-Threading](@id man-multithreading)

Juliaのマルチスレッディング機能の説明はこちらの[blog post](https://julialang.org/blog/2019/07/multithreading/)をご覧ください．

## Starting Julia with multiple threads

デフォルトでは，Juliaは単一の実行スレッドで起動します．これは[`Threads.nthreads()`](@ref)コマンドを
使用して確認することができます．

```julia-repl
julia> Threads.nthreads()
1
```

実行スレッド数は，コマンドライン引数`-t`/`--threads`を用いるか，環境変数[`JULIA_NUM_THREADS`](@ref JULIA_NUM_THREADS)
を用いるかのいずれかで制御します．両方が指定された場合は，`-t`/`--threads`が優先されます．

!!! "Julia 1.5"互換性
    コマンドライン引数`-t`/`--threads`はJulia 1.5以上のバージョンで利用できます．古いバージョンでは代わりに環境変数を用いる必要があります．

4つのスレッドでJuliaを起動してみましょう:

```bash
$ julia --threads 4
```

4つのスレッドが立っていることを確認してみましょう．

```julia-repl
julia> Threads.nthreads()
4
```

しかし，現在はマスタスレッド上にいます．これを確認するには[`Threads.threadid`](@ref)を使います．

```julia-repl
julia> Threads.threadid()
1
```

!!! note
    環境変数を用いたいときには，Bash (Linux/macOS)では以下のように設定できます:
    ```bash
    export JULIA_NUM_THREADS=4
    ```
    Linux/macOS上のC shellや，Windows上のCMDでは以下のようにします:
    ```bash
    set JULIA_NUM_THREADS=4
    ```
    Windows上のPowershellでは以下のようにします:
    ```powershell
    $env:JULIA_NUM_THREADS=4
    ```
	これはJuliaを起動する*前*に行わねばならないことに注意してください．

!!! note
    `-t`/`--threads`で指定されたスレッド数は，コマンドラインオプション`-p`/`--procs`または`--machine-file`を使用して生成されたワーカプロセスへ伝搬されます．例えば，`julia -p2 -t2`を実行すると，1つのメインプロセスと2つのワーカプロセスを生成し，これら3つのプロセスは全て2つのスレッドを有効にしています．ワーカスレッドをより細かく制御するには，[`addprocs`](@ref)を使用し，`-t`/`--threads`を`exeflags`として渡します．

## データ競合の自由

あなたのプログラムがデータ競合フリーであることを保証するのはあなたの全責任であり，
その要件を守らなければ，ここで約束されたことは何も想定できません．観察された結果は
非常に直観的ではないかもしれません．

これを確実にする最善の方法は，複数のスレッドから観測できるデータへのアクセスの周りのロックを取得することです．
例えば，ほとんどの場合，次のようなコードパターンを使用する必要があります．

```julia-repl
julia> lock(a) do
           use(a)
       end

julia> begin
           lock(a)
           try
               use(a)
           finally
               unlock(a)
           end
       end
```

さらに，データ競合が発生した場合，Juliaはメモリセーフではありません．他のスレッドが
グローバル変数（またはクロージャ変数）に書き込む可能性がある場合，その読み込みには十分に
注意してください．代わりに，複数のスレッドから見えるデータ（グローバルへの代入など）を
変更する場合は，常に上記のロックパターンを使用してください．

```julia
Thread 1:
global b = false
global a = rand()
global b = true

Thread 2:
while !b; end
bad(a) # it is NOT safe to access `a` here!

Thread 3:
while !@isdefined(a); end
use(a) # it is NOT safe to access `a` here
```

## `@threads` マクロ

ネイティブスレッドを使って，簡単な例を作ってみましょう．ゼロの配列を作ってみましょう:

```jldoctest
julia> a = zeros(10)
10-element Array{Float64,1}:
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
```

この配列を4つのスレッドを使って同時に操作してみましょう．各スレッドにはそれぞれの場所にスレッドIDを書き込ませます．

Juliaは[`Threads.@threads`](@ref)マクロを使って並列ループをサポートしています．このマクロは`for`ループの前につけて，
そのループがマルチスレッド領域であることをJuliaに示すためのものです:

```julia-repl
julia> Threads.@threads for i = 1:10
           a[i] = Threads.threadid()
       end
```

イテレーションスペースはスレッド間で分割され，各スレッドは割り当てられた場所にスレッドIDを書き込みます:

```julia-repl
julia> a
10-element Array{Float64,1}:
 1.0
 1.0
 1.0
 2.0
 2.0
 2.0
 3.0
 3.0
 4.0
 4.0
```

[`Threads.@threads`](@ref)には[`@distributed`](@ref)のような，リダクションのオプションパラメータはないことに注意してください．

## アトミックな操作

Juliaでは，[race conditions](https://en.wikipedia.org/wiki/Race_condition)を避けるために，スレッドセーフな方法で，
値へのアクセスや変更を*アドミックに行うこと*をサポートしています．ある値（プリミティブ型でなければならない）を
[`Threads.Atomic`](@ref)としてラップすることで，この方法でアクセスしなければならないことを示すことができます．
ここではその例を見てみましょう:

```julia-repl
julia> i = Threads.Atomic{Int}(0);

julia> ids = zeros(4);

julia> old_is = zeros(4);

julia> Threads.@threads for id in 1:4
           old_is[id] = Threads.atomic_add!(i, id)
           ids[id] = id
       end

julia> old_is
4-element Array{Float64,1}:
 0.0
 1.0
 7.0
 3.0

julia> ids
4-element Array{Float64,1}:
 1.0
 2.0
 3.0
 4.0
```

アトミックタグを使わずに足し算をしようとしていたら，競合条件のために，間違った答えが
出ていたかもしれません．競合を回避しなかった場合の例は以下の通りです:

```julia-repl
julia> using Base.Threads

julia> nthreads()
4

julia> acc = Ref(0)
Base.RefValue{Int64}(0)

julia> @threads for i in 1:1000
          acc[] += 1
       end

julia> acc[]
926

julia> acc = Atomic{Int64}(0)
Atomic{Int64}(0)

julia> @threads for i in 1:1000
          atomic_add!(acc, 1)
       end

julia> acc[]
1000
```

!!! note
    全てのプリミティブ型が`Atomic`タグでサポートされているわけではありません．サポートしてされているのは，
    `Int8`，`Int16`，`Int32`，`Int64`，`Int128`，`UInt8`，`UInt16`，`UInt32`,
    `UInt64`，`UInt128`，`Float16`，`Float32`，および`Float64`です． 付け加えると，
    `Int128`と`UInt128`はAAarch32やppc64le上ではサポートされていません.

## 副作用と変更可能な関数の引数

マルチスレッディングを使用する際に，[pure](https://en.wikipedia.org/wiki/Pure_function)でない
関数を使用する場合には，誤った答えを得る可能性があるため，注意が必要です．
例えば，コンベンションで[name ending with `!`](@ref bang-convention)を持つ関数は，引数を変更してしまうので，pureではありません．

## @threadcall

[`ccall`](@ref)経由で呼び出されるような外部ライブラリは，JuliaのタスクベースI/Oメカニズム
に問題をもたらします．Cライブラリがブロッキング操作を行うと，その呼び出しが戻るまで，Julia
スケジューラが他のタスクを実行できなくなります．（例外は，カスタムCコードへの呼び出しが
Juliaにコールバックして，[`yield`](@ref)を返す場合，またはCコードへの呼び出しが，[`yield`](@ref)と等価な
`jl_yield()`を呼び出す場合です．）

[`@threadcall`](@ref)マクロはこのようなシナリオでの実行の停止を回避する方法を提供します．
これはC関数を別々のスレッドで実行するようにスケジュールします．これにはデフォルトのサイズが4の
スレッドプールが使用されます．スレッドプールのサイズは環境変数`UV_THREADPOOL_SIZE`で制御されます．
空いているスレッドを待っている間，およびスレッドが利用可能になった後の関数実行中，要求するタスクは
（メインのJuliaイベントループ上で）他のタスクにyieldします．実行が完了するまで`@threadcall`は
返らないことに注意してください．ユーザの視点から見ると，他のJulia APIのようなブロッキング呼び出しになります．

呼び出された関数がセグメンテーションフォルトを起こすため，呼び出された関数がJuliaにコールバックしないことは非常に重要です．

`@threadcall`は将来のJuliaのバージョンで削除/変更される可能性があります．

## 警告事項

現時点では，ユーザコードがデータ競合の無いものであれば，Juliaランタイムと標準
ライブラリのほとんどの操作はスレッドセーフな方法で使用できます．しかし，いくつか
の分野では，スレッドのサポートを安定化させるための作業が進行中です．マルチスレッド
プログラミングには多くの固有の難しさがあり，スレッドを使用したプログラムが異常な
動作や望ましくない動作（クラッシュや不可解な結果など）を示す場合には，一般的には
スレッドの相互作用を最初に疑うべきです．

Juliaでスレッドを使用する際に注意すべき制限と警告がいくつかあります:

  * 基本的なコレクションの型は，少なくとも1つのスレッドがコレクションを変更する複数のスレッドで同時に使用された場合，手動でロックする必要があります（よくある例としては，配列への`push!`や`Dict`へのアイテムの挿入などがあります）．
  * タスクが特定のスレッドで実行を開始した後（例えば`@spawn`経由など），ブロックしたあとは常に同じスレッドで再起動されます．将来的にはこの制限は取り除かれ，タスクはスレッド間で移行するようになるでしょう．
  * `@threads`は現在，静的なスケジュールを使用しており，全てのスレッドを使用し，各スレッドに等しい反復回数を割り当てています．将来的には，デフォルトのスケジュールは動的なものに変更される可能性があります．
  * `@spawn`によって使用されるスケジュールは非決定的なものであり，これに頼るべきではありません．
  * 計算に縛られた，メモリを割り当てないタスクは，メモリを割り当てている他のスレッドでガベージコレクションが実行されるのを防ぐことができます．これらのケースでは，GCの実行を許可するために`GC.safepoint()`への手動呼び出しを挿入する必要があるかもしれません．この制限は将来的には削除される予定です．
  * 型，メソッド，モジュール定義の`include`や`eval`などのトップレベルの操作を並行して実行しないようにしてください．
  * Be aware that finalizers registered by a library may break if threads are enabled.
    This may require some transitional work across the ecosystem before threading
    can be widely adopted with confidence. See the next section for further details.
  * スレッドが有効になっている場合，ライブラリによって登録されたファイナライザが壊れる可能性があることに注意してください．これはスレッド化が自信を持って広く採用されるようになるまでは，エコシステム全体での移行作業が必要になるかもしれません．詳細は次のセクションを参照してください．

## ファイナライザのセーフな利用方法

ファイナライザはどのようなコードにも割り込むことができるので，どのようにグローバルな
状態と相互作用するかについては非常に注意しなければなりません．残念ながら，ファイナライザが
使われる主な理由はグローバル状態を更新するためです（pureな関数は一般的にファイナライザとしては
無意味です）．これはちょっとした難問です．この問題に対処するためのアプローチはいくつかあります:

1. シングルスレッドの場合，コードは内部の`jl_gc_enable_finalizers` C関数を呼び出して，クリティカルな領域内でファイナライザがスケジュールされるのを防ぐことができます．内部的には，特定の操作（インクリメンタルパッケージの読み込みやcodegenなど）を行う際の再帰を防ぐために，いくつかの関数（C locksなど）の内部て使用されています．ロックとこのフラグを組み合わせることで，ファイナライザをセーフにすることができます．

2. Baseがいくつかの場所で採用している第二の戦略は，再帰的ではないロックを取得できるようになるまでファイナライザを明示的に遅延させることです．次の例は，この戦略がどのように`Distributed.finalize_ref`に適用されるかを示しています:

   ```
   function finalize_ref(r::AbstractRemoteRef)
       if r.where > 0 # Check if the finalizer is already run
           if islocked(client_refs) || !trylock(client_refs)
               # delay finalizer for later if we aren't free to acquire the lock
               finalizer(finalize_ref, r)
               return nothing
           end
           try # `lock` should always be followed by `try`
               if r.where > 0 # Must check again here
                   # Do actual cleanup here
                   r.where = 0
               end
           finally
               unlock(client_refs)
           end
       end
       nothing
   end
   ```

3. 関連する第三の戦略は，yield-freeなキューを使うことです．現在のところBaseではロックフリーなキューは実装されていませんが，`Base.InvasiveLinkedListSynchronized{T}`が適しています．これはイベントループを持つコードに使うと良い戦略になることがあります．例えば，この戦略は`Gtk.jl`でライフタイムのref-countingを管理するために採用されています．このアプローチでは，`finalizer`の内部では明示的な作業は行わず，代わりにキューに追加して，セーフな時間に実行させています．実際，Juliaのタスクスケジューラは既にこれらを使用しているので，ファイナライザを`x -> @spawn do_cleanup(x)`と定義するのは，このアプローチの一例です．しかしこれは`do_cleanup`がどのスレッドで実行されるかを制御しないので，`do_cleanup`はロックを取得する必要があることに注意してください．自分自身のキューを実装している場合は，そのキューを明示的に自分のスレッドからのみ排出することができるので，これを満たしていなくてもかまいません．
