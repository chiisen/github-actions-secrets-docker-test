# CI/CD Framework Test (Simulator)

這個目錄（`.gitignore`）包含了簡化後的 GitHub Actions 框架，專門用於在新專案中測試 CI/CD 的流程邏輯與 GitHub Secrets 的設定。所有 Actions 皆為**模擬器**模式，僅會輸出 Log，不會對實際伺服器造成更動。

## GitHub Secrets 設定需求清單

為了確保 Workflow 能正確運作並通過模擬器的 Secrets 驗證，請在新專案的 GitHub Repository (Settings > Secrets and variables > Actions) 中設定以下 **11 個 Secrets**：

### 1. 部署相關 (Deployment)
| Secret 名稱 | 說明 | 測試用內容 (Test Value) |
| :--- | :--- | :--- |
| `TEST_SERVER_HOST` | 測試機伺服器位址 (IP 或 Domain) | `1.2.3.4` |
| `TEST_SERVER_USERNAME` | 測試機 SSH 登入使用者 (如 `root` 或 `ubuntu`) | `test-runner-user` |
| `TEST_SSH_PRIVATE_KEY` | 測試機 SSH 私鑰 (用於 SSH 連線) | `-----BEGIN OPENSSH PRIVATE KEY-----` (純文字) |
| `TEST_SERVER_DB_PWD` | 測試環境資料庫密碼 | `mock_db_pwd_2026` |
| `REDIS_PASSWORD` | Redis 連接密碼 | `redis_test_pwd_999` |

### 2. 外部整合 (Integrations)
| Secret 名稱 | 說明 | 測試用內容 (Test Value) |
| :--- | :--- | :--- |
| `FIREBASE_SECRET` | Firebase 服務帳號 JSON | `{"project_id":"test-firebase-123"}` |
| `GRAFANA_TOKEN` | Grafana API Service Token (用於監控配置) | `glsa_mock_token_abcdefg12345` |
| `TELEGRAM_CHAT_ID` | Telegram 通知群組 ID | `-100123456789` |
| `TELEGRAM_BOT_TOKEN` | Telegram Bot API Token | `123456789:ABCdefGHIjklMNOpqrSTU` |

### 3. 發佈與認證 (Registry & Auth)
| Secret 名稱 | 說明 | 測試用內容 (Test Value) |
| :--- | :--- | :--- |
| `GHCR_TOKEN` | GitHub Container Registry Token (需具備 Packages 寫入權限) | `ghp_mock_registry_token_xyz` |
| `GITHUB_TOKEN` | (自動提供) GitHub 內建 Token，無需手動設定，但需確保 Actions 權限為 `Read and write` | (系統自動帶入) |

---

## 模擬器功能說明
*   **Log 導向**：所有步驟皆使用 `echo` 輸出 `LOG: [...]`。
*   **Secrets 驗證**：在 `Deploy Simulator` 步驟中，會檢查上述 Secrets 是否成功傳入，並顯示 ✅ (已接收) 或 ❌ (未設定)。
*   **無副作用**：不執行 `ssh` 連線、`docker` 建置、或 `composer` 套件安裝。

## 如何使用
1. 將此目錄下的 `workflows/` 和 `actions/` 複製到新專案的 `.github/` 目錄中。
2. 設定上述 GitHub Secrets。
3. 在 GitHub 介面的 `Actions` 標籤頁手動觸發 `TEST-Develop-CI` 或 `TEST-Master-CI`。

---

## 💡 偵錯小技巧 (Debug Tips)

由於 GitHub Actions 會自動遮蔽 (Mask) Secrets 輸出為 `***`，若您在測試階段需要「確認內容是否正確」，可以參考以下方式：

### 方法 A：使用 Base64 編碼輸出 (推薦)
這可以讓您在 Log 中看到加密後的字串，複製出來解碼後即可確認內容。
```yaml
- name: 🔍 Debug Secrets (Encoded)
  run: |
    echo "SERVER_HOST: $(echo ${{ secrets.TEST_SERVER_HOST }} | base64)"
    echo "DB_PWD: $(echo ${{ secrets.TEST_SERVER_DB_PWD }} | base64)"
```

### 方法 B：印出部分字串
利用 Shell 的字串切片技術，只印出開頭與結尾。
```yaml
- name: 🔍 Partial Secret Print
  run: |
    # 假設變數名為 SECRET_VAL
    echo "Secret begins with: ${S_VAL:0:3}..."
    echo "Secret ends with: ...${S_VAL: -3}"
  env:
    S_VAL: ${{ secrets.TEST_SERVER_DB_PWD }}
```

> ⚠️ **警告**：以上方法僅限於「測試專案」或「除錯期」使用，在正式生產環境應移除相關步驟，以防洩露機密訊息。

