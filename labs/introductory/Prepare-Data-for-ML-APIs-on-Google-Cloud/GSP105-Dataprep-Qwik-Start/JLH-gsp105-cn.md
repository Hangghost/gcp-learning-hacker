# GSP105-Dataprep: Qwik Start

## Lab 標題
Dataprep：快速入門

## 先決條件
- 具備 GCP 基礎知識

## 目標
完成本實驗室後，您將能夠：
- 匯入資料
- 更正不匹配的資料
- 轉換資料
- 合併資料

## 預計時間
約 60 分鐘

## Lab 步驟

### 步驟 1: 在您的專案中建立 Cloud Storage 儲存桶
本步驟將指導您建立一個 Cloud Storage 儲存桶。

**說明:**
1. 在 Cloud Console 中，依序選取 **導覽選單** (Navigation menu) > **Cloud Storage** > **儲存桶** (Buckets)。
2. 按一下 **建立儲存桶** (Create bucket)。
3. 在 **建立儲存桶** (Create a bucket) 對話框中，為儲存桶 **命名** 一個唯一的名稱。其他設定請保留預設值。
4. 取消勾選「選擇如何控制物件的存取權」中的 **在此儲存桶上強制執行公開存取防護** (Enforce public access prevention on this bucket)。
5. 按一下 **建立** (Create)。

**預期結果:**
您已成功建立儲存桶。

### 步驟 2: 初始化 Cloud Dataprep
本步驟將初始化 Cloud Dataprep 服務。

**說明:**
1. 開啟 **Cloud Shell** 並執行以下指令：
```bash
gcloud beta services identity create --service=dataprep.googleapis.com
```
2. 在 Cloud Console 中，前往 **導覽選單** (Navigation menu)，點擊 **檢視所有產品** (View All Products)，並在 **分析** (Analytics) 下方選擇 **Alteryx Designer Cloud**。
3. 勾選以接受 Google Dataprep 服務條款，然後點擊 **接受** (Accept)。
4. 勾選以授權與 Trifacta 共享您的帳戶資訊，然後點擊 **同意並繼續** (Agree and Continue)。
5. 點擊 **允許** (Allow) 以允許 Trifacta 存取專案資料。
6. 點擊您的學生使用者名稱以登入 Cloud Dataprep by Trifacta。您的使用者名稱是實驗室左側面板中的 **使用者名稱** (Username)。
7. 點擊 **允許** (Allow) 以授予 Cloud Dataprep 存取您的 Google Cloud 實驗室帳戶。
8. 勾選以同意 Trifacta 服務條款，然後點擊 **接受** (Accept)。
9. 在 **首次設定** (First time setup) 畫面上點擊 **繼續** (Continue) 以建立預設儲存位置。

**預期結果:**
Dataprep 服務已成功初始化並開啟。

### 步驟 3: 建立流程
本步驟將引導您在 Dataprep 中建立一個新的資料流程。

