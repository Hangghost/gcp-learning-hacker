# GSP1151 - Generative AI with Vertex AI: Prompt Design

## Lab Overview
This lab explores prompt engineering and best practices for designing effective prompts to improve the quality of your LLM-generated responses. You'll learn how to craft prompts that are concise, specific, and well-defined, focusing on one task at a time. The lab also covers advanced techniques like turning generative tasks into classification tasks and using examples to enhance response quality. For further exploration, refer to the official documentation on [prompt design](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/introduction-prompt-design).

## Gemini

[Gemini](https://deepmind.google/technologies/gemini/) is a family of powerful generative AI models developed by Google DeepMind, capable of understanding and generating various forms of content, including text, code, images, audio, and video.

### Gemini API in Vertex AI

The Gemini API in Vertex AI provides a unified interface for interacting with Gemini models. This allows developers to easily integrate these powerful AI capabilities into their applications. For the most up-to-date details and specific features of the latest versions, please refer to the official [Gemini documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#gemini-models).

### Gemini Models

- [**Gemini Pro**](https://deepmind.google/technologies/gemini/pro/): Designed for complex reasoning, including:
  - Analyzing and summarizing large amounts of information
  - Sophisticated cross-modal reasoning (across text, code, images, etc.)
  - Effective problem-solving with complex codebases

- [**Gemini Flash**](https://deepmind.google/technologies/gemini/flash/): Optimized for speed and efficiency, offering:
  - Sub-second response times and high throughput
  - High quality at a lower cost for a wide range of tasks
  - Enhanced multimodal capabilities, including improved spatial understanding, new output modalities (text, audio, images), and native tool use (Google Search, code execution, and third-party functions)

## Prerequisites

Before starting this lab, you should be familiar with:

- Basic Python programming
- General API concepts
- Running Python code in a Jupyter notebook on [Vertex AI Workbench](https://cloud.google.com/vertex-ai/docs/workbench/introduction)

## Objectives

In this lab, you will learn how to:

- Get started with prompt engineering using the Google Gen AI SDK
- Apply best practices for prompt design, including conciseness, specificity, and task definition
- Explore various text generation use cases with the Google Gen AI SDK, such as:
  - Ideation
  - Question answering
  - Text classification
  - Text extraction
  - Text summarization

## Estimated Time
45 minutes

## Lab Steps

### Task 1. Open the notebook in Vertex AI Workbench

1. In the Google Cloud console, on the **Navigation menu** (), click **Vertex AI > Workbench**.

2. Find the `Workbench instance name` instance and click on the **Open JupyterLab** button.

The JupyterLab interface for your Workbench instance opens in a new browser tab.

**Note:** If you do not see notebooks in JupyterLab, please follow these additional steps to reset the instance:

1. Close the browser tab for JupyterLab, and return to the Workbench home page.

2. Select the checkbox next to the instance name, and click **Reset**.

3. After the **Open JupyterLab** button is enabled again, wait one minute, and then click **Open JupyterLab**.

### Task 2. Set up the notebook

1. Open the `notebook name` file.

2. In the **Select Kernel** dialog, choose **Python 3** from the list of available kernels.

3. Run through the **Getting Started** section of the notebook. The Project ID and Location are pre-configured for you.

**Note:** If you experience a 429 response from any of the notebook cell executions, wait one minute before running the cell again to proceed.

Click **Check my progress** to verify the objective.

Install packages and import libraries

### Task 3. Prompt engineering best practices

Prompt engineering is all about how to design your prompts so that the response is what you were indeed hoping to see. The idea of using "unfancy" prompts is to minimize the noise in your prompt to reduce the possibility of the LLM misinterpreting the intent of the prompt. Below are a few guidelines on how to engineer "unfancy" prompts.

In this section, you'll cover the following best practices when engineering prompts:

- Be concise
- Be specific, and well-defined
- Ask one task at a time
- Improve response quality by including examples
- Turn generative tasks to classification tasks to improve safety

1. Run through the **Be concise** section of the notebook.

Click **Check my progress** to verify the objective.

Be concise

1. Run through the **Be specific, and well-defined** section of the notebook.

Click **Check my progress** to verify the objective.

Be specific, and well-defined

1. Run through the **Ask one task at a time** section of the notebook.

Click **Check my progress** to verify the objective.

Ask one task at a time

1. Run through the **Watch out for hallucinations** section of the notebook.

Click **Check my progress** to verify the objective.

Watch out for hallucinations

### Task 4. Reduce Output Variability

How can you attempt to reduce the chances of irrelevant responses and hallucinations? One way is to provide the LLM with [system instructions](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instruction-introduction). In this section, you will see how system instructions works and how you can use them to reduce hallucinations or irrelevant questions for a travel chatbot.

1. Run through the **Using system instructions to guardrail the model from irrelevant responses** section of the notebook.

Click **Check my progress** to verify the objective.

Using system instructions to guardrail the model from irrelevant responses

1. Run through the **Turn generative tasks into classification tasks to reduce output variability** section of the notebook.

Click **Check my progress** to verify the objective.

Generative tasks lead to higher output variability

1. Run through the **Classification tasks reduces output variability** section of the notebook.

Click **Check my progress** to verify the objective.

Classification tasks reduces output variability

### Task 5. Improve Response Quality by Including Examples

Another way to improve response quality is to add examples in your prompt. The LLM learns in-context from the examples on how to respond. Typically, one to five examples (shots) are enough to improve the quality of responses. Including too many examples can cause the model to over-fit the data and reduce the quality of responses.

Similar to classical model training, the quality and distribution of the examples is very important. Pick examples that are representative of the scenarios that you need the model to learn, and keep the distribution of the examples (e.g. number of examples per class in the case of classification) aligned with your actual distribution.

1. Run through the **Improve response quality by including examples** section of the notebook.

Click **Check my progress** to verify the objective.

Improve response quality by including examples

## Verification
Complete execution of all notebook sections and successfully pass all checkpoints.

## Troubleshooting

### Common Issues
- **429 Error Response**: If you encounter API rate limiting, wait 1 minute and retry
- **Kernel Not Starting**: Ensure Python 3 kernel is selected in JupyterLab
- **Package Installation Failure**: Check network connection and retry

## Cleanup
This lab primarily executes notebooks in Vertex AI Workbench and requires no special cleanup steps. The Workbench instance will automatically stop after a period of time to save costs.

## Additional Resources

- [Gemini Overview](https://deepmind.google/technologies/gemini/)
- [Generative AI on Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [Generative AI on YouTube](https://www.youtube.com/@googlecloudtech/)
- Explore the Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) for a curated, searchable gallery of notebooks for Generative AI
- Explore other notebooks and samples in the [Google Cloud Generative AI repository](https://github.com/GoogleCloudPlatform/generative-ai)

## Notes
- This lab focuses on prompt engineering best practices
- Gemini models provide both text and multimodal capabilities
- System instructions help reduce hallucinations and irrelevant responses
- Examples can significantly improve model response quality
