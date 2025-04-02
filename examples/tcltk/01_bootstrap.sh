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
##     2. 依存関係の解決(または指摘)。
##     3. Zshの起動
##
##   を行い、機能の実装は速やかにZsh以降で行う。
## - スクリプトエディタで最初の保存時に「アプリケーション」
##   を選ぶことでApp化できる。
## - *アプリアイコンを変更後はスクリプトの保存に失敗する。*
##
## ### 依存している機能がインストールされているか調べる。
## - シェルの単独起動では.zshrcやPATHは設定されていない。
##   シェルで`source /etc/profile` を実行するとPATHが設定される。
## - `which`はコマンドがないと失敗する。これを利用して依存関係を調べる。
##
## ```applescript
## try
## 	do shell script "source /etc/profile; which wish"
## 	--   ┗ wish がインストールされていなければ失敗する。
## on error
## 	display dialog "wishが見つかりませんでした。Tcl/Tkをインストールしてください。"
## --      ┗ メッセージボックスを出す。
## 	return
## end try
## ```
## ### Zshスクリプトを実行する。
## - `スクリプトのバンドルフォルダ/Contents/Resources/Scripts`にスクリプトを
##   保存しておく。
## - 実行時にPATHの準備とカレントディレクトリの変更をしておく。
##
## ```applescript
## -- PATHを用意し、カレントフオルダを変更してから起動すると開発しやすい。
## set wd to POSIX path of (path to resource "Scripts" as text)
## --  ┗ アプリのバンドル内のResourceフォルダ内の"Scripts"へのパスを
## --    POSIX形式で得る。
## --            do shell script で起動されいるのはshなのでzshを明示する。┓
## -- カレントフォルダを移動しておくと使いやすい。┓                         ┃
## do shell script ("source /etc/profile && cd " & wd & " && /usr/bin/env zsh ./01_bootstrap.sh")
## --     ┃                     ┃                ┗ 文字列の連結
## --     ┃                     ┗ PATH環境変数の準備
## --     ┗ /bin/sh を起動する。
## ```
##
## # 02 Zsh
## グルーとしてzshを利用する。
##
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
  if [[ $line =~ "^say:[[:space:]]*(.*)$" ]]; then
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

