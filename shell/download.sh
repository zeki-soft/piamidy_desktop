#!/bin/sh
################################################################# 
# $1:接続先URL（必須）
# $2:VIDEOID ／ メモリー（16/24/32）
#################################################################

# 定数（密度）
CHECK_DENSITY=30

# 引数チェック
if [ $# = 0 ]; then
    echo "引数に接続先URLを指定してください。"
    exit 1
fi

# 開始時間
start_time=`date +%s`

# ダウンロード対象を選択
if [ ${#2} = 11 ]; then
    # 第2引数がビデオIDの場合
    VIDEO_ID=${2}
else
    # 第2引数がメモリーの場合
    VIDEO_ID=`curl -X POST ${1}/python/SearchMusicPython -d "memory=${2}"`
fi

if [ -z "${VIDEO_ID}" ]; then
    echo '対象なしのため終了'
    exit 2
else
    echo "VIDEO ID【${VIDEO_ID}】"
fi

# Youtubeダウンロード処理
yt-dlp https://www.youtube.com/watch?v=${VIDEO_ID} -x --audio-format wav -o "/tmp/${VIDEO_ID}.%(ext)s"

# ファイル存在チェック
if [ ! -e /tmp/${VIDEO_ID}.wav ]; then
    echo "ダウンロード失敗"
    rm -rf /tmp/${VIDEO_ID}*
    curl -X POST -d "videoid=${VIDEO_ID}" -d "errorcode=E0" "${1}/python/UploadErrorPython"
    exit 3
fi

# メロディーフレーズをMIDI/CSVに変換
echo "【basic-pitch】MIDI/CSVに変換"
basic-pitch --save-note-events /tmp /tmp/${VIDEO_ID}.wav
if [ $? -gt 0 ]; then
    # エラー処理('std::bad_alloc'メモリ確保失敗)
    echo "【basic-pitch】エラー発生"
    rm -rf /tmp/${VIDEO_ID}*
    curl -X POST -d "videoid=${VIDEO_ID}" -d "errorcode=E1" "${1}/python/UploadErrorPython"
    exit 4
fi

# ノート数
NOTE_COUNT=`cat /tmp/${VIDEO_ID}_basic_pitch.csv | wc -l`
echo "ノート数: ${NOTE_COUNT}"

# 曲時間
WAV_TIME=`python /app/python/wav_time.py /tmp/${VIDEO_ID}.wav`
echo "曲時間: ${WAV_TIME}秒"

# ノート密度算出(ノート数/分)
DENSITY=`echo $((${NOTE_COUNT}*60/${WAV_TIME}))`
echo "ノート密度: ${DENSITY}"

# ノート密度チェック
if [ ${DENSITY} -lt ${CHECK_DENSITY} ]; then
    # 基準値を満たさない場合
    echo "【DENSITY】エラー発生"
    rm -rf /tmp/${VIDEO_ID}*
    curl -X POST -d "videoid=${VIDEO_ID}" -d "errorcode=E2" "${1}/python/UploadErrorPython"
    exit 5
fi

# BPM解析
BPM=`python /app/python/bpm_analyze.py /tmp/${VIDEO_ID}.wav`
echo "BPM: ${BPM}"

# サビ時間解析
CHORUS=`python /app/python/chorus_analyze.py /tmp/${VIDEO_ID}.wav`
echo "サビ時間: ${CHORUS}秒"

# 対象パートのファイル名を変更
mv /tmp/${VIDEO_ID}_basic_pitch.mid /tmp/${VIDEO_ID}.mid
mv /tmp/${VIDEO_ID}_basic_pitch.csv /tmp/${VIDEO_ID}.csv

# CSV解析
python /app/python/csv_analyze.py ${VIDEO_ID}

# BASE64エンコード
python /app/python/base64_encode.py /tmp/${VIDEO_ID}_sort.csv >> /tmp/${VIDEO_ID}.txt
python /app/python/base64_encode.py /tmp/${VIDEO_ID}.mid >> /tmp/${VIDEO_ID}.txt

# 実行時間
end_time=`date +%s`
run_time=$((end_time - start_time))

# アップロードファイル生成
echo ${VIDEO_ID} >> /tmp/${VIDEO_ID}.txt
echo ${BPM} >> /tmp/${VIDEO_ID}.txt
echo ${CHORUS} >> /tmp/${VIDEO_ID}.txt
echo ${run_time} >> /tmp/${VIDEO_ID}.txt

# アップロード
curl -X POST -F file1=@/tmp/${VIDEO_ID}.txt ${1}/python/UploadMusicPython

# アップロード確認
if [ $? -gt 0 ]; then
    echo "【UPLOAD】エラー発生"
    rm -rf /tmp/${VIDEO_ID}*
    curl -X POST -d "videoid=${VIDEO_ID}" -d "errorcode=E3" "${1}/python/UploadErrorPython"
    exit 6
fi

# ファイル削除
rm -rf /tmp/${VIDEO_ID}*

end_time=`date +%s`
run_time=$((end_time - start_time))
echo "実行時間【${run_time}秒】"