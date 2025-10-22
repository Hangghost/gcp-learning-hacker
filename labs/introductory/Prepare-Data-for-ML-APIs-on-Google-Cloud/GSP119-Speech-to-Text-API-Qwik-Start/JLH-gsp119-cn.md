# GSP119 - Speech-to-Text API: Qwik Start

## 實驗概述

Speech-to-Text API 可以輕鬆將 Google 語音辨識技術整合到開發人員應用程式中。Speech-to-Text API 允許您發送音訊並從服務中接收文字轉錄。

## 學習目標

在本實驗中，您將學習如何：

- 創建 API 金鑰
- 創建 Speech-to-Text API 請求
- 呼叫 Speech-to-Text API

## 預估時間

30 分鐘

## 事前準備

- Google Cloud Platform 帳戶
- 基本的命令列知識
- 熟悉 curl 指令

## 實驗步驟

### 步驟 1：創建 API 金鑰

由於您將使用 `curl` 向 Speech-to-Text API 發送請求，您需要生成一個 API 金鑰來傳遞到請求 URL 中。

1. 要創建 API 金鑰，請點擊 **Navigation menu** > **APIs & services** > **Credentials**。
2. 然後點擊 **Create credentials**。
3. 在下拉選單中，選擇 **API key**。
4. 複製您剛剛生成的金鑰並點擊 **Close**。

**預期結果：**
- 成功創建 API 金鑰

### 步驟 2：連接到 Linux 實例並設定環境變數

現在您有了 API 金鑰，請將其儲存為環境變數，以避免在每個請求中插入您的 API 金鑰值。

1. 在 **Navigation menu** 中，選擇 **Compute Engine**。您應該會在 **VM instances** 視窗中看到一個 `linux-instance`。
2. 點擊與 `linux-instance` 對應的 **SSH** 按鈕。您將進入互動式 shell。
3. 在命令列中輸入以下內容，將 `<YOUR_API_KEY>` 替換為您之前生成的 API 金鑰：

```bash
export API_KEY=<YOUR_API_KEY>
```

**預期結果：**
- 成功連接到 SSH 並設定 API_KEY 環境變數

### 步驟 3：創建 Speech-to-Text API 請求

**注意：** 您將使用 Cloud Storage 上可用的預錄音檔：`gs://cloud-samples-tests/speech/brooklyn.flac`。[在將音訊檔案發送到 Speech-to-Text API 之前先聆聽音訊檔案](https://storage.cloud.google.com/cloud-samples-tests/speech/brooklyn.flac)。

1. 在 SSH 命令列中創建 `request.json`：

```bash
touch request.json
```

2. 使用 nano 開啟 `request.json`：

```bash
nano request.json
```

**注意：** 您可以使用您偏好的命令列編輯器 (`nano`、`vim`、`emacs`) 或 `gcloud`。本實驗將提供 `nano` 的說明。

3. 將以下內容添加到您的 `request.json` 檔案中，使用範例原始音訊檔案的 `uri` 值：

```json
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-samples-tests/speech/brooklyn.flac"
  }
}
```

4. 按 `control` + `x`，然後按 `y` 儲存並按 `Enter` 關閉 `request.json` 檔案。

請求主體有一個 `config` 和 `audio` 物件。

在 `config` 中，您告訴 Speech-to-Text API 如何處理請求。`encoding` 參數告訴 API 音訊檔案發送到 API 時使用的音訊編碼類型。`FLAC` 是 .raw 檔案的編碼類型。有關編碼類型的更多資訊，請參閱 [RecognitionConfig Guide](https://cloud.google.com/speech/reference/rest/v1/RecognitionConfig)。

您可以將其他參數添加到您的 `config` 物件中，但 `encoding` 是唯一必需的參數。

在 `audio` 物件中，您將 Cloud Storage 中音訊檔案的 uri 傳遞給 API。

**預期結果：**
- 成功創建包含正確 JSON 配置的 request.json 檔案

### 步驟 4：呼叫 Speech-to-Text API

1. 使用以下 `curl` 命令將您的請求主體連同 API 金鑰環境變數一起傳遞給 Speech-to-Text API（全部在一個命令列中）：

```bash
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}"
```

您的回應應該類似於：

```json
{
  "results": [
    {
      "alternatives": [
        {
          "transcript": "how old is the Brooklyn Bridge",
          "confidence": 0.98267895
        }
      ]
    }
  ]
}
```

`transcript` 值將返回 Speech-to-Text API 對您的音訊檔案的文字轉錄，而 `confidence` 值表示 API 對準確轉錄您的音訊的確定程度。

您會注意到您在上面的請求中呼叫了 `syncrecognize` 方法。Speech-to-Text API 支援同步和非同步語音轉文字轉錄。在此範例中您發送了一個完整的音訊檔案，但您也可以使用 `syncrecognize` 方法在使用者仍在說話時執行串流語音轉文字轉錄。

2. 運行以下命令將回應儲存在 `result.json` 檔案中：

```bash
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json
```

**預期結果：**
- 成功呼叫 API 並接收包含轉錄文字的 JSON 回應
- result.json 檔案包含 API 回應

## 驗證

要驗證實驗是否成功完成：

1. 檢查 API 回應是否包含轉錄文字
2. 驗證 confidence 值在合理範圍內（通常 > 0.8）
3. 確認 result.json 檔案已創建並包含正確的 JSON 結構

## 故障排除

常見問題和解決方案：

- **API 金鑰無效錯誤**：確保 API_KEY 環境變數正確設定且金鑰有效
- **權限錯誤**：確保 Speech-to-Text API 已啟用且金鑰具有適當權限
- **檔案不存在錯誤**：確認 request.json 檔案存在且 JSON 語法正確
- **網路錯誤**：檢查網路連線並重試請求

## 清理

此實驗不需要特殊的清理步驟，因為它只使用了 API 呼叫而沒有創建持久性資源。

## 額外資源

- [Speech-to-Text API 官方文檔](https://cloud.google.com/speech-to-text/docs)
- [Speech-to-Text API 參考](https://cloud.google.com/speech/reference/rest/v1/RecognitionConfig)
- [Google Cloud Speech-to-Text 教學](https://cloud.google.com/speech-to-text/docs/tutorials)
- [語音辨識最佳實務](https://cloud.google.com/speech-to-text/docs/best-practices)
- 相關實驗：
  - GSP097: Cloud Natural Language API: Qwik Start
  - 其他 AI/ML API 相關實驗

## 筆記

- Speech-to-Text API 支援多種音訊格式和語言
- 可以處理同步和串流語音轉錄
- API 金鑰應安全儲存，不要在程式碼中硬編碼
- 對於生產環境，建議使用服務帳戶認證而不是 API 金鑰
