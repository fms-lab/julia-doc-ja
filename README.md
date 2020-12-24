# Julia公式ドキュメント日本語化プロジェクト

## 概要

[プログラミング言語Juliaの公式ドキュメント](https://docs.julialang.org/en/v1/)を日本語に翻訳するプロジェクトです．現在はJulia 1.5の翻訳作業を進めています．

- [Julia公式ドキュメント日本語版(作業中)](https://fms-lab.github.io/julia-doc-ja/v1.5/)

## 作業の進め方

### □ 翻訳作業の手順

`/doc/src`内のmarkdownファイルの翻訳作業を進めています．作業を開始する際は以下を実行して頂ければと思います．

1. Asigneeが存在しないIssueを選び作業を宣言 (作業の衝突を防ぐため)
2. 翻訳作業の実施
3. PRの実施

PRがマージされるとGithub Actionsにより自動でgh-pagesが更新され，[Julia公式ドキュメント日本語版](https://fms-lab.github.io/julia-doc-ja/v1.5/)にも翻訳内容(PR内容)が反映されます．

参考情報：[Julia公式ドキュメント日本語版](https://fms-lab.github.io/julia-doc-ja/v1.5/)右上の`Edit on Github`を押すことで，該当するmarkdownファイルにブラウザから直接アクセスすることが可能です．

### □ その他作業(誤訳や表現の修正，バク等)

適宜IssueおよびPRを実施頂けますと幸いです．

## ビルド方法

mainブランチにPRがマージされる際，Github Actionsによって自動でビルドやデプロイは実行されます．もし動作確認等を理由にローカル環境でもビルドしたいケースがあれば，本リポジトリのmainブランチのルートディレクトリで以下のコマンドを実行してください．`doc/src`内のMarkdownファイルが変換され，`doc/_build/html/ja`内にHTMLファイルが生成されます．

```bash
$make docs
```

## クレジット

先人の方々の翻訳内容を参考にさせて頂きながら本リポジトリでの作業を進めています．

- [kyokke](https://github.com/kyokke)さん
  - https://github.com/kyokke/julialang-doc-ja
- [mnru](https://github.com/mnru)さん
  - https://github.com/mnru/julia-doc-ja-v1.0-source
- [hshindo](https://github.com/hshindo)さん
  - https://github.com/hshindo/julia-doc-ja-v0.6
- [Julia Tokyo](http://julia.tokyo/)さん
  - https://github.com/JuliaTokyo/julia-doc-ja
