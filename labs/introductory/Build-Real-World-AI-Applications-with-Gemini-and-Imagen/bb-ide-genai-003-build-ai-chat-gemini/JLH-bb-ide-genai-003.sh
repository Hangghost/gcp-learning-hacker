#!/bin/bash

# 使用 Gemini 模型構建聊天應用程式 - 自動化腳本
# 此腳本自動化執行實驗室的各個步驟

set -e  # 遇到錯誤時停止執行

# 顏色輸出設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數定義
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

check_prerequisites() {
    print_header "檢查先決條件"

    # 檢查 gcloud 是否已安裝
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud 未安裝，請先安裝 Google Cloud SDK"
        exit 1
    fi

    # 檢查 python3 是否已安裝
    if ! command -v python3 &> /dev/null; then
        print_error "python3 未安裝，請先安裝 Python 3"
        exit 1
    fi

    # 檢查是否已登入 gcloud
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 | grep -q "@"; then
        print_warning "未登入 gcloud，正在嘗試登入..."
        gcloud auth login
    fi

    print_success "先決條件檢查完成"
}

setup_environment() {
    print_header "設定環境變數"

    # 提示使用者輸入專案 ID
    if [ -z "$PROJECT_ID" ]; then
        read -p "請輸入您的 Google Cloud 專案 ID: " PROJECT_ID
    fi

    # 設定預設區域
    if [ -z "$REGION" ]; then
        read -p "請輸入區域 (預設: us-central1): " REGION
        REGION=${REGION:-us-central1}
    fi

    # 設定專案
    gcloud config set project $PROJECT_ID

    print_success "環境變數設定完成"
}

enable_apis() {
    print_header "啟用必要的 API"

    # 啟用 Vertex AI API
    gcloud services enable aiplatform.googleapis.com --project=$PROJECT_ID

    print_success "API 啟用完成"
}

install_packages() {
    print_header "安裝必要的套件"

    # 升級 pip
    python3 -m pip install --upgrade pip

    # 安裝必要的套件
    python3 -m pip install google-cloud-aiplatform
    python3 -m pip install google-generativeai

    print_success "套件安裝完成"
}

create_python_files() {
    print_header "創建 Python 程式碼檔案"

    # 創建無串流聊天程式碼
    cat > SendChatwithoutStream.py << 'EOF'
from google import genai
from google.genai.types import HttpOptions, ModelContent, Part, UserContent

import logging
from google.cloud import logging as gcp_logging

# 初始化 GCP 日誌（供 Qwiklab 內部使用，請勿編輯/刪除）
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

# 初始化 Gemini 客戶端
client = genai.Client(
    vertexai=True,
    project="PROJECT_ID_PLACEHOLDER",
    location="REGION_PLACEHOLDER",
    http_options=HttpOptions(api_version="v1")
)

# 建立聊天對話
chat = client.chats.create(
    model="gemini-2.0-flash-001",
    history=[
        UserContent(parts=[Part(text="Hello")]),
        ModelContent(
            parts=[Part(text="Great to meet you. What would you like to know?")],
        ),
    ],
)

# 發送訊息並獲取回應
response = chat.send_message("What are all the colors in a rainbow?")
print(response.text)

response = chat.send_message("Why does it appear when it rains?")
print(response.text)
EOF

    # 創建串流聊天程式碼
    cat > SendChatwithStream.py << 'EOF'
from google import genai
from google.genai.types import HttpOptions

import logging
from google.cloud import logging as gcp_logging

# 初始化 GCP 日誌（供 Qwiklab 內部使用，請勿編輯/刪除）
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

# 初始化 Gemini 客戶端
client = genai.Client(
    vertexai=True,
    project="PROJECT_ID_PLACEHOLDER",
    location="REGION_PLACEHOLDER",
    http_options=HttpOptions(api_version="v1")
)

# 建立聊天對話
chat = client.chats.create(model="gemini-2.0-flash-001")
response_text = ""

# 使用串流發送訊息並即時顯示回應
for chunk in chat.send_message_stream("What are all the colors in a rainbow?"):
    print(chunk.text, end="")
    response_text += chunk.text
EOF

    print_success "Python 檔案創建完成"
}

replace_placeholders() {
    print_header "替換程式碼中的預留位置"

    # 替換專案 ID
    sed -i "s/PROJECT_ID_PLACEHOLDER/$PROJECT_ID/g" SendChatwithoutStream.py SendChatwithStream.py

    # 替換區域
    sed -i "s/REGION_PLACEHOLDER/$REGION/g" SendChatwithoutStream.py SendChatwithStream.py

    print_success "預留位置替換完成"
}

test_non_streaming() {
    print_header "測試無串流聊天應用程式"

    echo "執行無串流聊天程式碼..."
    python3 SendChatwithoutStream.py

    print_success "無串流聊天測試完成"
}

test_streaming() {
    print_header "測試串流聊天應用程式"

    echo "執行串流聊天程式碼..."
    python3 SendChatwithStream.py

    print_success "串流聊天測試完成"
}

cleanup() {
    print_header "清理資源"

    echo "這個實驗室主要使用現有的 API 和服務，通常不會產生額外的運算資源費用。"
    echo "建議檢查 Google Cloud Console 的計費頁面確認沒有意外費用。"

    read -p "是否要刪除建立的 Python 檔案？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f SendChatwithoutStream.py SendChatwithStream.py
        print_success "Python 檔案已刪除"
    else
        print_warning "Python 檔案保留在當前目錄中"
    fi
}

show_summary() {
    print_header "實驗室完成摘要"

    echo -e "${GREEN}恭喜！您已成功完成實驗室：使用 Gemini 模型構建聊天應用程式${NC}"
    echo ""
    echo "完成內容："
    echo "✅ 設定環境並連接到 Vertex AI"
    echo "✅ 安裝必要的套件"
    echo "✅ 建立無串流聊天回應應用程式"
    echo "✅ 建立串流聊天回應應用程式"
    echo "✅ 測試不同的提示並觀察回應"
    echo ""
    echo "學到的技能："
    echo "• 如何連接到 Google Cloud Vertex AI"
    echo "• 使用 Gemini 模型進行文字生成"
    echo "• 實現串流和非串流聊天回應"
    echo "• 處理 AI 模型的輸入和輸出"
    echo ""
    echo "專案資訊："
    echo "• 專案 ID: $PROJECT_ID"
    echo "• 區域: $REGION"
    echo ""
    print_warning "重要提醒：請記錄您的學習筆記並嘗試不同的提示來探索 Gemini 的功能！"
}

main() {
    print_header "開始執行實驗室：使用 Gemini 模型構建聊天應用程式"

    check_prerequisites
    setup_environment
    enable_apis
    install_packages
    create_python_files
    replace_placeholders

    echo ""
    print_warning "即將執行程式碼測試。請確保網路連線正常。"
    read -p "按 Enter 鍵繼續執行測試..."

    test_non_streaming
    test_streaming

    show_summary

    print_warning "實驗室執行完成！"
}

# 執行主函數
main "$@"
