# 專案文檔

此目錄包含專案相關的文檔和指南，補充主要專案內容。

## 文檔列表

### [GCP 指令修正指南](./gcp-command-fixes.md)

記錄在生成 GCP Skill Badge (GSP) labs 自動化腳本時發現的常見 GCP 指令問題及其修正方法。

#### 適用場景
- 生成新的 lab 自動化腳本時
- 遇到 GCP CLI 指令執行錯誤時
- 需要了解 GCP API 變更帶來的影響時

#### 內容包含
- Health Check 指令語法修正
- Instance Template 參數問題解決
- Startup Script 格式化最佳實踐
- Firewall Rule 命名規範
- 其他常見 GCP CLI 問題的解決方案

#### 更新時機
- 發現新的 GCP 指令語法錯誤
- GCP API 或 CLI 工具更新
- 新的 lab 類型需要特定修正
- 發現更好的指令實踐

## 使用建議

1. **新手開發者**：建議先閱讀此指南以避免常見錯誤
2. **腳本維護者**：定期檢查並更新修正指南
3. **問題排查**：遇到指令問題時以此為參考

## 相關連結

- [Lab 生成指令](../../.cursor/commands/generate-gsp-lab.md)
- [Lab 模板](../../labs/templates/)
- [已完成 Labs](../../labs/COMPLETED_LABS.md)
