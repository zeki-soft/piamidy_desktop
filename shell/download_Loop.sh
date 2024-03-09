#!/bin/sh
################################################################# 
# $1:接続先URL（必須）
# $2:バッチ実行時間
# $3:対象ステータス
################################################################# 

# 引数チェック
if [ $# -lt 1 ]; then
    echo "引数に接続先URLを指定してください。"
    exit 1
fi

# バッチ実行時間
if [ $# -lt 2 ]; then
    # デフォルト8時間
    MAX_SECONDS=28800
else
    MAX_SECONDS=$2
fi

# 対象ステータス
if [ $# -lt 3 ]; then
    # デフォルト
    MEMORY=16
else
    MEMORY=$3
fi

# 計測開始
TIME1=$(cat /proc/uptime | awk '{print $1}')
TIME1=${TIME1%.*}

while true
do
    # ダウンロード処理実行（メモリー指定）
    bash /app/shell/download.sh $1 ${MEMORY}

    # ダウンロード対象が無くなるまで繰り返し
    if [ $? -eq 2 ]; then
        break
    fi

    # バッチ実行時間
    TIME2=$(cat /proc/uptime | awk '{print $1}')
    TIME2=${TIME2%.*}
    DIFF=`echo $(($TIME2 - $TIME1))`

    # 指定した時間が経過したら終了
    if [ ${DIFF} -gt ${MAX_SECONDS} ]; then
        echo "${DIFF}秒経過したため終了"
        break
    fi
done
