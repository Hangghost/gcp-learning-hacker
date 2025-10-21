# bb-ide-genai-004 - Build a Multi-Modal GenAI Application: Challenge Lab - Integrated Execution Guide

This guide provides a streamlined, executable solution for the Multi-Modal GenAI Application Challenge Lab. You can copy and run the commands below directly in your terminal.

## Prerequisites
- Google Cloud project with Vertex AI API enabled
- Python 3.7+ with required packages installed
- gcloud CLI configured and authenticated

## Integrated Solution

### Environment Setup
```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
```

### Task 1: Generate Bouquet Image
```bash
cat > GenerateImage.py <<EOF_TASK_ONE
import argparse
import os
import vertexai
from vertexai.vision_models import ImageGenerationModel

def generate_bouquet_image(
    project_id: str, location: str, output_file: str, prompt: str):
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

# Execute the function
generate_bouquet_image(
    project_id=os.environ['PROJECT_ID'],
    location=os.environ['REGION'],
    output_file='generated_bouquet.png',
    prompt='Create an image containing a bouquet of 2 sunflowers and 3 roses',
)
EOF_TASK_ONE
```

```bash
/usr/bin/python3 GenerateImage.py
```

### Task 2: Analyze Image and Generate Birthday Wishes
```bash
cat > AnalyzeImage.py <<EOF_TASK_TWO
import vertexai
from vertexai.generative_models import GenerativeModel, Part, Image
import os

def analyze_bouquet_image(project_id: str, location: str):
    """Analyze bouquet image and generate birthday wishes.

    Args:
        project_id: Google Cloud project ID
        location: Google Cloud region"""

    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)

    # Load the Gemini multimodal model (version 2.0 flash)
    model = GenerativeModel("gemini-2.0-flash-001")

    # Load the image from file
    image_path = "generated_bouquet.png"
    image_part = Part.from_image(Image.load_from_file(image_path))

    # Generate birthday wishes based on the image
    print("🎂 Analyzing image and generating birthday wishes...")
    response_stream = model.generate_content(
        [image_part, Part.from_text("Please analyze this bouquet image and create warm birthday wishes in English. Describe what you see and express sincere birthday blessings.")],
        stream=True
    )

    full_response = ""
    for chunk in response_stream:
        if chunk.text:
            print(chunk.text, end="", flush=True)
            full_response += chunk.text
    print("\n")

    print("✅ Birthday wishes generation completed!")
    return full_response

# Execute the function
analyze_bouquet_image(
    project_id=os.environ['PROJECT_ID'],
    location=os.environ['REGION']
)
EOF_TASK_TWO
```

```bash
/usr/bin/python3 AnalyzeImage.py
```

## Verification Commands

### Check Generated Files
```bash
# Verify image file was created
ls -la generated_bouquet.png

# Check file size (should be > 0 if successful)
stat generated_bouquet.png
```

### Test Individual Components
```bash
# Test image generation separately
python3 -c "
import os
import vertexai
from vertexai.vision_models import ImageGenerationModel

# Set environment variables
os.environ['PROJECT_ID'] = '$PROJECT_ID'
os.environ['REGION'] = '$REGION'

# Initialize Vertex AI
vertexai.init(project=os.environ['PROJECT_ID'], location=os.environ['REGION'])

# Generate image
model = ImageGenerationModel.from_pretrained('imagen-3.0-generate-002')
images = model.generate_images(
    prompt='Create an image containing a bouquet of 2 sunflowers and 3 roses',
    number_of_images=1,
    seed=1,
    add_watermark=False,
)
images[0].save(location='test_bouquet.png')
print('✅ Test image generation completed')
"

# Test text generation separately
python3 -c "
import os
import vertexai
from vertexai.generative_models import GenerativeModel

# Set environment variables
os.environ['PROJECT_ID'] = '$PROJECT_ID'
os.environ['REGION'] = '$REGION'

# Initialize Vertex AI
vertexai.init(project=os.environ['PROJECT_ID'], location=os.environ['REGION'])

# Test with text generation
model = GenerativeModel('gemini-2.0-flash-001')
response = model.generate_content('Create a simple birthday wish for a friend.')
print('✅ Test text generation completed')
print('Response:', response.text[:100] + '...' if len(response.text) > 100 else response.text)
"
```

## Cleanup
```bash
# Remove generated files
rm -f generated_bouquet.png GenerateImage.py AnalyzeImage.py diagnose.py test_bouquet.png

echo "✅ Cleanup completed!"
```

## Alternative: Complete Application Script

For a more integrated approach, here's a single script that handles both tasks:

