# Project Memory
### 變更管理規範 (Change Management)
為了確保專案的演進歷程可被追溯，需遵循以下變更記錄規則：
- **主要記錄檔**：`CHANGELOG.md` (位於專案根目錄)。
- **記錄標準**：採用 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) 格式。
- **語言要求**：所有變更內容說明必須使用 **繁體中文**。
- **觸發時機**：當執行以下操作時，必須同步更新 `CHANGELOG.md`：
    1. **新增功能/技能**：例如引入新的 Skill 或 Workflow。
    2. **結構調整**：例如修改目錄結構、核心規則 (`GEMINI.md`)。
    3. **重大內容更新**：例如新增主要文檔、重構現有筆記。
- **操作方式**：在 `CHANGELOG.md` 的 `[Unreleased]` 或當日日期區塊下，新增對應的 `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security` 項目。

### Git 提交規範 (Git Commit Standards)
為了保持 Git 歷史記錄的清晰與一致性，需遵循以下提交訊息規範：
- **格式結構**：`<type>(<scope>): <subject>`
    - 第一行：簡短標題，不超過 50 字元。
    - 第二行：空行。
    - 第三行：詳細描述（每行不超過 72 字元）。
- **Type 類型**：
    - `✨ feat` (新功能)
    - `🐛 fix` (修正)
    - `📝 docs` (文件)
    - `💄 style` (格式，不影響程式碼運行的變動)
    - `♻️ refactor` (重構，既不是新增功能也不是修正 bug 的程式碼變動)
    - `⚡️ perf` (效能優化)
    - `🧪 test` (測試相關)
    - `🔧 chore` (雜項，建構過程或輔助工具的變動)
    - `⏪️ revert` (回滾)
- **Scope 範圍**：說明影響範圍。
- **Subject 主旨**：使用 **繁體中文**，簡短描述變更。
- **Body 內容**：詳細描述變更內容、原因及背景，使用 **繁體中文**。

### 技術偏好 (Tech Preferences)
依據使用者慣用技術堆疊，本專案使用以下元件版本與配置。即使無 Docker 設定檔，所有代碼生成與問題回答皆應優先考量這些特性：

| 元件 (Service) | 版本 (Version) | 端口 (Port) | 備註 (Notes) |
| :--- | :--- | :--- | :--- |
| **App Server** | `Dockerfile` | `80` | PHP/Nginx, Env: `./code/.env` |
| **Grafana** | `v12.1` | `3000` | Provisioning: `./grafana/provisioning` |
| **Loki** | `v3.5.5` | `3100` | Log Aggregation |
| **Promtail** | `v3.5` | - | Log Shipper |
| **Prometheus** | `v3.5.0` | `9090` | Metrics Database |
| **Node Exporter** | `v1.9.1` | `9100` | System Metrics |
| **cAdvisor** | `v0.49.1` | `8080` | Container Metrics (Privileged) |

### 互動準則 (Interaction Protocol)
為了提升溝通效率，請遵循 **「逆向導引 (Reverse Prompting)」** 策略：
1. **主動澄清**：若使用者的需求模糊或缺乏必要上下文（如錯誤日誌、設定檔內容），**禁止隨意猜測**。請直接列出「解決該問題所需的具體資訊清單」或「建議執行的檢測指令」。
2. **引導思考**：在處理複雜問題時，優先詢問使用者的預期結果與當前限制，而非直接跳入代碼實作。
3. **混合策略**：先嘗試使用 Available Tools（如 `read_file`, `run_command`）自動獲取上述資訊。只有在無法自動獲取時，才反問使用者。

### 協作規範 (Collaboration Guidelines)
- Artifacts 中的 Implementation Plan 統一使用 **繁體中文**。
- Artifacts 中的 Task 統一使用 **繁體中文**。
- Artifacts 中的 Walkthrough 統一使用 **繁體中文**。
