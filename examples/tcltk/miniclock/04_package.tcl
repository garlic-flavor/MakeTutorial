#!/usr/bin/env tclsh
## パッケージを使う。
## ### pkgIndexを作る。
## パッケージのファイルができたら`pkgIndex`を生成する。
## ```sh
## tclsh
## ```
## Tclインタプリタで
## ```tcl
## pkg_mkIndex miniclock
## ```
## のように`miniclock`の部分でパッケージのあるフォルダを指定する。
## フォルダ内に`pkgIndex`が生成される。
package provide miniclock 1.0
#                  ┗ 提供するパッケージ名。
#                    フォルダ名と一致させておく。

## パッケージで公開するシンボルを指定する。
#                   ┏ 名前空間を定義する。
namespace eval ::miniclock {
  namespace export create
  #                  ┗ シンボルを公開する。
  namespace ensemble create
  #           ┗ いい感じで呼び出せる様にする。

}

## 時計を作成する。
#         ┏ 名前空間を指定する。
proc ::miniclock::create {name} {

  set clockVar "miniclock.variable$name"
  global $clockVar
  #         ┗ 新しい名前でグローバル変数を定義している。

  after idle "tick $clockVar"
  #       ┗ アイドル時間に第二引数を評価する。

  set $clockVar {00:00}
  return [label $name -textvariable $clockVar -font {monospace -12}]
  #         ┃               ┗ ラベルで表示する内容を格納する変数名を指定する。
  #         ┃                 この変数に代入するとラベルも変更される。
  #         ┗ ラベルを出す。
}

## 時計の更新関数
proc tick {varName} {
  global $varName

  set systemTime [clock seconds]
  #                 ┗ 現在のUNIX時間を得る。
  set msec [expr {[clock milliseconds] % 1000}]
  #                   ┗ 現在時刻を高解像度で得ている。
  #                     clock format と互換性がないので注意。

  if {$msec < 500} {
    set fmt "%H %M"
    set nxt [expr {500-$msec}]
  } else {
    set fmt "%H:%M"
    set nxt [expr {1000-$msec}]
  }
  set $varName [clock format $systemTime -format $fmt]
  #                  ┗ 秒数を指定形式に変換する。
  after $nxt "tick $varName"
  # ┗ 第一引数ミリ秒後に第二引数を評価する。
}

