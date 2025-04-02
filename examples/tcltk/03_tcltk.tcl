#!/usr/bin/env wish
## tcl/tkでテストウィンドウを出す。
##
## ## Description
## - インタプリタは`tclsh`。Tkを使う場合は`wish`
## - Tclは文字列ベース。いろんなものが実は文字列。
## - `#`で一行コメント。ブロックコメントは存在しない。
## - コードの末尾にコメントがある場合は`;#`セミコロンが必要。
## - コードは上から実行され、main関数的なものは存在しない。
## - `""`で括ると置換が発生する。
## - `{}`で括ると置換は発生しない。
## - 括られた文字列には改行を含めることができる。
## - 空白文字を含まない文字列は括る必要がない。
## - 全角スペースは空白文字ではない。
## - 文字は非ASCII、サロゲートペアも一文字と数えられる。
## - 行末に`\`を置くと行が継続する。
## - `[]`で括ると、中身の評価結果に展開される。
## - コマンドライン引数は`argv`に格納されている。プログラム名は含まれていない。
## 
#                ┗ Tk用インタプリタ
package require cmdline
#                 ┗ コマンドライン引数をパースする。
#                   パースの対象は必ずしもコマンドラインのみに限らない
#                   通常の関数の引数も同様にパースが可能

## ### 自前のパッケージを読み込む。
## パッケージは前段の環境変数`TCLLIBPATH`にあるフォルダに構成されている
## ものとする。
package require miniclock 1.0
#                          ┗ 要求するヴァージョン。省略可。

## ### コマンドライン引数のパース
## tcl同梱のcmdlineパッケージを使う。
## コマンドライン引数に限定されず、通常の関数の引数のパースにも使える。
## - 書式 `{NAME(.arg|.arg?|arg+) (VALUE) HELP_MESSAGE}`
##     - NAME オプション名。指定する時は`-NAME`のようにハイフンを一つつける。
##     - .arg 引数を取ることを示す。
##     - .arg? 引数はオプション
##     - .arg+ 引数は複数ある。残りの引数全部か`--`までを引数にする。
##     - VALUE 引数の初期値
##     - HELP_MESSAGE ヘルプメッセージに表示される。

# 前段のZshから与えられた引数をパースする。
# ┏ 変数への代入
# ┃    ┏ 代入時に変数名に`$`はつけない。
# ┃    ┃    ┏ ブロックに見えるが文字列
# ┃    ┃    ┃ この中にコメントを書いても文字列と判定される。
set OPTIONS {
  {title.arg テストウィンドウ タイトルパーに表示する文字列}
  {width.arg 100 ウィンドウ幅の初期値}
  {height.arg 100 ウィンドウ高さの初期値}
  {msg.arg+ {} メッセージ}
  {verbose 冗長モード}
}
#         ┏ ""で括られた文字列には置換が発生する。
#         ┃ 中身の[cmdline::getArgv0]は展開される。
set USAGE " テストウィンドウ
書式:
  > [cmdline::getArgv0] -title ウィンドウタイトル"
#           ┃     ┗ 関数の呼び出し。()は必要ない。
#           ┗ namespaceの指定 $::argv のように書くとグローバル変数

# ┏ 例外処理 try - trap - finally
try {
  array set OPTS [cmdline::typedGetoptions argv $OPTIONS $USAGE]
  # ┃                                       ┗ 参照の仕組みがない為、lvalueを
  # ┃                                         とる必要がある場合は名前を指定
  # ┃                                         する。
  # ┗ 変数へ`Array`として代入する。
  #   `Array`は`キー`と`値`が交互に並んだリストのようなもの。
  #   $arr(hoge)のようにアクセスできる。
  #   関数からArrayを返す場合は`return [array get $arr]`の様に一度リストにする
  #   必要があり、注意が必要。
} trap {CMDLINE USAGE} {msg} {
  #          ┗ return の -errorcode 引数の値。後述の予定。
  puts $msg
  # ┗ 標準出力
  exit 1
  #    ┗ プログラムの終了値
} finally {
  puts 引数のパースを完了しました。
  #               ┗ 空白文字を含まなけれは""や{}は必要ない。
}

## ## Tk
## ### ウィンドウのレイアウト
wm title . $OPTS(title) ;# ウィンドウタイトルの変更
#        ┗ '.'は最外ウィンドウの名前。
wm geometry . $OPTS(width)x$OPTS(height) ;# ウィンドウサイズを指定する。

## 自前のパッケージを呼び出している。
grid [miniclock create .clock1] -column 0 -row 0 
# ┗ コントロールを並べる仕組みには他に pack などがある様だが、
#   とりあえず、grid で良い。

## ラベルを出す。
#            ┏ ラベルの名前
grid [label .l1 -text {Hello, Tcl/Tk world!} -fg white -bg black \
  -font {Helvetica -32}] \
  -column 1 -row 0 -sticky we

## テキストボックスを出す。
grid [text .t1] -column 0 -columnspan 2 -row 1 -sticky nesw

## ボタンを出す。
grid [button .b1 -text 喋るよ! -command button1Clicked] \
  -column 0 -columnspan 2 -row 2

proc button1Clicked {} {
  tk_messageBox -title 注意 -message 音が出ます。
  puts "say: [.t1 get 1.0 {end -1c}]"
  #                ┗ テキストボックスの内容を得る。
}

## 各グリッドを設定する。
grid columnconfigure . 0 -weight 0
grid columnconfigure . 1 -weight 1
grid rowconfigure . 1 -weight 1

