## 為什麼適合擴充？
- **現有架構**：workflow → env → docker-compose → 容器 script，已有完整傳遞路徑。 [github](https://github.com/orgs/community/discussions/27185)
- **對比清晰**：先用 `secrets`（機密），再用 `vars`（非機密，如 API URL、版本），正好對照差異。 [stackoverflow](https://stackoverflow.com/questions/76084152/difference-between-var-and-env-in-github-action)
- **真實情境**：Laravel/Vue CI 常用 vars 設 `APP_ENV=staging`、`REGISTRY_URL=dockerhub.com/sam` 等。 [docs.github](https://docs.github.com/actions/learn-github-actions/variables)

***

## 擴充步驟：加 Repository Variables + Environments

### 步驟 1：設定 Repository Variables
Repository → Settings → Secrets and variables → Actions → **Variables** → **New repository variable**：
```
APP_ENV          staging
REGISTRY_URL     ghcr.io/yourusername
BUILD_VERSION    1.0.0
```

### 步驟 2：建立 GitHub Environments
同頁面 → **Environments** → **New environment**：
- 名稱：`dev`  
  Variables：`APP_ENV=development`、`DEBUG_MODE=true`  
- 名稱：`staging`  
  Variables：`APP_ENV=staging`、`DEBUG_MODE=false`  
- 名稱：`production`  
  Variables：`APP_ENV=production`、`DEBUG_MODE=false`  

> **⚠️ 常見問題：我看不到「選擇環境」的選單？**
> 這是 GitHub Actions 初學者最常遇到的問題，請檢查以下兩點：
>
> 1.  **檔案必須在 Default Branch**：
>     GitHub 規定 `workflow_dispatch` (手動觸發) 的設定檔 (`.yml`) **必須存在於 `main` (或 `master`) 分支上**，介面才會顯示按鈕。如果您只在 Feature Branch 開發，請先合併或推送上去。
>
> 2.  **正確的操作路徑 (顯示選單的關鍵)**：
>     不要只看 Commit 的自動執行紀錄！請依照以下步驟操作：
>     1. 點擊 GitHub Repo 上方的 **Actions** 頁籤。
>     2. 在左側列表點擊 **Workflow 名稱** (例如 `Secrets + Vars Multi-Env Test`)。
>     3. **這是關鍵步驟**：在右側列表上方，尋找一個淺色的 **Run workflow ▾** 按鈕。
>     4. 點擊該按鈕，才會彈出 **Environment 下拉選單** 供您選擇。  

**Environment Variables 特性**：
- 可保護（Require approval、Required reviewers）。  
- 優先權：Environment vars > Repository vars > env 區塊。 [stackoverflow](https://stackoverflow.com/questions/65957197/difference-between-githubs-environment-and-repository-secrets)

### 步驟 3：更新 `test-script.sh`（多印 vars）
```bash
#!/bin/bash
echo "=== Secrets 測試 ==="
echo "APP_SECRET: ${APP_SECRET:0:10}..."
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
```

### 步驟 4：更新 workflow（多環境支援）
為了能手動選擇環境（如 `dev`、`staging`），我們在 **`workflow_dispatch`** 加入了 **`inputs`** 設定。這會在 GitHub Actions 執行頁面產生一個**下拉式選單**，讓你執行時能指定目標環境。

**設定重點解析**：
- **`type: choice`**: 產生下拉選單介面，避免手動輸入錯誤。
- **`options`**: 定義可選清單（需對應之前建立的 Environments 名稱）。
- **`environment: ${{ ... }}`**: 根據使用者選擇，動態載入該環境專屬的變數。

#### `secrets-vars-test.yml`（完整版）
```yaml
name: Secrets + Vars Multi-Env Test

on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: '選擇環境'
        required: true
        default: 'dev'
        type: choice
        options:
        - dev
        - staging
        - production

jobs:
  test-vars:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}  # 手動選 dev/staging/prod
    
    steps:
    - uses: actions/checkout@v4

    - name: 🔧 Fix permissions
      run: chmod +x test-script.sh

    - name: 🪄 Inject ALL variables to env
      env:
        # Secrets（機密）
        APP_SECRET: ${{ secrets.APP_SECRET }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
        # Repository / Environment Variables（非機密）
        APP_ENV: ${{ vars.APP_ENV }}
        REGISTRY_URL: ${{ vars.REGISTRY_URL }}
        BUILD_VERSION: ${{ vars.BUILD_VERSION }}
        DEBUG_MODE: ${{ vars.DEBUG_MODE }}
      run: |
        echo "=== Workflow sees vars ==="
        echo "APP_ENV=${{ vars.APP_ENV }}"
        echo "DEBUG_MODE=${{ vars.DEBUG_MODE }}"
        cat .env  # 從前版保留

    - name: 🚀 Docker Compose（全變數注入）
      env:
        APP_SECRET: ${{ secrets.APP_SECRET }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
        APP_ENV: ${{ vars.APP_ENV }}
        REGISTRY_URL: ${{ vars.REGISTRY_URL }}
        BUILD_VERSION: ${{ vars.BUILD_VERSION }}
        DEBUG_MODE: ${{ vars.DEBUG_MODE }}
      run: |
        docker compose up test-app
        docker compose down
```

***

## 測試流程 (Step-by-Step)

### 1. 提交程式碼 (Push Code)
GitHub Actions 是在雲端執行的，所以必須先將本地新增的 Workflows (`.github/workflows/*.yml`) 和修改後的 Script (`test-script.sh`) 推送到 GitHub。

### 2. 在 GitHub 設定變數 (關鍵步驟)
這部分必須到 GitHub 網頁版操作：

**A. 設定 Repository Variables (所有環境共用)**
1.  進入 Repo **Settings** > **Secrets and variables** > **Actions** > **Variables** 分頁。
2.  點擊 **New repository variable**，新增：
    *   `REGISTRY_URL`: (例如: `ghcr.io/my-repo`)
    *   `APP_ENV`: (預設值，例如: `base-env`)
    *   `BUILD_VERSION`: (例如: `1.0.0`)

**B. 設定 Environments (環境專屬)**
1.  進入 Repo **Settings** > **Environments**。
2.  建立 `dev` 環境：
    *   點 **New environment** > 輸入 `dev`。
    *   在該環境下新增 Variable：`DEBUG_MODE` = `true`，`APP_ENV` = `development` (會覆蓋 Repo 層級)。
3.  建立 `staging` 環境：
    *   點 **New environment** > 輸入 `staging`。
    *   在該環境下新增 Variable：`DEBUG_MODE` = `false`，`APP_ENV` = `staging`。

### 3. 執行測試 (Run Workflow)
1.  進入 Repo 的 **Actions** 分頁。
2.  左側選擇 **"Secrets + Vars Multi-Env Test"**。
3.  點擊右側 **Run workflow** 按鈕。
4.  **選擇環境**：下拉選單會出現 `dev` / `staging` / `production`。
5.  點擊綠色按鈕執行。

**預期結果 (Log)**：
```
=== Repository / Environment Variables 測試 ===
APP_ENV: development (若選 dev) 或 staging (若選 staging)
DEBUG_MODE: true (若選 dev) 或 false (若選 staging)
✅ Secrets 傳遞成功！
```

***

## Real World Scenarios (真實場景應用)

以下提供兩個實際開發中常用的範例，分別對應後端 (Laravel) 與前端 (Vue) 的 CI/CD 流程。這些範例展示了如何利用 `inputs` 選單與 `vars/secrets` 來管理多環境配置。

### 1. 後端 Laravel CI (`.github/workflows/laravel-ci.yml`)
重點：
- **PHP 環境模擬**：使用 `shivammathur/setup-php`。
- **混合注入**：同時使用 `vars` (ENV, DEBUG) 與 `secrets` (KEY, PASSWORD) 生成 `.env`。
- **防止測試失敗**：偵測 vendor 與 phpunit 是否存在。

```yaml
name: Laravel CI

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:
    inputs:
      environment:
        description: '選擇環境'
        required: true
        default: 'dev'
        type: choice
        options:
        - dev
        - staging
        - production

jobs:
  laravel-tests:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}

    steps:
    - uses: actions/checkout@v4

    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.4'
        extensions: mbstring, xml, bcmath

    - name: 🔐 Inject Environment Variables
      env:
        APP_ENV: ${{ vars.APP_ENV }}
        APP_DEBUG: ${{ vars.DEBUG_MODE }}
        APP_KEY: ${{ secrets.APP_KEY }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
      run: |
        echo "=== Generating .env for Laravel ==="
        echo "APP_ENV=$APP_ENV" >> .env
        echo "APP_DEBUG=$APP_DEBUG" >> .env
        echo "APP_KEY=$APP_KEY" >> .env
        echo "DB_PASSWORD=$DB_PASSWORD" >> .env
        
        # 簡單驗證 (隱藏敏感資訊)
        echo "Created .env with APP_ENV=$APP_ENV"

    - name: Install Dependencies
      run: |
         if [ -f "composer.json" ]; then
            composer install -q --no-ansi --no-interaction --no-scripts --no-progress --prefer-dist
         else
            echo "No composer.json found, skipping install."
         fi

    - name: Execute Tests
      run: |
         if [ -f "vendor/bin/phpunit" ]; then
            vendor/bin/phpunit
         else
            echo "No PHPUnit found, skipping tests."
         fi
```

### 2. 前端 Vue Deploy (`.github/workflows/vue-deploy.yml`)
重點：
- **前端變數轉換**：將 `APP_ENV` 等變數轉為 Vite 可讀取的 `VITE_APP_ENV` 格式。
- **Build Time 注入**：前端 Build 過程需要這些變數 (Baked-in)。
- **範例特別技巧**：加入 `package.json` 檢查，允許在沒有真實 Vue 專案的空 Repo 中測試流程（Mock Build）。

```yaml
name: Vue Deploy

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:
    inputs:
      environment:
        description: '選擇環境'
        required: true
        default: 'dev'
        type: choice
        options:
        - dev
        - staging
        - production

jobs:
  vue-build:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}

    steps:
    - uses: actions/checkout@v4

    - name: Setup Node
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        # cache: 'npm' # 若無 lock file 需移除此行

    - name: Install Dependencies
      run: |
        if [ -f "package.json" ]; then
          npm install
        else
          echo "⚠️ No package.json found. Skipping install for test demo."
        fi

    - name: 🏗️ Build Application
      env:
        # 注入前端需要的 VITE_ 變數
        VITE_APP_ENV: ${{ vars.APP_ENV }}
        VITE_API_URL: ${{ vars.REGISTRY_URL }}
        DEBUG_MODE: ${{ vars.DEBUG_MODE }}
      run: |
        echo "=== Mocking Build Process for Vue App ==="
        echo "Environment: $VITE_APP_ENV"
        echo "API URL: $VITE_API_URL"
        
        # 建立 .env 供 build 過程讀取
        echo "VITE_APP_ENV=$VITE_APP_ENV" >> .env
        echo "VITE_API_URL=$VITE_API_URL" >> .env
        
        echo "=== Generated .env content ==="
        cat .env
        
        # 模擬 Build (若有 package.json 才執行)
        if [ -f "package.json" ]; then
           npm run build --if-present
        else
           echo "✅ Mock build completed (No actual project)."
        fi
```

---

## Repository vs Environment Variables 對比表

| 類型 | 設定位置 | 安全性 | 範圍 | 範例用途 | 存取方式 |
|------|----------|--------|------|----------|----------|
| **Repository Variables** | Settings → Variables | 明文 | 全 repo workflows | `APP_ENV`、`REGISTRY_URL` | `${{ vars.MY_VAR }}` |
| **Environment Variables** | Environments → dev/staging | 明文 + 保護 | 特定 environment | `DEBUG_MODE`、`API_URL` | `${{ vars.MY_VAR }}` (需指定 `environment`) |
| **Secrets** | Secrets and variables → Actions | 加密 + 遮蔽 | 全 repo 或 environment | `APP_KEY`、`DB_PASSWORD` | `${{ secrets.MY_SECRET }}` |

***

## ⚠️ 關鍵陷阱：Docker Compose 變數傳遞

這是開發者最容易忽略的細節：**GitHub Actions 的變數，不會「自動」穿透到 Docker 容器內部。**

一定要在 `docker-compose.yml` 做**顯式宣告 (Explicit Mapping)**。

### ❌ 錯誤寫法 (以為會自動傳遞)
Workflow 有設定 `env`，但 `docker-compose.yml` 什麼都沒寫，容器內的 `APP_ENV` 會是空的。

### ✅ 正確寫法 (Explicit Mapping)
必須在 `docker-compose.yml` 的 `environment` 區塊中，一條一條接變數接進來：

```yaml
# docker-compose.yml
services:
  app:
    # ...
    environment:
      # 左邊是容器內的名稱，右邊是宿主機(Runner)的變數
      - APP_SECRET=${APP_SECRET}
      - APP_ENV=${APP_ENV}       # 漏了這行，容器就讀不到！
      - DEBUG_MODE=${DEBUG_MODE} # 非機密變數也需要這樣接
```

### 💡 背後邏輯：變數的「過關斬將」
想像變數要從 GitHub 傳到你的 Code，必須經過**三個關卡**，每一關都不會自動放行：

1.  **第一關：GitHub → Runner (宿主機)**
    *   **動作**：Workflow 中定義 `env: APP_ENV: ${{ vars.APP_ENV }}`。
    *   **結果**：變數存在於 Runner (虛擬機) 的 Shell 中。

2.  **第二關：Runner → Docker Compose (設定檔)**
    *   **動作**：執行 `docker compose up`。
    *   **結果**：Compose 讀取 YAML 檔，並解析 `${APP_ENV}` 為實際值。如果你 YAML 裡沒寫，Compose 預設**不會**把宿主機的所有變數倒進容器 (為了安全與隔離)。

3.  **第三關：Docker Compose → Container (容器內部)**
    *   **動作**：Docker 引擎啟動容器。
    *   **結果**：只有在 `environment` 區塊宣告過的變數，才會出現在容器內的 `/proc/1/environ` 中，讓你的程式碼 (PHP/Node/Python) 讀取到。

### 🔥 進階技巧：Pass-through (透傳寫法)
覺得 `${APP_ENV}` 寫起來太冗長？Docker Compose 支援更簡潔的**透傳寫法**：

```yaml
services:
  app:
    environment:
      - APP_SECRET   # ✅ 自動抓取宿主機同名變數
      - APP_ENV      # ✅ 等同於 APP_ENV=${APP_ENV}
      - DEBUG_MODE   # ✅ 簡潔有力！
```
只要確保 Workflow 的 `env` 變數名稱與容器內變數名稱**完全一致**，就可以這樣寫。

***

## 安全性特別說明：需要產生 `.env` 檔案嗎？

在範例中我們示範了將變數寫入 `.env`，你可能會問：「這樣安全嗎？有必要嗎？」

1.  **視框架需求而定**：
    *   **Laravel**：通常依賴 `.env`，且 `php artisan config:cache` 需要它。
    *   **Vite/Vue**：Build 工具預設會讀取 `.env` 來注入 `VITE_` 變數。
    *   **Docker Container**：如果像本專案 `docker-compose.yml` 是用 `environment: - KEY=${KEY}` 方式，則**不需要**實體 `.env` 檔，直接傳遞系統變數即可。

2.  **安全性考量**：
    *   **Runner 是暫時的**：GitHub Actions Runner 在執行完後會被銷毀，暫存的 `.env` 也會隨之刪除，因此是安全的。
    *   **絕對不要做的事**：
        *   ❌ **Don't Commit**：永遠不要把生成的 `.env` 加入 git 版控。
        *   ❌ **Don't Upload**：不要將包含 Secrets 的 `.env` 作為 Artifact 上傳（除非是用於加密的部署包）。
        *   ❌ **Don't Cat Secrets**：生產環境中避免 `cat .env`，雖然 GitHub 會嘗試遮蔽，但這是不良習慣（範例中僅為教學驗證用）。

***
