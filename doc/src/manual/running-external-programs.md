# [外部プログラムの実行](@id Running-External-Programs)

JuliaはShell，Perl，Rubyのコマンドのバックティック記法を借用しています．しかしJuliaで以下のような書き方

```jldoctest
julia> `echo hello`
`echo hello`
```

をすると，様々なShellやPerl,Rubyでの動作といくつかの点で異なるものになります:

  * コマンドをすぐに実行するのではなく，バックティックはコマンドを表わす[`Cmd`](@ref)オブジェクトを作成します．このオブジェクトを使ってパイプを介してそれを[`run`](@ref)したり，[`read`](@ref)や[`write`](@ref)したりすることができます．
  * コマンドが実行されると，特に指定しない限り，Juliaはその出力をキャプチャしません．その代わりに，コマンドの出力は`libc`の`system`コールを使用した場合と同様にデフォルトで[`stdout`](@ref)に出力されます．
  * コマンドはシェルで実行されることはありません．代わりにJuliaはコマンドの構文を直接解析し，シェルの引用構文を尊重しながら，シェルが行うように変数を適切に補間したり，単語を分割したりします．コマンドは`julia`の直系の子プロセスとして実行され，`fork`と`exec`呼び出しを使用します．

ここに外部プログラムを実行する簡単な例があります:

```jldoctest
julia> mycommand = `echo hello`
`echo hello`

julia> typeof(mycommand)
Cmd

julia> run(mycommand);
hello
```

`hello`は[`stdout`](@ref)に送られた`echo`コマンドの出力です．runメソッドそのものは`nothing`を返し，
外部コマンドの実行に失敗した場合には[`ErrorException`](@ref)をスローします．


外部コマンドの出力を読み込みたい場合には，代わりに[`read`](@ref)を使用することができます:

```jldoctest
julia> a = read(`echo hello`, String)
"hello\n"

julia> chomp(a) == "hello"
true
```

より一般的には，[`open`](@ref)を使用して外部コマンドを読み込んだり書き込んだりすることができます．

```jldoctest
julia> open(`less`, "w", stdout) do io
           for i = 1:3
               println(io, i)
           end
       end
1
2
3
```

プログラム名とコマンド内の個々の引数にアクセスして，あたかもコマンドが文字列の配列であるかのように反復処理することができます．
```jldoctest
julia> collect(`echo "foo bar"`)
2-element Array{String,1}:
 "echo"
 "foo bar"

julia> `echo "foo bar"`[2]
"foo bar"
```

## [補間](@id command-interpolation)

もう少し複雑なことをして，変数`file`のファイル名をコマンドの引数として使いたいとしましょう．
文字列リテラルの場合と同じように，補間に`$`を使うことができます（[Strings](@ref)を参照してください）．

```jldoctest
julia> file = "/etc/passwd"
"/etc/passwd"

julia> `sort $file`
`sort /etc/passwd`
```

シェル経由で外部プログラムを実行する際によくある落とし穴は，ファイル名にシェルにとって特別な
文字が含まれている場合に，望ましくない動作を引き起こす可能性があるということです．例えば，
`/etc/passwd`の代わりに，`/Volumes/External HD/data.csv`というファイルの内容をソートしたいと
します．試してみましょう:

```jldoctest
julia> file = "/Volumes/External HD/data.csv"
"/Volumes/External HD/data.csv"

julia> `sort $file`
`sort '/Volumes/External HD/data.csv'`
```

ファイル名はどうやって引用されたのでしょうか？Juliaは`file`が一つの引数として補間されること
を知っているので，その言葉を引用しています．実際にはこれは正確ではありません．`file`の値は
シェルによって解釈されることはありませんので，実際の引用の必要はありません．引用が挿入される
のはユーザに提示するためだけです．これはシェルの単語の一部として値を補間しても動作します:

```jldoctest
julia> path = "/Volumes/External HD"
"/Volumes/External HD"

julia> name = "data"
"data"

julia> ext = "csv"
"csv"

julia> `sort $path/$name.$ext`
`sort '/Volumes/External HD/data.csv'`
```

ご覧のように，`path`変数のスペースは適切にエスケープされています．しかし，複数の単語を補間
したい場合はどうでしょうか？その場合は，配列（またはその他の反復可能なコンテナ）を使用します:

```jldoctest
julia> files = ["/etc/passwd","/Volumes/External HD/data.csv"]
2-element Array{String,1}:
 "/etc/passwd"
 "/Volumes/External HD/data.csv"

julia> `grep foo $files`
`grep foo /etc/passwd '/Volumes/External HD/data.csv'`
```

