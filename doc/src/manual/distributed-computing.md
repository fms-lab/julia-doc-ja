# 複数プロセス処理と分散計算

分散メモリ型の並列計算の実装は，Julia同梱の標準ライブラリの一部として`Distributed`モジュールによって提供されます．

ほとんどの現代の計算機は2つ以上のCPUを搭載しており，クラスタ内で複数の計算機をまとめて用いることができます．
これらの複数CPUの力を使いこなすことで，より多くの計算をより高速に行うことが可能となります．
性能に影響を及ぼすのは2つの大きな要因があります: CPUのスピードそのものと，CPUがメモリへアクセスする速度です．
クラスタにおいては，ある特定のCPUが同じコンピュータ（ノード）内のRAMに最速でアクセスできることはほぼ自明です．
おそらくもっと驚くべきことに，メインメモリと[キャッシュ](https://www.akkadia.org/drepper/cpumemory.pdf)の速度
が異なることが原因で，同様の問題が一般的なマルチコアラップトップにも関連してきます．
したがって，優れたマルチプロセシング環境では，特定のCPUによってメモリチャンクの「所有権」を制御できるべきです．
Juliaはメッセージパッシングに基づいてマルチプロセシング環境を提供し，別々のメモリドメイン内の複数プロセス上で
プログラムを一度に実行することを可能にします．


Juliaのメッセージパッシングの実装は，MPI[^1]などほかの環境とは異なるものとなっています．
Julia内の通信は一般的には「一方向的(one-sided)」です，すなわちプログラマは2プロセスの操作の内，1つのプロセス
のみを明示的に管理する必要があります．さらには，これらの操作は典型的には「メッセージ送信」や「メッセージ受信」
のようには見えず，ユーザ関数を呼び出すような高レベルな操作に似たものとなります．

Juliaにおける分散計算は，2つのプリミティブによって構成されます: *リモートリファレンス*と*リモートコール*です．
リモートリファレンスは，任意のプロセスから，特定のプロセスに格納されているオブジェクトを参照するために使うことができるものです．リモートコールは1つのプロセスによるリクエストで，別の（同じでも良い）プロセス上で関数と引数を指定しながら呼び出すためのものです．

リモートリファレンスには2つのフレーバーがあります: [`Future`](@ref Distributed.Future) and [`RemoteChannel`](@ref)です．

リモートコールは，[`Future`](@ref Distributed.Future)をその結果に返します．リモートコールは直ちに結果を返します，
すなわちリモート呼び出しが別の場所で発生している間に，呼び出しを行ったプロセスは次の操作に進みます．
あなたはリモートコールが終わるのを[`wait`](@ref)を返される[`Future`](@ref Distributed.Future)上で呼ぶことで待つことができ，
また[`fetch`](@ref)を用いて結果のすべての値を取得することができます．


一方で，[`RemoteChannel`](@ref)は上書き可能です．例えば，複数のプロセスが同じリモートの`Channel`を参照することにより
それらの処理を組み合わせることができます．


各プロセスは識別子を持ちます．インタラクティブなJuliaプロンプトを提供するプロセスは常に1という`id`を持ちます．
並列操作に用いられるプロセスはデフォルトでは「ワーカ」として参照されます．プロセスが一つだけの時は，プロセス1が
ワーカとしてとらえられます．そうでない場合は，ワーカはプロセス1以外のすべてのプロセスであるととらえられます．
結果として，[`pmap`](@ref)のような並列処理メソッドから恩恵を得るためには，2つ以上のプロセスが必要となります．
長い計算がワーカ上で実行されている間にメインプロセスで他のことをやらせたい場合は，シングルプロセスを1つ足すことで恩恵を得られます．

これを試してみましょう．`julia -p n`で始めると，`n`はローカルマシン上にn個のワーカプロセスを提供します．
一般的に`n`はマシン上のCPUスレッド数（論理コア数）と同じにするのが理にかなっています．`-p`引数は，暗黙の内に
`Distributed`モジュールをロードすることに注意してください．

```julia
$ ./julia -p 2

julia> r = remotecall(rand, 2, 2, 2)
Future(2, 1, 4, nothing)

julia> s = @spawnat 2 1 .+ fetch(r)
Future(2, 1, 5, nothing)

julia> fetch(s)
2×2 Array{Float64,2}:
 1.18526  1.50912
 1.16296  1.60607
```

[`remotecall`](@ref)の第一引数は呼び出される関数です．Juliaにおける並列プログラミングのほとんどは，
特定のプロセスや利用可能なプロセス数を参照しませんが，[`remotecall`](@ref)はより細かい制御を
提供する低レベルのインタフェースと考えられています．[`remotecall`](@ref)の第二引数は処理を行う
プロセスの`id`で，残りの引数は呼び出される関数に渡されます．

1行目ではプロセス2に2x2のランダム行列を構築するように求め，2行目ではこれに1を加えるように求めていることが
見て取れます．両方の計算結果は，2つのフューチャ，`r`と`s`で利用可能です．[`@spawnat`](@ref)マクロは，
第一引数で指定されたプロセス上で第二引数内の表現を評価します．

リモートで計算された値がすぐに必要になることがあるかもしれません．これは典型的には，次のローカル操作で必要な
データを取得するために，リモートオブジェクトから読み出しを行う時に起こります．この目的のために，[`remotecall_fetch`](@ref)
関数が存在します．これは`fetch(remotecall(...))`と等価ですが，より効率的です．


```julia-repl
julia> remotecall_fetch(getindex, 2, r, 1, 1)
0.18526337335308085
```

[`getindex(r,1,1)`](@ref)は`r[1,1]`と[equivalent](@ref man-array-indexing)であるため，この呼び出しはフューチャ`r`の
最初の要素をフェッチすることを覚えておいてください．

より簡単にするために，シンボル`:any`を[`@spawnat`]に渡すことができ，これにより操作を行う場所を選択します．

```julia-repl
julia> r = @spawnat :any rand(2,2)
Future(2, 1, 4, nothing)

julia> s = @spawnat :any 1 .+ fetch(r)
Future(3, 1, 5, nothing)

julia> fetch(s)
2×2 Array{Float64,2}:
 1.38854  1.9098
 1.20939  1.57158
```

ここで，私たちが`1 .+ r`ではなく，`1 .+ fetch(r)`を用いていることに注意してください．これはコードがどこで
実行されるのかを知ることができないため，一般的には，加算を行うプロセスに`r`を移動させるのに[`fetch`](@ref)が
必要になる場合があるからです．この場合，[`@spawnat`](@ref)は`r`を所有しているプロセス上で計算を実行するのに
十分賢いので，[`fetch`](@ref)はno-opです（処理は行われません）．

（[`@spawnat`](@ref)は組み込みではなく，Juliaで[macro](@ref man-macros)として定義されているのは注記に値します．
このような構造体を独自に定義することも可能です．）

覚えておくべき重要なことは，一度フェッチされると，[`Future`](@ref Distributed.Future)はその値をローカルにキャッシュする
ということです．さらなる[`fetch`](@ref)の呼び出しは，ネットワークホップを必要としません．すべての参照する
[`Future`](@ref Distributed.Future)sをフェッチされると，リモートに格納されている値は削除される．

[`@async`](@ref)は[`@spawnat`](@ref)と似ていますが，ローカルプロセス上でしかタスクを動かしません．
これを使って，各プロセスに「フィーダ」タスクを作成します．各タスクは計算が必要な次のインデックスを指定し，
そのプロセスが終了するのを待ち，インデックスが無くなるまでこれを繰り返します．メインタスクが[`@sync`](@ref)の
最終ブロック，すなわち制御を放棄し関数から戻る前にすべてのローカルタスクが完了するのを末ポイントに到達するまで，
フィーダタスクは実行を開始しないことに注意してください．
v0.7以降では，フィーダタスクは，すべて同じプロセス上で実行されるため，`nextidx`を介して状態を共有することが
できます．`Task`が協調的にスケジュールされていたとしても，[asynchronous I/O](@ref faq-async-io)のように，
コンテキストによってはロックが必要になる場合があります．
これは，コンテキストスイッチは良く定義されたポイント，この場合は [`remotecall_fetch`](@ref)が呼ばれた時のみ発生する
ことを意味します．これは現在の実装の状態であり，将来のJuliaのバージョンでは，M個の`Process`上でN個まで`Tasks`を実行
する，[M:N Threading](https://en.wikipedia.org/wiki/Thread_(computing)#Models)を可能にするために変更される
可能性があります．その場合，複数のプロセスに同時に単一のリソースへの読み書きを行わせるのはセーフでないため，
`nextidx`用のロック獲得/再解放モデルが必要になります．


## [コードの利用可能性とパッケージの読み込み](@id code-availability)

あなたのコードは，それを実行する全てのプロセスで利用可能でなければなりません．例えば，
Juliaプロンプトに以下のように入力します:

```julia-repl
julia> function rand2(dims...)
           return 2*rand(dims...)
       end

julia> rand2(2,2)
2×2 Array{Float64,2}:
 0.153756  0.368514
 1.15119   0.918912

julia> fetch(@spawnat :any rand2(2,2))
ERROR: RemoteException(2, CapturedException(UndefVarError(Symbol("#rand2"))
Stacktrace:
[...]
```

プロセス1は関数`rand2`を知っていましたが，プロセス2は知りませんでした．

ほとんどの場合，あなたはファイルやパッケージからコードをロードすることになりますが，どのプロセスが
コードをロードするのかはかなり柔軟に制御することができます．以下のようなコードを含む`DummyModule.jl`
というファイルを考えてみましょう:

```julia
module DummyModule

export MyType, f

mutable struct MyType
    a::Int
end

f(x) = x^2+1

println("loaded")

end
```

全てのプロセスにわたって`MyType`を参照するためには，全てのプロセスで`DummyModule.jl`をロードする
必要があります．`include("DummyModule.jl")`を呼び出すと，単一のプロセス上でのみロードされます．
全てのプロセスでロードするには，[`@everywhere`](@ref)マクロを使用します．(`julia -p 2`でJuliaを開始します．):

```julia-repl
julia> @everywhere include("DummyModule.jl")
loaded
      From worker 3:    loaded
      From worker 2:    loaded
```

いつものように，これは`DummyModule`をどのプロセスのスコープにも入れません，`using`または`import`を
必要とします．さらに，`DummyModule`を1つのプロセスのスコープに入れると，他のプロセスではスコープに入れません:

```julia-repl
julia> using .DummyModule

julia> MyType(7)
MyType(7)

julia> fetch(@spawnat 2 MyType(7))
ERROR: On worker 2:
UndefVarError: MyType not defined
⋮

julia> fetch(@spawnat 2 DummyModule.MyType(7))
MyType(7)
```

しかしながら，例えば，スコープに入っていないとしても，`DummyModule`をロードしたプロセスに
`MyType`を送ることは可能です．

```julia-repl
julia> put!(RemoteChannel(2), MyType(7))
RemoteChannel{Channel{Any}}(2, 1, 13)
```

`-L`フラグを使って起動時に複数のプロセスにファイルをプリロードしたり，ドライバスクリプトを
使って計算を駆動したりすることもできます:

```
julia -p <n> -L file1.jl -L file2.jl driver.jl
```

上の例のドライバスクリプトを実行しているJuliaプロセスは，対話型プロンプトを提供するプロセスと
同じように`id`として1を持ちます．

最後に，`DummyModule.jl`がスタンドアロンファイルではなくパッケージである場合，`using DummyModule`
は全てのプロセスで`DummyModule.jl`を_ロード_しますが，`using`が呼ばれたプロセスでのみスコープに入ります．

## ワーカプロセスの開始と管理

基本となるJuliaのインストールでは，2種類のクラスタがサポートされています:

  * 上で示した通り，`-p`オプションで指定されたローカルクラスタ．
  * `--machine-file`オプションを使ったマシンをまたいだクラスタ．これはパスワードなしの`ssh`ログインを
	使用して，指定されたマシン上で（現在のホストと同じパスから）Juliaワーカプロセスを起動します．

[`addprocs`](@ref), [`rmprocs`](@ref), [`workers`](@ref)などの関数が，クラスタ内のプロセスを追加，
削除，クエリするためのプログラム的な手段として利用できます．

```julia-repl
julia> using Distributed

julia> addprocs(2)
2-element Array{Int64,1}:
 2
 3
```

モジュール`Distributed`は[`addprocs`](@ref)を呼び出す前に，マスタプロセス上で明示的にロードされなければなりません．
ワーカプロセス上では自動的に利用可能になります．

ワーカは`~/.julia/config/startup.jl`スタートアップスクリプトを実行せず，またワーカはグローバル状態
（グローバル変数，新しいメソッド定義，ロードされたモジュール）を他の実行中のプロセスと同期させません．
特定の環境でワーカを初期化するために，`addprocs(exeflags="--project")`を使用し，その後`@everywhere using <modulename>`
または`@everywhere include("file.jl")`を使用することができます．

他のタイプのクラスタは，以下の[ClusterManagers](@ref)で説明されているように，独自のカスタム`ClusterManager`
を書くことでサポートすることができます．

## データ移動

メッセージの送信とデータの移動は，分散プログラムのオーバーヘッドの大部分を占めています．
メッセージの数と送信されるデータの量を減らすことは，パフォーマンスとスケーラビリティを達成するために非常に重要です．
この目的のために，Juliaの様々な分散プログラミング構造によって実行されるデータ移動を理解することが重要です．

考えることができます．[`@spawnat`](@ref)（といくつかの関連する構造）もデータを移動しますが，これは明らかではないので，
暗黙のデータ移動操作と呼ぶことができます．ランダム行列を構築して二乗するための2つのアプローチを考えてみましょう:

メソッド1:

```julia-repl
julia> A = rand(1000,1000);

julia> Bref = @spawnat :any A^2;

[...]

julia> fetch(Bref);
```

メソッド2:

```julia-repl
julia> Bref = @spawnat :any rand(1000,1000)^2;

[...]

julia> fetch(Bref);
```

これらの違いは些細なように見えますが，実際には[`@spawnat`](@ref)の振る舞いによってかなり大きな違いがあります．
1つめのメソッドでは，ランダム行列が局所的に構築され，別のプロセスに送られて二乗されます．2つめのメソッドでは，
ランダム行列は，別のプロセスで構築も二乗もされます．ゆえに，2つめのメソッドは1つめのメソッドよりもはるかに少ないデータを送信します．

このおもちゃの例では，この2つの方法は簡単に区別して選択することができます．しかし，実際のプログラムでは，
データ移動の設計をするにはより多くの考えが必要であり，おそらく何らかの測定が必要になる場合があります．
例えば，1つめのプロセスが行列`A`を必要とする場合，1つめのメソッドが良いかもしれません．あるいは，`A`の
計算コストが高く現在のプロセスだけがそれを持っている場合は，他のプロセスへの移動は避けられないかもしれません．
あるいは，現在のプロセスが[`@spawnat`](@ref)と`fetch(Bref)`の間にほとんど何もしない場合には，並列性を完全に
排除した方が良いかもしれません．あるいは，`rand(1000,1000)`がより計算コストのかかる処理に置き換えられることを
想像してみてください．その場合，このステップのためだけに，別の[`@spawnat`](@ref)文を追加するのが理にかなっている
かもしれません．

## グローバル変数
`@spawnat`経由でリモート実行される式や，`remotecall`を使ってリモートで実行するために指定されたクロージャは，
グローバル変数を参照することがあります．`Main`モジュールの下のグローバルバインディングは，
他のモジュールのグローバルバインディングとは少し違った扱いになります．以下のコードスニペットを考えてみましょう:

```julia-repl
A = rand(10,10)
remotecall_fetch(()->sum(A), 2)
```

この場合，[`sum`](@ref)はリモートプロセスで定義されなければなりません．`A`はローカルのワークスペースで定義された
グローバル変数であることに注意してください．ワーカ2は`Main`の下に`A`という変数を持っていません．クロージャ`()->sum(A)`
をワーカ2に送る行為は`Main.A`がワーカ2に定義される結果となります．`remotecall_fetch`の呼び出しがリターンされた後も，
ワーカ2の上に`Main.A`は存在し続けます．グローバル参照が埋め込まれたリモート呼び出し（`Main`モジュールの下でのみ）は，
以下のようにグローバルを管理します:

- リモートコールの一部といして参照されている場合，宛先ワーカに新しいグローバルバインディングが作成されます

- グローバル定数はリモートノード上でも定数として宣言されます．

- グローバル変数が宛先ワーカに再送信されるのは，リモート呼び出しのコンテキストのみで，その値が変更された
  場合のみです．また，クラスタはノード間でグローバルバインディングを同期化しません．例えば以下のようになります:

  ```julia
  A = rand(10,10)
  remotecall_fetch(()->sum(A), 2) # worker 2
  A = rand(10,10)
  remotecall_fetch(()->sum(A), 3) # worker 3
  A = nothing
  ```

  上記のスニペットを実行すると，ワーカ2の`Main.A`はワーカ3の`Main.A`とは異なる値を持ち，
  ノード1の`Main.A`の値は何も設定されません．

お気付きかもしれませんが，マスタ上で再割り当てられたされたときにグローバルに関連付けられたメモリが収集される
場合がありますが，バインディングが有効であり続けるため，ワーカにはそのようなアクションは実行されません．
[`clear!`](@ref)を使用すると，リモートのノード上の特定のグローバルが不要になったら，手動でそれらを`nothing`へ
再割り当てすることができます．これにより，通常のガベージコレクションサイクルの一部として，それらに関連付けられた
メモリが解放されます．

したがって，プログラムはリモート呼び出しの際のグローバルの参照に注意する必要があります．実際には，可能であれば
完全に避けることが望ましいです．グローバルを参照する必要がある場合は，グローバル変数をローカライズするために，
`let`ブロックを使用することを検討してください．


以下は例です:

```julia-repl
julia> A = rand(10,10);

julia> remotecall_fetch(()->A, 2);

julia> B = rand(10,10);

julia> let B = B
           remotecall_fetch(()->B, 2)
       end;

julia> @fetchfrom 2 InteractiveUtils.varinfo()
name           size summary
––––––––– ––––––––– ––––––––––––––––––––––
A         800 bytes 10×10 Array{Float64,2}
Base                Module
Core                Module
Main                Module
```

このように，グローバル変数`A`はワーカ2上で定義されていますが，`B`はローカル変数として捉えられているため，
ワーカ2上には`B`のバインディングが存在しません．


## 並列マップとループ

幸いなことに多くの有用な並列計算はデータ移動を必要としません．一般的な例としては，
複数のプロセスが独立したシミュレーション試行を同時に処理することができるモンテカルロシミュレーションがあります．
ここでは，[`@spawnat`](@ref)を使って，2つのプロセスでコインを反転させることができます．まず，`count_heads.jl`に
以下のような関数を書きます:

```julia
function count_heads(n)
    c::Int = 0
    for i = 1:n
        c += rand(Bool)
    end
    c
end
```

関数`count_heads`は，単純に`n`個のランダムビットを加算します．ここでは，2つのマシンでいくつかの
試行を行い，その結果を足し合わせる方法を示します．

```julia-repl
julia> @everywhere include_string(Main, $(read("count_heads.jl", String)), "count_heads.jl")

julia> a = @spawnat :any count_heads(100000000)
Future(2, 1, 6, nothing)

julia> b = @spawnat :any count_heads(100000000)
Future(3, 1, 7, nothing)

julia> fetch(a)+fetch(b)
100001564
```

この例は，今日六でよく使われる並列プログラミングパターンを示しています．多くの反復処理はいくつかの
プロセスで独立して実行され，その結果が何らかの関数を使って結合されます．
この組み合わせのプロセスは*reduction*と呼ばれます，なぜならそれは一般的にtensor-rank-reducingだからです: 
あるベクトルが1つの数に削減されたり，行列が1つの行や列に削減されたりすることから，こう呼びます．
コードでは，これは通常，`x = f(x,v[i])`というパターンのように見えます．ここで`x`はアキュムレータ，
`f`はリダクション関数，`v[i]`はリデュースされる要素です．演算がどのような順序で実行されても問題ないように，
`f`は結合律を満たしていることが望ましいです．

`count_heads`でのこのパターンの使用は一般化できることに注意してください．2つの明示的な[`@spawnat`](@ref)文を
使用しているので，並列処理は2つのプロセスに制限されています．任意の数のプロセスで実行するためには，
分散メモリで実行する*parallel for loop*を使うことができ，これはJuliaでは[`@distributed`](@ref)を
使って以下のように書くことができます:

```julia
nheads = @distributed (+) for i = 1:200000000
    Int(rand(Bool))
end
```

この構文は複数のプロセスに反復処理を割り当て，指定されたリダクション（ここでは`(+)`）と組み合わせるパターンを
実装しています．各反復の結果は，ループ内の最後の式の値として取られます．並列ループ全体の式自体は，
最終的な答えとして評価されます．


並列ループはシリアルループのように見えますが，動作は劇的に異なることに注意してください．特に，
反復は指定された順序では行われず，変数や配列への書き込みは，反復が異なるプロセスで実行されるため，
グローバルには表示されません．並列ループ内で使用される変数は全てコピーされ，各プロセスにブロードキャストされます．

例えば，以下のようなコードは意図通りには動きません:

```julia
a = zeros(100000)
@distributed for i = 1:100000
    a[i] = i
end
```

このコードでは，各プロセスが個別のコピーを持つことになるので，全ての`a`を初期化することはできません．
このようなループのための並列化は避けなければなりません．幸いなことに，[Shared Arrays](@ref man-shared-arrays)
を使うことで，この制限を回避することができます:

```julia
using SharedArrays

a = SharedArray{Float64}(10)
@distributed for i = 1:10
    a[i] = i
end
```

変数が読み取り専用であれば，並列ループで「外部」変数を使用するのは完全に合理的です:

```julia
a = randn(1000)
@distributed (+) for i = 1:100000
    f(a[rand(1:end)])
end
```

ここでは，各反復処理は，全ての処理で共有されるベクトル`a`からランダムに選択されたサンプルに対して`f`を適用します．

ここで見た通り，リダクション演算子は必要なければ省略することができます．その場合，ループは非同期に実行される．
つまり，利用可能な全てのワーカ上で独立したタスクを生成し，完了を待たずに直ちに[`Future`](@ref Distributed.Future)の
配列を返します．呼び出し元は，[`Future`](@ref Distributed.Future)の完了を後のポイントで[`fetch`](@ref)を呼び出すことで
待つか，ループの最後に`@sync @distributed for`のように[`@sync`](@ref)を接頭辞としてつけることにより完了を待つことができる．

場合によってはリダクション演算子は必要とされず，ある範囲の全ての整数（またはより一般的には，あるコレクションの全ての要素）
に関数を適用したいだけの場合もあります．これは*parallel map*と呼ばれるもう一つの便利な操作で，Juliaでは
[`pmap`](@ref)関数として実装されています．例えば，以下のようにいくつかの大きな乱数行列の特異値を並列に計算することができます:

```julia-repl
julia> M = Matrix{Float64}[rand(1000,1000) for i = 1:10];

julia> pmap(svdvals, M);
```

Juliaの[`pmap`](@ref)は各関数呼び出しが大量の作業を行う場合のために設計されています．
対照的に`@distributed for`は，それぞれの反復が小さなもので，おそらく2つの数値を合計するだけのような状況を
扱うことができます．[`pmap`](@ref)と`@distributed for`は並列計算のためにワーカプロセスのみを使用します．
`@distributed for`を使う場合には，最終的なリダクションは呼び出したプロセスで行われます．

## リモートリファレンスとアブストラクトチャネル

リモートリファレンスは常に`AbstractChannel`の実装を参照します．

（`Channel`のような）`AbstractChannel`の具体的な実装は[`put!`](@ref)，[`take!`](@ref)， [`fetch`](@ref)，
[`isready`](@ref)および[`wait`](@ref)を実装するのに必要とされます．
[`Future`](@ref Distributed.Future)によって参照されるリモートオブジェクトは，`Channel{Any}(1)`，すなわち
`Any`タイプのオブジェクトを保持することのできるサイズ1の`Channel`に格納されます．

[`RemoteChannel`](@ref)は上書き可能ですが，任意の型やサイズのチャネル，あるいは`AbstractChannel`の
他の実装を指定することができます．

コンストラクタ`RemoteChannel(f::Function, pid)()`を使用すると，特定の型の複数の値を保持するチャネルへの
参照を作成することができます．`f`は`pid`上で実行される関数であり，`AbstractChannel`を返さなければなりません．

例えば，`RemoteChannel(()->Channel{Int}(10), pid)`はInt型でサイズ10のチャネルへの参照を返します．
このチャネルはワーカ`pid`上に存在します．

[`RemoteChannel`](@ref)上のメソッド[`put!`](@ref)，[`take!`](@ref)，[`fetch`](@ref)，[`isready`](@ref)および[`wait`](@ref)
は，リモートプロセス上のバッキングストアにプロキシされます．

このように，[`RemoteChannel`](@ref)はユーザが実装した`AbstractChannel`オブジェクトを参照するために
使用することができます．この単純な例は，[Examples repository](https://github.com/JuliaAttic/Examples)
の`dictchannel.jl`で提供されており，リモートストアとして辞書を使用しています．


## チャネルとリモートチャネル

  * [`Channel`](@ref)はプロセスに対してローカルなものです．ワーカ2がワーカ3の[`Channel`](@ref)を直接参照することはできません
が，[`RemoteChannel`](@ref)はワーカ間で値を入れたり出したりすることができます．
  * [`RemoteChannel`](@ref)は[`Channel`](@ref)の*handle*と考えることができます．
  * [`RemoteChannel`](@ref)に関連付けられたプロセスid`pid`は，バッキングストアが存在するプロセス
	言い換えるとバッキング[`Channel`](@ref)が存在するプロセスを識別します．
  * [`RemoteChannel`](@ref)への参照を持つ全てのプロセスは，チャネルからアイテムを入れたり出したりできます．
	データは[`RemoteChannel`](@ref)が関連付けられているプロセスに自動的に送信されます（またはそこから取得されます）．
  * [`Channel`](@ref)をシリアライズすると，チャネル内に存在する全てのデータもシリアライズされます．そのため，
	チャネルをデシリアライズすると，元のオブジェクトのコピーが効果的に作成されます．
  * 一方，[`RemoteChannel`](@ref)をシリアライズすると，ハンドルが参照している[`Channel`](@ref)の場所とインスタンス
	を識別する識別子のシリアライズのみが行われます．したがって，（任意のワーカ上の）デシリアライズされた
	[`RemoteChannel`](@ref)オブジェクトはオリジナルと同じバッキングストアを指すことになります

上記のチャネルの例は，以下のようにプロセス間通信のために変更することができます．

単一の`jobs`リモートチャネルを処理するために4つのワーカを起動します．Jobsは`job_id`によって識別され，
そのチャネルに書き込まれます．このシミュレーションでは各リモート実行タスクは`job_id`を読み込み，
ランダムな時間だけ待機し，`job_id`，かかった時間，自身の`pid`のタプルを結果チャネルに書き戻します．
最後に，全ての結果がマスタプロセスに出力されます．

```julia-repl
julia> addprocs(4); # add worker processes

julia> const jobs = RemoteChannel(()->Channel{Int}(32));

julia> const results = RemoteChannel(()->Channel{Tuple}(32));

julia> @everywhere function do_work(jobs, results) # define work function everywhere
           while true
               job_id = take!(jobs)
               exec_time = rand()
               sleep(exec_time) # simulates elapsed time doing actual work
               put!(results, (job_id, exec_time, myid()))
           end
       end

julia> function make_jobs(n)
           for i in 1:n
               put!(jobs, i)
           end
       end;

julia> n = 12;

julia> @async make_jobs(n); # feed the jobs channel with "n" jobs

julia> for p in workers() # start tasks on the workers to process requests in parallel
           remote_do(do_work, p, jobs, results)
       end

julia> @elapsed while n > 0 # print out results
           job_id, exec_time, where = take!(results)
           println("$job_id finished in $(round(exec_time; digits=2)) seconds on worker $where")
           global n = n - 1
       end
1 finished in 0.18 seconds on worker 4
2 finished in 0.26 seconds on worker 5
6 finished in 0.12 seconds on worker 4
7 finished in 0.18 seconds on worker 4
5 finished in 0.35 seconds on worker 5
4 finished in 0.68 seconds on worker 2
3 finished in 0.73 seconds on worker 3
11 finished in 0.01 seconds on worker 3
12 finished in 0.02 seconds on worker 3
9 finished in 0.26 seconds on worker 5
8 finished in 0.57 seconds on worker 4
10 finished in 0.58 seconds on worker 2
0.055971741
```

### リモートリファレンスと分散ガベージコレクション

リモートリファレンスによって参照されるオブジェクトはクラスタ内で保持されている*全ての*参照が
削除されたときにのみ解放されることができます．

値が格納されているノードは，どのワーカがその値への参照を持っているかを追跡します．
[`RemoteChannel`](@ref)や（フェッチされていない）[`Future`](@ref Distributed.Future)がワーカにシリアライズされるたびに，
参照先のノードが通知されます．また，[`RemoteChannel`](@ref)や（フェッチされていない）[`Future`](@ref Distributed.Future)が
ローカルでガベージコレクションされるたびに，値を所有するノードは再度通知される．これは内部クラスタを意識した
シリアライザで実装されています．リモート参照は実行中のクラスタのコンテキストでのみ有効です．通常の`IO`オブジェクトへの，
または通常の`IO`オブジェクトからの参照のシリアライズとデシリアライズはサポートされていません．

この通知は参照が別のプロセスにシリアライズされた場合は，「参照を追加」メッセージ，参照がローカルで
ガベージコレクションされた場合には「参照を削除」メッセージという「トラッキングメッセージ」の送信によって
行われます．

[`Future`](@ref Distributed.Future)は一度限りの書き込みでローカルにキャッシュされるので，
[`Future`](@ref Distributed.Future)を[`fetch`](@ref)する行為は，値を所有しているノードの参照トラッキング情報も更新する．

値を所有しているノードは，値への全ての参照がクリアされると，値を解放します．

[`Future`](@ref Distributed.Future)では，オリジナルのリモートストアがこの時点までに値を収集している場合があるので，
すでに別のノードへフェッチされた[`Future`](@ref Distributed.Future)をシリアライズした時も値を送信します．

オブジェクトが*いつ*ローカルでガベージコレクションされるのかが，オブジェクトのサイズとシステム内の
現在のメモリプレッシャに依存することに注意することは重要です．

リモートリファレンスの場合，ローカルリファレンスオブジェクトのサイズはかなり小さいですが，リモートノードに
格納されている値はかなり大きいかもしれません．ローカルオブジェクトはすぐに収集されない可能性があるので，
[`RemoteChannel`](@ref)のローカルインスタンスや，フェッチされていない[`Future`](@ref Distributed.Future)に
対して明示的に[`finalize`](@ref)を呼び出すのが良い方法です．[`Future`](@ref Distributed.Future)に対して，
[`fetch`](@ref)を呼び出すと，リモートストアからの参照も削除されるので，フェッチされた[`Future`](@ref Distributed.Future)sに
対してはこれは必要ありません．明示的に[`finalize`](@ref)を呼び出すと，リモートノードに値への参照を削除するための
即時メッセージが送信されます．

一度ファイナライズされると，参照は無効になり，それ以降の呼び出しでは使用できなくなります．

## ローカルな呼び出し

実行のためにデータは必然敵にリモートノードにコピーされる．これはリモートコールの場合と，
データが別のノードの[`RemoteChannel`](@ref) / [`Future`](@ref Distributed.Future)に格納されている場合の両方に当てはまる．
予想通り，これはリモートノード上のシリアライズされたオブジェクトのコピーになります．しかし，宛先ノードが
ローカルノードである場合，つまり呼び出し元のプロセスIDがリモートノードIDと同じである場合は，ローカルコールとして
実行されます．通常は（常にではありませんが）別のタスクで実行されますが，データのシリアライズ/デシリアライズは
行われません．その結果，コールは渡されたものと同じオブジェクトインスタンスを参照します，この時コピーは作成されません．
この動作を以下に示します．

```julia-repl
julia> using Distributed;

julia> rc = RemoteChannel(()->Channel(3));   # RemoteChannel created on local node

julia> v = [0];

julia> for i in 1:3
           v[1] = i                          # Reusing `v`
           put!(rc, v)
       end;

julia> result = [take!(rc) for _ in 1:3];

julia> println(result);
Array{Int64,1}[[3], [3], [3]]

julia> println("Num Unique objects : ", length(unique(map(objectid, result))));
Num Unique objects : 1

julia> addprocs(1);

julia> rc = RemoteChannel(()->Channel(3), workers()[1]);   # RemoteChannel created on remote node

julia> v = [0];

julia> for i in 1:3
           v[1] = i
           put!(rc, v)
       end;

julia> result = [take!(rc) for _ in 1:3];

julia> println(result);
Array{Int64,1}[[1], [2], [3]]

julia> println("Num Unique objects : ", length(unique(map(objectid, result))));
Num Unique objects : 3
```

見て取られるように，ローカルに所有されている[`RemoteChannel`](@ref)に呼び出しの間に修正された
同一のオブジェクト`v`を[`put!`](@ref)すると，同じ単一のオブジェクトインスタンスが格納されます．
これは，`rc`を所有しているノードが別のノードである場合に`v`のコピーが作成されるのとは対照的です．

これは一般的には問題ではないことに注意してください．これは，オブジェクトがローカルに保存されている場合と，
呼び出し後に変更されている場合にのみ考慮すべきことです．そのような場合は，オブジェクトの`deepcopy`を
保存するのが適切かもしれません．

これは，次の例のようにローカルノード上のリモートコールにも当てはまります:

```julia-repl
julia> using Distributed; addprocs(1);

julia> v = [0];

julia> v2 = remotecall_fetch(x->(x[1] = 1; x), myid(), v);     # Executed on local node

julia> println("v=$v, v2=$v2, ", v === v2);
v=[1], v2=[1], true

julia> v = [0];

julia> v2 = remotecall_fetch(x->(x[1] = 1; x), workers()[1], v); # Executed on remote node

julia> println("v=$v, v2=$v2, ", v === v2);
v=[0], v2=[1], false
```

再度見て取れるように，ローカルノードへのリモート呼び出しは，直接呼び出しと同じように動作します．
呼び出しは引数として渡されたローカルオブジェクトを変更します．リモート呼び出しでは，引数のコピーを操作します．

繰り返しになりますが，これは一般的には問題になりません．ローカルノードが計算ノードとしても使用されており，
呼び出し後に引数が使用されている場合，要求された引数のディープコピーをローカルノードで実行するコールへ渡さねば
ならないときには，このディープコピーの中で，この動作を考慮する必要があります．



## [Shared Arrays](@id man-shared-arrays)

Shared Arraysはシステムの共有メモリを使用して，多くのプロセスにわたって同じ配列をマッピングします．
[`DArray`](https://github.com/JuliaParallel/DistributedArrays.jl)といくつかの類似点がありますが，
[`SharedArray`](@ref)の動作はかなり異なります．[`DArray`](https://github.com/JuliaParallel/DistributedArrays.jl)では，
各プロセスはデータのチャンクへのローカルアクセス権を持ち，2つのプロセスが同じチャンクを共有することはありません:
対照的に，[`SharedArray`](@ref)では各「参加」プロセスは，配列全体にアクセスすることができます．
[`SharedArray`](@ref)は，同じマシン上の2つ以上のプロセスが共同でアクセスできる大量のデータを持ちたい場合に良い選択です．


Shared Arrayのサポートは，参加している全てのワーカ上で明示的にロードされなければならない`SharedArrays`
モジュールを介して利用可能です．

[`SharedArray`](@ref)のインデクシング（値の代入とアクセス）は通常の配列と同じように動作し，
ローカルプロセスで利用可能なメモリ上で動作しているので効率的です．したがって，シングルプロセスモードとはいえ，
ほとんどのアルゴリズムは自然に[`SharedArray`](@ref)s上で動作します．アルゴリズムが[`Array`](@ref)入力を要求
する場合，[`sdata`](@ref)を呼ぶことによって，[`SharedArray`](@ref)からその下にある配列を取得することができます．
他の`AbstractArray`型の場合，[`sdata`](@ref)はオブジェクト自体を返すだけなので，どんな`Array`型のオブジェクト上で
[`sdata`](@ref)を使ってもセーフです．

Shared Arrayのコンストラクタは以下の形式です:

```julia
SharedArray{T,N}(dims::NTuple; init=false, pids=Int[])
```

これは`pids`で指定されたプロセス間でビット型`T`とサイズ`dims`の`N`次元のshared arrayを作成します．
分散配列とは異なり，shared arrayは引数に指定された`pids`で指定された参加ワーカからのみアクセス可能です（
同じホスト上にある場合は作成プロセスからもアクセス可能です．）SharedArrayでは，[`isbits`](@ref)である
要素のみがサポートされていることに注意してください．

シグネチャ`initfn(S::SharedArray)`の`init`関数が指定された場合，参加している全てのワーカ上で呼び出されます．
各ワーカが配列の異なる部分で`init`関数を実行できるように指定することで，初期化を並列化することができます．


以下に簡単な例を示します:

```julia-repl
julia> using Distributed

julia> addprocs(3)
3-element Array{Int64,1}:
 2
 3
 4

julia> @everywhere using SharedArrays

julia> S = SharedArray{Int,2}((3,4), init = S -> S[localindices(S)] = repeat([myid()], length(localindices(S))))
3×4 SharedArray{Int64,2}:
 2  2  3  4
 2  3  3  4
 2  3  4  4

julia> S[3,2] = 7
7

julia> S
3×4 SharedArray{Int64,2}:
 2  2  3  4
 2  3  3  4
 2  7  4  4
```

[`SharedArrays.localindices`](@ref)はインデックスの不連続な一次元の範囲を提供し，プロセス間でタスクを分割するのに
便利なことがあります．もちろん好きなように作業を分割することができます:

```julia-repl
julia> S = SharedArray{Int,2}((3,4), init = S -> S[indexpids(S):length(procs(S)):length(S)] = repeat([myid()], length( indexpids(S):length(procs(S)):length(S))))
3×4 SharedArray{Int64,2}:
 2  2  2  2
 3  3  3  3
 4  4  4  4
```

全てのプロセスが下にあるデータにアクセスできるので，コンフリクトを起こさないように気を付けなければなりません．
例えば:

```julia
@sync begin
    for p in procs(S)
        @async begin
            remotecall_wait(fill!, p, S, p)
        end
    end
end
```

これは定義されていない挙動を生む結果となります．各々のプロセスは自身の`pid`で配列*全体*を埋めるので，
最後に（Sの任意の特定の要素に対して）実行したプロセスがいずれであっても，その`pid`を保持することになります．

より拡張された複雑な例として，以下の「カーネル」を並列に実行することを考えてみましょう:

```julia
q[i,j,t+1] = q[i,j,t] + u[i,j,t]
```

この場合，1次元のインデックスを使って作業を分割しようとすると，問題が発生する可能性があります:
`q[i,j,t]`があるワーカに割り当てられたブロックの終わり近くにあり，`q[i,j,t+1]`が別のワーカに割り当て
られたブロックの始まり近くにある場合，`q[i,j,t]`が`q[i,j,t+1]`を計算するのに必要な時間に準備できていない
可能性が高いです．このような場合には，手動で配列をチャンクした方が良いでしょう．2つ目の次元に沿って
分割してみましょう．このワーカに割り当てられた`(irange, jrange)`インデックスを返す関数を定義します:

```julia-repl
julia> @everywhere function myrange(q::SharedArray)
           idx = indexpids(q)
           if idx == 0 # This worker is not assigned a piece
               return 1:0, 1:0
           end
           nchunks = length(procs(q))
           splits = [round(Int, s) for s in range(0, stop=size(q,2), length=nchunks+1)]
           1:size(q,1), splits[idx]+1:splits[idx+1]
       end
```

次に，カーネルを定義します:

```julia-repl
julia> @everywhere function advection_chunk!(q, u, irange, jrange, trange)
           @show (irange, jrange, trange)  # display so we can see what's happening
           for t in trange, j in jrange, i in irange
               q[i,j,t+1] = q[i,j,t] + u[i,j,t]
           end
           q
       end
```

`SharedArray`実装のために便利なラッパも定義します:

```julia-repl
julia> @everywhere advection_shared_chunk!(q, u) =
           advection_chunk!(q, u, myrange(q)..., 1:size(q,3)-1)
```

では3つの異なるバージョンを比べてみましょう．シングルプロセスで動作させた場合:

```julia-repl
julia> advection_serial!(q, u) = advection_chunk!(q, u, 1:size(q,1), 1:size(q,2), 1:size(q,3)-1);
```

[`@distributed`](@ref)を使った場合:

```julia-repl
julia> function advection_parallel!(q, u)
           for t = 1:size(q,3)-1
               @sync @distributed for j = 1:size(q,2)
                   for i = 1:size(q,1)
                       q[i,j,t+1]= q[i,j,t] + u[i,j,t]
                   end
               end
           end
           q
       end;
```

そしてチャンクに委譲した場合:

```julia-repl
julia> function advection_shared!(q, u)
           @sync begin
               for p in procs(q)
                   @async remotecall_wait(advection_shared_chunk!, p, q, u)
               end
           end
           q
       end;
```

`SharedArray`sを作成してこれらの関数を実行すると，以下のような結果が得られます（`julia -p 4`を用いた場合）:

```julia-repl
julia> q = SharedArray{Float64,3}((500,500,500));

julia> u = SharedArray{Float64,3}((500,500,500));
```

関数を一度実行してJITコンパイルし，2回目の実行時に [`@time`](@ref)で計測します:

```julia-repl
julia> @time advection_serial!(q, u);
(irange,jrange,trange) = (1:500,1:500,1:499)
 830.220 milliseconds (216 allocations: 13820 bytes)

julia> @time advection_parallel!(q, u);
   2.495 seconds      (3999 k allocations: 289 MB, 2.09% gc time)

julia> @time advection_shared!(q,u);
        From worker 2:       (irange,jrange,trange) = (1:500,1:125,1:499)
        From worker 4:       (irange,jrange,trange) = (1:500,251:375,1:499)
        From worker 3:       (irange,jrange,trange) = (1:500,126:250,1:499)
        From worker 5:       (irange,jrange,trange) = (1:500,376:500,1:499)
 238.119 milliseconds (2264 allocations: 169 KB)
```

`advection_shared!`の最大の利点は，ワーカ間のトラフィックを最小限に抑え，各ワーカが割り当てられたピースで
長時間計算することを可能にすることです．

### Shared Arraysと分散ガベージコレクション

リモートリファレンスと同様に，shared arraysもまた，参加している全てのワーカから参照を解放をするのに，
作成ノードのガベージコレクションに依存しています．短期間で多くのshared arrayオブジェクトを作成するコードでは，
これらのオブジェクトをできるだけ早く明示的にファイナライズすることが有益です．これにより，共有セグメントを
マッピングするメモリとファイルハンドルの両方がより早く解放されるようになります．


## ClusterManagers

論理クラスタへのJuliaプロセスの起動，管理，ネットワーキングは，クラスタマネージャを介して行われます．
`ClusterManager`は以下を担当します:

  * クラスタ環境下におけるワーカプロセスの起動
  * 各ワーカのライフタイムの間のイベント管理
  * オプションで，データ転送を提供

Juliaクラスタは以下のような特徴を持ちます:

  * 最初のJuliaプロセスは`master`とも呼ばれますが，これは特別なもので，`id`として1を持ちます．
  * `master`プロセスだけが，ワーカプロセスを追加したり削除したりできます．
  * 全てのプロセスはお互いに直接通信することができます．

ワーカ間の接続（ビルトインのTCP/IP転送を利用）は，以下のような形で確立されます:

  * マスタプロセス上で，`ClusterManager`とともに，[`addprocs`](@ref)を呼び出します．
  * [`addprocs`](@ref)は適切な [`launch`](@ref)を呼び，適切なマシン上で要求された数のワーカを生成します．
  * 各ワーカはフリーなポートをリスンし始め，[`stdout`](@ref)にそのホストとポート情報を書き出します．
  * クラスタマネージャは各ワーカの [`stdout`](@ref)をキャプチャし，マスタプロセスで利用できるようにします．
  * マスタプロセ薄は個の情報をパース氏，各ワーカとのTCP/IP接続をセットアップします．
  * 全てのワーカはクラスタ内の他のワーカにも通知されます．
  * 各ワーカは自分自身の`id`よりも小さい`id`を持つ全てのワーカに接続します．
  * このようにして，メッシュネットワークが確立され，そこでは全てのワーカが全ての他のワーカと直接つなげられています．

デフォルトのトランスポートレイヤは[`TCPSocket`](@ref)を用いていますが，Juliaクラスタでは独自のトランスポートを
提供することができます．

Juliaは2つのビルトインなクラスタマネージャを提供します:

  * [`addprocs()`](@ref)または[`addprocs(np::Integer)`](@ref)が呼ばれたときに使用される`LocalManager`
  * [`addprocs(hostnames::Array)`](@ref)がホストネームのリスト共に呼び出された時に使用される`SSHManager`

`LocalManager`は同じホスト上でワーカを追加して起動するのに用いられ，それによりマルチコア，マルチプロセッサ
なハードウェアを有効活用します．

Thus, a minimal cluster manager would need to:
したがって，最小限のクラスタマネージャは以下のようである必要があります: 

  * アブストラクトな`ClusterManager`のサブタイプであること
  * 新しいワーカを起動することを担当するメソッドである[`launch`](@ref)を実装すること
  * ワーカのライフタイムの間の様々なイベント（例えば，割り込み信号の送信）の際に呼ばれる，[`manage`](@ref)を実装すること

[`addprocs(manager::FooManager)`](@ref addprocs)は`FooManager`が実装されていることを必要とします:

```julia
function launch(manager::FooManager, params::Dict, launched::Array, c::Condition)
    [...]
end

function manage(manager::FooManager, id::Integer, config::WorkerConfig, op::Symbol)
    [...]
end
```

例として，同じホスト上でワーカの起動を担当するマネージャである`LocalManager`がどのように実装されているかを見てみましょう:

```julia
struct LocalManager <: ClusterManager
    np::Integer
end

function launch(manager::LocalManager, params::Dict, launched::Array, c::Condition)
    [...]
end

function manage(manager::LocalManager, id::Integer, config::WorkerConfig, op::Symbol)
    [...]
end
```

[`launch`](@ref)メソッドは以下のような引数を取ります:

  * `manager::ClusterManager`: [`addprocs`](@ref)が呼び出されるクラスタマネージャ
  * `params::Dict`: [`addprocs`](@ref)に渡される全てのキーワード引数
  * `launched::Array`: 1つ以上の`WorkerConfig`オブジェクトをアペンドするための配列
  * `c::Condition`: ワーカの起動時に通知される条件変数

[`launch`](@ref)メソッドは，別のタスクで非同期的に呼び出されます．このタスクの終了は，
要求された全てのワーカが起動されたことを示しています．したがって，要求された全てのワーカが
起動されたらすぐに，[`launch`](@ref)関数は終了されなければなりません．

新たに起動されたワーカは，お互いとマスタプロセスに網羅的に接続されます．コマンドライン引数`--worker[=<cookie>]`
を指定すると，起動されたプロセスがワーカとして初期化され，TCP/IPソケットを介して接続がセットアップされます．

クラスタ内の全てのワーカはマスタと同じ[cookie](@ref man-cluster-cookie)を共有します．クッキーが指定されていない場合，
つまり`--worker`を指定した場合，ワーカはそれを標準入力から読み込もうとします．
`LocalManager`と`SSHManager`はどちらも自らの標準入力を介して，新しく起動されたワーカにクッキーを渡します．


デフォルトではワーカは[`getipaddr()`](@ref)の呼び出しで返されたアドレスの空きポートをリスンします．
リスンする特定のアドレスはオプションの引数`--bind-to bind_addr[:port]`で指定できます．これはマルチホームホストに便利です．

非TCP/IPトランスポートの例として，実装はMPIを使用することを選ぶことができるが，その場合は`--worker`は指定してはならない．
代わりに，新しく起動されたワーカは，並列構成を使う前に`init_worker(cookie)`を呼び出さねばなりません．

起動された全てのワーカに対して，[`launch`](@ref)は`WorkerConfig`オブジェクトを（適切なフィールドを初期化しながら）`launched`に追加しなければなりません．

```julia
mutable struct WorkerConfig
    # Common fields relevant to all cluster managers
    io::Union{IO, Nothing}
    host::Union{AbstractString, Nothing}
    port::Union{Integer, Nothing}

    # Used when launching additional workers at a host
    count::Union{Int, Symbol, Nothing}
    exename::Union{AbstractString, Cmd, Nothing}
    exeflags::Union{Cmd, Nothing}

    # External cluster managers can use this to store information at a per-worker level
    # Can be a dict if multiple fields need to be stored.
    userdata::Any

    # SSHManager / SSH tunnel connections to workers
    tunnel::Union{Bool, Nothing}
    bind_addr::Union{AbstractString, Nothing}
    sshflags::Union{Cmd, Nothing}
    max_parallel::Union{Integer, Nothing}

    # Used by Local/SSH managers
    connect_at::Any

    [...]
end
```

`WorkerConfig`のフィールドのほとんどは，ビルトインのマネージャで使用されます．カスタムクラスタマネージャは通常，
`io`または`host` / `port`のみを指定します:

  * `io`が指定された場合，それはホスト/ポート情報を読み込むために使用されます．Juliaワーカは起動時に
	バインドアドレスとポートを出力します．これにより，ワーカのポートを手動で設定することを要求する代わりに
	Juliaワーカは空いている任意ポートをリスンすることができます．
  * `io`が指定されていない場合，`host`と`port`が接続に用いられます．
  * `count`，`exename`，および`exeflags`は，ワーカから追加のワーカを起動する際に関連します．
	例えばクラスタマネージャはノードごとに単一のワーカを起動し，それを使用して追加のワーカを起動することができます．

	  * `count`に整数値`n`を指定すると合計`n`個のワーカが起動されます．
	  * `count`に`:auto`の値を指定すると，そのマシンのCPUスレッド（論理コア）の数と同じ数のワーカを起動します．
	  * `exename`はフルパスを含む`julia`実行ファイルの名前です．
	  * `exeflags`は新しいワーカに必要なコマンドライン引数に設定してください．
  * `tunnel`，`bind_addr`，`sshflags`および`max_parallel`はマスタプロセスからワーカに接続するために
	sshトンネルが必要な場合に使用されます．
  * `userdata`はカスタムクラスタマネージャが独自のワーカの固有の情報を保存するために提供されます．

`manage(manager::FooManager, id::Integer, config::WorkerConfig, op::Symbol)`は以下のような`op`値を指定して，
ワーカのライフタイム中に異なるタイミングで呼び出されます: 

  * Juliaワーカプールでワーカが追加削除されたときに指定する`:register`/`:deregister`
  * `interrupt(workers)`が呼び出されたときに指定する`:interrupt`．`ClusterManager`は適切なワーカに対して，
	割り込み信号を送信しなければなりません．
  * クリーンアップのために指定する`:finalize`．

### Cluster Managers with Custom Transports

Replacing the default TCP/IP all-to-all socket connections with a custom transport layer is a
little more involved. Each Julia process has as many communication tasks as the workers it is
connected to. For example, consider a Julia cluster of 32 processes in an all-to-all mesh network:

  * Each Julia process thus has 31 communication tasks.
  * Each task handles all incoming messages from a single remote worker in a message-processing loop.
  * The message-processing loop waits on an `IO` object (for example, a [`TCPSocket`](@ref) in the default
    implementation), reads an entire message, processes it and waits for the next one.
  * Sending messages to a process is done directly from any Julia task--not just communication tasks--again,
    via the appropriate `IO` object.

Replacing the default transport requires the new implementation to set up connections to remote
workers and to provide appropriate `IO` objects that the message-processing loops can wait on.
The manager-specific callbacks to be implemented are:

```julia
connect(manager::FooManager, pid::Integer, config::WorkerConfig)
kill(manager::FooManager, pid::Int, config::WorkerConfig)
```

The default implementation (which uses TCP/IP sockets) is implemented as `connect(manager::ClusterManager, pid::Integer, config::WorkerConfig)`.

`connect` should return a pair of `IO` objects, one for reading data sent from worker `pid`, and
the other to write data that needs to be sent to worker `pid`. Custom cluster managers can use
an in-memory `BufferStream` as the plumbing to proxy data between the custom, possibly non-`IO`
transport and Julia's in-built parallel infrastructure.

A `BufferStream` is an in-memory [`IOBuffer`](@ref) which behaves like an `IO`--it is a stream which can
be handled asynchronously.

The folder `clustermanager/0mq` in the [Examples repository](https://github.com/JuliaAttic/Examples)
contains an example of using ZeroMQ to connect Julia workers
in a star topology with a 0MQ broker in the middle. Note: The Julia processes are still all *logically*
connected to each other--any worker can message any other worker directly without any awareness
of 0MQ being used as the transport layer.

When using custom transports:

  * Julia workers must NOT be started with `--worker`. Starting with `--worker` will result in the
    newly launched workers defaulting to the TCP/IP socket transport implementation.
  * For every incoming logical connection with a worker, `Base.process_messages(rd::IO, wr::IO)()`
    must be called. This launches a new task that handles reading and writing of messages from/to
    the worker represented by the `IO` objects.
  * `init_worker(cookie, manager::FooManager)` *must* be called as part of worker process initialization.
  * Field `connect_at::Any` in `WorkerConfig` can be set by the cluster manager when [`launch`](@ref)
    is called. The value of this field is passed in all [`connect`](@ref) callbacks. Typically,
    it carries information on *how to connect* to a worker. For example, the TCP/IP socket transport
    uses this field to specify the `(host, port)` tuple at which to connect to a worker.

`kill(manager, pid, config)` is called to remove a worker from the cluster. On the master process,
the corresponding `IO` objects must be closed by the implementation to ensure proper cleanup.
The default implementation simply executes an `exit()` call on the specified remote worker.

The Examples folder `clustermanager/simple` is an example that shows a simple implementation using UNIX domain
sockets for cluster setup.

### Network Requirements for LocalManager and SSHManager

Julia clusters are designed to be executed on already secured environments on infrastructure such
as local laptops, departmental clusters, or even the cloud. This section covers network security
requirements for the inbuilt `LocalManager` and `SSHManager`:

  * The master process does not listen on any port. It only connects out to the workers.
  * Each worker binds to only one of the local interfaces and listens on an ephemeral port number
    assigned by the OS.
  * `LocalManager`, used by `addprocs(N)`, by default binds only to the loopback interface. This means
    that workers started later on remote hosts (or by anyone with malicious intentions) are unable
    to connect to the cluster. An `addprocs(4)` followed by an `addprocs(["remote_host"])` will fail.
    Some users may need to create a cluster comprising their local system and a few remote systems.
    This can be done by explicitly requesting `LocalManager` to bind to an external network interface
    via the `restrict` keyword argument: `addprocs(4; restrict=false)`.
  * `SSHManager`, used by `addprocs(list_of_remote_hosts)`, launches workers on remote hosts via SSH.
    By default SSH is only used to launch Julia workers. Subsequent master-worker and worker-worker
    connections use plain, unencrypted TCP/IP sockets. The remote hosts must have passwordless login
    enabled. Additional SSH flags or credentials may be specified via keyword argument `sshflags`.
  * `addprocs(list_of_remote_hosts; tunnel=true, sshflags=<ssh keys and other flags>)` is useful when
    we wish to use SSH connections for master-worker too. A typical scenario for this is a local laptop
    running the Julia REPL (i.e., the master) with the rest of the cluster on the cloud, say on Amazon
    EC2. In this case only port 22 needs to be opened at the remote cluster coupled with SSH client
    authenticated via public key infrastructure (PKI). Authentication credentials can be supplied
    via `sshflags`, for example ```sshflags=`-i <keyfile>` ```.

    In an all-to-all topology (the default), all workers connect to each other via plain TCP sockets.
    The security policy on the cluster nodes must thus ensure free connectivity between workers for
    the ephemeral port range (varies by OS).

    Securing and encrypting all worker-worker traffic (via SSH) or encrypting individual messages
    can be done via a custom `ClusterManager`.

  * If you specify `multiplex=true` as an option to `addprocs`, SSH multiplexing is used to create
    a tunnel between the master and workers. If you have configured SSH multiplexing on your own and
    the connection has already been established, SSH multiplexing is used regardless of `multiplex`
    option. If multiplexing is enabled, forwarding is set by using the existing connection
    (`-O forward` option in ssh). This is beneficial if your servers require password authentication;
    you can avoid authentication in Julia by logging in to the server ahead of `addprocs`. The control
    socket will be located at `~/.ssh/julia-%r@%h:%p` during the session unless the existing multiplexing
    connection is used. Note that bandwidth may be limited if you create multiple processes on a node
    and enable multiplexing, because in that case processes share a single multiplexing TCP connection.

### [Cluster Cookie](@id man-cluster-cookie)

All processes in a cluster share the same cookie which, by default, is a randomly generated string
on the master process:

  * [`cluster_cookie()`](@ref) returns the cookie, while `cluster_cookie(cookie)()` sets
    it and returns the new cookie.
  * All connections are authenticated on both sides to ensure that only workers started by the master
    are allowed to connect to each other.
  * The cookie may be passed to the workers at startup via argument `--worker=<cookie>`. If argument
    `--worker` is specified without the cookie, the worker tries to read the cookie from its
    standard input ([`stdin`](@ref)). The `stdin` is closed immediately after the cookie is retrieved.
  * `ClusterManager`s can retrieve the cookie on the master by calling [`cluster_cookie()`](@ref).
    Cluster managers not using the default TCP/IP transport (and hence not specifying `--worker`)
    must call `init_worker(cookie, manager)` with the same cookie as on the master.

Note that environments requiring higher levels of security can implement this via a custom `ClusterManager`.
For example, cookies can be pre-shared and hence not specified as a startup argument.

## Specifying Network Topology (Experimental)

The keyword argument `topology` passed to `addprocs` is used to specify how the workers must be
connected to each other:

  * `:all_to_all`, the default: all workers are connected to each other.
  * `:master_worker`: only the driver process, i.e. `pid` 1, has connections to the workers.
  * `:custom`: the `launch` method of the cluster manager specifies the connection topology via the
    fields `ident` and `connect_idents` in `WorkerConfig`. A worker with a cluster-manager-provided
    identity `ident` will connect to all workers specified in `connect_idents`.

Keyword argument `lazy=true|false` only affects `topology` option `:all_to_all`. If `true`, the cluster
starts off with the master connected to all workers. Specific worker-worker connections are established
at the first remote invocation between two workers. This helps in reducing initial resources allocated for
intra-cluster communication. Connections are setup depending on the runtime requirements of a parallel
program. Default value for `lazy` is `true`.

Currently, sending a message between unconnected workers results in an error. This behaviour,
as with the functionality and interface, should be considered experimental in nature and may change
in future releases.

## Noteworthy external packages

Outside of Julia parallelism there are plenty of external packages that should be mentioned.
For example [MPI.jl](https://github.com/JuliaParallel/MPI.jl) is a Julia wrapper for the `MPI` protocol, or
[DistributedArrays.jl](https://github.com/JuliaParallel/Distributedarrays.jl), as presented in [Shared Arrays](@ref).
A mention must be made of Julia's GPU programming ecosystem, which includes:

1. Low-level (C kernel) based operations [OpenCL.jl](https://github.com/JuliaGPU/OpenCL.jl) and [CUDAdrv.jl](https://github.com/JuliaGPU/CUDAdrv.jl) which are respectively an OpenCL interface and a CUDA wrapper.

2. Low-level (Julia Kernel) interfaces like [CUDAnative.jl](https://github.com/JuliaGPU/CUDAnative.jl) which is a Julia native CUDA implementation.

3. High-level vendor-specific abstractions like [CuArrays.jl](https://github.com/JuliaGPU/CuArrays.jl) and [CLArrays.jl](https://github.com/JuliaGPU/CLArrays.jl)

4. High-level libraries like [ArrayFire.jl](https://github.com/JuliaComputing/ArrayFire.jl) and [GPUArrays.jl](https://github.com/JuliaGPU/GPUArrays.jl)


In the following example we will use both `DistributedArrays.jl` and `CuArrays.jl` to distribute an array across multiple
processes by first casting it through `distribute()` and `CuArray()`.

Remember when importing `DistributedArrays.jl` to import it across all processes using [`@everywhere`](@ref)


```julia-repl
$ ./julia -p 4

julia> addprocs()

julia> @everywhere using DistributedArrays

julia> using CuArrays

julia> B = ones(10_000) ./ 2;

julia> A = ones(10_000) .* π;

julia> C = 2 .* A ./ B;

julia> all(C .≈ 4*π)
true

julia> typeof(C)
Array{Float64,1}

julia> dB = distribute(B);

julia> dA = distribute(A);

julia> dC = 2 .* dA ./ dB;

julia> all(dC .≈ 4*π)
true

julia> typeof(dC)
DistributedArrays.DArray{Float64,1,Array{Float64,1}}

julia> cuB = CuArray(B);

julia> cuA = CuArray(A);

julia> cuC = 2 .* cuA ./ cuB;

julia> all(cuC .≈ 4*π);
true

julia> typeof(cuC)
CuArray{Float64,1}
```
Keep in mind that some Julia features are not currently supported by CUDAnative.jl[^2] , especially some functions like `sin` will need to be replaced with `CUDAnative.sin`(cc: @maleadt).

In the following example we will use both `DistributedArrays.jl` and `CuArrays.jl` to distribute an array across multiple
processes and call a generic function on it.

```julia
function power_method(M, v)
    for i in 1:100
        v = M*v
        v /= norm(v)
    end

    return v, norm(M*v) / norm(v)  # or  (M*v) ./ v
end
```

`power_method` repeatedly creates a new vector and normalizes it. We have not specified any type signature in
function declaration, let's see if it works with the aforementioned datatypes:

```julia-repl
julia> M = [2. 1; 1 1];

julia> v = rand(2)
2-element Array{Float64,1}:
0.40395
0.445877

julia> power_method(M,v)
([0.850651, 0.525731], 2.618033988749895)

julia> cuM = CuArray(M);

julia> cuv = CuArray(v);

julia> curesult = power_method(cuM, cuv);

julia> typeof(curesult)
CuArray{Float64,1}

julia> dM = distribute(M);

julia> dv = distribute(v);

julia> dC = power_method(dM, dv);

julia> typeof(dC)
Tuple{DistributedArrays.DArray{Float64,1,Array{Float64,1}},Float64}
```

To end this short exposure to external packages, we can consider `MPI.jl`, a Julia wrapper
of the MPI protocol. As it would take too long to consider every inner function, it would be better
to simply appreciate the approach used to implement the protocol.

Consider this toy script which simply calls each subprocess, instantiate its rank and when the master
process is reached, performs the ranks' sum

```julia
import MPI

MPI.Init()

comm = MPI.COMM_WORLD
MPI.Barrier(comm)

root = 0
r = MPI.Comm_rank(comm)

sr = MPI.Reduce(r, MPI.SUM, root, comm)

if(MPI.Comm_rank(comm) == root)
   @printf("sum of ranks: %s\n", sr)
end

MPI.Finalize()
```

```
mpirun -np 4 ./julia example.jl
```

[^1]:
    In this context, MPI refers to the MPI-1 standard. Beginning with MPI-2, the MPI standards committee
    introduced a new set of communication mechanisms, collectively referred to as Remote Memory Access
    (RMA). The motivation for adding rma to the MPI standard was to facilitate one-sided communication
    patterns. For additional information on the latest MPI standard, see <https://mpi-forum.org/docs>.

[^2]:
    [Julia GPU man pages](http://juliagpu.github.io/CUDAnative.jl/stable/man/usage.html#Julia-support-1)
