# コードの読み込み

!!! note
    このチャプタではパッケージの読み込みの技術的な詳細について説明します．パッケージをインストールするには，Juliaの組み込みパッケージマネージャである[`Pkg`](@ref Pkg)を使って，パッケージをアクティブな環境に追加します．既にアクティブな環境にあるパッケージを使うには，[Modulesdocumentation](@ref modules)で説明されているように，`import X`または`using X`を書いてください．

## Definitions

Juliaには2種類のコード読み込みのメカニズムがあります:

1. **コードインクルージョン:**，例えば`include("source.jl")`．インクルードによって，単一のプログラムを複数のソースファイルに分割することが可能になります．`include("source.jl")`は，`include`呼び出しが発生したモジュールのグローバルスコープで，ファイル`source.jl`の内容を評価します．`include("source.jl")`が複数回呼び出された場合，`source.jl`は複数回評価されます．インクルードされたパスである`source.jl`は，`include`呼び出しが発生したファイルからの相対パスとして解釈されます．これにより，ソースファイルのサブツリーを簡単に再配置することができます．REPLでは，インクルードされたパスは，現在の作業ディレクトリ[`pwd()`](@ref)を基準に相対的に解釈されます．
2. **パッケージ読み込み:**例えば，`import X`または`using X`．インポートの仕組みを使うと，パッケージ，すなわち独立で再利用可能なJuliaコードの集合体をモジュールにラップしたものを読み込んで，その結果のモジュールをインポートしているモジュールの中で`X`という名前で利用できるようにします．同じ`X`パッケージが同じJuliaセッションで複数回インポートされた場合，読み込まれるのは最初のものだけで，その後のインポートではインポートモジュールは同じモジュールへの参照を取得します．ただし，`import X`は異なるコンテキストでは異なるパッケージを読み込むことができることに注意してください: `x`はメインプロジェクトでは`X`という名前のパッケージを参照しますが，依存関係ごとに`X`という名前の異なるパッケージを参照する可能性があります．これについては後述します．

コードインクルージョンは，非常に簡単でシンプルです: 呼び出し元のコンテキストで与えられたソースファイルを評価します．パッケージの読み込みはコードインクルージョンの上に構築され，[different purpose](@ref modules)を果たします．このチャプタの残りの部分はパッケージの読み込みの動作と仕組みに焦点を当てていきます．

*パッケージ*とは，他のJuliaプロジェクトで再利用できる機能を提供する標準的なレイアウトのソースツリーです．パッケージは`import X`または`using X`で読み込まれます．これらのステートメントは，パッケージのコードを読み込んだ結果として得られた`X`という名前のモジュールを，インポートステートメントが呼び出されたモジュール内で利用できるようにもします．`import X`内の`X`の意味はコンテキスト依存です，すなわち，どの`X`パッケージが読み込まれるかは，そのステートメントがどのコードで発生したかに依存します．したがって，`import X`のハンドリングには二段階あります．第一に，**どの**パッケージがこのコンテキストで`X`と定義されているかを決定し，第二にその特定の`X`パッケージが**どこ**にあるかを決定します．

これらの質問は[`LOAD_PATH`](@ref)に記載されているプロジェクト環境でプロジェクトファイル（`Project.toml`または`JuliaProject.toml`），マニフェストファイル（`Manifest.toml`または`JuliaManifest.toml`），またはソースファイルのフォルダを検索することで答えを得ることができます．


## パッケージのフェデレーション

ほとんどの場合，パッケージは名前だけで一意に識別できます．しかし，プロジェクトが同じ名前を
共有する二つの異なるパッケージを使用しなければならない場合もあります．どちらかのパッケージの
名前を変更することで解決できるかもしれませんが，大規模な共有されているコードベースでは，それ
を共有することはとても混乱を招きます．その代わりに，Juliaのコード読み込みのメカニズムでは，
同じパッケージ名を用いて，アプリケーションの異なるコンポーネントにおいて異なるパッケージを
参照することができます．

