# 外部プログラムの実行

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

## Quoting

Inevitably, one wants to write commands that aren't quite so simple, and it becomes necessary
to use quotes. Here's a simple example of a Perl one-liner at a shell prompt:

```
sh$ perl -le '$|=1; for (0..3) { print }'
0
1
2
3
```

The Perl expression needs to be in single quotes for two reasons: so that spaces don't break the
expression into multiple shell words, and so that uses of Perl variables like `$|` (yes, that's
the name of a variable in Perl), don't cause interpolation. In other instances, you may want to
use double quotes so that interpolation *does* occur:

```
sh$ first="A"
sh$ second="B"
sh$ perl -le '$|=1; print for @ARGV' "1: $first" "2: $second"
1: A
2: B
```

In general, the Julia backtick syntax is carefully designed so that you can just cut-and-paste
shell commands as is into backticks and they will work: the escaping, quoting, and interpolation
behaviors are the same as the shell's. The only difference is that the interpolation is integrated
and aware of Julia's notion of what is a single string value, and what is a container for multiple
values. Let's try the above two examples in Julia:

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

The results are identical, and Julia's interpolation behavior mimics the shell's with some improvements
due to the fact that Julia supports first-class iterable objects while most shells use strings
split on spaces for this, which introduces ambiguities. When trying to port shell commands to
Julia, try cut and pasting first. Since Julia shows commands to you before running them, you can
easily and safely just examine its interpretation without doing any damage.

## Pipelines

Shell metacharacters, such as `|`, `&`, and `>`, need to be quoted (or escaped) inside of Julia's backticks:

```jldoctest
julia> run(`echo hello '|' sort`);
hello | sort

julia> run(`echo hello \| sort`);
hello | sort
```

This expression invokes the `echo` command with three words as arguments: `hello`, `|`, and `sort`.
The result is that a single line is printed: `hello | sort`. How, then, does one construct a
pipeline? Instead of using `'|'` inside of backticks, one uses [`pipeline`](@ref):

```jldoctest
julia> run(pipeline(`echo hello`, `sort`));
hello
```

This pipes the output of the `echo` command to the `sort` command. Of course, this isn't terribly
interesting since there's only one line to sort, but we can certainly do much more interesting
things:

```julia-repl
julia> run(pipeline(`cut -d: -f3 /etc/passwd`, `sort -n`, `tail -n5`))
210
211
212
213
214
```

This prints the highest five user IDs on a UNIX system. The `cut`, `sort` and `tail` commands
are all spawned as immediate children of the current `julia` process, with no intervening shell
process. Julia itself does the work to setup pipes and connect file descriptors that is normally
done by the shell. Since Julia does this itself, it retains better control and can do some things
that shells cannot.

Julia can run multiple commands in parallel:

```jldoctest; filter = r"(world\nhello|hello\nworld)"
julia> run(`echo hello` & `echo world`);
world
hello
```

The order of the output here is non-deterministic because the two `echo` processes are started
nearly simultaneously, and race to make the first write to the [`stdout`](@ref) descriptor they
share with each other and the `julia` parent process. Julia lets you pipe the output from both
of these processes to another program:

```jldoctest
julia> run(pipeline(`echo world` & `echo hello`, `sort`));
hello
world
```

In terms of UNIX plumbing, what's happening here is that a single UNIX pipe object is created
and written to by both `echo` processes, and the other end of the pipe is read from by the `sort`
command.

IO redirection can be accomplished by passing keyword arguments `stdin`, `stdout`, and `stderr` to the
`pipeline` function:

```julia
pipeline(`do_work`, stdout=pipeline(`sort`, "out.txt"), stderr="errs.txt")
```

### Avoiding Deadlock in Pipelines

When reading and writing to both ends of a pipeline from a single process, it is important to
avoid forcing the kernel to buffer all of the data.

For example, when reading all of the output from a command, call `read(out, String)`, not `wait(process)`,
since the former will actively consume all of the data written by the process, whereas the latter
will attempt to store the data in the kernel's buffers while waiting for a reader to be connected.

Another common solution is to separate the reader and writer of the pipeline into separate [`Task`](@ref)s:

```julia
writer = @async write(process, "data")
reader = @async do_compute(read(process, String))
wait(writer)
fetch(reader)
```

### Complex Example

The combination of a high-level programming language, a first-class command abstraction, and automatic
setup of pipes between processes is a powerful one. To give some sense of the complex pipelines
that can be created easily, here are some more sophisticated examples, with apologies for the
excessive use of Perl one-liners:

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

This is a classic example of a single producer feeding two concurrent consumers: one `perl` process
generates lines with the numbers 0 through 5 on them, while two parallel processes consume that
output, one prefixing lines with the letter "A", the other with the letter "B". Which consumer
gets the first line is non-deterministic, but once that race has been won, the lines are consumed
alternately by one process and then the other. (Setting `$|=1` in Perl causes each print statement
to flush the [`stdout`](@ref) handle, which is necessary for this example to work. Otherwise all
the output is buffered and printed to the pipe at once, to be read by just one consumer process.)

Here is an even more complex multi-stage producer-consumer example:

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

This example is similar to the previous one, except there are two stages of consumers, and the
stages have different latency so they use a different number of parallel workers, to maintain
saturated throughput.

We strongly encourage you to try all these examples to see how they work.
