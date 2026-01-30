#!/bin/bash
echo "=== Secrets 測試 ==="
if [ -n "$APP_SECRET" ] && [ -n "$DB_PASSWORD" ]; then
  echo "✅ Secrets 傳遞成功！"
else
  echo "❌ Secrets 遺失！"
fi

echo "=== Repository / Environment Variables 測試 ==="
echo "APP_ENV: ${APP_ENV:-未設定}"
echo "REGISTRY_URL: ${REGISTRY_URL:-未設定}"
echo "BUILD_VERSION: ${BUILD_VERSION:-未設定}"
echo "DEBUG_MODE: ${DEBUG_MODE:-未設定}"

echo "=== 結束 ==="
