FROM dorowu/ubuntu-desktop-lxde-vnc

# 関連パッケージ
RUN apt install gnupg
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y python3-pip

# PyAutoGuiインストール
RUN python -m pip install pyautogui

# レコーダーインストール
RUN apt-get install -y recordmydesktop

# FireFoxインストール
RUN apt-get -y install firefox

# モジュールコピー
RUN mkdir -p /app/python
RUN mkdir -p /app/shell
COPY python/ /app/python/
COPY shell/ /app/shell/

# デプロイ疎通用の簡易サーバ起動
# CMD ["python","/app/python/server.py"]