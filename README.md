# make tutorial
## 概要
プログラムソースファイルからMarkdownを作る。

## 動機
- プログラミング学習時、チュートリアルを行う際にコード内にメモを残したい。
- チュートリアル完走と同時に「俺専用チュートリアル」が完成し、
  再学習時に使える様にしたい。
- 以前に[ddoc](https://dlang.org/spec/ddoc.html)や
  [Doxygen](https://www.doxygen.nl)を使っていたが、
  これらは目的がドキュメントの生成であるので代替の手段を用意したい。
    - ドキュメントはインターフェイスの説明であるのに対し、
      コードそのものへの注釈の形が望ましい。
    - Doxygenは高機能であるために同等以上の機能を提供するが、
      文法がやや複雑であり、記述量もやや多く、出力の量も多い。
- 出力されるMarkdownにプログラムの出力が入っていると読みやすい。

## ライセンス
```sh
LICENSE='Some rights reserved under MIT License, by garlic-flavor, March 23 2025.'
```
## GitHub リポジトリ
[GitHubリポジトリ](https://github.com/garlic-flavor/MakeTutorial)
```sh
GitHub='https://github.com/garlic-flavor/MakeTutorial'
```
## 目標
1. 元のソースコードとして適格。
2. 独自の書式をなるべく排し、書きやすく、覚えやすくする。
3. 処理前のソースコードを見てもまあまあ読める。
4. 様々なソースコードに対応しやすい。

## ToDo
1. 色々な言語に対応する。
2. 色々な実行環境に対応する。
3. 拡張子以外の方法で言語の種類を指定する方法を作る。
4. autotoolを用意する。

## 開発環境
- MacOS 15.4.1
- zsh 5.9 (x86_64-apple-darwin24.0)

## 説明
### 準備
1. ソースコードのコメントをMarkdown風に書く。
2. ファイル名の先頭を`01_`の様にして順番指定しておく。
3. shebangを書いて、`chmod u+x`しておく。

### 引数なしで実行した場合の処理の流れ。
1. 現在のフォルダ以下から、ファイル名が`01_My_First_Program.c`の様な
   数字で始まるファイル名のものを探す。
2. ファイルベース名でソートする。
3. 実行可能ファイルである場合はshebangを利用して実行し、出力を得る。
4. ファイルベース名のアンダーバーを空白に変えたものを`見出し1`で出力する。
5. 各言語毎に設定したドキュメント行からドキュメントヘッダ+空白1つを除き、
   Markdownにする。
6. ドキュメントヘッダ+'>'の行はシェルスクリプトと見做して実行し、
   その出力を得る。
7. ドキュメント行以外はコード行である。連続したコード行をまとめて
   コードブロックで括り、Markdownとして出力する。
8. 各言語毎に設定した出力行に、3.で得た内容を出力する。

### この`README.md`の出力コード
```sh
>zsh make_tutorial -oREADME.md make_tutorial
```
___!! この時、make_tutotial を実行可能(statが744)にしない !!___

### おまけ
MarkdownをHTMLにする。
[make_md2html](./README_make_md2html.html)

```sh
>zsh make_tutorial make_tutorial | zsh make_md2html -oREADME.html
```

## 使い方
```sh
USAGE="MakeTutorial: ソースコードからMarkdownを出力する。
$LICENSE
GitHub: $GitHub

オプション:
  -o : 出力ファイルを指定する。
  -t : ファイルの中身をパイプで渡す際に、タイトルと拡張子を指定する。

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

* パイプでファイルの中身を渡す。
>cat main.c | $0 -t My_Special_Program.c
"
```
## 対応言語
```sh
function setLanguageSpec {
  # Tcl
  if   [[ $1 = tcl ]]; then 
    EXT=$1
    DOC_HEADER='##'
    OUTPUT_HEADER='#>'

  # Shell script
  elif [[ $1 = sh || -z $1 ]]; then
    EXT=sh
    DOC_HEADER='##'
    OUTPUT_HEADER='#>'

  # C/C++ Programming Language
  elif [[ $1 = c(|pp) ]]; then
    EXT=$1
    DOC_HEADER='///'
    OUTPUT_HEADER='//>'

  # Fortran
  elif [[ ${1:l} = f(|[0-9][0-9]) ]]; then
    EXT=fortran
    DOC_HEADER='!!'
    OUTPUT_HEADER='!>'

  # 未対応ファイルだった。
  else
   print - "$1は非対応です。" >&2
   exit 1
  fi
}
```
## 詳細
### 標準入力からファイルの中身を読み取り、処理する。
```sh
function processContents {
  # 第一引数がファイルパス
  local filepath=$1

  # 実行可能なファイルの場合は実行する。
  local -a outs
  if [[ -x $filepath ]]; then
    #          ┏ 絶対パスを得る。
    ${filepath:a} | { while IFS= read -r line; do
      outs+=$line
    done}
  fi

  # ファイル名を見出しにする。
  # ファイル名から拡張子を除いて、アンダースコアをスペースに置換している。
  print - '# '${filepath:t:r} | sed s/_/\ /g

  # 言語用設定
  setLanguageSpec ${filepath:e}

  local counter=1 # 出力の何行目かを格納する。
  local insidecode=false # コードブロックかどうかを格納する。
  local emptycount=0 # コードブロック内で保留中の空行の数を格納する。
  local -a firstline # コードの一行目のシェルスクリプト行が格納される。
  local linenum=0 # 行数

  # 入力の各行に対して
  while IFS= read -r line; do
    tline=${${(MS)line##[[:graph:]]*[[:graph:]]}:l}
    # ┗ 末尾の空白を除き、小文字にしたもの。

    (( linenum++ ))
    # コードブロックに入る。
    function enterCode() {
      if $insidecode; then
        for (( i = 0; i<$emptycount; ++i )); do
          print -
        done
      else
        print - '```'$EXT
        insidecode=true
        if [[ $firstline ]]; then
          printf '%s\n' "${firstline[@]}"
          firstline=
        fi
      fi
      emptycount=0
    }
    # コードブロックを出る。
    function leaveCode() {
      if $insidecode; then
        print - '```'
        insidecode=false
      fi
    }

    # shebangはとばす。
    if   (( $linenum == 1 )) && [[ $line = '#!'* ]]; then
      firstline=($line)
    elif (( $linenum == 1 )) && [[ $line = '//usr/bin/env'* ]]; then
      firstline=($line)
    elif (( $linenum == 1 )) && [[ ${line:l} = '#if'* ]]; then
      firstline=($line)
      while IFS= read -r subline; do
        firstline+=$subline
        if [[ ${subline:l} = '#endif' ]]; then
          break
        fi
      done
    # 空行
    elif [[ -z $line ]]; then
      if $insidecode; then
        (( emptycount++ ))
      else
        print -
      fi
    # 処理を終える。
    elif [[ $tline = eof ]]; then
      break
    # 末尾が「hide」である行は出力しない。
    elif [[ $tline = *hideshebang ]]; then
      firstline=
    elif [[ $tline = *hide ]]; then
      enterCode
    elif [[ $tline = *hide! ]]; then
      enterCode
      ((counter++))
    # 「##>」で始まる行はシェルでコマンドを実行する。
    elif [[ $tline = $DOC_HEADER\>* ]]; then
      leaveCode
      eval ${line#*$DOC_HEADER\>}
    # ドキュメント行
    elif [[ $tline = $DOC_HEADER\ * ]]; then
      leaveCode
      print -r - ${line#*$DOC_HEADER\ }
    elif [[ $tline = $DOC_HEADER* ]]; then
      leaveCode
      print -r - ${line#*$DOC_HEADER}
    # 「#>!」があれば出力をとばす。
    elif [[ $line = *$OUTPUT_HEADER'!' ]]; then
      ((counter++))
    # 「#>」で終わる行にあらかじめ得ておいた出力を挿入する。
    elif [[ $line = *$OUTPUT_HEADER ]]; then
      enterCode
      print -rn - $line
      print -r - $outs[$counter]
      ((counter++))
    # それ以外はコードブロック
    else
      enterCode
      print -r - $line;
    fi
  done

  if $insidecode; then
    print - '```'
  fi
}
```
### 一つのファイルから標準出力にMarkdownを出力する。
```sh
function processAFile {
  # 第一引数がファイルパス
  local filepath=$1
  cat $filepath | processContents $filepath
}
```
### オプションのパース
```sh
title=
# オプションをパースする。
while getopts o:t:h OPT; do
  case $OPT in
    o) exec >$OPTARG;;
    #   ┗━━━┻ これ以降をリダイレクト
    t) title=$OPTARG;;
    h) print $USAGE; exit;;
    *) print $USAGE; exit 1;;
  esac
done
((1 < OPTIND)) && shift $((OPTIND - 1))
```
### 各ファイルに対して処理を実行する。
```sh
# stdin がターミナル(= パイプに接続されていない)。
if   [[ -t 0 ]]; then
  # 引数がある場合はそれを順に処理する。
  if (( $# )); then
    for aFile in $@; do
      processAFile $aFile
    done
  # 引数がない場合は現在のフォルダを検索する。
  else
    #       数字で始まるファイル名を持つファイルそれぞれに対して
    #     ┏ サブフォルダを再帰検索
    print -l **/<->* | {while read filepath; do
      #          ┏ basename;path に変換
      echo ${filepath:t}';'$filepath
      #      ┏ basename でソート
    done} | sort | { while read filepath; do
      #              ┏ 先頭のbasenameを除く。
      processAFile ${filepath##*;}
    done}
  fi
# stdin がパイプに接続されていて、
# titleが指定されている
elif [[ -n $title ]]; then
  processContents $title
# titleが指定されていない
else
  # パイプからファイル名を得る。
  while read line; do
    processAFile $line
  done
fi
```
