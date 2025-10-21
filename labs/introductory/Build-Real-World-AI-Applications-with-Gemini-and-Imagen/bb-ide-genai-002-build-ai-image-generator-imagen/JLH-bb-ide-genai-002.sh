#!/bin/bash

# Build an AI Image Generator app using Imagen on Vertex AI
# bb-ide-genai-002

# 設定腳本為失敗時立即結束
set -e

# 顏色輸出設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：輸出帶顏色的訊息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查必要的環境變數
check_environment() {
    print_info "檢查環境設定..."

    # 檢查是否安裝了 python3
    if ! command -v python3 &> /dev/null; then
        print_error "python3 未安裝。請先安裝 Python 3。"
        exit 1
    fi

    # 檢查是否安裝了 Google Cloud SDK
    if ! command -v gcloud &> /dev/null; then
        print_warning "Google Cloud SDK 未安裝。請先安裝 gcloud。"
        print_info "您可以從這裡下載：https://cloud.google.com/sdk/docs/install"
        exit 1
    fi

    print_success "環境檢查完成"
}

# 設定 GCP 專案和區域
setup_gcp() {
    print_info "設定 GCP 專案和區域..."

    # 提示用戶輸入專案 ID 和區域
    read -p "請輸入您的 GCP 專案 ID: " PROJECT_ID
    read -p "請輸入 GCP 區域 (例如: us-central1): " REGION

    # 設定專案
    gcloud config set project $PROJECT_ID

    # 確認專案設定
    CURRENT_PROJECT=$(gcloud config get-value project)
    if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
        print_error "無法設定專案。請檢查專案 ID 是否正確。"
        exit 1
    fi

    print_success "GCP 專案設定完成：$PROJECT_ID，區域：$REGION"
}

# 啟用必要的 API
enable_apis() {
    print_info "啟用必要的 API..."

    # 啟用 Vertex AI API
    print_info "啟用 Vertex AI API..."
    gcloud services enable aiplatform.googleapis.com

    print_success "API 啟用完成"
}

# 建立並執行圖片生成腳本
create_and_run_script() {
    print_info "建立圖片生成腳本..."

    # 建立 Python 腳本
    cat > GenerateImage.py << 'EOF'
import argparse

import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_image(
    project_id: str, location: str, output_file: str, prompt: str
) -> vertexai.preview.vision_models.ImageGenerationResponse:
    """Generate an image using a text prompt.
    Args:
      project_id: Google Cloud project ID, used to initialize Vertex AI.
      location: Google Cloud region, used to initialize Vertex AI.
      output_file: Local path to the output image file.
      prompt: The text prompt describing what you want to see."""

    vertexai.init(project=project_id, location=location)

    model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")

    images = model.generate_images(
        prompt=prompt,
        # Optional parameters
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )

    images[0].save(location=output_file)

    return images

if __name__ == "__main__":
    # 從環境變數獲取參數
    import os

    project_id = os.getenv('PROJECT_ID', 'your-project-id')
    location = os.getenv('REGION', 'us-central1')
    output_file = 'image.jpeg'
    prompt = 'Create an image of a cricket ground in the heart of Los Angeles'

    print(f"Generating image with prompt: {prompt}")
    generate_image(project_id, location, output_file, prompt)
    print(f"Image saved to: {output_file}")
EOF

    print_success "圖片生成腳本建立完成"

    # 執行腳本
    print_info "執行圖片生成腳本..."
    python3 GenerateImage.py

    if [ -f "image.jpeg" ]; then
        print_success "圖片生成成功！檔案：image.jpeg"
    else
        print_error "圖片生成失敗"
        exit 1
    fi
}

# 查看生成的圖片
view_image() {
    print_info "檢查生成的圖片..."
    if [ -f "image.jpeg" ]; then
        print_success "圖片檔案存在：image.jpeg"
        ls -la image.jpeg
    else
        print_error "找不到圖片檔案"
        exit 1
    fi
}

# 清理資源
cleanup() {
    print_info "執行清理作業..."

    read -p "是否要刪除生成的圖片檔案？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f image.jpeg
        rm -f GenerateImage.py
        print_success "清理完成"
    else
        print_info "保留檔案"
    fi
}

# 主執行流程
main() {
    echo -e "${BLUE}"
    echo "======================================"
    echo "  Build an AI Image Generator app"
    echo "  using Imagen on Vertex AI"
    echo "======================================"
    echo -e "${NC}"

    check_environment
    setup_gcp
    enable_apis
    create_and_run_script
    view_image

    print_success "實驗室執行完成！"
    print_info "您可以使用不同的文字提示來測試 AI 模型的功能"

    # 詢問是否清理
    read -p "是否要執行清理？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup
    fi
}

# 執行主函數
main "$@"
