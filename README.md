# github-actions-secrets-docker-test
測試 GitHub Secrets 傳到 docker-compose → 容器內 shell script → log 印出驗證。

## 專案目標確認
1. **具體目標**：測試 GitHub Secrets 傳到 docker-compose → 容器內 shell script → log 印出驗證。  
2. **回答格式**：完整專案檔案內容 + 建立步驟 + 驗證方式。  
3. **特殊要求**：專案最小化，只用 ubuntu 容器 + docker-compose；secrets 會在 GitHub Actions log 被遮蔽（`***`），但容器內能正常讀取並印出。  
4. **情境目的**：作為你 PHP/Laravel/Vue CI/CD 的 secrets 注入範例，未來可擴充到 Laravel `.env` 或 Vue build。  

***

## 步驟 1：建立新 GitHub Repository
1. 新建 repo 名稱：`github-actions-secrets-docker-test`  
2. Clone 到本地：`git clone https://github.com/yourusername/github-actions-secrets-docker-test.git`  
3. 進入目錄：`cd github-actions-secrets-docker-test`  

***

## 步驟 2：建立專案檔案

### `docker-compose.yml`
```yaml
version: '3.8'

services:
  test-app:
    image: ubuntu:22.04  # 簡單 ubuntu 容器，模擬你的 app
    container_name: secrets-test
    environment:
      - APP_SECRET=${APP_SECRET}      # 從 host env 注入
      - DB_PASSWORD=${DB_PASSWORD}    # 多 secrets 測試
    volumes:
      - ./test-script.sh:/test-script.sh  # mount shell script
    command: ["/bin/bash", "/test-script.sh"]
    stdin_open: true
    tty: true
```

**說明**：  
- 用 `environment:` 把 GitHub Actions 的 env（來自 secrets）注入容器。 [github](https://github.com/orgs/community/discussions/25269)
- 掛載你的 shell script，容器啟動就執行。 [github](https://github.com/orgs/community/discussions/27185)

### `test-script.sh`（你的驗證 script）
```bash
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
```

**說明**：  
- 印出 secrets 值、長度、前幾字（驗證不是空字串）。  
- 在容器內是**明文**，但 GitHub Actions log 會遮蔽。 [jmh](https://jmh.me/blog/secrets-management-docker-compose-deployment)

### `.github/workflows/secrets-test.yml`
```yaml
name: Secrets Docker Test

on:
  push:
    branches: [ main ]
  workflow_dispatch:  # 手動觸發

jobs:
  test-secrets:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Docker Compose
      uses: docker/setup-buildx-action@v3

    - name: Create secrets env file  # 最安全：寫入臨時 .env，不 commit
      env:
        APP_SECRET: ${{ secrets.APP_SECRET }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
      run: |
        cat > .env << EOF
        APP_SECRET=$APP_SECRET
        DB_PASSWORD=$DB_PASSWORD
        EOF
        cat .env  # 這行會在 log 被遮蔽

    - name: Run Docker Compose with secrets
      env:
        APP_SECRET: ${{ secrets.APP_SECRET }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
      run: |
        chmod +x test-script.sh
        docker compose up --build test-app
        docker compose down
```

**重點說明**：  
- 用 `env:` 把 secrets 注入到 `docker compose up` 的環境變數。 [github](https://github.com/orgs/community/discussions/25269)
- 產生臨時 `.env`（只在 runner 上，不 commit），更像 Laravel 真實用法。 [stackoverflow](https://stackoverflow.com/questions/77840895/github-actions-how-to-handle-github-secrets-and-use-them-in-docker-container)
- `--build` 確保 script 權限正確。 [github](https://github.com/orgs/community/discussions/27185)

***

## 步驟 3：設定 GitHub Secrets
1. Repository → Settings → Secrets and variables → Actions  
2. New repository secret：  
   - 名稱：`APP_SECRET`，值：`my-super-secret-app-key-123456`（隨便設）  
   - 名稱：`DB_PASSWORD`，值：`super-secure-db-pass-789`  

***

## 步驟 4：Push & 驗證
```bash
# commit 所有檔案
git add .
git commit -m "Add GitHub Actions secrets docker test"
git push origin main
```

**預期結果**（Actions → 你的 workflow）：  
```
=== GitHub Actions Secrets 測試 ===
APP_SECRET: my-super-secret-app-key-123456
長度: 26
前 5 字: my-su
DB_PASSWORD: super-secure-db-pass-789
長度: 22
✅ Secrets 傳遞成功！
```

**GitHub Actions log 會顯示**：  
```
APP_SECRET: ***
DB_PASSWORD: ***
```
（遮蔽保護，但容器內正常） [jmh](https://jmh.me/blog/secrets-management-docker-compose-deployment)

***

## 擴充到你的 Laravel/Vue 專案
未來套用到真專案：  
```yaml
# 在 docker-compose.yml
services:
  laravel:
    environment:
      - APP_KEY=${APP_KEY}
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./:/var/www  # Laravel 程式碼
    command: bash -c "cp .env.example .env && envsubst < .env.template > .env && php artisan migrate"
```
用 `envsubst` 替換 `.env.template`，完全符合你 PowerShell / Bash 習慣。 [stackoverflow](https://stackoverflow.com/questions/60176044/how-do-i-use-an-env-file-with-github-actions)


***

## 進階閱讀 (Documentation)

專案包含兩份詳細的技術文件，解決常見問題與進階應用：

### 1. [Permission Denied 權限問題詳解](docs/PermissionDenied.md)
**遇到 `bash: /test-script.sh: Permission denied` 錯誤怎麼辦？**
- **原因**：GitHub Actions Runner 與 Docker 容器間的檔案權限 (`chmod +x`) 和 User ID 不匹配。
- **解法**：文件中詳細說明了如何在 Workflow 中修復權限，以及 `docker-compose.yml` 的 `user: "0:0"` 設定技巧。

### 2. [Repository & Environment Variables 進階應用](docs/Repository_Environment_Variables.md)
**如何管理多環境（Dev / Staging / Prod）變數？**
- **區分 Secrets 與 Vars**：何時用加密 Secrets，何時用明文 Repository Variables。
- **多環境實戰**：包含完整的 **Laravel CI** 與 **Vue Deploy** 範例，教你如何用 `workflow_dispatch` 的 inputs 選單來切換環境變數。

***
