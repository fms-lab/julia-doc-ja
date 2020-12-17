# プログラミング言語Julia公式ドキュメント日本語化プロジェクト

## 概要

[プログラミング言語Juliaの公式ドキュメント](https://docs.julialang.org/en/v1/)を日本語に翻訳するプロジェクトです．
現在はJulia 1.5のドキュメントの対応を進めています．

- https://fms-lab.github.io/julia-doc-ja/v1.5/

## ビルド方法

本リポジトリのmainブランチのルートディレクトリで以下のコマンドを実行してください．
`doc/src`内のMarkdownファイルが変換され，`doc/_build`にHTMLファイルが生成されます．

```bash
$make docs
```

gh-pagesブランチ内のファイルは`doc/_build`内に生成されたものです．

## ライセンス

- [MIT ライセンス](https://tldrlegal.com/license/mit-license)
