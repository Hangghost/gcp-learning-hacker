#!/bin/bash

# GSP1151 - 使用 Vertex AI 的生成式 AI：提示設計 - 自動化腳本
# 此腳本協助設定 Vertex AI Workbench 環境以執行提示設計實驗室

set -e  # 遇到錯誤時停止執行

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 腳本開始
echo -e "${GREEN}=== GSP1151 - 使用 Vertex AI 的生成式 AI：提示設計 ===${NC}"
echo ""

# 檢查必要的環境變數
check_environment() {
    echo -e "${YELLOW}檢查環境變數...${NC}"

    if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
        echo -e "${RED}錯誤：請設定 GOOGLE_CLOUD_PROJECT 環境變數${NC}"
        echo "例如：export GOOGLE_CLOUD_PROJECT='your-project-id'"
        exit 1
    fi

    echo -e "${GREEN}✓ 環境變數檢查完成${NC}"
    echo "專案 ID: $GOOGLE_CLOUD_PROJECT"
}

# 啟用必要的 API
enable_apis() {
    echo -e "${YELLOW}啟用必要的 Google Cloud APIs...${NC}"

    local apis=(
        "aiplatform.googleapis.com"
        "generativelanguage.googleapis.com"
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

# 檢查 Vertex AI Workbench 實例
check_workbench_instance() {
    echo -e "${YELLOW}檢查 Vertex AI Workbench 實例...${NC}"

    local instance_name="prompt-design-workbench"

    # 檢查實例是否存在
    if gcloud workbench instances describe "$instance_name" \
        --project="$GOOGLE_CLOUD_PROJECT" \
        --location="us-central1" \
        --format="value(state)" 2>/dev/null; then

        echo -e "${GREEN}✓ Vertex AI Workbench 實例 '$instance_name' 已存在${NC}"
    else
        echo -e "${YELLOW}未找到 Vertex AI Workbench 實例 '$instance_name'${NC}"
        echo "請按照以下步驟手動建立："
        echo ""
        echo "1. 前往 Google Cloud Console"
        echo "2. 導覽至 Vertex AI > Workbench"
        echo "3. 建立新的 Workbench 實例"
        echo "4. 選擇適當的機器類型和地區"
        echo "5. 等待實例建立完成"
        echo ""
        read -p "按 Enter 鍵繼續（假設您已建立 Workbench 實例）..."
    fi
}

# 顯示實驗室指示
show_lab_instructions() {
    echo -e "${BLUE}=== 實驗室執行指示 ===${NC}"
    echo ""
    echo "此實驗室主要在 Vertex AI Workbench 的 Jupyter notebook 中執行。"
    echo ""
    echo "請按照以下步驟操作："
    echo ""
    echo "1. 在 Google Cloud Console 中前往 Vertex AI > Workbench"
    echo "2. 找到您的 Workbench 實例並點擊 'Open JupyterLab'"
    echo "3. 在 JupyterLab 中開啟提示設計 notebook"
    echo "4. 在 'Select Kernel' 對話框中選擇 'Python 3'"
    echo "5. 依序執行以下區段："
    echo "   - Getting Started（開始）"
    echo "   - Be concise（保持簡潔）"
    echo "   - Be specific, and well-defined（保持具體且定義良好）"
    echo "   - Ask one task at a time（一次只問一個任務）"
    echo "   - Watch out for hallucinations（注意幻覺）"
    echo "   - Using system instructions（使用系統指令）"
    echo "   - Turn generative tasks into classification tasks（將生成性任務轉換為分類任務）"
    echo "   - Improve response quality by including examples（透過包含範例來改善回應品質）"
    echo ""
    echo "6. 每個區段執行後，點擊 'Check my progress' 來驗證完成"
    echo ""
    echo -e "${YELLOW}注意：如果遇到 429 錯誤，請等待 1 分鐘後重試${NC}"
}

# 顯示學習資源
show_resources() {
    echo -e "${BLUE}=== 學習資源 ===${NC}"
    echo ""
    echo "官方文件："
    echo "- Gemini 總覽: https://deepmind.google/technologies/gemini/"
    echo "- Vertex AI 生成式 AI 文件: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview"
    echo "- 提示設計介紹: https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/introduction-prompt-design"
    echo "- 系統指令: https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instruction-introduction"
    echo ""
    echo "實作資源："
    echo "- Vertex AI Cookbook: https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook"
    echo "- Google Cloud 生成式 AI GitHub: https://github.com/GoogleCloudPlatform/generative-ai"
    echo "- YouTube 生成式 AI 教學: https://www.youtube.com/@googlecloudtech/"
}

# 主執行流程
main() {
    echo "開始設定 GSP1151 提示設計實驗室的環境..."
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

    # 檢查 Workbench 實例
    check_workbench_instance

    echo ""

    # 顯示實驗室指示
    show_lab_instructions

    echo ""

    # 顯示學習資源
    show_resources

    echo ""
    echo -e "${GREEN}=== 環境設定完成！===${NC}"
    echo ""
    echo "現在您可以按照上述指示在 Vertex AI Workbench 中執行 notebook。"
    echo "實驗室涵蓋以下主題："
    echo "• 提示工程最佳實踐"
    echo "• 簡潔性和具體性"
    echo "• 任務定義和範例使用"
    echo "• 減少幻覺和輸出變異性"
    echo "• 系統指令和分類任務"
    echo ""
    echo "祝學習愉快！"
}

# 執行主函數
main "$@"
