#!/bin/bash

# GSP1154 - Vertex AI Studio 入門 - 自動化腳本
# 此腳本協助設定 Vertex AI Studio 環境以執行入門實驗室

set -e  # 遇到錯誤時停止執行

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 腳本開始
echo -e "${GREEN}=== GSP1154 - Vertex AI Studio 入門 ===${NC}"
echo ""

# 檢查必要的環境變數
check_environment() {
    echo -e "${YELLOW}檢查環境變數...${NC}"

    if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
        echo -e "${RED}錯誤：請設定 GOOGLE_CLOUD_PROJECT 環境變數${NC}"
        echo "例如：export GOOGLE_CLOUD_PROJECT='your-project-id'"
        exit 1
    fi

    if [ -z "$GOOGLE_CLOUD_LOCATION" ]; then
        echo -e "${RED}錯誤：請設定 GOOGLE_CLOUD_LOCATION 環境變數${NC}"
        echo "例如：export GOOGLE_CLOUD_LOCATION='us-central1'"
        exit 1
    fi

    echo -e "${GREEN}✓ 環境變數檢查完成${NC}"
    echo "專案 ID: $GOOGLE_CLOUD_PROJECT"
    echo "地區: $GOOGLE_CLOUD_LOCATION"
}

# 啟用必要的 API
enable_apis() {
    echo -e "${YELLOW}啟用必要的 Google Cloud APIs...${NC}"

    local apis=(
        "aiplatform.googleapis.com"
        "generativelanguage.googleapis.com"
        "run.googleapis.com"
        "cloudbuild.googleapis.com"
        "texttospeech.googleapis.com"
    )

    for api in "${apis[@]}"; do
        echo "啟用 $api..."
        if gcloud services enable "$api" --project="$GOOGLE_CLOUD_PROJECT"; then
            echo -e "${GREEN}✓ 已啟用 $api${NC}"
        else
            echo -e "${RED}✗ 啟用 $api 失敗${NC}"
            return 1
        fi
    done

    echo -e "${GREEN}✓ 所有必要的 APIs 已啟用${NC}"
}

# 設定預設地區
set_default_region() {
    echo -e "${YELLOW}設定預設地區...${NC}"

    if gcloud config set compute/region "$GOOGLE_CLOUD_LOCATION" --project="$GOOGLE_CLOUD_PROJECT"; then
        echo -e "${GREEN}✓ 已設定預設地區為 $GOOGLE_CLOUD_LOCATION${NC}"
    else
        echo -e "${RED}✗ 設定預設地區失敗${NC}"
        return 1
    fi
}

# 檢查 Vertex AI Studio 存取權限
check_vertex_ai_access() {
    echo -e "${YELLOW}檢查 Vertex AI Studio 存取權限...${NC}"

    # 嘗試列出 Vertex AI 資源以檢查存取權限
    if gcloud ai models list --region="$GOOGLE_CLOUD_LOCATION" --project="$GOOGLE_CLOUD_PROJECT" --limit=1 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Vertex AI 存取權限正常${NC}"
    else
        echo -e "${RED}✗ Vertex AI 存取權限檢查失敗${NC}"
        echo "請確保您的帳戶有 Vertex AI 使用者或編輯者角色"
        return 1
    fi
}