シェルの単語の一部として配列を補間すると，Juliaはシェルの`{a,b,c}`引数生成をエミュレートします:

```jldoctest
julia> names = ["foo","bar","baz"]
3-element Array{String,1}:
 "foo"
 "bar"
 "baz"

julia> `grep xylophone $names.txt`
`grep xylophone foo.txt bar.txt baz.txt`
```

さらに，複数の配列を同じ単語に補間すると，シェルのデカルト積生成動作がエミュレートされます:

```jldoctest
julia> names = ["foo","bar","baz"]
3-element Array{String,1}:
 "foo"
 "bar"
 "baz"

julia> exts = ["aux","log"]
2-element Array{String,1}:
 "aux"
 "log"

julia> `rm -f $names.$exts`
`rm -f foo.aux foo.log bar.aux bar.log baz.aux baz.log`
```

リテラル配列を補間できるので，最初に一時的な配列オブジェクトを作成しなくても，この生成機能を使うことができます．

```jldoctest
julia> `rm -rf $["foo","bar","baz","qux"].$["aux","log","pdf"]`
`rm -rf foo.aux foo.log foo.pdf bar.aux bar.log bar.pdf baz.aux baz.log baz.pdf qux.aux qux.log qux.pdf`
```

## 引用

必然的に，それほど単純ではないコマンドを書きたくなって，引用符を使う必要が出てきます．
ここでは，シェルプロンプトでのPerlのワンライナの簡単な例を示します:

```
sh$ perl -le '$|=1; for (0..3) { print }'
0
1
2
3
```

スペースが式を複数のシェルワードに分割しないようにするためと，`$|`のようなPerlの変数（これは
Perlの変数名です）を使用しても補間が発生しないようにするためです．他の例では，補間が*発生する*
ように二重引用符を使用したい場合もあるでしょう:

```
sh$ first="A"
sh$ second="B"
sh$ perl -le '$|=1; print for @ARGV' "1: $first" "2: $second"
1: A
2: B
```

一般的に，Juliaのバックティック構文は慎重に設計されているので，シェルコマンドをそのまま
バックティックにカットアンドペーストするだけで動作するようになっています．エスケープ，引用，
補間の動作はシェルのものと同じです．唯一の違いは，補間が統合されており，何が単一の文字列で
何が複数の値のためのコンテナであるかというJuliaの概念を認識しているということです．上記2つ
の例をJuliaで試してみましょう:

```jldoctest
julia> A = `perl -le '$|=1; for (0..3) { print }'`
`perl -le '$|=1; for (0..3) { print }'`

julia> run(A);
0
1
2
3

julia> first = "A"; second = "B";

julia> B = `perl -le 'print for @ARGV' "1: $first" "2: $second"`
`perl -le 'print for @ARGV' '1: A' '2: B'`

julia> run(B);
1: A
2: B
```

結果は同じで，ほとんどのシェルがスペースで分割された文字列を使用して曖昧さを出してしまう一方，
Juliaは素晴らしい反復可能オブジェクトをサポートしているという事実から，Juliaの補間動作は
シェルのものをいくらか改善しながら真似ています．シェルコマンドをJuliaに移植使用とする時は，
まずはカットアンドペーストを試してみてください．Juliaコマンドを実行する前にコマンドを見せて
くれるので，ダメージを与えることなく，簡単かつ安全にコメントの解釈を調べることができます．

## パイプライン

`|`や`&`，`>`といったシェルのメタ文字は，Juliaのバックティックの中では引用符を付けるか，
エスケープする必要があります:

```jldoctest
julia> run(`echo hello '|' sort`);
hello | sort

julia> run(`echo hello \| sort`);
hello | sort
```

この式は3つのワード`hello`，`|`，`sort`を引数として`echo`コマンドを呼び出します．その結果，
`hello | sort`という一行が表示されます．では，どのようにしてパイプラインを構築するのでしょうか？
バックティックの中で，`|`を使うかわりに，[`pipeline`](@ref)を使います．

```jldoctest
julia> run(pipeline(`echo hello`, `sort`));
hello
```

これは`echo`コマンドwを`sort`コマンドにパイプします．もちろん，これはソートする行が一行しか
ないので，あまり面白いものではありませんが，実際もっと面白いことができます:

```julia-repl
julia> run(pipeline(`cut -d: -f3 /etc/passwd`, `sort -n`, `tail -n5`))
210
211
212
213
214
```

