#!/bin/bash

# 使用 Gemini on Vertex AI 構建 AI 圖像識別應用 - 自動化腳本
# 此腳本自動化執行 AI 圖像識別實驗室的步驟

set -e  # 遇到錯誤時停止執行

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 腳本開始
echo -e "${GREEN}=== 使用 Gemini on Vertex AI 構建 AI 圖像識別應用 ===${NC}"
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

    if [ -z "$GOOGLE_GENAI_USE_VERTEXAI" ]; then
        echo -e "${RED}錯誤：請設定 GOOGLE_GENAI_USE_VERTEXAI 環境變數為 True${NC}"
        echo "例如：export GOOGLE_GENAI_USE_VERTEXAI=True"
        exit 1
    fi

    echo -e "${GREEN}✓ 環境變數檢查完成${NC}"
}

# 創建 Python 腳本
create_python_script() {
    echo -e "${YELLOW}創建 Python 腳本...${NC}"

    cat > genai.py << 'EOF'
from google import genai
from google.genai.types import HttpOptions, Part

client = genai.Client(http_options=HttpOptions(api_version="v1"))
response = client.models.generate_content(
    model="gemini-2.0-flash-001",
    contents=[
        "What is shown in this image?",
        Part.from_uri(
            file_uri="https://storage.googleapis.com/cloud-samples-data/generative-ai/image/scones.jpg",
            mime_type="image/jpeg",
        ),
    ],
)
print(response.text)
EOF

    echo -e "${GREEN}✓ Python 腳本創建完成：genai.py${NC}"
}

# 執行 Python 腳本
run_python_script() {
    echo -e "${YELLOW}執行 Python 腳本...${NC}"

    # 嘗試執行腳本，如果失敗則重試一次
    local max_attempts=2
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo "執行嘗試 $attempt/$max_attempts..."

        if /usr/bin/python3 genai.py; then
            echo -e "${GREEN}✓ Python 腳本執行成功${NC}"
            return 0
        else
            echo -e "${RED}執行失敗，錯誤碼：$?${NC}"
            if [ $attempt -eq $max_attempts ]; then
                echo -e "${RED}已達到最大重試次數，請手動檢查錯誤${NC}"
                return 1
            fi
            echo "等待 5 秒後重試..."
            sleep 5
        fi

        ((attempt++))
    done
}

# 清理暫存文件
cleanup() {
    echo -e "${YELLOW}清理暫存文件...${NC}"

    if [ -f "genai.py" ]; then
        rm -f genai.py
        echo -e "${GREEN}✓ 已刪除 genai.py${NC}"
    fi

    echo -e "${GREEN}✓ 清理完成${NC}"
}

# 主執行流程
main() {
    echo "開始執行 AI 圖像識別實驗室..."
    echo ""

    # 檢查環境變數
    check_environment

    echo ""

    # 創建 Python 腳本
    create_python_script

    echo ""

    # 執行 Python 腳本
    if run_python_script; then
        echo ""
        echo -e "${GREEN}=== 實驗室完成！===${NC}"
        echo ""
        echo "實驗室已成功執行。您已經："
        echo "1. ✓ 設定了 Vertex AI 環境變數"
        echo "2. ✓ 載入了 Gemini 預訓練模型"
        echo "3. ✓ 向 AI 模型發送了圖像和文字問題"
        echo "4. ✓ 從 AI 獲得了基於文字的答案"
        echo ""
        echo "現在您可以嘗試使用不同的圖像 URI 和問題來進一步探索 Gemini 的功能！"
    else
        echo ""
        echo -e "${RED}=== 實驗室執行失敗 ===${NC}"
        echo "請檢查上述錯誤信息並手動執行步驟。"
        exit 1
    fi

    echo ""

    # 詢問是否清理文件
    read -p "是否要刪除暫存的 Python 腳本？(y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup
    else
        echo -e "${YELLOW}保留 Python 腳本以供進一步實驗${NC}"
    fi
}

# 執行主函數
main "$@"
