# GSP1230 - Using Gemini for Multimodal Retail Recommendations

## Lab Overview
Gemini is a family of generative AI models developed by Google DeepMind that is designed for multimodal use cases.

For retail companies, recommendation systems improve customer experience and thus can increase sales. In this lab, you will learn how to use the Gemini model to rapidly create a multimodal recommendation system. The Gemini model can provide both recommendations and explanations using a multimodal model.

In this lab, you will begin with a scene (e.g. a living room) and use the Gemini model to perform visual understanding. You will also investigate how the Gemini model can be used to recommend an item (e.g. a chair) from a list of furniture items as input.

## Gemini Overview

### Gemini API in Vertex AI
The Gemini API in Vertex AI provides a unified interface for interacting with Gemini models. This allows developers to easily integrate these powerful AI capabilities into their applications. For the most up-to-date details and specific features of the latest versions, please refer to the official [Gemini documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#gemini-models).

### Gemini Models

- [**Gemini Pro**](https://deepmind.google/technologies/gemini/pro): Designed for complex reasoning, including:
  - Analyzing and summarizing large amounts of information
  - Sophisticated cross-modal reasoning (across text, code, images, etc.)
  - Effective problem-solving with complex codebases

- [**Gemini Flash**](https://deepmind.google/technologies/gemini/flash): Optimized for speed and efficiency, offering:
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

- Use the Gemini model (`model_id`) to perform visual understanding
- Take multimodality into consideration in prompting for the Gemini model
- Create a retail recommendation application using the Gemini model

## Estimated Time
60 minutes

## Lab Steps

### Step 1: Open the notebook in Vertex AI Workbench

1. In the Google Cloud console, on the **Navigation menu** (), click **Vertex AI > Workbench**.

    [Navigation menu icon](https://cdn.qwiklabs.com/tkgw1TDgj4Q%2BYKQUW4jUFd0O5OEKlUMBRYbhlCrF0WY%3D)

2. Find the `Workbench instance name` instance and click on the **Open JupyterLab** button.

The JupyterLab interface for your Workbench instance opens in a new browser tab.

**Note:** If you do not see notebooks in JupyterLab, please follow these additional steps to reset the instance:

1. Close the browser tab for JupyterLab, and return to the Workbench home page.

2. Select the checkbox next to the instance name, and click **Reset**.

3. After the **Open JupyterLab** button is enabled again, wait one minute, and then click **Open JupyterLab**.

### Step 2: Set up the notebook

1. Open the `notebook name` file.

2. In the **Select Kernel** dialog, choose **Python 3** from the list of available kernels.

3. Run through the **Getting Started** section of the notebook. The Project ID and Location are pre-configured for you.

**Note:** If you experience a 429 response from any of the notebook cell executions, wait one minute before running the cell again to proceed.

Click **Check my progress** to verify the objective.

Install Gen AI SDK for Python and import libraries

In the following sections, you will run through the notebook cells to see how to use the multimodal capabilities of the Gemini model.

### Step 3: Use the Gemini model

The Gemini model (`model_id`) is a multimodal model that supports adding image and video in text or chat prompts for a text response.

1. In this task, run through the notebook cells to see how to use the Gemini model to describe a room in details from its image, combining text and image in a single prompt.

Click **Check my progress** to verify the objective.

Use Gemini model to describe a room

### Step 4: Generate open recommendations based on built-in knowledge

Using the same image, you can ask the model to recommend a piece of furniture that would fit in it alongside with the description of the room. Note that the model can choose **any furniture** to recommend in this case, and can do so from its only built-in knowledge.

1. Using the same image, run through the notebook cells to see how to use the Gemini model to recommend a piece of furniture that would fit in the room, alongside with the description of the room.

Click **Check my progress** to verify the objective.

Use Gemini model to recommend a piece of furniture

### Step 5: Generate recommendations based on provided images

Instead of keeping the recommendation open, you can also provide a list of items for the model to choose from. This is particularly useful for retail companies who want to provide recommendations to users based on the kind of room they have, and the available items that the store offers.

1. In this task, run through the notebook cells to see how to use the Gemini model to recommend a piece of furniture from a list of items.

Click **Check my progress** to verify the objective.

Use Gemini model to recommend an item from a selection

## Verification
Complete all notebook tasks and successfully run all cells.

## Troubleshooting
- **429 Error**: If you encounter API rate limits, wait one minute and retry
- **Kernel Issues**: If JupyterLab has problems, reset the Workbench instance
- **Permission Errors**: Ensure you have appropriate permissions for Vertex AI APIs

## Cleanup
1. Close JupyterLab tabs
2. Stop Workbench instance if needed to avoid charges

## Additional Resources
- [Gemini Overview](https://deepmind.google/technologies/gemini/)
- [Generative AI on Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [Generative AI on YouTube](https://www.youtube.com/@googlecloudtech/)
- Explore the Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) for a curated, searchable gallery of notebooks for Generative AI
- Explore other notebooks and samples in the Google Cloud Generative AI repository (https://github.com/GoogleCloudPlatform/generative-ai)

## Notes
This lab demonstrates how to use Gemini's multimodal capabilities to build retail recommendation systems. You can use similar approaches to:
- Recommend clothes based on an occasion or image of the venue
- Recommend wallpaper based on the room and settings
