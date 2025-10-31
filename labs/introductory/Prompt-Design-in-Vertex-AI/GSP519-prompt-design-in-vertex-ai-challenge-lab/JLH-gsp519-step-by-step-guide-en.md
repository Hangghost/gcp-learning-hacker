# GSP519 - Prompt Design in Vertex AI: Challenge Lab Complete Guide

## Challenge Lab Overview

This is a **Challenge Lab**, where you will not receive step-by-step instructions. Instead, you need to apply the skills learned from the course to complete the tasks on your own. An automated scoring system will provide feedback on whether you have completed your tasks correctly.

### Challenge Scenario
You are a member of an educational content startup specializing in engaging learners with the natural world. You've formed a partnership with Cymbal Direct, an online retailer launching a new line of outdoor gear and apparel designed to encourage young people to explore and connect with nature.

Your task is to help them develop a set of tools within Google Cloud's Vertex AI platform that will streamline the generation of the following:

- **Evocative Product Descriptions**: using image analysis to inspire short, descriptive text that captures the essence of their products and the feeling of being in nature.
- **Catchy Taglines**: focused on highlighting product features, the target audience, and the desired emotional response.

### Topics Tested
- Craft effective prompts and use parameters to guide generative AI output in Vertex AI Studio.
- Apply Gemini models to create product descriptions and taglines in a real-world marketing scenario.
- Examine and run Python code exported from Vertex AI Studio to gain a basic understanding of generative AI implementation.
- Use Jupyter Notebooks to test and modify generative AI code.

## Environment Setup

### Before Starting the Lab
1. Ensure you use an Incognito or private browser window
2. Use only the student account for this lab
3. Read all instructions as labs cannot be paused once started

### Required Environment Setup
- Standard internet browser (Chrome recommended)
- Vertex AI Workbench instance
- Vertex AI Studio access permissions

## Task 1: Build a Gemini Image Analysis Tool

### Objective
Create a template for analyzing images of Cymbal Direct products using the Gemini model in Vertex AI Studio. The goal is to generate descriptive text options inspired by the image, from simple details to more evocative, mood-setting phrases.

### Detailed Steps

1. **Open Vertex AI Studio**
   - In the Google Cloud Console, go to **Vertex AI > Studio**
   - Select the appropriate region (usually `us-central1`)

2. **Create a New Prompt**
   - Click **Create Prompt**
   - Choose **Gemini 1.5 Pro** or **Gemini 1.5 Flash** as the model
   - Name the prompt **Cymbal Product Analysis**

3. **Set Up Image Input**
   - In the prompt editor, click **Add Media**
   - Choose **Image** and enter the image URL:
     ```
     gs://cloud-samples-data/generative-ai/image/gardening-tools.jpeg
     ```
     or other provided Cymbal Direct product images

4. **Write the Analysis Prompt**
   ```
   Analyze this product image and generate multiple descriptive text options inspired by the image.

   Generate three types of descriptions:
   1. Short, factual descriptions (under 10 words)
   2. Catchy advertising phrases (10-20 words)
   3. Poetic nature-focused descriptions (20-30 words)

   Focus on:
   - Colors and textures
   - The feeling of being outdoors
   - Connection with nature
   - Target audience (young adventurers)
   ```

5. **Configure Parameters**
   - Temperature: 0.7 (balance creativity and consistency)
   - Top-P: 0.8
   - Top-K: 40
   - Max output tokens: 256

6. **Test and Iterate**
   - Click **Generate** to test the prompt
   - Adjust the prompt text based on results
   - Try different parameter settings
   - Ensure output covers all three types of descriptions

7. **Save the Prompt**
   - Click **Save**
   - Confirm the name is **Cymbal Product Analysis**
   - Select the appropriate region

### Verification Steps
- Ensure the prompt generates three different styles of descriptions
- Confirm output is relevant to outdoor gear theme
- Verify the prompt is saved correctly

## Task 2: Build a Gemini Tagline Generator

