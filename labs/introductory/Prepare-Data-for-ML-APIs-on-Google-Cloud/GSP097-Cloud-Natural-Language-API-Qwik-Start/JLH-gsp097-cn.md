# GSP097 - Cloud Natural Language API: Qwik Start

## 實驗概述
學習如何使用 Google Cloud Natural Language API 從文本中提取實體（entity）。Natural Language API 是一種雲端服務，提供自然語言處理能力，可以分析文本、識別實體、提取信息並回答問題。

## 先決條件
- Google Cloud Platform 帳戶
- 基本 GCP 控制台操作知識
- 了解自然語言處理概念

## 學習目標
完成此實驗後，您將能夠：
- 創建 API 金鑰用於 Natural Language API
- 使用 Cloud Natural Language API 從文本中提取實體（人名、地點、事件等）

## 預估時間
30 分鐘

## 實驗步驟

### 步驟 1：創建 API 金鑰

**說明：**
設置環境變數並創建服務帳戶來存取 Natural Language API。

**操作指示：**
1. 設置專案 ID 環境變數：
```bash
export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value core/project)
```

2. 創建新的服務帳戶：
```bash
gcloud iam service-accounts create my-natlang-sa \
  --display-name "my natural language service account"
```

3. 創建服務帳戶金鑰並下載 JSON 文件：
```bash
gcloud iam service-accounts keys create ~/key.json \
  --iam-account my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
```

4. 設置 Google Application Credentials 環境變數：
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/home/USER/key.json"
```
**注意：** 請將 `/home/USER/key.json` 替換為實際的金鑰文件路徑。

**預期結果：**
- 成功創建服務帳戶和金鑰文件
- 環境變數正確設置

### 步驟 2：進行實體分析請求

**說明：**
使用 Natural Language API 分析文本並提取實體信息。

**操作指示：**
1. 連接到提供的 Linux 實例：
   - 在 GCP 控制台中打開導航選單
   - 選擇 Compute Engine
   - 找到已配置的 Linux 實例
   - 點擊 SSH 按鈕連接到實例

2. 運行 Natural Language API 實體分析命令：
```bash
gcloud ml language analyze-entities --content="Michelangelo Caravaggio, Italian painter, is known for 'The Calling of Saint Matthew'." > result.json
```

3. 查看分析結果：
```bash
cat result.json
```

**預期結果：**
您應該看到類似以下的 JSON 響應：

```json
{
  "entities": [
    {
      "name": "Michelangelo Caravaggio",
      "type": "PERSON",
      "metadata": {
        "wikipedia_url": "http://en.wikipedia.org/wiki/Caravaggio",
        "mid": "/m/020bg"
      },
      "salience": 0.83047235,
      "mentions": [
        {
          "text": {
            "content": "Michelangelo Caravaggio",
            "beginOffset": 0
          },
          "type": "PROPER"
        },
        {
          "text": {
            "content": "painter",
            "beginOffset": 33
          },
          "type": "COMMON"
        }
      ]
    },
    {
      "name": "Italian",
      "type": "LOCATION",
      "metadata": {
        "mid": "/m/03rjj",
        "wikipedia_url": "http://en.wikipedia.org/wiki/Italy"
      },
      "salience": 0.13870546,
      "mentions": [
        {
          "text": {
            "content": "Italian",
            "beginOffset": 25
          },
          "type": "PROPER"
        }
      ]
    },
    {
      "name": "The Calling of Saint Matthew",
      "type": "EVENT",
      "metadata": {
        "mid": "/m/085_p7",
        "wikipedia_url": "http://en.wikipedia.org/wiki/The_Calling_of_St_Matthew_(Caravaggio)"
      },
      "salience": 0.030822212,
      "mentions": [
        {
          "text": {
            "content": "The Calling of Saint Matthew",
            "beginOffset": 69
          },
          "type": "PROPER"
        }
      ]
    }
  ],
  "language": "en"
}
```

## 驗證
- 成功收到包含實體信息的 JSON 響應
- 響應包含實體名稱、類型、元數據和顯著性分數
- 能夠識別人物（Michelangelo Caravaggio）、地點（Italian）和事件（The Calling of Saint Matthew）

## 故障排除
- **API 金鑰錯誤**：確保 GOOGLE_APPLICATION_CREDENTIALS 環境變數指向正確的金鑰文件路徑
- **權限問題**：確認服務帳戶具有 Natural Language API 的存取權限
- **命令失敗**：檢查專案 ID 是否正確設置，確保已啟用 Natural Language API

## 清理
完成實驗後，執行以下清理步驟以避免額外費用：
1. 刪除創建的服務帳戶金鑰：
```bash
rm ~/key.json
```

2. 刪除服務帳戶（可選，根據需要）：
```bash
gcloud iam service-accounts delete my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
```

## 額外資源
- [Cloud Natural Language API 文檔](https://cloud.google.com/natural-language/docs/)
- [Natural Language API 快速入門](https://cloud.google.com/natural-language/docs/getting-started)
- [GCP Skill Boost 目錄](http://cloudskillsboost.google/catalog) - 尋找更多 Qwik Start 實驗

## 實體分析結果解釋
對於每個實體，響應包含：
- **name** 和 **type**：實體名稱和類型（PERSON、LOCATION、EVENT 等）
- **metadata**：相關的維基百科 URL（如果有）
- **salience**：實體在文本中的重要性分數（0-1 範圍）
- **mentions**：實體在文本中出現的位置和方式

## 注意事項
- 此實驗是 Qwik Starts 系列的一部分，旨在讓您快速體驗 GCP 的各種功能
- Natural Language API 支持多種語言和分析類型
- 生產環境中使用時，請妥善管理服務帳戶金鑰的安全性
