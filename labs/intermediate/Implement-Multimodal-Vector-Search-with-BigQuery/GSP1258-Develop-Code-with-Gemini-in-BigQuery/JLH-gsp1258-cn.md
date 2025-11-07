# GSP1258 - 使用 Gemini 在 BigQuery 中開發代碼

## Lab 概述
在此實驗中，您將學習如何使用 Gemini 在 BigQuery 中生成、解釋、轉換和除錯 SQL 代碼。您將扮演資料分析師的角色，使用自然語言提示來創建複雜的 SQL 查詢，並利用 Gemini 的功能來改進您的代碼。

## 先決條件
- 基本 SQL 知識
- Google Cloud 控制台訪問權限
- BigQuery 基本概念了解

## 學習目標
完成此實驗後，您將能夠：
- 使用自然語言提示生成 SQL 查詢
- 使用 BigQuery 的代碼解釋功能
- 使用轉換功能修改 SQL 代碼
- 使用 Gemini 進行代碼審核和除錯
- 請求 Gemini 提供代碼改進建議

## 預估時間
45 分鐘

## 實驗步驟

### 任務 1：檢查 menu 和 order_item 表結構

#### 檢查 menu 表結構
1. 在 Google Cloud 控制台中，點擊 **Navigation menu** > **BigQuery**
2. 點擊 **DONE** 關閉歡迎對話框
3. 在 **Explorer** 面板中，展開 `set at lab start` 項目
4. 展開 `coffee_on_wheels` 數據集
5. 點擊 `menu` 表查看結構
6. 查看字段詳情

**問題：哪些字段使用 FLOAT 作為數據類型？**

#### 檢查 order_item 表結構
1. 點擊 `order_item` 表查看結構
2. 查看字段詳情

**問題：哪些字段使用 INTEGER 作為數據類型？**

### 任務 2：使用自然語言提示生成 SQL 查詢

#### 生成顯示前三高和前三低收入菜單 ID 的查詢
1. 點擊 + 創建新的 SQL 查詢標籤頁
2. 點擊 SQL 生成工具按鈕
3. 輸入提示："Show the menu IDs and total revenue from the order_item table with the top three highest and top three lowest by total revenue."
4. 點擊 **Generate**
5. 點擊 **INSERT** 將生成的查詢添加到標籤頁

#### 解釋生成的查詢
1. 選擇查詢
2. 點擊查詢左側的 Gemini 按鈕
3. 點擊 **Explain this query**
4. 查看 Gemini 的解釋
5. 點擊 **RUN** 查看結果

**反思問題：**
- 考慮您的數據和 BigQuery 用例，您將如何使用代碼生成功能？
- 您將如何使用代碼解釋功能？

### 任務 3：轉換查詢

#### 生成包含菜單名稱的查詢
1. 創建新的 SQL 查詢標籤頁
2. 使用 SQL 生成工具
3. 輸入提示："Join the menu table with the order item table, return the menu_id, the item_name, and show the top three highest items and bottom three lowest items by total_revenue."
4. 點擊 **Generate** 和 **INSERT**
5. 點擊 **RUN** 查看結果

#### 格式化總收入字段
1. 選擇查詢
2. 點擊轉換工具按鈕
3. 輸入提示："Format the total revenue column so that there are only two decimal places. Use the ROUND function to do so."
4. 點擊 **GENERATE** 和 **INSERT**
5. 點擊 **RUN** 查看結果

**反思問題：**
- Clouds of Coffee Delight 的總收入是多少？
- 考慮您的數據和 BigQuery 用例，您將如何使用代碼生成功能？

### 任務 4：代碼審核、除錯和建議

#### 除錯錯誤的 SQL 查詢
1. 創建新的 SQL 查詢標籤頁
2. 輸入提供的錯誤查詢
3. 點擊 **RUN** 確認錯誤
4. 在 Gemini 聊天窗口中輸入問題並貼上查詢
5. 查看 Gemini 的建議
6. 應用修復並重新運行

#### 格式化總收入字段到兩位小數
1. 在聊天窗口中請求進一步的代碼修復
2. 應用 ROUND 函數修復
3. 測試最終查詢

**反思問題：**
- 第 5 高收入項目的名稱和收入是什麼？
- 考慮您的數據和用例，您將如何使用代碼審核和建議功能來修復您遇到的問題？

## 驗證
- 成功生成並運行所有 SQL 查詢
- 結果顯示正確的菜單項目和收入數據
- 總收入字段正確格式化為兩位小數

## 故障排除
- **語法錯誤**：檢查生成的 SQL 語法，特別是 UNION 操作
- **數據集未找到錯誤**：確保正確指定數據集名稱 `coffee_on_wheels`
- **解釋功能無響應**：重新選擇查詢並重試解釋
- **轉換失敗**：確保提示清晰具體

## 清理
此實驗不需要特定的清理步驟，因為它只涉及查詢現有數據。

## 額外資源
- [Generate a SQL query](https://cloud.google.com/bigquery/docs/write-sql-gemini#generate_a_sql_query)
- [Explain SQL queries](https://cloud.google.com/bigquery/docs/write-sql-gemini#explain_sql_queries)
- [Gemini Models](https://deepmind.google/technologies/gemini/#introduction)
- [Generative AI](https://cloud.google.com/bigquery/docs/generative-ai-overview#generative_ai)
- [Write better prompts for Gemini for Google Cloud](https://cloud.google.com/gemini/docs/discover/write-prompts)

## 筆記
- 此實驗重點介紹 BigQuery 中 Gemini AI 的實用應用
- 學習使用自然語言生成複雜 SQL 查詢
- 理解代碼解釋和轉換功能的重要性
- 練習代碼審核和除錯技術
