# Julia公式ドキュメント日本語化プロジェクト

## 概要

[プログラミング言語Juliaの公式ドキュメント](https://docs.julialang.org/en/v1/)を日本語に翻訳するプロジェクトです．現在はJulia 1.5の翻訳作業を進めています．

- [日本語ドキュメント(作業中)](https://fms-lab.github.io/julia-doc-ja/v1.5/)

## 作業の進め方

### 翻訳作業の手順

`/doc/src`内のファイル(.md)の翻訳を進めています．作業を開始する際は以下を実行してください．

1. Asigneeが存在しないIssueを選び作業を宣言(作業の衝突を防ぐため)
2. 翻訳作業の実施
3. PRの実施
4. PRのReviewおよびマージ

PRがマージされるとGithub Actionsにより自動でgh-pagesが更新され，[日本語ドキュメント](https://fms-lab.github.io/julia-doc-ja/v1.5/)にPR内容が反映されます．

参考情報：[日本語ドキュメント](https://fms-lab.github.io/julia-doc-ja/v1.5/)右上の`Edit on Github`から該当するmarkdownファイルに直接アクセスすることが可能です．作業箇所の選択の参考材料にして頂ければと思います．

### その他作業(誤訳や表現の修正，バク等)

適宜IssueおよびPRを実施頂けれますと幸いです．

## ビルド方法

mainブランチにPRがマージされる際，Github Actionsによって自動でビルドやデプロイは実行されます．もし動作確認等を理由にローカル環境でもビルドを実行したい場合がございましたら，本リポジトリのmainブランチのルートディレクトリで以下のコマンドを実行してください．`doc/src`内のMarkdownファイルが変換され，`doc/_build/html/ja`内にHTMLファイルが生成されます．

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