**說明:**
1. 點擊 **流程** (Flows) 圖示，然後點擊 **建立** (Create) 按鈕，接著選取 **空白流程** (Blank Flow)。
2. 點擊 **未命名流程** (Untitled Flow)，然後命名並描述該流程。由於本實驗室使用來自 [美國聯邦選舉委員會 2016](https://www.fec.gov/data/browse-data/?tab=bulk-data) 的 2016 年數據，將流程命名為 "FEC-2016"，並將描述設定為 "United States Federal Elections Commission 2016"。
3. 點擊 **OK**。

**預期結果:**
FEC-2016 流程頁面開啟。

### 步驟 4: 匯入資料集
本步驟將匯入並將資料新增到 FEC-2016 流程中。

**說明:**
1. 點擊 **新增資料集** (Add Datasets)，然後選取 **匯入資料集** (Import Datasets) 連結。
2. 在左側選單窗格中，選取 **Cloud Storage** 以從 Cloud Storage 匯入資料集，然後點擊鉛筆圖示以編輯檔案路徑。
3. 在 **選擇檔案或資料夾** (Choose a file or folder) 文字框中輸入 `gs://spls/gsp105`，然後點擊 **前往** (Go)。
4. 點擊 **us-fec/**。
5. 點擊 `cn-2016.txt` 旁邊的 **+** 圖示以在右側窗格中建立資料集。點擊右側窗格中資料集的標題並將其重新命名為 "Candidate Master 2016"。
6. 以相同方式新增 `itcont-2016-orig.txt` 資料集，並將其重新命名為 "Campaign Contributions 2016"。
7. 兩個資料集都列在右側窗格中；點擊 **匯入並新增至流程** (Import & Add to Flow)。

**預期結果:**
兩個資料集都已作為流程列出。

### 步驟 5: 準備候選人檔案
本步驟將對候選人主檔案進行資料準備。

**說明:**
1. 預設選取 Candidate Master 2016 資料集。在右側窗格中，點擊 **編輯配方** (Edit Recipe)。
2. 在網格檢視中，點擊 Column5 的直方圖中最高的 bin（代表 2016 年）。這將建立一個選取這些值的步驟。
3. 在右側的 **建議** (Suggestions) 面板中，在 **保留列** (Keep rows) 部分，點擊 **新增** (Add) 以將此步驟新增到您的配方中。
4. 在 Column6 (State) 中，將滑鼠懸停在標題中不匹配（紅色）的部分並點擊以選取不匹配的列。
5. 點擊 **建議** (Suggestions) 面板頂部的 **X** 以取消轉換，然後點擊 Column6 中的旗幟圖示並將其更改為「字串」類型。
6. 在 Column7 的直方圖中，點擊代表 "P" 的 bin，以篩選出總統候選人。
7. 在右側的 **建議** (Suggestions) 面板中，點擊 **新增** (Add) 以接受該步驟到配方中。

**預期結果:**
候選人檔案已根據配方進行資料準備。

### 6: 整理捐款檔案並將其與候選人檔案合併
本步驟將整理捐款檔案並將其與候選人檔案合併。

**說明:**
1. 在網格檢視頁面頂部，點擊 **FEC-2016** (資料集選擇器)。
2. 點擊選取灰色的 **Campaign Contributions 2016**。
3. 在右側窗格中，點擊 **新增** (Add) > **配方** (Recipe)，然後點擊 **編輯配方** (Edit Recipe)。
4. 點擊頁面右上角的 **配方** (recipe) 圖示，然後點擊 **新增步驟** (Add New Step)。
5. 在搜尋框中插入以下 Wrangle 語言命令：
```
replacepatterns col: * with: '' on: `{start}"|"{end}` global: true
```
6. 點擊 **新增** (Add) 以將轉換新增到配方中。
7. 新增另一個新步驟到配方中。點擊 **新增步驟** (New Step)，然後在搜尋框中輸入 "Join"。
8. 點擊 **合併資料集** (Join datasets) 以開啟合併頁面。
9. 點擊 "Candidate Master 2016" 以與 Campaign Contributions 2016 合併，然後在右下角點擊 **接受** (Accept)。
10. 在右側的 **合併金鑰** (Join keys) 部分，將滑鼠懸停在鉛筆圖示上（編輯圖示），然後點擊。
11. 在 **新增金鑰** (Add Key) 面板的 **建議的合併金鑰** (Suggested join keys) 部分，點擊 **column2 = column11**。
12. 點擊 **儲存並繼續** (Save and Continue)。
13. 點擊 **下一步** (Next)，然後勾選「Column」標籤左側的核取方塊，以將兩個資料集的所有欄位新增到合併資料集中。
14. 點擊 **檢閱** (Review)，然後點擊 **新增至配方** (Add to Recipe) 以返回網格檢視。

**預期結果:**
捐款檔案已整理並成功與候選人檔案合併。

### 步驟 7: 資料摘要
本步驟將通過聚合、平均和計數貢獻來生成有用的摘要，並按候選人 ID、姓名和黨派歸屬進行分組。

**說明:**
1. 在右側的 **配方** (Recipe) 面板頂部，點擊 **新增步驟** (New Step) 並在 **轉換** (Transformation) 搜尋框中輸入以下公式以預覽聚合資料：
```
pivot value:sum(column16),average(column16),countif(column16 > 0) group: column2,column24,column8
```
2. 點擊 **新增** (Add) 以開啟主要美國總統候選人及其 2016 年競選捐款指標的摘要表。

**預期結果:**
已生成總統候選人及其競選捐款的摘要表。

### 步驟 8: 重新命名欄位
本步驟將重新命名欄位，使資料更易於解釋。

**說明:**
1. 點擊 **新增步驟** (New Step)，然後輸入以下內容以手動映射欄位：
```
rename type: manual mapping: [column24,'Candidate_Name'], [column2,'Candidate_ID'],[column8,'Party_Affiliation'], [sum_column16,'Total_Contribution_Sum'], [average_column16,'Average_Contribution_Sum'], [countif,'Number_of_Contributions']
```
2. 點擊 **新增** (Add)。
3. 新增此最後一個 **新步驟** (New Step) 以四捨五入平均貢獻金額：
```
set col: Average_Contribution_Sum value: round(Average_Contribution_Sum)
```
4. 點擊 **新增** (Add)。

**預期結果:**
欄位已成功重新命名並格式化。

## 驗證
透過檢查 Dataprep 中顯示的最終摘要表，確認資料已正確轉換並重新命名欄位。

## 故障排除
- **服務帳戶權限問題**: 確保 Dataprep 服務帳戶具有存取 Cloud Storage 儲存桶的權限。
- **資料集導入失敗**: 檢查 `gs://spls/gsp105` 路徑是否正確，以及檔案是否存在。
- **Wrangle 命令錯誤**: 仔細檢查 Wrangle 語言命令的語法。

## 清理
由於 Cloud Dataprep 是無伺服器服務，因此無需手動清理。實驗室結束後，所有資源將自動釋放。

## 額外資源
- [Dataprep by Alteryx Designer Cloud (Trifacta)](https://www.alteryx.com/products/designer-cloud)
- [Bucket naming guidelines](https://cloud.google.com/storage/docs/naming-buckets)
- [United States Federal Elections Commission 2016](https://www.fec.gov/data/browse-data/?tab=bulk-data)
- [GCP 指令修正指南](../../docs/gcp-command-fixes.md)

## 備註
此 Lab 示範了使用 Dataprep 進行資料清洗、轉換和合併的強大功能。
