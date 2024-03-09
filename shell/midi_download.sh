#!/bin/sh

# 引数チェック
if [ $# = 0 ]; then
    echo "引数に接続先ドメインを指定してください。"
    exit 1
fi

# ダウンロード対象
if [ $# = 2 ]; then
    VIDEO_ID=${2}
fi

if [ -z "${VIDEO_ID}" ]; then
    echo '対象なしのため終了'
    exit 2
else
    echo "VIDEO ID【${VIDEO_ID}】"
fi

# MIDIデータを取得
curl -X POST -d "videoid=${VIDEO_ID}" "${1}/download/MidiDownload" > /download/${VIDEO_ID}_Base64.txt

# ファイルサイズチェック
if [ -s /download/${VIDEO_ID}_Base64.txt ]; then
  echo "【midi_download】MIDIデータあり"
else
  echo "【midi_download】データなし"
  exit 2
fi

# MIDIデータをデコード TODO デコードPython作成
python /app/python/base64_decode.py /download/${VIDEO_ID}_Base64.txt /download/${VIDEO_ID}_decode.mid

# ファイル削除
rm -rf /download/${VIDEO_ID}_Base64.txt