# 顯示實驗室指示
show_lab_instructions() {
    echo -e "${BLUE}=== 實驗室執行指示 ===${NC}"
    echo ""
    echo "此實驗室主要在 Google Cloud Console 的 Vertex AI Studio 中執行。"
    echo ""
    echo "請按照以下步驟操作："
    echo ""
    echo "=== 任務 1：從提示創建應用程式 ==="
    echo "1. 前往 Google Cloud Console > Vertex AI > Vertex AI Studio"
    echo "2. 點擊 'New > Chat' 創建新聊天"
    echo "3. 將提示命名為 'Insurance Risk Summary - Prototype'"
    echo "4. 設定系統指令為保險承保部門專家角色"
    echo "5. 貼上客戶筆記並設定任務"
    echo "6. 儲存提示"
    echo "7. 使用 'Code > Deploy > Deploy as app' 部署為 Cloud Run 應用程式"
    echo "8. 測試已部署的應用程式"
    echo ""
    echo "=== 任務 2：設計有效的提示 ==="
    echo "1. 創建新的 'Insurance Claim Data Extraction' 提示"
    echo "2. 試驗零樣本提示（沒有範例）"
    echo "3. 添加少樣本範例以改善輸出"
    echo "4. 試驗不同的模型參數（溫度、Top-P、權杖限制）"
    echo ""
    echo "=== 任務 3：工程和管理提示 ==="
    echo "1. 創建 'Insurance Risk Factor Identification' 提示"
    echo "2. 使用比較功能比較不同的系統指令"
    echo "3. 比較不同的溫度設定"
    echo "4. 比較不同的模型（Gemini Pro vs Gemini Flash）"
    echo ""
    echo "=== 任務 4：使用 Gemini 的多模態提示 ==="
    echo "1. 創建 'Timetable Image Analysis' 提示"
    echo "2. 從 Cloud Storage 匯入 timetable.png 影像"
    echo "3. 要求模型分析影像並提取資訊"
    echo "4. 測試推理問題（例如計算百分比）"
    echo "5. 試驗不同的溫度設定"
    echo ""
    echo "=== 任務 5：生成媒體（可選）==="
    echo "1. 點擊 'New > Image' 生成影像"
    echo "2. 使用 Imagen 模型生成蜜蜂採集花粉的影像"
    echo "3. 探索 Inpaint 和 Outpaint 功能"
    echo "4. （可選）嘗試語音生成使用 Chirp"
    echo ""
    echo -e "${YELLOW}注意事項：${NC}"
    echo "- 此實驗室幾乎完全在 UI 中執行"
    echo "- 確保使用 Global 地區以獲得最佳模型可用性"
    echo "- 部署應用程式可能需要 2-3 分鐘"
    echo "- 如果部署失敗，請等待 1 分鐘後重試"
}

# 顯示學習資源
show_resources() {
    echo -e "${BLUE}=== 學習資源 ===${NC}"
    echo ""
    echo "官方文件："
    echo "- Vertex AI Studio: https://cloud.google.com/generative-ai-studio"
    echo "- 提示設計指南: https://cloud.google.com/discover/what-is-prompt-engineering#types-of-prompts"
    echo "- Imagen 文件: https://cloud.google.com/vertex-ai/docs/generative-ai/image/overview"
    echo "- Chirp 語音生成: https://cloud.google.com/text-to-speech/docs/ssml"
    echo "- SynthID 說明: https://deepmind.google/technologies/synthid/"
    echo ""
    echo "相關工具："
    echo "- Vertex AI Cookbook: https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook"
    echo "- Google Cloud Generative AI GitHub: https://github.com/GoogleCloudPlatform/generative-ai"
    echo ""
    echo "學習重點："
    echo "- 系統指令用於控制模型行為"
    echo "- 少樣本提示可以顯著改善結構化和準確性"
    echo "- 溫度控制隨機性和創意性"
    echo "- 多模態功能支援影像和文字分析"
    echo "- Vertex AI Studio 提供快速原型化功能"
}

# 主執行流程
main() {
    echo "開始設定 GSP1154 Vertex AI Studio 入門實驗室的環境..."
    echo ""

    # 檢查環境變數
    check_environment

    echo ""

    # 啟用必要的 APIs
    if enable_apis; then
        echo ""
    else
        echo -e "${RED}API 啟用失敗，請手動啟用必要的 APIs${NC}"
        exit 1
    fi

    # 設定預設地區
    if set_default_region; then
        echo ""
    else
        echo -e "${RED}地區設定失敗${NC}"
        exit 1
    fi

    # 檢查 Vertex AI 存取權限
    if check_vertex_ai_access; then
        echo ""
    else
        echo -e "${RED}Vertex AI 存取權限檢查失敗${NC}"
        exit 1
    fi

    # 顯示實驗室指示
    show_lab_instructions

    echo ""

    # 顯示學習資源
    show_resources

    echo ""
    echo -e "${GREEN}=== 環境設定完成！===${NC}"
    echo ""
    echo "現在您可以按照上述指示在 Vertex AI Studio 中執行實驗室。"
    echo ""
    echo "實驗室涵蓋以下主題："
    echo "• 從提示創建和部署應用程式"
    echo "• 設計有效的提示（零樣本 vs 少樣本）"
    echo "• 提示工程和管理（比較功能）"
    echo "• 多模態提示（影像分析）"
    echo "• 媒體生成（Imagen 影像和 Chirp 語音）"
    echo ""
    echo "關鍵學習點："
    echo "- Vertex AI Studio 的直觀介面"
    echo "- 系統指令和少樣本提示的威力"
    echo "- 模型參數如何影響輸出"
    echo "- 多模態 AI 的實際應用"
    echo "- 從原型到生產的快速路徑"
    echo ""
    echo -e "${YELLOW}提示：開始時選擇 'Global' 地區以獲得最佳模型可用性${NC}"
    echo ""
    echo "祝學習愉快！🎯"
}

# 執行主函數
main "$@"