### Objective
Create a customizable tagline generator using the Gemini model in Vertex AI Studio. The goal is to develop a prompt that allows for customization of the tagline style, based on product attributes, target audience, and emotional resonance.

### Detailed Steps

1. **Create a New Prompt**
   - Click **Create Prompt** in Vertex AI Studio
   - Choose the same Gemini model
   - Name the prompt **Cymbal Tagline Generator Template**

2. **Set System Instructions**
   ```
   Cymbal Direct is partnering with an outdoor gear retailer. They're launching a new line of products designed to encourage young people to explore the outdoors. Help them create catchy taglines for this product line.
   ```

3. **Add Examples**
   Click **Add Example** and enter the following examples:

   **Example 1:**
   - Input: `Write a tagline for a durable backpack designed for hikers that makes them feel prepared. Consider styles like minimalist.`
   - Output: `Built for the Journey: Your Adventure Essentials.`

   **Example 2:**
   - Input: `Create a tagline for lightweight hiking boots that emphasize freedom and exploration for young adventurers.`
   - Output: `Step into Freedom: Explore Beyond Limits.`

4. **Write the Main Prompt**
   ```
   Generate a catchy tagline for a {product_type} designed for {target_audience}.

   Product attributes: {attributes}
   Desired emotional response: {emotion}
   Style preferences: {style}

   Make it memorable, under 8 words, and inspiring.
   ```

5. **Configure Parameters**
   - Temperature: 0.8 (higher creativity)
   - Top-P: 0.9
   - Top-K: 40
   - Max output tokens: 50

6. **Test Different Combinations**
   Try the following parameter combinations:

   | Product Type | Target Audience | Attributes | Emotion | Style |
   |-------------|----------------|------------|---------|-------|
   | backpack | young hikers | durable, waterproof | empowered | adventurous |
   | jacket | outdoor enthusiasts | lightweight, warm | connected | minimalist |
   | boots | nature explorers | comfortable, rugged | free | poetic |

7. **Iterate and Optimize**
   - Adjust prompt text based on outputs
   - Add more examples to improve consistency
   - Test edge cases

8. **Save the Prompt**
   - Confirm the name is **Cymbal Tagline Generator Template**
   - Select the appropriate region

### Verification Steps
- Ensure taglines are concise (less than 8 words)
- Confirm taglines are relevant to outdoor themes
- Verify different parameter combinations produce different results

## Task 3: Experiment with Image Analysis Code

### Objective
Explore the Python code for the image analysis prompt you created, then modify the prompt to be more specific and test the new prompt in a notebook.

### Detailed Steps

1. **Open Vertex AI Workbench**
   - In the Google Cloud Console, go to **Vertex AI > Workbench**
   - Find your Workbench instance and click **Open JupyterLab**

2. **Open the Notebook**
   - In JupyterLab, open `image-analysis.ipynb`
   - Set the kernel to **Python 3**
   - Run all cells to ensure the environment is set up correctly

3. **Export Code from Vertex AI Studio**
   - Go back to the **Cymbal Product Analysis** prompt
   - Click **Code** on the right side
   - Choose **Python** as the language
   - Copy the **second code cell** (containing the prompt)

4. **Paste Code into Notebook**
   - Paste the code in the specified cell in the notebook
   - Replace the API key authentication block with the version that uses PROJECT_ID and LOCATION:
   ```python
   import vertexai
   from vertexai.generative_models import GenerativeModel

   # Initialize Vertex AI
   vertexai.init(project="your-project-id", location="us-central1")

   model = GenerativeModel("gemini-1.5-pro")
   ```

5. **Modify the Prompt**
   - Find the prompt text between triple quotes
   - Change it to:
   ```
   Describe this image in less than 10 words, focusing on the most creative and unusual aspects.
   ```
   - Adjust parameters to increase creativity:
   ```python
   response = model.generate_content(
       [image, prompt],
       generation_config=genai.types.GenerationConfig(
           temperature=1.0,  # Increase creativity
           top_p=0.9,
           top_k=40,
           max_output_tokens=50,
       ),
   )
   ```