これは，UNIXシステム上のユーザIDのうち，上位5つのユーザIDを表示します．`cut`，`sort`，`tail`
コマンドは全て現在の`julia`プロセスの即席子プロセスとして生成され，シェルプロセスは介在
しません．通常シェルが行うパイプの設定やファイルディスクリプタの接続は，Julia自身が行い
ます．Julia自身がこれを行うので，より良い制御を保持し，シェルにはできないことを行うことが
できます．

Juliaは複数のコマンドを並列に実行することができます:

```jldoctest; filter = r"(world\nhello|hello\nworld)"
julia> run(`echo hello` & `echo world`);
world
hello
```

2つの`echo`プロセスはほぼ同時に実行され，お互いに共有している[`stdout`](@ref)ディスクリプタ
と`julia`親プロセスへの最初の書き込みを競って行うため，ここでの出力の順序は決定性がありませ
ん．Juliaではこれら両方のプロセスからの出力を別のプログラムにパイプすることができます:

```jldoctest
julia> run(pipeline(`echo world` & `echo hello`, `sort`));
hello
world
```

UNIXの配管の観点から見て，ここで何が起こっているのかというと，両方の`echo`プロセスによって
単一のUNIXパイプオブジェクトが作成されて書き込まれ，パイプのもう一方の端が`sort`コマンド
によって読み込まれるということになっています．


IOリダイレクトは，キーワード変数`stdin`，`stdout`，`stderr`を`pipeline`関数に渡すことで実現できます:

```julia
pipeline(`do_work`, stdout=pipeline(`sort`, "out.txt"), stderr="errs.txt")
```

### パイプラインでのデッドロックを避ける

単一プロセスからパイプラインの両端に読み書きする場合，カーネルが全てのデータをバッファリング
することを強制しないようにすることが重要です．

例えば，コマンドからの出力を全て読み込む場合は，`wait(process)`ではなく，`read(out, String)`
を呼び出してください．なぜなら，前者はプロセスによって書き込まれた全てのデータを積極的に
消費するのに対し，後者はリーダが接続されるのを待っている間にカーネルのバッファにデータを
保存しようとするからです．

もう一つの一般的な解決策は，パイプラインのリーダとライタを別々の[`Task`](@ref)sに分離することです:

```julia
writer = @async write(process, "data")
reader = @async do_compute(read(process, String))
wait(writer)
fetch(reader)
```

### 複雑な例

高レベルのプログラミング言語，素晴らしいコマンド抽象化，そしてプロセス間の自動セットアップ
の組み合わせは強力なものです．簡単に作成できる複雑なパイプラインを理解してもらうために，
ここではより洗練された例をいくつか紹介します．Perlのワンライナを多用しすぎたことをお詫び
しておきます:

```jldoctest prefixer; filter = r"([A-B] [0-5])"
julia> prefixer(prefix, sleep) = `perl -nle '$|=1; print "'$prefix' ", $_; sleep '$sleep';'`;

julia> run(pipeline(`perl -le '$|=1; for(0..5){ print; sleep 1 }'`, prefixer("A",2) & prefixer("B",2)));
B 0
A 1
B 2
A 3
B 4
A 5
```

これは1つのプロデューサが2つの並行したコンシューマに同時に供給している例です．1つのPerl
プロセスが0から5までの数字が書かれた行を生成し，2つの並列プロセスがその出力を消費して
います．片方は行を「A」でプレフィックスし，もう片方は「B」でプレフィックスいます．
どちらが最初の行を取得するかは非決定論的ですが，その競争に勝利すると，行は一方のプロセス
ともう一方のプロセスによって交互に消費されます．（Perlで`$|=1`を設定すると，各print文は
[`stdout`](@ref)ハンドルをフラッシュするようになります．これはこの例が動作するのに必要
なことで，そうしないと全ての出力はバッファリングされてパイプに一度だけプリントされ，1つの
コンシューマプロセスだけからしか読めないようになってしまいます．）

ここでは更に複雑な多段のプロデューサとコンシューマの例を示します:

```jldoctest prefixer; filter = r"[A-B] [X-Z] [0-5]"
julia> run(pipeline(`perl -le '$|=1; for(0..5){ print; sleep 1 }'`,
           prefixer("X",3) & prefixer("Y",3) & prefixer("Z",3),
           prefixer("A",2) & prefixer("B",2)));
A X 0
B Y 1
A Z 2
B X 3
A Y 4
B Z 5
```

この例は前の例に似ていますが，コンシューマの2つのステージがあり，各ステージは異なる
レイテンシを持っているので，飽和したスループットを維持するために異なる数の並列ワーカ
を使用します．

これらの例を全て試してみて，どのように動作するかを確認することを強くお勧めします．
