#!/usr/bin/env zsh
# hideshebang
## AppleScript -> zsh <-> tcl/tk コンボの説明。
##
## ## ストラテジ
## 1. 開発時はZshで起動。
## 2. GUIはcoprocでwish(Tcl/Tk)を起動。
## 3. Tcl<->Zsh間では標準パイプで通信し、
##    Zshで不足な部分はCとか何かで実装する。
## 4. 最後にAppleScriptでApp化する。
##
## このメリットは非同期処理を実装しやすいこと。
##
## ## AppleScriptで起動する。
## - AppleScriptでは
##     1. App化
##     2. Zshの起動
##
##   を行い、機能の実装は速やかにZsh以降で行う。
## - スクリプトエディタで最初の保存時に
##     + `on run`イベントハンドラを書く。
##     + 「アプリケーション」を選ぶ。
##   でApp化できる。
## - *アプリアイコンを変更後はスクリプトの保存に失敗する。*
##
## ### Zshスクリプトを実行する。
## - `スクリプトのバンドルフォルダ/Contents/Resources/Scripts`にスクリプトを
##   保存しておく。
## - 実行時にPATHの準備とカレントディレクトリの変更をしておく。
## - シェルの単独起動では.zshrcやPATHは設定されていない。
##   シェルで`source /etc/profile` を実行するとPATHが設定される。
##
## ```applescript
## -- PATHを用意し、カレントフオルダを変更してから起動すると開発しやすい。
## on run
##   set wd to POSIX path of (path to resource "Scripts" as text)
##   --  ┗ アプリのバンドル内のResourceフォルダ内の"Scripts"へのパスを
##   --    POSIX形式で得る。
##   try
##     --           do shell script で起動されいるのはshなのでzshを明示する。┓
##     -- カレントフォルダを移動しておくと使いやすい。┓                        ┃
##     do shell script ("source /etc/profile && cd " & wd & " && /usr/bin/env zsh ./01_bootstrap.sh")
##     --     ┃                     ┃                ┗ 文字列の連結
##     --     ┃                     ┗ PATH環境変数の準備
##     --     ┗ /bin/sh を起動する。
##   on error msg
##     --     ┗stderrの内容が格納されている。
##     display dialog msg
##     -- ┗メッセージボックスを出す。
##   end try
## end run
## ```
##
## # 02 Zsh
## グルーとしてzshを利用する。
##
## ### 依存している機能がインストールされているか調べる。
function 依存関係を調べる {
  if [[ ${+commands[$1]} -eq 0 ]]; then
  #       ┗定義済みなら1に展開される。
    >&2 print - $2 がインストールされていません。
    >&2 print - $3 $2 をインストールしてください。
    exit 1
  fi
}
依存関係を調べる wish Tcl/Tk GUI表示に使っています。

## ## GUIの起動
coproc TCLLIBPATH=. wish ./03_tcltk.tcl -title サンプル1 -width 640 -height 480
# ┃         ┃         ┗ Tkを使うインタプリタ。ターミナルを出さない。
# ┃         ┗ Tclのパッケージがあるフォルダの指定
# ┗ バックグラウンドで実行し、パイプをpに設定する。

## ## GUIからの入力の監視
# ┏ 読み込みを続ける。
# ┃   ┏ IFS='' で空白をそのまま読み込む
# ┃   ┃ ┏ 一行読み込む
# ┃   ┃ ┃  ┏ -r でエスケープシーケンスをそのまま読み込む
# ┃   ┃ ┃  ┃ ┏ 読み込まれた行が格納される変数名
# ┃   ┃ ┃  ┃ ┃  ┏ セミコロンを忘れがち
{while read line; do
  if [[ $line =~ '^say:[[:space:]]*(.*)$' ]]; then
  #            ┃            ┗ \sに当たる表現。
  #            ┗ 正規表現。マッチ全体が$MATCHに、サブマッチが$matchに
  #              格納される。
    say $match[1] &
    # ┃           ┗ 非同期処理
    # ┗ 喋るやつ
  else
    echo ">>> $line"
  fi
done} <&p
#   ┃  ┗ Tkの標準出力から読み込む
#   ┗ 忘れがち
wait
# ┗ バックグラウンドジョブの終了待ち。(この例では必要ない)
echo '***** DONE *****'

