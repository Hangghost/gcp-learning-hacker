# GSP1231 - Multimodal Retrieval Augmented Generation (RAG) using the Gemini API in Vertex AI

## Lab Overview
Gemini is a family of generative AI models developed by Google DeepMind that is designed for multimodal use cases.

Retrieval augmented generation (RAG) has become a popular paradigm for enabling LLMs to access external data and also as a mechanism for grounding to mitigate against hallucinations. RAG models are trained to retrieve relevant documents from a large corpus and then generate a response based on the retrieved documents. In this lab, you learn how to perform multimodal RAG where you perform Q&A over a financial document filled with both text and images.

## Comparing text-based and multimodal RAG

Multimodal RAG offers several advantages over text-based RAG:

1. **Enhanced knowledge access**: Multimodal RAG can access and process both textual and visual information, providing a richer and more comprehensive knowledge base for the LLM.

2. **Improved reasoning capabilities**: By incorporating visual cues, multimodal RAG can make better informed inferences across different types of data modalities.

This lab shows you how to use RAG with the Gemini API in Vertex AI, text embeddings, and multimodal embeddings, to build a document search engine.

## Prerequisites
Before starting this lab, you should be familiar with:

- Basic Python programming
- General API concepts
- Running Python code in a Jupyter notebook on Vertex AI Workbench

## Objectives
In this lab, you learn how to:

- Extract and store metadata of documents containing both text and images, and generate embeddings the documents
- Search the metadata with text queries to find similar text or images
- Search the metadata with image queries to find similar images
- Using a text query as input, search for contextual answers using both text and images

## Estimated Time
90 minutes

## Lab Steps

### Step 1: Open the notebook in Vertex AI Workbench

