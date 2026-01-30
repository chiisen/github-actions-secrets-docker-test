# github-actions-secrets-docker-test
測試 GitHub Secrets 傳到 docker-compose → 容器內 shell script → log 印出驗證。

## 專案目標確認
- 具體目標：測試 GitHub Secrets 傳到 docker-compose → 容器內 shell script → log 印出驗證。

- 回答格式：完整專案檔案內容 + 建立步驟 + 驗證方式。

- 特殊要求：專案最小化，只用 ubuntu 容器 + docker-compose；secrets 會在 GitHub Actions log 被遮蔽（***），但容器內能正常讀取並印出。

- 情境目的：作為你 PHP/Laravel/Vue CI/CD 的 secrets 注入範例，未來可擴充到 Laravel .env 或 Vue build。

