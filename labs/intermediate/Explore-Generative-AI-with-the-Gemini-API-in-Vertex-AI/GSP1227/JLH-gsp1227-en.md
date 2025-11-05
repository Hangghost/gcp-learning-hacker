# GSP1227 - Introduction to Function Calling with Gemini

## Lab Overview

Function calling lets developers create a description of a function in their code, then pass that description to a language model in a request. The response from the model includes the name of a function that matches the description and the arguments to call it with.

Function calling is similar to Vertex AI Extensions in that they both generate information about functions. The difference between them is that function calling returns JSON data with the name of a function and the arguments to use in your code, whereas Vertex AI Extensions returns the function and calls it for you.

## Gemini

[Gemini](https://deepmind.google/technologies/gemini/) is a family of powerful generative AI models developed by Google DeepMind, capable of understanding and generating various forms of content, including text, code, images, audio, and video.

### Gemini API in Vertex AI

The Gemini API in Vertex AI provides a unified interface for interacting with Gemini models. This allows developers to easily integrate these powerful AI capabilities into their applications. For the most up-to-date details and specific features of the latest versions, please refer to the official [Gemini documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#gemini-models).

### Gemini Models

- [**Gemini Pro**](https://deepmind.google/technologies/gemini/pro/): Designed for complex reasoning, including:
  - Analyzing and summarizing large amounts of information.
  - Sophisticated cross-modal reasoning (across text, code, images, etc.).
  - Effective problem-solving with complex codebases.

- [**Gemini Flash**](https://deepmind.google/technologies/gemini/flash/): Optimized for speed and efficiency, offering:
  - Sub-second response times and high throughput.
  - High quality at a lower cost for a wide range of tasks.
  - Enhanced multimodal capabilities, including improved spatial understanding, new output modalities (text, audio, images), and native tool use (Google Search, code execution, and third-party functions).

## Prerequisites

Before starting this lab, you should be familiar with:

- Basic Python programming.
- General API concepts.
- Running Python code in a Jupyter notebook on Vertex AI Workbench.

## Objectives

In this lab, you learn how to:

- Install the Google Gen AI SDK for Python
- Use the Gemini API in Vertex AI to interact with the Gemini 2.0 Flash (`gemini-2.0-flash`) model:
  - Generate function calls from a text prompt to help customers get information about products in the Google Store
  - Generate function calls from a text prompt and call an external API to geocode addresses
  - Generate function calls from a text prompt to extract entities from log data

## Estimated Time

90 minutes

## Lab Steps

### Task 1. Open the notebook in Vertex AI Workbench

1. In the Google Cloud console, on the **Navigation menu** (), click **Vertex AI > Workbench**.

    [Navigation menu icon](https://cdn.qwiklabs.com/tkgw1TDgj4Q%2BYKQUW4jUFd0O5OEKlUMBRYbhlCrF0WY%3D)

2. Find the `Workbench instance name` instance and click on the **Open JupyterLab** button.

The JupyterLab interface for your Workbench instance opens in a new browser tab.

**Note:** If you do not see notebooks in JupyterLab, please follow these additional steps to reset the instance:

1. Close the browser tab for JupyterLab, and return to the Workbench home page.
2. Select the checkbox next to the instance name, and click **Reset**.
3. After the **Open JupyterLab** button is enabled again, wait one minute, and then click **Open JupyterLab**.

### Task 2. Set up the notebook

1. Open the `notebook name` file.
2. In the **Select Kernel** dialog, choose **Python 3** from the list of available kernels.
3. Run through the **Getting Started** and the **Import libraries** sections of the notebook.
   - For **Project ID**, use `Project ID`, and for **Location**, use `Region`.

**Note:** You can skip any notebook cells that are noted *Colab only*. If you experience a 429 response from any of the notebook cell executions, wait 1 minute before running the cell again to proceed.

In the following sections, you will run through the notebook cells to see how to use the Gemini API in Vertex AI with the Google Gen AI SDK for Python.

Click **Check my progress** to verify the objective.

Install Gen AI SDK for Python and import libraries

### Task 3. Using function calling for structured Google Store queries

When working with a generative text model, it can be difficult to coerce the LLM to give consistent responses in a structured format such as JSON. Function calling makes it easy to work with LLMs via prompts and unstructured inputs, and have the LLM return a structured response that can be used to call an external function.

You can think of function calling as a way to get structured output from user prompts and function definitions, use that structured output to make an API request to an external system, then return the function response to the LLM to generate a response to the user. In other words, function calling in Gemini extracts structured parameters from unstructured text or messages from users. In this example, you'll use function calling along with the chat modality in the Gemini model to help customers get information about products in the Google Store.

1. In this task, run through the notebook cells to see how to use the Gemini model to help customers get information about products in the Google Store.

Click **Check my progress** to verify the objective.

Generate a simple function call

### Task 4. Using function calling to geocode addresses with a maps API

In this example, you'll use the text modality in the Gemini API to define a function that takes multiple parameters as inputs. You'll use the function call response to then make a live API call to convert an address to latitude and longitude coordinates.

1. In this task, run through the notebook cells to see how to use the Gemini Flash model to generate a function call to geocode an address.

Here we used the [OpenStreetMap Nominatim API](https://nominatim.openstreetmap.org/ui/search.html) to geocode an address to make it easy to use and learn in this notebook. If you're working with large amounts of maps or geolocation data, you can use the [Google Maps Geocoding API](https://developers.google.com/maps/documentation/geocoding).

Click **Check my progress** to verify the objective.

Generate a complex function call

### Task 5. Using function calling for entity extraction

In the previous examples, you made use of the entity extraction functionality within Gemini Function Calling so that you could pass the resulting parameters to a REST API or client library. However, you might want to only perform the entity extraction step with Gemini Function Calling and stop there without actually calling an API. You can think of this functionality as a convenient way to transform unstructured text data into structured fields.

In this example, you'll build a log extractor that takes raw log data and transforms it into structured data with details about error messages.

1. In this task, run through the notebook cells to see how to use the Gemini Flash model to generate function calls to extract entities from log data.

Click **Check my progress** to verify the objective.

Generate function calls from a chat prompt

## Verification

Complete all notebook tasks and successfully execute all cells to complete this lab successfully.

## Troubleshooting

Common issues and their solutions:

- **429 Response Error**: If you encounter API rate limiting, wait one minute before retrying
- **Notebook Not Loading**: Reset the Vertex AI Workbench instance
- **Permission Errors**: Ensure your service account has appropriate Vertex AI permissions
- **Function Call Failures**: Check that function definitions are correct and parameters match

## Cleanup

This lab uses managed Vertex AI Workbench services, and most resources are automatically cleaned up when the session ends. For manual cleanup:

1. Close all unused Jupyter notebooks
2. Delete any manually created test data
3. Stop the Vertex AI Workbench instance (if not ephemeral)

## Additional Resources

- [Gemini Overview](https://deepmind.google/technologies/gemini/)
- [Generative AI on Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [Generative AI on YouTube](https://www.youtube.com/@googlecloudtech/)
- Explore the Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) for a curated, searchable gallery of notebooks for Generative AI
- Explore other notebooks and samples in the [Google Cloud Generative AI repository](https://github.com/GoogleCloudPlatform/generative-ai)

## Congratulations!

Congratulations! In this lab, you learned how to use the Gemini API in Vertex AI to generate function calls from text prompts. You used the Gemini Flash model to generate function calls to help customers get information about products in the Google Store, geocode addresses, and extract entities from log data.

## Next steps / learn more

Check out the following resources to learn more about Gemini:

- [Gemini Overview](https://deepmind.google/technologies/gemini/)
- [Generative AI on Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [Generative AI on YouTube](https://www.youtube.com/@googlecloudtech/)
- Explore the Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) for a curated, searchable gallery of notebooks for Generative AI
- Explore other notebooks and samples in the [Google Cloud Generative AI repository](https://github.com/GoogleCloudPlatform/generative-ai)

---

**Original Lab Link**: https://www.skills.google/paths/1284/course_templates/981/labs/597908
**GSP Number**: GSP1227
**Completion Date**: 2025-11-05
**File Location**: intermediate/Explore-Generative-AI-with-the-Gemini-API-in-Vertex-AI/GSP1227-Introduction-to-Function-Calling-with-Gemini/
