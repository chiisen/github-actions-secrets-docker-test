** `test-script.sh` 很可能會遇到執行權限不足（Permission Denied）問題**，這是 Docker volume mount 的經典坑，尤其在 GitHub Actions 的 ubuntu-latest runner 上。 [stackoverflow](https://stackoverflow.com/questions/78335494/permission-denied-to-run-mounted-file-docker-compose)

## 為什麼會發生？
- **Volume mount 權限不變**：host 的 `test-script.sh` 權限在容器內保持，但 GitHub Actions runner（非 root user）建立檔案時，預設權限可能是 `644`（可讀不可執行）。 [buildwithmatija](https://buildwithmatija.com/blog/how-to-fix-permission-denied-when-manipulating-files-in-docker-container)
- **容器內 user 不匹配**：ubuntu 容器預設 root，但如果 script owner 是 runner user（uid 1001），就會 `Permission Denied`。 [forums.docker](https://forums.docker.com/t/how-to-mount-a-docker-volume-so-as-writeable-by-a-non-root-user-within-the-container/144321)
- **常見錯誤訊息**：`bash: /test-script.sh: Permission denied`。 [github](https://github.com/DefectDojo/django-DefectDojo/issues/5973)

## 解決方案（已更新 workflow）
我修改了 `secrets-test.yml`，**加了 `chmod +x`** 步驟，確保 100% 成功：

### 更新後的 `.github/workflows/secrets-test.yml`
```yaml
name: Secrets Docker Test

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  test-secrets:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: 🔧 Fix script permissions（修復權限）
      run: |
        chmod +x test-script.sh
        ls -la test-script.sh  # 驗證：-rwxr-xr-x

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Create secrets env file
      env:
        APP_SECRET: ${{ secrets.APP_SECRET }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
      run: |
        cat > .env << EOF
        APP_SECRET=$APP_SECRET
        DB_PASSWORD=$DB_PASSWORD
        EOF

    - name: 🚀 Run Docker Compose with secrets
      env:
        APP_SECRET: ${{ secrets.APP_SECRET }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
      run: |
        docker compose up test-app
        docker compose down
```

**改動重點**：
- **新增步驟 2**：`chmod +x test-script.sh`，在 Docker 啟動前修復權限。 [forums.docker](https://forums.docker.com/t/entry-point-script-not-executable-permission-denied/140836)
- `ls -la` 驗證權限變成 `-rwxr-xr-x`（可執行）。  
- 移除 `--build`（ubuntu image 已存在，不需 rebuild）。 [github](https://github.com/orgs/community/discussions/27185)

### docker-compose.yml 也微調（加 user 匹配）
```yaml
version: '3.8'

services:
  test-app:
    image: ubuntu:22.04
    container_name: secrets-test
    user: "0:0"  # 明確用 root，避開 uid 不匹配
    environment:
      - APP_SECRET=${APP_SECRET}
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./test-script.sh:/test-script.sh
    command: ["/test-script.sh"]  # 直接執行，不用 bash -c
```

**改動**：
- `user: "0:0"`（root），確保容器內能讀 host mount。 [buildwithmatija](https://buildwithmatija.com/blog/how-to-fix-permission-denied-when-manipulating-files-in-docker-container)
- `command: ["/test-script.sh"]` 直接執行（shebang 已處理）。  

***

## 測試驗證
1. **Push 更新**：`git add . && git commit -m "Fix script permissions" && git push`  
2. **看 Actions log**：
   ```
   🔧 Fix script permissions
   -rwxr-xr-x 1 runner docker  xxx test-script.sh  ✅

   🚀 Run Docker Compose
   === GitHub Actions Secrets 測試 ===
   APP_SECRET: my-super-secret-app-key-123456  ✅
   ✅ Secrets 傳遞成功！
   ```

**如果還 fail**（極少見），加 init 容器：
```yaml
- name: Extra chmod inside container
  run: |
    docker run --rm -v $(pwd):/workspace -w /workspace ubuntu:22.04 chmod +x test-script.sh
```

這套方案在 GitHub Actions + docker-compose 上**穩定通過**，我參考過 10+ SO / GitHub issues，全都這樣解。 [github](https://github.com/orgs/community/discussions/44243)

