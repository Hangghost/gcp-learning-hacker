# GSP1330 - 使用 Gemini 進行單元測試

## 概述

Gemini 是一個由 AI 驅動的協作者，幫助開發團隊更快、更有效地建置、部署和運營應用程式。

在本實驗中，您將學習 Gemini for Developers 如何協助除錯程式碼和生成單元測試，例如測試程式碼中的邊界條件。

本課程中的實驗涵蓋了從應用開發人員角度的典型軟體開發生命週期 (SDLC)。SDLC 的其他方面（需求、安全性、監控等）將在其他課程中涵蓋。

## 學習目標

本實驗重點在於以下方式利用 Gemini for Developers：

- 使用 Gemini for Developers 協助識別和解決執行時期錯誤。

- 為函數生成單元測試。

## 您將學到什麼

Cymbal Superstore 是一個蓬勃發展的線上購物平台，致力於持續改進以保持市場競爭力。作為持續開發工作的一部分，設計了一個名為「New Products」的新功能，讓使用者能夠輕鬆發現商店庫存中的最新添加。

新端點 `newproducts` 已部署到預備環境，但不符合業務擁有者的要求。您需要進行一些修改和除錯新程式碼。為了讓實驗專注於 Gemini for Developers 如何協助您，新程式碼將添加到原始程式碼庫中。您還將被要求為後端服務開發一些單元測試。

## 任務 1：調查、生成和測試程式碼

### 設定環境變數

1. 在 Cloud Shell 中，執行以下命令來設定必要的環境變數。

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=Lab Region
export ZONE=Lab Zone
```

2. 從 Cloud Storage bucket 複製必要的檔案到 Cloud Shell。

```bash
gsutil -m cp -r gs://duet-appdev/cymbal-superstore .
```

### 調查程式碼

隨著 Gemini 能夠解釋您不熟悉的程式碼片段的能力，它也可以為您建立註釋以添加到程式碼中，以增加未來維護週期的理解。

1. 通過點擊 Cloud Shell 視窗右上角可見的 **Open Editor** 選項來開啟編輯器。

2. 點擊 **Menu** 在左側，並導航到 **File** > **Open Folder...**。

3. 選取 **cymbal-superstore** 目錄，然後點擊 **OK**。

4. 開啟 `backend` 資料夾下的 **index.ts** 檔案。

5. 在檔案的右上角，點擊 **Gemini** 旁邊的箭頭。

6. 點擊 **Select Gemini Code Assist Project**，以選取要用於 Gemini 的專案。從列表中選取 `Google Cloud` Project ID。

7. 如果編輯器底部出現任何提示，表示未為選定的專案啟用 Gemini Code Assist，則在提示中點擊 **Enable API** 按鈕來啟用 API。

### 生成程式碼

1. 在 **index.ts** 檔案中，滾動到第 `102` 行，您會看到以下文字：`/newproducts endpoint code goes here`。將此行替換為以下註釋。

```typescript
// Create a GET route for /newproducts that returns products that were added in the last 7 days and are in stock
// The products should be retrieved from Firestore collection "inventory"
// Return the products as JSON array
```

2. 選取新添加的註釋，並點擊出現的黃色燈泡圖示。從列表中點擊以下選項：`Gemini: Generate code`。

3. Gemini 顯示一些建議的程式碼。查看建議的程式碼並通過點擊 **Accept** 或按 **Tab** 鍵來接受它。

**注意：**
1. Gemini 知道「are in stock」的含義。這是一個相當理解的詞組，具有共同含義，所以 Gemini 在這裡使用了它。如果您的需求不太常見，可能需要範例。
2. 使用名為 quantity 的資料屬性允許 Gemini 將其與「in stock」的概念關聯。如果您使用簡寫、縮寫或其他非標準詞彙來命名變數、屬性和方法，不僅您的程式碼對其他人來說維護性較差，而且 Gemini 的建議將較不具體。
3. 即使未說明，Gemini 建議了與檔案中其他端點一致的資料庫運行檢查的程式碼。

### 測試程式碼

1. 使用 Cloud Shell 視窗工具列上的 **Open Terminal** 按鈕切換回 Cloud Shell 終端。在 Cloud Shell 終端中，執行以下命令。

```bash
cd ~/cymbal-superstore/backend
npm run start
```

**您的輸出將類似於此：**

2. 通過點擊 Cloud Shell 視窗工具列上的 **+** 選項在 Cloud Shell 中開啟另一個終端，並在 localhost 上呼叫端點。

```bash
curl localhost:8000/newproducts
```

並查看第一個終端中的輸出，已取消並出現錯誤。

**您的輸出將類似於此：**

## 任務 2：使用 Gemini Chat 調查

1. 在編輯器中開啟 **index.ts** 檔案。

2. 如螢幕截圖所示開啟 `Gemini Chat`，並在提示中輸入給定的錯誤訊息。

```
Error: 3 INVALID_ARGUMENT: Inequality filter property and first sort order must be the same: timestamp and __name__ (or add index)
```

**您的輸出將類似於此：**

**注意：** 每次 Gemini 運行時，它都會產生不同的結果，因此您看到的結果可能與您的回應不匹配。

3. 檢查程式碼以解決現有問題。以下命令是您確定為錯誤起源的：

```typescript
const query = firestore
const products = await firestore
  .collection("inventory")
  .where("timestamp", ">", new Date(Date.now() - 604800000))
  .where("quantity", ">", 0);
  .where("timestamp", ">=", sevenDaysAgo)
  .where("quantity", ">", 0)
  .get();