Juliaはフェデレートされたパッケージ管理をサポートしており，これは，複数の独立したパーティが
パブリックおよびプライベートなパッケージとパッケージのレジストリの両方を管理し，プロジェクト
は異なるレジストリからパブリックおよびプライベートパッケージを混在させながら依存できることを
意味します．様々なレジストリのパッケージは，共通のツールとワークフローのセットを使って
インストールされ，管理されます．Juliaにビルトインな`Pkg`というパッケージマネージャを使用
すると，プロジェクトに依存関係のあるものをインストールし，管理することができます．
プロジェクトファイル（プロジェクトが依存している他のプロジェクトを記述したもの）や
マニフェストファイル（プロジェクトの完全な依存関係グラフの正確なバージョンをスナップショット
したもの）の作成と操作を支援します．

フェデレーションの一つの結果として，パッケージの命名のための中央管理者は存在しません．
異なるエンティティが無関係なパッケージを参照するために同じ名前を使うことがあります．
これらのエンティティは連携しておらず，お互いのことを知らない場合もあるので，この可能性は
不可避です．中央の命名権限がないため，単一のプロジェクトが同じ名前の異なるパッケージに
依存してしまう可能性があります．Juliaのパッケージ読み込みメカニズムでは，単一のプロジェクト
の依存関係グラフ内であっても，パッケージ名がグローバルに一意である必要はありません．
その代わりに，パッケージは[universally unique identifiers](https://en.wikipedia.org/wiki/Universally_unique_identifier) (UUIDs)で識別され，
このUUIDは各パッケージが生成された時に割り当てられます．通常，`Pkg`が生成や追跡を担って
くれるので，この128ビットの識別子を直接扱う必要はありません．しかし，これらのUUIDは
*`X`はどのパッケージを参照しているか?*という質問に対する確実な答えを提供します．

中央管理されていない名前の問題は抽象的なので，問題を理解するためには具体的なシナリオを
見ていくことが役立つかもしれません．今，`App`というアプリケーションを開発しているとし，
その際`Pub`と`Priv`という2つのパッケージを使っているとしましょう．`Priv`はあなたが作った
プライベートパッケージであり，`Pub`はあなたが使用しているが管理はしていないパブリック
パッケージです．あなたが`Priv`を作成した時，`Priv`という名前のパブリックパッケージは
ありませんでした．しかしその後，`Priv`という名前の無関係なパッケージが公開され，人気が
出てきました．実際，`Pub`パッケージはそれを使い始めました．そのため，次に`Pub`を
アップグレードして最新のバグフィックスや機能を手に入れようとすると，アップグレード以外に
何もしなくても，`App`は`Priv`という名前の異なる2つのパッケージに依存してしまうことに
なります．`App`はあなたのプライベートな`Priv`パッケージに直接依存しており，`Pub`を通して
新しいパブリックな`Priv`パッケージに間接的に依存しています．これら2つの`Priv`パッケージは
異なるものですが，`App`が正しく動作し続けるためには双方が必要なので，`import Priv`が，
`App`のコードの中にあるのか，`Pub`のコードにあるのかによって，異なる`Priv`パッケージを
参照しなければなりません．これを処理するために，Juliaのパッケージ読み込みメカニズムは
2つの`Priv`パッケージをUUIDで区別し，そのコンテキスト（すなわち`import`を呼んだモジュール）
に基づいて，正しい方を選択します．以下のセクションで説明するように，これは環境によって
決まります．

## 環境

*環境*とは，様々なコードコンテキストにおける`import X`および`using X`の意味と，これらの
ステートメントによって読み込まれるファイルが何かを決定するものです．Juliaは2種類の環境を
理解しています:

1. **プロジェクト環境**はプロジェクトファイルとオプションのマニフェストファイルを含むディレクトリで，明示的な環境を形成します．プロジェクトファイルはプロジェクトの直接の依存関係の名前と同一性を決定づけます．マニフェストファイルがあるのであれば，全ての直接および間接的な依存関係，各依存関係の正確なバージョン，正しいバージョンを探して読み込むための十分な情報を含む，完全な依存関係グラフを提供します．
2. **パッケージディレクトリ**はパッケージの集合のソースツリーをサブディレクトリとして含むディレクトリであり，暗黙の環境を形成します．`X`がパッケージディレクトリのサブディレクトリであり，`X/src/X.jl`が存在する場合，パッケージ`X`はパッケージディレクトリ環境で利用可能であり，`X/src/X.jl`はそれがロードされるソースファイルです．

これらを混ぜ合わせて**スタック環境**を作成することができます，すなわち，プロジェクト環境と
パッケージディレクトリを順番に重ね合わせて一つの複合環境を作るということです．優先度と
可視性のルールを組み合わせて，どのパッケージが利用可能で，どこからロードされるのかを決定
します．例えばJuliaの読み込みパスはスタック環境を形成します．

これらの環境はそれぞれ異なる目的を持っています:

* プロジェクト環境は**再現性**を提供します．プロジェクト環境をバージョンコントロール（例えばgitリポジトリなど）でプロジェクトのの残りのソースコードと一緒にチェックすることで，プロジェクトとその依存関係の全てを正確に再現することができます．特にマニフェストファイルは，ソースツリーの暗号化ハッシュによって識別される全ての依存関係の正確なバージョンをキャプチャします．これにより，`Pkg`は正しいバージョンを取得し，全ての依存関係について記録された正確なコードを実行していることを確認することが可能になります．
* パッケージディレクトリは，完全に注意深く追跡されたプロジェクト環境は必要ないような場合に便利です．パッケージディレクトリはパッケージのセットをどこかに置いておいて，そのパッケージ向けのプロジェクト環境を作らなくても直接使えるようにしたいときに便利です．
* スタック環境では，プライマリ環境にツールを**追加**することができます．開発ツールの環境をスタックの端にプッシュしてREPLやスクリプトから利用できるようにすることはできますが，パッケージの内部からは利用できません．

高いレベルでは，各環境は概念的に，roots, graph, pathsの3つのマップを定義しています．`import X`の意味を解決するとき，rootsマップとgraphマップは`X`の同一性を決定するために使用され，pathsマップは`X`のソースコードを見つけるために使用されます．3つのマップの具体的な役割は以下の通りです:

- **roots:** `name::Symbol` ⟶ `uuid::UUID`

   環境のrootsマップは，その環境がメインプロジェクトで利用できるようにしているトップレベルの依存関係（すなわち，`Main`で読み込めるもの）の全てのUUIDにパッケージ名を割り当てます．Juliaのメインプロジェクト内で`import X`があると，Juliaは`X`のIDを`root[:X]`として調べます．

- **graph:** `context::UUID` ⟶ `name::Symbol` ⟶ `uuid::UUID`

   環境のgraphは，各`context` UUIDに対して，名前からUUIDへのマップを割り当てる多階層マップで，rootsマップに似ていますが，`context`に固有のものです．UUIDが`context`であるパッケージのコードの中で`import X`を見ると，Juliaは`graph[context][:X]`として`X`の同一性を調べます．特に，これは`import X`が`context`によって，異なるパッケージを参照できることを意味します．

- **paths:** `uuid::UUID` × `name::Symbol` ⟶ `path::String`

   pathsマップは各パッケージのUUID-名前のペアに，そのパッケージのエントリポイントソースファイルの場所を割り当てます．`import X`の`X`がrootsまたはgraph（メインプロジェクトから読み込まれるか依存関係から読み込まれるかによって変化する）経由でUUIDに名前解決されたあと，Juliaは環境内の`paths[uuid,:X]`を検索することで，`X`を取得するために読み込むファイルを決定します．このファイルをインクルードすると，`X`という名前のモジュールが定義されるはずです．このパッケージが読み込まれると，同じ`uuid`に解決する後続のインポートは，すでにロードされているパッケージモジュールへの新しいバインディングを作成します．

環境の種類ごとに，以下のセクションで詳しく説明するように，これらの3つのマップは異なる定義をしています．

!!! note
    理解を容易にするためにこの章の例では，roots, graph, pathsの完全なデータ構造を示していますが，Juliaのパッケージ読み込みコードはこれらを明示的には作成しません．その代わりに，与えられたパッケージを読み込むのに必要な分だけ，各構造の計算だけを行っています．

### プロジェクト環境

プロジェクト環境は，`Project.toml`と呼ばれるプロジェクトファイルと，必要に応じて`Manifest.toml`と呼ばれるマニフェストファイルを含むディレクトリによって決定されます．これらのファイルは，`JuliaProject.toml`や`JuliaManifest.toml`と呼ばれることもあり，この場合は`Project.toml`や`Manifest.toml`は無視されます．これにより，`Project.toml`や`Manifest.toml`と呼ばれるファイルを重視する他のツールとの共存が可能になります．しかし純粋なJuliaプロジェクトでは，`Project.toml`や`Manifest.toml`という名前が好まれます．

プロジェクト環境のrootsマップ，graphマップ，pathsマップは以下のように定義されています:

環境の**rootsマップ**は，プロジェクトファイルの内容，特にトップレベルの`name`と`uuid`エントリ，`[deps]`セクション（全てオプション）によって決まります．先に説明した仮想アプリケーション`App`のプロジェクトファイルの例を考えてみましょう:

```toml
name = "App"
uuid = "8f986787-14fe-4607-ba5d-fbff2944afa9"

[deps]
Priv = "ba13f791-ae1d-465a-978b-69c3ad90f72b"
Pub  = "c07ecb7d-0dc9-4db7-8803-fadaaeaf08e1"
```

このプロジェクトファイルは，Juliaの辞書型で表現されている場合，以下のようなrootsマップを意味しています:

```julia
roots = Dict(
    :App  => UUID("8f986787-14fe-4607-ba5d-fbff2944afa9"),
    :Priv => UUID("ba13f791-ae1d-465a-978b-69c3ad90f72b"),
    :Pub  => UUID("c07ecb7d-0dc9-4db7-8803-fadaaeaf08e1"),
)
```

このようなrootsマップが与えられると，`App`のコードでは，`import Priv`というステートメントがJuliaに`roots[:Priv]`を検索させ，そのコンテキストで読み込まれる`Priv`パッケージのUUIDである`ba13f791-ae1d-465a-978b-69c3ad90f72b`が生成されます．このUUIDは，メインアプリケーションが`import Priv`を評価する際に，どの`Priv`パッケージを読み込んで使用するかを識別します．

プロジェクト環境の**依存関係graph**は，マニフェストファイルがあれば，その内容によって決定されます．マニフェストファイルがない場合は，graphは空です．マニフェストファイルには，直接または間接的な依存関係のそれぞれについての節が含まれています．各依存関係について，ファイルにはパッケージのUUIDとソースツリーハッシュ，またはソースコードへの明示的なパスがリストされています．次の例で，例として`App`のマニフェストファイルを見てみましょう:

```toml
[[Priv]] # the private one
deps = ["Pub", "Zebra"]
uuid = "ba13f791-ae1d-465a-978b-69c3ad90f72b"
path = "deps/Priv"

[[Priv]] # the public one
uuid = "2d15fe94-a1f7-436c-a4d8-07a9a496e01c"
git-tree-sha1 = "1bf63d3be994fe83456a03b874b409cfd59a6373"
version = "0.1.5"

[[Pub]]
uuid = "c07ecb7d-0dc9-4db7-8803-fadaaeaf08e1"
git-tree-sha1 = "9ebd50e2b0dd1e110e842df3b433cb5869b0dd38"
version = "2.1.4"

  [Pub.deps]
  Priv = "2d15fe94-a1f7-436c-a4d8-07a9a496e01c"
  Zebra = "f7a24cb4-21fc-4002-ac70-f0e3a0dd3f62"

[[Zebra]]
uuid = "f7a24cb4-21fc-4002-ac70-f0e3a0dd3f62"
git-tree-sha1 = "e808e36a5d7173974b90a15a353b564f3494092f"
version = "3.4.2"
```

このマニフェストファイルには，`App`プロジェクトの完全な依存関係グラフが記述されています:

- アプリケーションが使用する`Priv`という名前の，異なる2つのパッケージがあります．ルート依存関係にあるプライベートパッケージと，`Pub`を通じて間接的に依存関係にあるパブリックパッケージを使用しています．これらは異なるUUIDによって区別されており，異なるdepsを持っています:
  * プライベートな`Priv`は`Pub`と`Zebra`パッケージに依存しています．
  * パブリックな`Priv`には依存関係はありません．
- アプリケーションは`Pub`パッケージにも依存しており，`Pub`パッケージはパブリックな`Priv`と，プライベートな`Priv`が依存しているのと同じ`Zebra`パッケージに依存しています．


この依存関係graphを辞書で書くと，以下のようになります:

```julia
graph = Dict(
    # Priv – the private one:
    UUID("ba13f791-ae1d-465a-978b-69c3ad90f72b") => Dict(
        :Pub   => UUID("c07ecb7d-0dc9-4db7-8803-fadaaeaf08e1"),
        :Zebra => UUID("f7a24cb4-21fc-4002-ac70-f0e3a0dd3f62"),
    ),
    # Priv – the public one:
    UUID("2d15fe94-a1f7-436c-a4d8-07a9a496e01c") => Dict(),
    # Pub:
    UUID("c07ecb7d-0dc9-4db7-8803-fadaaeaf08e1") => Dict(
        :Priv  => UUID("2d15fe94-a1f7-436c-a4d8-07a9a496e01c"),
        :Zebra => UUID("f7a24cb4-21fc-4002-ac70-f0e3a0dd3f62"),
    ),
    # Zebra:
    UUID("f7a24cb4-21fc-4002-ac70-f0e3a0dd3f62") => Dict(),
)
```

Given this dependency `graph`, when Julia sees `import Priv` in the `Pub` package—which has UUID `c07ecb7d-0dc9-4db7-8803-fadaaeaf08e1`—it looks up:

```julia
graph[UUID("c07ecb7d-0dc9-4db7-8803-fadaaeaf08e1")][:Priv]
```

and gets `2d15fe94-a1f7-436c-a4d8-07a9a496e01c`, which indicates that in the context of the `Pub` package, `import Priv` refers to the public `Priv` package, rather than the private one which the app depends on directly. This is how the name `Priv` can refer to different packages in the main project than it does in one of its package's dependencies, which allows for duplicate names in the package ecosystem.

What happens if `import Zebra` is evaluated in the main `App` code base? Since `Zebra` does not appear in the project file, the import will fail even though `Zebra` *does* appear in the manifest file. Moreover, if `import Zebra` occurs in the public `Priv` package—the one with UUID `2d15fe94-a1f7-436c-a4d8-07a9a496e01c`—then that would also fail since that `Priv` package has no declared dependencies in the manifest file and therefore cannot load any packages. The `Zebra` package can only be loaded by packages for which it appear as an explicit dependency in the manifest file: the  `Pub` package and one of the `Priv` packages.

**The paths map** of a project environment is extracted from the manifest file. The path of a package `uuid` named `X` is determined by these rules (in order):

1. If the project file in the directory matches `uuid` and name `X`, then either:
  - It has a toplevel `path` entry, then `uuid` will be mapped to that path, interpreted relative to the directory containing the project file.
  - Otherwise, `uuid` is mapped to  `src/X.jl` relative to the directory containing the project file.
2. If the above is not the case and the project file has a corresponding manifest file and the manifest contains a stanza matching `uuid` then:
  - If it has a `path` entry, use that path (relative to the directory containing the manifest file).
  - If it has a `git-tree-sha1` entry, compute a deterministic hash function of `uuid` and `git-tree-sha1`—call it `slug`—and look for a directory named `packages/X/$slug` in each directory in the Julia `DEPOT_PATH` global array. Use the first such directory that exists.

If any of these result in success, the path to the source code entry point will be either that result, the relative path from that result plus `src/X.jl`; otherwise, there is no path mapping for `uuid`. When loading `X`, if no source code path is found, the lookup will fail, and the user may be prompted to install the appropriate package version or to take other corrective action (e.g. declaring `X` as a dependency).

In the example manifest file above, to find the path of the first `Priv` package—the one with UUID `ba13f791-ae1d-465a-978b-69c3ad90f72b`—Julia looks for its stanza in the manifest file, sees that it has a `path` entry, looks at `deps/Priv` relative to the `App` project directory—let's suppose the `App` code lives in `/home/me/projects/App`—sees that `/home/me/projects/App/deps/Priv` exists and therefore loads `Priv` from there.

If, on the other hand, Julia was loading the *other* `Priv` package—the one with UUID `2d15fe94-a1f7-436c-a4d8-07a9a496e01c`—it finds its stanza in the manifest, see that it does *not* have a `path` entry, but that it does have a `git-tree-sha1` entry. It then computes the `slug` for this UUID/SHA-1 pair, which is `HDkrT` (the exact details of this computation aren't important, but it is consistent and deterministic). This means that the path to this `Priv` package will be `packages/Priv/HDkrT/src/Priv.jl` in one of the package depots. Suppose the contents of `DEPOT_PATH` is `["/home/me/.julia", "/usr/local/julia"]`, then Julia will look at the following paths to see if they exist:

1. `/home/me/.julia/packages/Priv/HDkrT`
2. `/usr/local/julia/packages/Priv/HDkrT`

Julia uses the first of these that exists to try to load the public `Priv` package from the file `packages/Priv/HDKrT/src/Priv.jl` in the depot where it was found.

Here is a representation of a possible paths map for our example `App` project environment,
as provided in the Manifest given above for the dependency graph,
after searching the local file system:

```julia
paths = Dict(
    # Priv – the private one:
    (UUID("ba13f791-ae1d-465a-978b-69c3ad90f72b"), :Priv) =>
        # relative entry-point inside `App` repo:
        "/home/me/projects/App/deps/Priv/src/Priv.jl",
    # Priv – the public one:
    (UUID("2d15fe94-a1f7-436c-a4d8-07a9a496e01c"), :Priv) =>
        # package installed in the system depot:
        "/usr/local/julia/packages/Priv/HDkr/src/Priv.jl",
    # Pub:
    (UUID("c07ecb7d-0dc9-4db7-8803-fadaaeaf08e1"), :Pub) =>
        # package installed in the user depot:
        "/home/me/.julia/packages/Pub/oKpw/src/Pub.jl",
    # Zebra:
    (UUID("f7a24cb4-21fc-4002-ac70-f0e3a0dd3f62"), :Zebra) =>
        # package installed in the system depot:
        "/usr/local/julia/packages/Zebra/me9k/src/Zebra.jl",
)
```

This example map includes three different kinds of package locations (the first and third are part of the default load path):

1. The private `Priv` package is "[vendored](https://stackoverflow.com/a/35109534)" inside the `App` repository.
2. The public `Priv` and `Zebra` packages are in the system depot, where packages installed and managed by the system administrator live. These are available to all users on the system.
3. The `Pub` package is in the user depot, where packages installed by the user live. These are only available to the user who installed them.


### Package directories

Package directories provide a simpler kind of environment without the ability to handle name collisions. In a package directory, the set of top-level packages is the set of subdirectories that "look like" packages. A package `X` is exists in a package directory if the directory contains one of the following "entry point" files:

- `X.jl`
- `X/src/X.jl`
- `X.jl/src/X.jl`

Which dependencies a package in a package directory can import depends on whether the package contains a project file:

* If it has a project file, it can only import those packages which are identified in the `[deps]` section of the project file.
* If it does not have a project file, it can import any top-level package—i.e. the same packages that can be loaded in `Main` or the REPL.

**The roots map** is determined by examining the contents of the package directory to generate a list of all packages that exist.
Additionally, a UUID will be assigned to each entry as follows: For a given package found inside the folder `X`...

1. If `X/Project.toml` exists and has a `uuid` entry, then `uuid` is that value.
2. If `X/Project.toml` exists and but does *not* have a top-level UUID entry, `uuid` is a dummy UUID generated by hashing the canonical (real) path to `X/Project.toml`.
3. Otherwise (if `Project.toml` does not exist), then `uuid` is the all-zero [nil UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Nil_UUID).

**The dependency graph** of a project directory is determined by the presence and contents of project files in the subdirectory of each package. The rules are:

- If a package subdirectory has no project file, then it is omitted from graph and import statements in its code are treated as top-level, the same as the main project and REPL.
- If a package subdirectory has a project file, then the graph entry for its UUID is the `[deps]` map of the project file, which is considered to be empty if the section is absent.

As an example, suppose a package directory has the following structure and content:

```
Aardvark/
    src/Aardvark.jl:
        import Bobcat
        import Cobra

Bobcat/
    Project.toml:
        [deps]
        Cobra = "4725e24d-f727-424b-bca0-c4307a3456fa"
        Dingo = "7a7925be-828c-4418-bbeb-bac8dfc843bc"

    src/Bobcat.jl:
        import Cobra
        import Dingo

Cobra/
    Project.toml:
        uuid = "4725e24d-f727-424b-bca0-c4307a3456fa"
        [deps]
        Dingo = "7a7925be-828c-4418-bbeb-bac8dfc843bc"

    src/Cobra.jl:
        import Dingo

Dingo/
    Project.toml:
        uuid = "7a7925be-828c-4418-bbeb-bac8dfc843bc"

    src/Dingo.jl:
        # no imports
```

Here is a corresponding roots structure, represented as a dictionary:

```julia
roots = Dict(
    :Aardvark => UUID("00000000-0000-0000-0000-000000000000"), # no project file, nil UUID
    :Bobcat   => UUID("85ad11c7-31f6-5d08-84db-0a4914d4cadf"), # dummy UUID based on path
    :Cobra    => UUID("4725e24d-f727-424b-bca0-c4307a3456fa"), # UUID from project file
    :Dingo    => UUID("7a7925be-828c-4418-bbeb-bac8dfc843bc"), # UUID from project file
)
```

Here is the corresponding graph structure, represented as a dictionary:

```julia
graph = Dict(
    # Bobcat:
    UUID("85ad11c7-31f6-5d08-84db-0a4914d4cadf") => Dict(
        :Cobra => UUID("4725e24d-f727-424b-bca0-c4307a3456fa"),
        :Dingo => UUID("7a7925be-828c-4418-bbeb-bac8dfc843bc"),
    ),
    # Cobra:
    UUID("4725e24d-f727-424b-bca0-c4307a3456fa") => Dict(
        :Dingo => UUID("7a7925be-828c-4418-bbeb-bac8dfc843bc"),
    ),
    # Dingo:
    UUID("7a7925be-828c-4418-bbeb-bac8dfc843bc") => Dict(),
)
```

A few general rules to note:

1. A package without a project file can depend on any top-level dependency, and since every package in a package directory is available at the top-level, it can import all packages in the environment.
2. A package with a project file cannot depend on one without a project file since packages with project files can only load packages in `graph` and packages without project files do not appear in `graph`.
3. A package with a project file but no explicit UUID can only be depended on by packages without project files since dummy UUIDs assigned to these packages are strictly internal.

Observe the following specific instances of these rules in our example:

* `Aardvark` can import on any of `Bobcat`, `Cobra` or `Dingo`; it does import `Bobcat` and `Cobra`.
* `Bobcat` can and does import both `Cobra` and `Dingo`, which both have project files with UUIDs and are declared as dependencies in `Bobcat`'s `[deps]` section.
* `Bobcat` cannot depend on `Aardvark` since `Aardvark` does not have a project file.
* `Cobra` can and does import `Dingo`, which has a project file and UUID, and is declared as a dependency in `Cobra`'s  `[deps]` section.
* `Cobra` cannot depend on `Aardvark` or `Bobcat` since neither have real UUIDs.
* `Dingo` cannot import anything because it has a project file without a `[deps]` section.

**The paths map** in a package directory is simple: it maps subdirectory names to their corresponding entry-point paths. In other words, if the path to our example project directory is `/home/me/animals` then the `paths` map could be represented by this dictionary:

```julia
paths = Dict(
    (UUID("00000000-0000-0000-0000-000000000000"), :Aardvark) =>
        "/home/me/AnimalPackages/Aardvark/src/Aardvark.jl",
    (UUID("85ad11c7-31f6-5d08-84db-0a4914d4cadf"), :Bobcat) =>
        "/home/me/AnimalPackages/Bobcat/src/Bobcat.jl",
    (UUID("4725e24d-f727-424b-bca0-c4307a3456fa"), :Cobra) =>
        "/home/me/AnimalPackages/Cobra/src/Cobra.jl",
    (UUID("7a7925be-828c-4418-bbeb-bac8dfc843bc"), :Dingo) =>
        "/home/me/AnimalPackages/Dingo/src/Dingo.jl",
)
```

Since all packages in a package directory environment are, by definition, subdirectories with the expected entry-point files, their `paths` map entries always have this form.

### Environment stacks

The third and final kind of environment is one that combines other environments by overlaying several of them, making the packages in each available in a single composite environment. These composite environments are called *environment stacks*. The Julia `LOAD_PATH` global defines an environment stack—the environment in which the Julia process operates. If you want your Julia process to have access only to the packages in one project or package directory, make it the only entry in `LOAD_PATH`. It is often quite useful, however, to have access to some of your favorite tools—standard libraries, profilers, debuggers, personal utilities, etc.—even if they are not dependencies of the project you're working on. By adding an environment containing these tools to the load path, you immediately have access to them in top-level code without needing to add them to your project.

The mechanism for combining the roots, graph and paths data structures of the components of an environment stack is simple: they are merged as dictionaries, favoring earlier entries over later ones in the case of key collisions. In other words, if we have `stack = [env₁, env₂, …]` then we have:

```julia
roots = reduce(merge, reverse([roots₁, roots₂, …]))
graph = reduce(merge, reverse([graph₁, graph₂, …]))
paths = reduce(merge, reverse([paths₁, paths₂, …]))
```

The subscripted `rootsᵢ`, `graphᵢ` and `pathsᵢ` variables correspond to the subscripted environments, `envᵢ`, contained in `stack`. The `reverse` is present because `merge` favors the last argument rather than first when there are collisions between keys in its argument dictionaries. There are a couple of noteworthy features of this design:

1. The *primary environment*—i.e. the first environment in a stack—is faithfully embedded in a stacked environment. The full dependency graph of the first environment in a stack is guaranteed to be included intact in the stacked environment including the same versions of all dependencies.
2. Packages in non-primary environments can end up using incompatible versions of their dependencies even if their own environments are entirely compatible. This can happen when one of their dependencies is shadowed by a version in an earlier environment in the stack (either by graph or path, or both).

Since the primary environment is typically the environment of a project you're working on, while environments later in the stack contain additional tools, this is the right trade-off: it's better to break your development tools but keep the project working. When such incompatibilities occur, you'll typically want to upgrade your dev tools to versions that are compatible with the main project.

## Conclusion

Federated package management and precise software reproducibility are difficult but worthy goals in a package system. In combination, these goals lead to a more complex package loading mechanism than most dynamic languages have, but it also yields scalability and reproducibility that is more commonly associated with static languages. Typically, Julia users should be able to use the built-in package manager to manage their projects without needing a precise understanding of these interactions. A call to `Pkg.add("X")` will add to the appropriate project and manifest files, selected via `Pkg.activate("Y")`, so that a future call to `import X` will load `X` without further thought.
