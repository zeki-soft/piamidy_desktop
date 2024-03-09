#!/bin/sh

# デスクトップ録画
# recordmydesktop output.ogg

# WindowID(xwininfoコマンド取得)を指定してキャプチャ
# recordmydesktop -windowid 0x3a0001f
# xwininfo -display :0

# xwininfoで録画したいウィンドウの Window id を調べる
recordmydesktop --windowid `xwininfo -display :0 | grep 'id: 0x' | grep -Eo '0x[a-z0-9]+'`

# record開始
recordmydesktop output.ogg &
PROCESS_ID=$!

#(何かの処理)

# record停止
# ctrl+c によるSIGINTで停止
kill -s SIGINT ${PROCESS_ID}

# 録画処理が完了するまで待つ
wait ${PROCESS_ID}
