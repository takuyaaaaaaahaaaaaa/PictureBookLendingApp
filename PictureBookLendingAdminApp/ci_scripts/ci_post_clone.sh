#!/bin/sh
#
# Xcode Cloudのビルド前フックとして、リポジトリクローン直後に実行される。
# git管理外のSecrets.xcconfigはCI環境に存在しないため、Xcode Cloudの
# ワークフロー環境変数（RAKUTEN_APPLICATION_ID / RAKUTEN_ACCESS_KEY）から
# 生成する。ユニットテストはMockURLProtocolを使うため値が空でも失敗しない。
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG_PATH="$REPO_ROOT/PictureBookLendingAdminApp/Secrets.xcconfig"

cat <<EOF > "$CONFIG_PATH"
RAKUTEN_APPLICATION_ID = ${RAKUTEN_APPLICATION_ID}
RAKUTEN_ACCESS_KEY = ${RAKUTEN_ACCESS_KEY}
EOF