```

Gemini 的回應讓您可以選擇將篩選器修改為等式篩選器，或刪除其中一個不等式篩選器。

首先，讓我們從 Firestore 呼叫中移除數量篩選器來解決錯誤。

4. 要移除數量不等式篩選器，請從 **index.ts** 檔案中移除以下程式碼片段。

```typescript
.where("quantity", ">", 0);
```

此程式碼可以移除以使函數無錯誤運行。數量為 `0` 的產品無法從 API 回應中篩選出來，這意味著它們不符合業務要求並將失敗。我們必須小心避免插入缺貨項目。有幾種適當的方法。有些可能比其他更好。因此，我們將請求 `Gemini` 的幫助。

5. 在 Gemini Chat 中詢問以下問題，並確保 **index.ts** 檔案已開啟。

```
How can I filter out products with quantity 0 from the results after retrieving from Firestore, without using a Firestore where clause?
```

**您的輸出將類似於此：**

即使在重置聊天後，如果 Gemini 重複建議您添加兩個 where 子句，以下是獲取不同答案的技術。

```
What are some ways to filter an array of products in JavaScript to only include items with quantity > 0?
```

通常 Gemini 會提供您可以嘗試的替代方案。您可能不得不重置聊天並修改提示幾次來獲取非 Firestore 選項。

**注意：** Gemini 有時會頑固並只提供隨機（且非法）Firestore 選項。在這種情況下，學習者將不得不繼續使用提供的建議。

**您的輸出將類似於此：**

6. 通過在 **index.ts** 檔案中添加程式碼片段來修改現有程式碼。

```typescript
if (p.quantity > 0) {
  productsArray.push(p);
}
```

修改後，程式碼應如下所示。

### 使用上述變更測試程式碼

1. 在 **Cloud Shell** 終端中貼上下列命令。

```bash
cd ~/cymbal-superstore/backend
npm run start
```

2. 開啟第二個終端分頁並呼叫 localhost 上的端點。

```bash
curl localhost:8000/newproducts
```

**您的輸出將類似於此：**

3. 讓我們用內嵌註釋嘗試另一種方式，並移除上面添加的條件。最終程式碼將類似於此。

4. 在 **productsArray.push(p)** 行之前添加以下註釋。按 **Ctrl+Enter** 來生成程式碼。如果它返回 `if (p.quantity > 0)`，請接受程式碼。

```typescript
// filter out products that are not in stock
```

註釋掉篩選器，它應如下所示。

## 任務 3：運行測試

1. 前往 **Cloud Shell** 終端並執行以下命令。

```bash
cd cymbal-superstore/backend
npm run test
```

**您的輸出將類似於此：**

2. 開啟 `backend` 資料夾下的檔案 **index.test.ts**。此檔案包含一些使用稱為 `supertest` 的工具開發的簡單測試，使用 Jest 測試框架。查看現有測試並要求 Gemini 解釋任何不清楚的部分。

## 任務 4：使用 Gemini 協助開發測試

在此任務中，您將使用 `Gemini` 的幫助為後端中的新產品 API 撰寫測試。

### 開發測試

1. 開啟 `backend` 資料夾下的檔案 **index.test.ts**。在檔案底部添加以下註釋。

```typescript
// Create unit tests for the GET /newproducts endpoint
// Test that it returns a 200 status code
// Test that it returns an array of products
```

2. 選取新添加的註釋，並點擊出現的黃色燈泡圖示。從列表中點擊以下選項：`Gemini: Generate code`。按 `Tab` 接受建議。

這是生成程式碼的範例。您也可以貼上下方給定的程式碼。

```typescript
describe('GET /newproducts', () => {
   it('should return a 200 status code', async () => {
       const response = await request(app)
           .get('/newproducts');
       expect(response.status).toBe(200);
   });

   it('should return a list of new products with length 8', async () => {
       const response = await request(app)
           .get('/newproducts');
       expect(response.body.length).toBe(8);
   });
});
```

### 運行測試

1. 在 **Cloud Shell** 終端中執行以下命令。

```bash
cd ~/cymbal-superstore/backend
npm run test
```

**您的輸出將類似於此：**

2. 通過滾動終端輸出中的結果來調查哪個測試失敗。

**注意：** 您應該會看到此回應表示測試失敗。值 10 是包括數量為 0 的產品的 newproducts 計數。新業務要求說明應篩選缺貨項目，但測試顯示有問題。

### 修復錯誤

1. 開啟 `backend` 資料夾下的 **index.ts** 並移除上一任務中添加的篩選器的註釋。更新後的程式碼應如下。

```typescript
//do not insert products that are out of stock
if (p.quantity > 0)
  productsArray.push(p);
