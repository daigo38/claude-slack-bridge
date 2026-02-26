#!/bin/bash
# claude-slack-bridge LaunchAgent アンインストールスクリプト
# 自動起動を解除し、plistファイルを削除する

set -euo pipefail

LABEL="com.user.claude-slack-bridge"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"

# サービス停止・解除
if launchctl list "$LABEL" &>/dev/null; then
    echo "サービスを停止中..."
    launchctl bootout "gui/$(id -u)/$LABEL"
    echo "サービスを停止しました"
else
    echo "サービスは実行されていません"
fi

# plist削除
if [ -f "$PLIST_PATH" ]; then
    rm "$PLIST_PATH"
    echo "plistを削除しました: $PLIST_PATH"
else
    echo "plistが見つかりません: $PLIST_PATH"
fi

echo ""
echo "=== アンインストール完了 ==="
echo "ログは残っています: ~/Library/Logs/claude-slack-bridge/"
echo "不要なら手動で削除してください"
