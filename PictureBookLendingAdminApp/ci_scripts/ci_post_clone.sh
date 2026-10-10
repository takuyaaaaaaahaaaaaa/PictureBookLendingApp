#!/bin/sh
#
# Xcode Cloudのビルド前フックとして、リポジトリクローン直後に実行される。
# git管理外のSecrets.xcconfigはCI環境に存在しないため、Xcode Cloudの
# ワークフロー環境変数（RAKUTEN_APPLICATION_ID / RAKUTEN_ACCESS_KEY）から
# 生成する。ユニットテストはMockURLProtocolを使うため値が空でも失敗しない。
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG_PATH="$REPO_ROOT/PictureBookLendingAdminApp/Secrets.xcconfig"

# Read-only checks: fail before an expensive build; never rewrite sources in CI.
python3 "$REPO_ROOT/scripts/check_build_configuration.py"
python3 "$REPO_ROOT/scripts/swift_style.py"

cat <<EOF > "$CONFIG_PATH"
RAKUTEN_APPLICATION_ID = ${RAKUTEN_APPLICATION_ID}
RAKUTEN_ACCESS_KEY = ${RAKUTEN_ACCESS_KEY}
EOF

# GoogleService-Info.plist を生成（Firebase Analytics / Crashlytics 用）
# public repo のため plist はコミットしていない。
# GOOGLE_SERVICE_INFO_PLIST（plistの中身そのまま）が未設定の環境ではスキップし、
# アプリ側のガードによりAnalytics/Crashlytics無効で動作する。
PLIST_PATH="$REPO_ROOT/PictureBookLendingAdminApp/PictureBookLendingAdmin/GoogleService-Info.plist"
if [ -z "${GOOGLE_SERVICE_INFO_PLIST:-}" ]; then
  echo "GOOGLE_SERVICE_INFO_PLIST が未設定のため GoogleService-Info.plist の生成をスキップします。"
else
  printf '%s\n' "$GOOGLE_SERVICE_INFO_PLIST" > "$PLIST_PATH"
  echo "GoogleService-Info.plist を生成しました。"
fi