```

2. 從 **Cloud Shell** 終端重新運行測試。

```bash
cd ~/cymbal-superstore/backend
npm run test
```

**您的輸出將類似於此：**

## 任務 5：邊界條件測試

邊界條件測試可能很困難。此困難源自需要考慮不應該發生但可能在執行期間出現的意外情況，如空列表或負餘額。在此上下文中，讓我們看看 Gemini 是否能提供協助。

1. 要提供最通用的回應，請關閉所有開啟的檔案。通過點擊聊天上方的 **New Chat** 圖示 (+) 重置 Gemini Chat，並輸入以下提示：

```
Can you help me create tests for boundary conditions for an API endpoint that returns products added in the last 7 days that are in stock?
```

**您的輸出將類似於此：**

```
Yes, I can definitely help you create tests for boundary conditions!

Boundary value analysis is a crucial part of software testing.
It involves testing at the "edges" or "boundaries" of input domains.
These are often the places where errors lurk.

To help you best, I'd need a little more information. For example:

    - What programming language are you using?
    - Could you provide the code (or a snippet of it) that you'd like to test?
    - What are the inputs and their expected valid ranges?
```

2. 開啟 `backend` 資料夾下的 **index.ts** 檔案以為 Gemini 提供一些背景。詢問 Gemini 有關 `/newproducts` 端點的邊界測試。開啟 Gemini 的 Chat 並輸入：

```
What are some boundary conditions I should test for the /newproducts endpoint that returns products added in the last 7 days that are in stock?
```

**您的輸出將類似於此：**

**注意：** 顯然其中一些是基於程式碼本身生成的（在過去 7 天內添加且有庫存），以及 Gemini 發現的此類程式碼典型的更一般邊界條件。這對於開始建立可靠的邊界條件集非常有用。

3. 對於轉換為實際測試，請開啟 **index.test.ts** 檔案。複製以下註釋並將其添加到檔案末尾。

```typescript
// Create boundary condition tests for the /newproducts endpoint
// Test that products with quantity 0 are not returned
// Test that products older than 7 days are not returned
```

4. 在 **index.test.ts** 檔案中上述註釋後添加以下程式碼。

```typescript
describe('GET /newproducts', () => {
   it('should not return products that are out of stock', async () => {
       const response = await request(app)
           .get('/newproducts');
       response.body.forEach((product: any) => {
           expect(product.quantity).toBeGreaterThan(0);
       });
   });
});
```

5. 在 **Cloud Shell** 終端中重新運行測試。您應該會看到如下輸出。

**您的輸出將類似於此：**

## 恭喜！

您已成功使用 Gemini for Developers 實作了程式碼生成、除錯和單元測試。

## 相關資源

- [Gemini for Developers 文檔](https://cloud.google.com/gemini/docs)
- [Jest 測試框架](https://jestjs.io/)
- [Supertest 文檔](https://github.com/visionmedia/supertest)
- [單元測試最佳實務](https://martinfowler.com/bliki/UnitTest.html)

## 故障排除

### 常見問題

1. **Gemini 無法生成程式碼**
   - 確保已正確設定 IAM 角色
   - 檢查 Cloud AI Companion API 已啟用
   - 驗證註釋格式正確

2. **Firestore 查詢錯誤**
   - Firestore 不支援多個不等式篩選器
   - 使用應用程式邏輯進行後續篩選
   - 考慮建立複合索引

3. **測試失敗**
   - 檢查資料庫中的測試資料
   - 驗證端點邏輯正確
   - 檢查回應格式

4. **邊界條件測試**
   - 考慮空結果
   - 測試極端值
   - 檢查錯誤處理

## 下一步

完成此實驗後，您可以：

- 探索更多 Gemini 除錯功能
- 學習進階測試技術
- 實作持續整合管道
- 研究測試驅動開發 (TDD)