1. In the Google Cloud console, on the Navigation menu (), click Vertex AI > Workbench.

    [Navigation menu icon](https://cdn.qwiklabs.com/tkgw1TDgj4Q%2BYKQUW4jUFd0O5OEKlUMBRYbhlCrF0WY%3D)

2. Find the `Workbench instance name` instance and click on the Open JupyterLab button.

The JupyterLab interface for your Workbench instance opens in a new browser tab.

**Note:** If you do not see notebooks in JupyterLab, please follow these additional steps to reset the instance:

1. Close the browser tab for JupyterLab, and return to the Workbench home page.

2. Select the checkbox next to the instance name, and click Reset.

3. After the Open JupyterLab button is enabled again, wait one minute, and then click Open JupyterLab.

### Step 2: Set up the notebook

1. Open the `notebook name` file.

2. In the Select Kernel dialog, choose Python 3 from the list of available kernels.

3. Run through the Getting Started section of the notebook. The Project ID and Location are pre-configured for you.

**Note:** If you experience a 429 response from any of the notebook cell executions, wait one minute before running the cell again to proceed.

Click Check my progress to verify the objective.

Install the Gen AI SDK for Python and import libraries

In the following sections, you run through the notebook cells to see how to use the Gemini API to build a multimodal RAG system.

### Step 3: Download custom Python utilities & required files

In this section, you download some helper functions to improve the notebook's readability. These functions use the `model name` (`model id`) model, which is designed for natural language tasks, multiturn text and code chat, and code generation. You can also view the code (`intro_multimodal_rag_utils.py`) directly on GitHub.

1. In this task, run through the notebook cells to load the model and download the helper functions and get the documents and images from Cloud Storage.

Click Check my progress to verify the objective.

Download images and documents from Cloud Storage

### Step 4: Build metadata of documents containing text and images

The source data that you use in this lab is a modified version of Google-10K which provides a comprehensive overview of the company's financial performance, business operations, management, and risk factors. As the original document is rather large, you will be using a modified version with only 14 pages, split into two parts - Part 1 and Part 2 instead. Although it's truncated, the sample document still contains text along with images such as tables, charts, and graphs.

1. In this task, run through the notebook cells to extract and store metadata of text and images from a document.

**Note:** The cell to extract and store metadata of text and images from a document may take a few minutes to complete.

Click Check my progress to verify the objective.

Extract and store metadata of text and images from a document

### Step 5: Text Search

Let's start the search with a simple question and see if the simple text search using text embeddings can answer it. The expected answer is to show the value of basic and diluted net income per share of Google for different share types.

1. In this task, run through the notebook cells to search for similar text and images with a text query.

Click Check my progress to verify the objective.

Text Search

### Step 6: Image Search

Imagine searching for images, but instead of typing words, you use an actual image as the clue. You have a table with numbers about the cost of revenue for two years, and you want to find other images that look like it, from the same document or across multiple documents.

The ability to identify similar text and images based on user input, powered with Gemini and embeddings, forms a crucial foundation for the development of multimodal RAG systems, which explore in the next task.

1. In this task, run through the notebook cells to search for similar images with an image query.

**Note:** You may need to wait for a couple of minutes to get the score for this task.

Click Check my progress to verify the objective.

Image Search

### Comparative Reasoning

Imagine we have a graph showing how Class A Google shares did compared to other things like the S&P 500 or other tech companies. You want to know how Class C shares did compared to that graph. Instead of just finding another similar image, you can ask Gemini to compare the relevant images and tell you which stock might be better for you to invest in. Gemini would then explain why it thinks that way.

1. In this task, run through the notebook cells to compare two images and find the most similar image.

Click Check my progress to verify the objective.

Comparative Reasoning

### Step 7: Multimodal retrieval augmented generation (RAG)

Let's bring everything together to implement multimodal RAG. You use all the elements that you've explored in previous sections to implement the multimodal RAG. These are the steps:

- **Step 1:** The user gives a query in text format where the expected information is available in the document and is embedded in images and text.

- **Step 2:** Find all text chunks from the pages in the documents using a method similar to the one you explored in `Text Search`.

- **Step 3:** Find all similar images from the pages based on the user query matched with `image_description` using a method identical to the one you explored in `Image Search`.

- **Step 4:** Combine all similar text and images found in steps 2 and 3 as `context_text` and `context_images`.

- **Step 5:** With the help of Gemini, we can pass the user query with text and image context found in steps 2 & 3. You can also add a specific instruction the model should remember while answering the user query.

- **Step 6:** Gemini produces the answer, and you can print the citations to check all relevant text and images used to address the query.

1. In this task, run through the notebook cells to perform multimodal RAG.

**Note:** You may need to wait for a couple of minutes to get the score for this task.

Click Check my progress to verify the objective.

Print the citations to check all relevant text and images

## Verification
Complete all notebook tasks and successfully run all cells.

## Troubleshooting
- **429 Error**: If you encounter API rate limits, wait one minute and retry
- **Kernel Issues**: If JupyterLab has problems, reset the Workbench instance
- **Permission Errors**: Ensure you have appropriate permissions for Vertex AI APIs
- **Memory Issues**: RAG processing may require significant memory, ensure instance has adequate resources

## Cleanup
1. Close JupyterLab tabs
2. Stop Workbench instance if needed to avoid charges
3. Delete any temporary Cloud Storage buckets created

## Additional Resources
- [Gemini Overview](https://deepmind.google/technologies/gemini/)
- [Text Embeddings Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/text-embeddings)
- [Multimodal Embeddings Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/multimodal-embeddings)
- [Google-10K Sample Document Part 1](https://storage.googleapis.com/github-repo/rag/intro_multimodal_rag/intro_multimodal_rag_old_version/data/google-10k-sample-part1.pdf)
- [Google-10K Sample Document Part 2](https://storage.googleapis.com/github-repo/rag/intro_multimodal_rag/intro_multimodal_rag_old_version/data/google-10k-sample-part2.pdf)
- [Multimodal RAG Utils GitHub](https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/main/gemini/use-cases/retrieval-augmented-generation/utils/intro_multimodal_rag_utils.py)
- [Generative AI on Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [Generative AI on YouTube](https://www.youtube.com/@googlecloudtech/)
- Explore the Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) for a curated, searchable gallery of notebooks for Generative AI
- Explore other notebooks and samples in the Google Cloud Generative AI repository (https://github.com/GoogleCloudPlatform/generative-ai)

## Notes
This lab demonstrates how to build a multimodal RAG system using the Gemini API. Key concepts include:
- Text and image metadata extraction
- Embedding generation and similarity search
- Multimodal context integration
- Enhanced Q&A using Gemini with retrieved context

RAG systems significantly improve LLM accuracy and reliability by integrating external knowledge.
