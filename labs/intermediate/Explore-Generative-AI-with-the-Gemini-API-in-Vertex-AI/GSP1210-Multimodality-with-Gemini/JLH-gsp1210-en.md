# GSP1210 - Multimodality with Gemini

## Lab Overview

This lab introduces you to [Gemini](https://deepmind.google/technologies/gemini/#introduction), a family of multimodal generative AI models developed by Google. You use the Gemini API to explore how Gemini Flash can understand and generate responses based on text, images, and video.

Gemini's multimodal capabilities enable it to:

- **Analyze images:** Detect objects, understand user interfaces, interpret diagrams, and compare visual similarities and differences.
- **Process videos:** Generate descriptions, extract tags and highlights, and answer questions about video content.

You experiment with these features through hands-on tasks using the Gemini API in Vertex AI.

## Prerequisites

Before starting this lab, you should be familiar with:

- Basic Python programming.
- General API concepts.
- Running Python code in a Jupyter notebook on Vertex AI Workbench.

## Objectives

In this lab, you:

- Interact with the Gemini API in Vertex AI.
- Use the Gemini Flash model to analyze images and videos.
- Provide Gemini with text, image, and video prompts to generate informative responses.
- Explore practical applications of Gemini's multimodal capabilities.

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
3. Run through the **Getting Started** section of the notebook. The Project ID and Location are pre-configured for you.

**Note:** If you experience a 429 response from any of the notebook cell executions, wait one minute before running the cell again to proceed.

### Task 3. Use the Gemini Flash model

Gemini Flash is a multimodal model that supports multimodal prompts. You can include text, image(s), and video in your prompt requests and get text or code responses.

In this task, run through the specified notebook cells to see how to use the Gemini Flash model. Return here to check your progress as you complete the objectives.

#### Image understanding across multiple images

One of the Gemini's capabilities is being able to reason across multiple images. In this example, you use Gemini to calculate the total cost of groceries using an image of fruits and a price list.

Run through the **Image understanding across multiple images** section of the notebook.

Click **Check my progress** to verify the objective.

Image understanding across multiple images

#### Generating a video description

Gemini can also extract tags throughout a video and retrieve extra information beyond the video contents. In this example, you use Gemini to extract tags and retrieve extra information from different videos:

Run through the **Generating a video description** section of the notebook.

Click **Check my progress** to verify the objective.

Generating a video description

#### Audio understanding

Gemini can directly process audio for long-context understanding. In this example, you use Gemini to process audio for long-context understanding:

Run through the **Audio understanding** section of the notebook.

Click **Check my progress** to verify the objective.

Audio understanding

#### Reason across a codebase

Gemini can directly process audio for long-context understanding. In this example, you use Gemini to process audio for long-context understanding:

Run through the **Reason across a codebase** section of the notebook.

Click **Check my progress** to verify the objective.

Reason across a codebase

#### Video and audio understanding

In this example, you try out Gemini's native multimodal and long-context capabilities on video interleaving with audio inputs.:

Run through the **Video and audio understanding** section of the notebook.

Click **Check my progress** to verify the objective.

Video and audio understanding

#### All modalities (images, video, audio, text) at once

Gemini is natively multimodal and supports interleaving of data from different modalities. In this example, you try a mix of audio, visual, text, and code inputs in the same input sequence.

Run through the **All modalities (images, video, audio, text) at once** section of the notebook.

Click **Check my progress** to verify the objective.

All modalities (images, video, audio, text) at once

#### Generating recommendations based on provided images

Gemini is capable of image comparison and providing recommendations. This is particularly useful for retail companies who want to provide users product recommendations based on their current setup.

Run through the **Generating recommendations based on provided images** section of the notebook.

Click **Check my progress** to verify the objective.

Generating recommendations based on provided images

#### Understand entity relationships in technical diagrams

Gemini has multimodal capabilities that enable it to understand diagrams and take actionable steps, such as optimization or code generation. In this example, you see how Gemini can decipher an entity relationship (ER) diagram, understand the relationships between tables, identify requirements for optimization in a specific environment like BigQuery, and even generate corresponding code.

Run through the **Understand entity relationships in technical diagrams** section of the notebook.

Click **Check my progress** to verify the objective.

Understand entity relationships in technical diagrams

#### Compare images for similarities and differences

Gemini can compare images and identify similarities or differences between objects. In this example, you use Gemini to compare two images of the same location and identify the differences between them.

Run through the **Compare images for similarities and differences** section of the notebook.

Click **Check my progress** to verify the objective.

Compare images for similarities and differences

## Verification

Complete all notebook tasks and successfully execute all cells to complete this lab successfully.

## Troubleshooting

Common issues and their solutions:

- **429 Response Error**: If you encounter API rate limiting, wait one minute before retrying
- **Notebook Not Loading**: Reset the Vertex AI Workbench instance
- **Permission Errors**: Ensure your service account has appropriate Vertex AI permissions
- **Out of Memory**: Reduce batch size or use smaller models

## Cleanup

This lab uses managed Vertex AI Workbench services, and most resources are automatically cleaned up when the session ends. For manual cleanup:

1. Close all unused Jupyter notebooks
2. Delete any manually created Cloud Storage buckets (if any)
3. Stop the Vertex AI Workbench instance (if not ephemeral)

## Additional Resources

- [Gemini Overview](https://deepmind.google/technologies/gemini/)
- [Generative AI on Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [Generative AI on YouTube](https://www.youtube.com/@googlecloudtech/)
- Explore the Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) for a curated, searchable gallery of notebooks for Generative AI
- Explore other notebooks and samples in the [Google Cloud Generative AI repository](https://github.com/GoogleCloudPlatform/generative-ai)

## Congratulations!

You have now completed the lab! In this lab, you learned how to use the Gemini API in Vertex AI to generate text from text and image(s) prompts.

## Next steps / learn more

Check out the following resources to learn more about Gemini:

- [Gemini Overview](https://deepmind.google/technologies/gemini/)
- [Generative AI on Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [Generative AI on YouTube](https://www.youtube.com/@googlecloudtech/)
- Explore the Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) for a curated, searchable gallery of notebooks for Generative AI
- Explore other notebooks and samples in the [Google Cloud Generative AI repository](https://github.com/GoogleCloudPlatform/generative-ai)

---

**Original Lab Link**: https://www.skills.google/paths/1284/course_templates/981/labs/597908
**GSP Number**: GSP1210
**Completion Date**: 2025-11-05
**File Location**: intermediate/Explore-Generative-AI-with-the-Gemini-API-in-Vertex-AI/GSP1210-Multimodality-with-Gemini/