6. **Test the Modified Code**
   - Save the notebook
   - Re-run the code cell
   - Verify the new descriptions are shorter (less than 10 words) and more creative

### Verification Steps
- Confirm output is under 10 words
- Check if descriptions have creative and unusual characteristics
- Ensure code executes without errors

## Task 4: Experiment with Tagline Generation Code

### Objective
Explore the Python code for the tagline prompt you created, then modify the prompt to include a specific keyword and test the new prompt in a notebook.

### Detailed Steps

1. **Open the Tagline Generator Notebook**
   - Open `tagline-generator.ipynb` in Workbench
   - Set the kernel to **Python 3**

2. **Export Code from Vertex AI Studio**
   - Go back to the **Cymbal Tagline Generator Template** prompt
   - Click **Code** and choose **Python**
   - Copy the second code cell

3. **Paste and Modify Authentication**
   - Paste the code in the specified cell in the notebook
   - Replace with PROJECT_ID and LOCATION authentication

4. **Modify the Prompt**
   - Find the last input
   - Modify it to:
   ```
   Write a tagline for a durable backpack designed for hikers that makes them feel prepared. Consider styles like minimalist. Make sure to include the keyword "nature".
   ```

5. **Test the Modified Code**
   - Save the notebook
   - Re-run the code cell
   - Verify the new tagline includes the keyword "nature"

### Verification Steps
- Confirm the tagline includes the keyword "nature"
- Ensure code executes successfully
- Check the overall quality and relevance of the tagline

## Common Issues and Troubleshooting

### Vertex AI Studio Issues
- **Cannot Access Studio**: Ensure your account has Vertex AI API access permissions
- **Model Not Available**: Check if your region supports the selected model
- **Prompt Not Saved**: Confirm the name is correct and region is selected

### Notebook Issues
- **Kernel Error**: Restart the kernel and re-run setup cells
- **Import Errors**: Ensure all necessary libraries are installed
- **Authentication Errors**: Confirm PROJECT_ID and LOCATION are set correctly

### Code Execution Issues
- **API Errors**: Check quotas and permissions
- **Output Format Errors**: Adjust prompt text and parameters
- **Image Loading Errors**: Confirm image URL is correct and accessible

## Scoring Verification

### Automated Scoring Checkpoints
- **Task 1**: Check that **Cymbal Product Analysis** prompt exists and is configured correctly
- **Task 2**: Check that **Cymbal Tagline Generator Template** prompt exists
- **Task 3**: Check that image analysis notebook has been modified and saved
- **Task 4**: Check that tagline generator notebook includes the "nature" keyword

### Manual Verification Steps
1. Test that all prompts generate expected outputs
2. Confirm notebook code executes without errors
3. Verify all files are saved correctly

## Cleanup

This lab primarily uses Vertex AI Studio and notebooks, so no special cleanup steps are required. However, if you created any test resources:

1. Delete any test Cloud Storage files (if any)
2. Shut down unnecessary Workbench instances
3. Clear any temporary prompt versions

## Related Resources

- [Vertex AI Studio Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/studio)
- [Gemini API Guide](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- [Prompt Design Best Practices](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/prompts)
- [Vertex AI Workbench](https://cloud.google.com/vertex-ai/docs/workbench/introduction)

## Tips and Tricks

### Effective Prompt Design
- **Specificity**: Provide clear, specific instructions
- **Examples**: Use 2-3 examples to guide style
- **Parameter Tuning**: Temperature controls creativity, Top-P/Top-K control diversity
- **Iteration**: Test, evaluate, adjust, repeat

### Vertex AI Studio Usage Tips
- **Save Frequently**: Use the autosave functionality
- **Version Control**: Keep versions of successful prompts
- **Test Iterations**: Thoroughly test before final save

### Notebook Best Practices
- **Save Regularly**: Avoid losing work
- **Error Checking**: Check code syntax before execution
- **Output Validation**: Ensure results meet expectations

Remember: Challenge Labs are designed to test your problem-solving abilities and application of skills learned from the course. Carefully read each task's requirements and apply the concepts you learned in the Prompt Design in Vertex AI course!
