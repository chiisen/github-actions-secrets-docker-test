# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- 停用 `.github/workflows/secrets-test.yml` Workflow (已更名為 `.disabled` 以避免與 `secrets-vars-test.yml` 功能重複)。

### Added
- 新增 `docs/Repository_Environment_Variables.md` 中的「Docker Compose 變數傳遞陷阱」章節，強調在 `docker-compose.yml` 中顯式宣告變數的重要性。
- 補充 `docs/Repository_Environment_Variables.md` 中的「變數過關斬將」邏輯分析與「Pass-through 透傳寫法」技巧。

### Fixed
- 修正 `docker-compose.yml` 未正確傳遞 Reposiotry Variables (如 `APP_ENV`, `REGISTRY_URL`) 至容器的問題。
- 修正 `.github/workflows/secrets-vars-test.yml` 生成 `.env` 檔案時遺漏 `BUILD_VERSION` 與 `DEBUG_MODE` 的問題。
