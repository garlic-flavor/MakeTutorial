# make tutorial
## Summary
プログラムソースファイルからMarkdownを作る。

## Motivations
- プログラミング学習時、チュートリアルを行う際にコード内にメモを残したい。
- 以前に[ddoc](https://dlang.org/spec/ddoc.html)や
  [Doxygen](https://www.doxygen.nl)を使っていたが、
  これらは目的がドキュメントの生成であるので代替の手段を用意したい。
    - ドキュメントはインターフェイスの説明であるのに対し、
      コードそのものへの注釈の形が望ましい。
    - Doxygenは高機能であるために同等以上の機能を提供するが、
      文法がやや複雑であり、記述量も多い。

## Development Environment
```sh
#!/usr/bin/env zsh
# MacOS 15 / zsh 5.9 (x86_64-apple-darwin24.0)
```

## License
```sh
LICENSE='Some rights reserved under MIT License, by garlic-flavor, March 23 2025.'
```
## GitHub Repository
[GitHubリポジトリ](https://github.com/garlic-flavor/MakeTutorial)
```sh
GitHub='https://github.com/garlic-flavor/MakeTutorial'
```
## Goals
1. 元のソースコードとして適格。
2. 独自の書式をなるべく排し、書きやすく、覚えやすくする。
3. 処理前のソースコードを見てもまあまあ読める。
4. 様々なソースコードに対応しやすい。

## ToDo
1. 色々な言語に対応する。
2. 色々な実行環境に対応する。
3. 拡張子以外の方法で言語の種類を指定する方法を作る。

## Description
### 準備
1. ソースコードのコメントをMarkdown風に書く。
2. ファイル名の先頭を`01_`の様にして順番指定しておく。
3. shebangを書いて、`chmod u+x`しておく。

### 引数なしで実行した場合の処理の流れ。
1. 現在のフォルダ以下から、ファイル名が`01_My_First_Program.c`の様な
   `連続した数字+アンダーバー`で始まるファイル名のものを探す。
2. ファイルベース名でソートする。
3. 実行可能ファイルである場合はshebangを利用して実行し、出力を得る。
4. ファイルベース名のアンダーバーを空白に変えたものを`見出し1`で出力する。
5. 各言語毎に設定したドキュメント行からドキュメントヘッダ+空白1つを除き、
   Markdownにする。
6. ドキュメント行以外はコード行である。連続したコード行をまとめて
   コードブロックで括り、Markdownとして出力する。
7. 各言語毎に設定した出力行に、3.で出力した内容をコード行として出力する。
8. 全て標準出力に出力する。

 ### この`README.md`の出力コード
 ```sh
 >zsh make_tutorial -oREADME.md make_tutorial
 ```
 ___!! この時、make_tutotial を実行可能(statが744)にしない !!___


## Usage
```sh
USAGE="MakeTutorial: ソースコードからMarkdownを出力する。
$LICENSE
GitHub: $GitHub

書式:
>$0 [-o targetfile] [file1 file2 ...]

例:
* 引数なしで現在のフォルダからMarkdownを標準出力に出力する。
>$0

* 引数で出力先と処理ファイルを指定する。
  source1.c source2.c の順に処理し、tutorial.md に出力する。
>$0 -o tutorial.md source1.c source2.c

* パイプで処理するファイルを渡す。
>ls *.c | $0
"
```
## Supported Languages
```sh
function setLanguageSpec {
  # Tcl
  if   [[ $1 == tcl ]]; then 
    EXT=$1
    DOC_HEADER='##'
    OUTPUT_HEADER='#>'

  # Shell script
  elif [[ $1 == sh || $1 == '' ]]; then
    EXT=sh
    DOC_HEADER='##'
    OUTPUT_HEADER='#>'

  # C Programming Language
  elif [[ $1 == c ]]; then
    EXT=$1
    DOC_HEADER='///'
    OUTPUT_HEADER='//>'

  # 未対応ファイルだった。
  else
    throw "$1は非対応です。"
  fi
}
```
## Details
### 一つのファイルから標準出力にMarkdownを出力する。
```sh
function processAFile {
  # 第一引数がファイルパス
  filepath=$1

  # 実行可能なファイルの場合は実行する。
  outs=()
  if [[ -x $filepath ]]; then
    #          ┏ 絶対パスを得る。
    ${filepath:a} | { while IFS='' read -r line; do
      outs=($outs $line)
    done}
  fi

  # ファイル名を見出しにする。
  # ファイル名から拡張子を除いて、アンダースコアをスペースに置換している。
  echo -n '# '
  echo $filepath:t:r | sed s/_/\ /g

  # 言語用設定
  setLanguageSpec $filepath:t:e

  counter=1 # 出力の何行目かを格納する。
  insidecode=false # コードブロックかどうかを格納する。
  emptycount=0 # コードブロック内で保留中の空行の数を格納する。
  firstline= # コードの一行目のシェルスクリプト行が格納される。

  # ファイルの各行に対して
  cat $filepath | {while IFS='' read -r line; do
    # コードブロックに入る。
    function enterCode() {
      if $insidecode; then
        for (( i = 0; i<$emptycount; ++i )); do
          echo
        done
      else
        echo '```'$EXT
        insidecode=true
        if [[ $firstline ]]; then
          echo -E $firstline
          firstline=
        fi
      fi
      emptycount=0
    }
    # コードブロックを出る。
    function leaveCode() {
      if $insidecode; then
        echo '```'
        insidecode=false
      fi
    }

    # shebangはとばす。
    if   [[ $line == '#!'* ]]; then
      firstline=$line
    elif [[ $line == '//usr/bin/env'* ]]; then
      firstline=$line
    # 空行
    elif [[ $line == '' ]]; then
      if $insidecode; then
        (( emptycount++ ))
      else
        echo
      fi
    # 末尾が「hide」である行は出力しない。
    elif [[ $line == *'hide' ]]; then
    elif [[ $line == *'hide!' ]]; then
      ((counter++))
    # ドキュメント行
    elif [[ $line == $DOC_HEADER* ]]; then
      leaveCode
      echo -E ${line:$((${#DOC_HEADER}+1))}
    # 「#>!」があれば出力をとばす。
    elif [[ $line == *$OUTPUT_HEADER'!' ]]; then
      ((counter++))
    # 「#>」で始まる行にあらかじめ得ておいた出力を挿入する。
    elif [[ $line == *$OUTPUT_HEADER ]]; then
      enterCode
      echo -n $line
      echo -E $outs[$counter]
      ((counter++))
    # それ以外はコードブロック
    else
      enterCode
      echo -E $line;
    fi
  done}
  if $insidecode; then
    echo '```'
  fi
}
```
### オプションのパース
```sh
# 出力先 1 は標準出力
output=1
# オプションをパースする。
while getopts o:h OPT; do
  case $OPT in
    o) output=$OPTARG;;
    h) print $USAGE; exit;;
    *) print $USAGE; exit 1;;
  esac
done
shift $((OPTIND - 1))
```
### 各ファイルに対して処理を実行する。
```sh
# stdin がターミナル(= パイプに接続されていない)。
{if [ -t 0 ]; then
  # 引数がある場合はそれを順に処理する。
  if (( $# )); then
    for aFile in $@; do
      processAFile $aFile
    done
  # 引数がない場合は現在のフォルダを検索する。
  else
    # 2桁の数字で始まるファイル名を持つファイルそれぞれに対して
    #   ┏ サブフォルダを再帰検索
    #   ┃              ┏ 数字とアンダーバーで始まるファイルにフィルタ
    ls -R | grep -E '^\d+_.*' | {while read filepath; do
      #          ┏ basename;path に変換
      echo ${filepath:t}';'$filepath
      #      ┏ basename でソート
    done} | sort | { while read filepath; do
      #              ┏ 先頭のbasenameを除く。
      processAFile ${filepath##*;}
    done}
  fi
# stdin がパイプに接続されている。
else
  # パイプからファイル名を得る。
  while read line; do
    processAFile $line
  done
fi} >&$output
```
