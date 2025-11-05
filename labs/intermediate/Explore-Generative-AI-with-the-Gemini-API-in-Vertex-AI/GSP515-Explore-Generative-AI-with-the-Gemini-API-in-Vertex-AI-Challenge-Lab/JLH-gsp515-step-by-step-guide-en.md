# GSP515 - Explore Generative AI with the Gemini API in Vertex AI: Challenge Lab

## Task 1: Generate text using Gemini

### 1.1 Set Environment Variables

Execute the following commands in Cloud Shell:

```bash
PROJECT_ID=
LOCATION=
API_ENDPOINT=${LOCATION}-aiplatform.googleapis.com
MODEL_ID=""
```

### 1.2 Enable Required APIs

Go to the Vertex AI section in Cloud Console

Ensure Vertex AI API is enabled

If needed, search for and enable Vertex AI API in the API Library

### 1.3 Call Gemini Model via curl

Use the following curl command to call the Gemini API:

```bash
curl -X POST \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
"https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${MODEL_ID}:generateContent" \
-d '{
  "contents": [{
    "role": "user",
    "parts": [{"text": "Why is the sky blue?"}]
  }]
}'
```

Expected Result: You should receive a JSON response containing Gemini's explanation of "Why is the sky blue?"

### Verification

Check that you receive a valid JSON response

Confirm the response contains a text explanation

Click the Check my progress button to verify task completion

## Task 2: Open the notebook in Vertex AI Workbench

### 2.1 Open Vertex AI Workbench

In Google Cloud Console, click the navigation menu (≡)

Go to Vertex AI > Workbench

Find the instance named Workbench instance name

Click the Open JupyterLab button

### 2.2 If JupyterLab doesn't load

If you don't see notebooks in JupyterLab, follow these additional steps to reset the instance:

Close the JupyterLab browser tab

Return to the Workbench home page

Select the checkbox next to the instance name

Click Reset

Wait one minute for the Open JupyterLab button to be enabled again

Click Open JupyterLab

## Task 3: Create a function call using Gemini

### 3.1 Open and Set Up the Notebook

Open the notebook name file in JupyterLab

In the Select Kernel dialog, choose Python 3

Confirm Project ID and Location are pre-configured

```python
model_id = ""
```

### 3.2 Complete Function Call Implementation

Find the cells marked with INSERT and complete the missing parts:

```python
get_current_weather_func = FunctionDeclaration(
    name="get_current_weather",
    description="Get the current weather in a given location",
    parameters={
        "type": "object",
        "properties": {
            "location": {
                "type": "string",
                "description": "Location"
            }
        }
    },
)
```

### 3.3 Common Implementation Patterns

```python
weather_tool = Tool(
    function_declarations=[get_current_weather_func],
)
```

### 3.4 Test Function Call

```python
prompt = "What is the weather like in Boston?"

response = client.models.generate_content(
    model=model_id,
    contents=prompt,
    config=GenerateContentConfig(
        tools=[weather_tool],
        temperature=0,
    ),
)

response
```

Execute the cell containing the function call

Ensure the response contains weather-related data

Verify the function call JSON structure is correct

## Task 4: Describe video contents using Gemini

### 4.1 Find Task 4 Cell

Remain in Vertex AI Workbench in the same notebook

Find the cell with the comment # Task 4

```python
multimodal_model = "gemini-2.5-flash"
```

### 4.2 Complete Video Content Description Code

Complete the required sections of the notebook notebook name under Task 4:

Hint: You need to:

Load a video file or provide a video URL

Use Gemini's multimodal capabilities to process the video

Generate a description of the video contents

### 4.3 Common Implementation Patterns

```python
prompt = """
What is shown in this video?
Where should I go to see it?
What are the top 5 places in the world that look like this?
"""

video = Part.from_uri(
    file_uri="gs://github-repo/img/gemini/multimodality_usecases_overview/mediterraneansea.mp4",
    mime_type="video/mp4",
)

contents = [prompt, video]

responses = client.models.generate_content_stream(
    model=multimodal_model,
    contents=contents
)

print("-------Prompt--------")
print_multimodal_prompt(contents)

print("\n-------Response--------")
for response in responses:
    print(response.text, end="")
```

Good luck with the lab 🎉

Keep learning, Keep hacking!
