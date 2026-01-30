#!/bin/bash

echo "=== GitHub Actions Secrets 測試 ==="
echo "APP_SECRET: ${APP_SECRET:-'未設定'}"
echo "長度: ${#APP_SECRET}"
echo "前 5 字: ${APP_SECRET:0:5}"
echo "DB_PASSWORD: ${DB_PASSWORD:-'未設定'}"
echo "長度: ${#DB_PASSWORD}"

if [ -n "$APP_SECRET" ] && [ -n "$DB_PASSWORD" ]; then
  echo "✅ Secrets 傳遞成功！"
else
  echo "❌ Secrets 遺失！"
fi

echo "=== 結束 ==="