```bash
cat > multi_modal_app.py <<EOF_COMPLETE
#!/usr/bin/env python3
"""
Multi-Modal GenAI Bouquet Application
Integrates image generation and analysis functionality
"""

import os
import vertexai
from vertexai.vision_models import ImageGenerationModel
from vertexai.generative_models import GenerativeModel, Part, Image

def main():
    # Get environment variables
    project_id = os.environ.get('PROJECT_ID')
    region = os.environ.get('REGION')

    if not project_id or not region:
        print("❌ Error: PROJECT_ID and REGION environment variables must be set")
        return

    print("🎨 Starting Multi-Modal GenAI Bouquet Application")
    print(f"Project ID: {project_id}")
    print(f"Region: {region}")
    print("=" * 60)

    # Initialize Vertex AI
    vertexai.init(project=project_id, location=region)

    # Task 1: Generate bouquet image
    print("📷 Task 1: Generating bouquet image...")
    imagen_model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")

    images = imagen_model.generate_images(
        prompt="Create an image containing a bouquet of 2 sunflowers and 3 roses",
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )

    # Save image
    output_file = "generated_bouquet.png"
    images[0].save(location=output_file)
    print(f"✅ Image saved to: {output_file}")

    # Task 2: Analyze image and generate birthday wishes
    print("\n🎂 Task 2: Analyzing image and generating birthday wishes...")
    gemini_model = GenerativeModel("gemini-2.0-flash-001")

    # Load the image from file
    image = Image.load_from_file(output_file)

    response_stream = gemini_model.generate_content(
        [image, "Please analyze this bouquet image and create warm birthday wishes in English. Describe what you see and express sincere birthday blessings."],
        stream=True
    )

    print("Birthday wishes: ", end="")
    full_response = ""
    for chunk in response_stream:
        if chunk.text:
            print(chunk.text, end="", flush=True)
            full_response += chunk.text
    print("\n")

    print("✅ Multi-Modal GenAI Application completed successfully!")
    print(f"📁 Generated image: {output_file}")
    print(f"🎉 Birthday wishes length: {len(full_response)} characters")

if __name__ == "__main__":
    main()
EOF_COMPLETE

python3 multi_modal_app.py
```

## Expected Output

After successful execution, you should see:
1. **Image Generation**: A PNG file named `generated_bouquet.png` created in your directory
2. **Image Analysis**: Streaming birthday wishes text based on the actual generated bouquet image
3. **Success Messages**: Confirmation that both tasks completed successfully

## Troubleshooting

### Common Issues:

1. **API Permission Errors**:
   ```bash
   gcloud services enable aiplatform.googleapis.com
   gcloud auth application-default login
   ```

2. **Import Errors**:
   ```bash
   pip install google-cloud-aiplatform
   pip install pillow
   ```

3. **Model Not Found**:
   - Ensure you're using the correct model names: `imagen-3.0-generate-002` and `gemini-2.0-flash-001`
   - Check your project's region supports these models
   - Verify Vertex AI API is enabled in your project

4. **Region Issues**:
   - Ensure your region is supported for Vertex AI (us-central1 is supported)
   - Check if environment variables are properly set before running the script
   - Use `os.environ['VARIABLE']` instead of `$VARIABLE` in Python strings

5. **File Path Issues**:
   - Ensure the image file path is correct in the analysis script
   - Use absolute paths if relative paths don't work

6. **Multimodal Input Format**:
   - Use the correct format for multimodal input: `Part.from_image(Image.load_from_file(path))`
   - Ensure the image file exists before attempting analysis
   - Make sure the image format is supported (PNG, JPEG, etc.)

## Tips for Success

1. **Check API Quotas**: Ensure your project has sufficient quota for Vertex AI requests
2. **Monitor Costs**: Image generation and analysis consume API credits
3. **Test Incrementally**: Run each task separately to isolate any issues
4. **Review Logs**: Check the console output for any error messages or warnings
5. **Verify Environment**: Always check that environment variables are properly set before running Python scripts

## Quick Diagnostic Script

If you encounter issues, run this diagnostic script first:

```bash
cat > diagnose.py <<EOF_DIAGNOSE
import os
import vertexai

# Check environment variables
project_id = os.environ.get('PROJECT_ID')
region = os.environ.get('REGION')

print(f"Project ID: {project_id}")
print(f"Region: {region}")

if project_id and region:
    try:
        # Test Vertex AI initialization
        vertexai.init(project=project_id, location=region)
        print("✅ Vertex AI initialization successful")

        # Test model loading
        from vertexai.vision_models import ImageGenerationModel
        imagen_model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")
        print("✅ ImageGenerationModel loaded successfully")

        from vertexai.generative_models import GenerativeModel
        gemini_model = GenerativeModel("gemini-2.0-flash-001")
        print("✅ GenerativeModel loaded successfully")

        # Test basic functionality
        response = gemini_model.generate_content("Hello, world!")
        print("✅ Basic text generation test successful")

        # Test image loading capability
        try:
            from vertexai.vision_models import Image
            test_image = Image.load_from_file("test_bouquet.png")
            print("✅ Image loading test successful")
        except Exception as e:
            print(f"⚠️ Image loading test skipped: {e}")

    except Exception as e:
        print(f"❌ Error: {e}")
else:
    print("❌ Environment variables not set properly")
EOF_DIAGNOSE

python3 diagnose.py
```

---

**🎉 Congratulations!** You have successfully completed the Multi-Modal GenAI Application Challenge Lab by implementing both image generation and analysis functionality with streaming responses.
