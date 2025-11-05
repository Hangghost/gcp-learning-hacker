# GSP1330 - Unit Testing with Gemini

## Overview

Gemini is an AI-powered collaborator helping development teams build, deploy, and operate applications faster and more efficiently.

In this lab, you will learn how Gemini for developers can assist in debugging your code and generate unit tests such as when testing for boundary conditions within your code.

The labs in this course covers a typical software development life cycle (SDLC) from the application developers point of view. Other aspects of the SDLC (requirements, security, monitoring, etc.) will be covered in other courses.

## Objectives

This lab focuses on to utilize Gemini for Developers in the following ways:

- Identify and resolve runtime errors with the assistance of Gemini for Developers.

- To generate unit tests for functions.

## What you'll learn

Cymbal Superstore is a thriving online shopping platform seeking continuous improvements to stay competitive in the market. As part of the ongoing development efforts, a new feature named 'New Products' is designed, allowing users to easily discover the latest additions to the store's inventory.

The new endpoint, `newproducts` has been deployed to staging, but isn't quite what the business owner wants. You need to make some modifications and debug the new code. To keep the lab focused on how Gemini for Developers can assist you, the new code will be added to the original code base. You will also be asked to develop some unit tests of the backend services.

## Task 1. Investigate, generate and test the code

### Set environment variables

1. In Cloud Shell, run the following command to set the necessary environment variables.

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=Lab Region
export ZONE=Lab Zone
```

2. Copy necessary files to Cloud Shell from Cloud Storage bucket.

```bash
gsutil -m cp -r gs://duet-appdev/cymbal-superstore .
```

### Investigate the code

Along with Gemini's ability to explain code segments you are not familiar with, it can also create comments for you to add to your code to increase understanding during future maintenance cycles.

1. Open the editor by clicking the **Open Editor** option visible at the top right of the Cloud Shell window.

2. Click on **Menu** on the left, and navigate to **File** > **Open Folder...**.

3. Select the **cymbal-superstore** directory, and click **OK**.

4. Open **index.ts** file under the `backend` folder.

5. At the top right of the file, click the arrow next to **Gemini**.

6. Click on **Select Gemini Code Assist Project**, to select the project to use for Gemini. From the list, select `Google Cloud` Project ID.

7. If any prompt appears at the bottom of the editor that Gemini Code Assist is not enabled for the selected project, then click **Enable API** button in the prompt to enable the API.

### Generate the code

1. In the **index.ts** file, scroll to the line `102` where you see the following text: `/newproducts endpoint code goes here`. Replace this line with the comment shown below.

```typescript
// Create a GET route for /newproducts that returns products that were added in the last 7 days and are in stock
// The products should be retrieved from Firestore collection "inventory"
// Return the products as JSON array
```

2. Select the newly added comment, and click on the yellow light bulb icon that appears. From the list, click on the following option: `Gemini: Generate code`.

3. Gemini displays some suggested code. Look at the suggested code and accept it by clicking **Accept** or pressing **Tab** key.

**Note:**

1. Gemini knew the meaning of 'are in stock'. That is a fairly understood phrase with a common meaning, so Gemini used that here. If your requirement was less common, an example might be needed.

2. The use of a data property named quantity allowed Gemini to associate that with the concept of 'in stock'. If you name your variable, properties, and methods with shorthand, abbreviations, or other non-standard wording, not only will your code be less maintainable by others, but Gemini will be less specific with its suggestions.

3. Even though not stated, Gemini suggested code with the database running check to be consistent with other endpoints in the file.

### Test the code

1. Switch back to the Cloud Shell terminal using the **Open Terminal** button present on the tool bar of the Cloud Shell window. In the Cloud Shell terminal, run the following command.

```bash
cd ~/cymbal-superstore/backend
npm run start
```

**Your output will look similar to this:**

2. Open another terminal in Cloud Shell by clicking on the **+** option on the tool bar of the Cloud Shell window, and call the endpoint on localhost.

```bash
curl localhost:8000/newproducts
```

and see the output in the 1st terminal, that is cancelled and there was an error.

**Your output will look similar to this:**

## Task 2. Investigate with the Gemini Chat

1. Open the **index.ts** file in the editor.

2. Open `Gemini Chat` as shown in the screenshot and enter the given error message in the prompt.

```
Error: 3 INVALID_ARGUMENT: Inequality filter property and first sort order must be the same: timestamp and __name__ (or add index)
```

**Your output will look similar to this:**

**Note:** Every time Gemini runs, it produces a different result, therefore the results you see could not match your response.

3. Examine the code to resolve the existing issue. The below command is what you determine to be the error's origin:

```typescript
const query = firestore
const products = await firestore
  .collection("inventory")
  .where("timestamp", ">", new Date(Date.now() - 604800000))
  .where("quantity", ">", 0);
  .where("timestamp", ">=", sevenDaysAgo)
  .where("quantity", ">", 0)
  .get();
```

Gemini's response gives you the option to either modify the filters to become equality filters or to delete one of the inequality filters.

First, let's remove the quantity filter from the Firestore call to resolve the error.

4. To remove the quantity inequality filter, remove the following code fragment from the **index.ts** file.

```typescript
.where("quantity", ">", 0);
```

This code can be removed to make the function operate error-free. Products with a quantity of `0` won't be able to filter out of the API response, which means they won't meet the business requirement and will fail. We must take care to avoid inserting out-of-stock items. There are several appropriate approaches to this. Some might work better than others. Therefore, we would request help from `Gemini`.

5. Ask the question below in the Gemini Chat, and make sure the **index.ts** file is open.

```
How can I filter out products with quantity 0 from the results after retrieving from Firestore, without using a Firestore where clause?
```

**Your output will look similar to this:**

Even after resetting the chat, if Gemini repeatedly suggests you to add two where clauses, here is a technique to get a different answer.

```
What are some ways to filter an array of products in JavaScript to only include items with quantity > 0?
```

Often Gemini will offer an alternative that you can try. You might have to reset the chat and modify your prompt a few times to get a non-firestore option.

**Note:** Gemini sometimes gets stubborn and offers only random (and illegal) firestore options. In this case, the learner will just have to move on with the suggestion offered.

**Your output will look similar to this:**

6. Modify the existing code by adding the code snippet in the **index.ts** file.

```typescript
if (p.quantity > 0) {
  productsArray.push(p);
}
```

After modifying, the code should look like this.

### Testing the code, with the above changes

1. Open the **Cloud Shell** terminal and paste the command below.

```bash
cd ~/cymbal-superstore/backend
npm run start
```

2. Open a second terminal tab and call the endpoint `localhost`.

```bash
curl localhost:8000/newproducts
```

**Your output will look similar to this:**

3. Let's try another way with an inline comment and remove the condition added above. The final code would be similar to this.

4. Before the **productsArray.push(p)** line, add the given comment below. Press **Ctrl+Enter**, to generate a code. Accept the code, if it returns `if (p.quantity > 0)`.

```typescript
// filter out products that are not in stock
```

Comment out the filter and it should look like this.

## Task 3. Running the Tests

1. Go to the **Cloud Shell** terminal and execute the command below.

```bash
cd cymbal-superstore/backend
npm run test
```

**Your output will look similar to this:**

2. Open the file **index.test.ts** under the backend folder. This file contains a few simple tests that are developed with a tool called `supertest`, using the Jest testing framework. Review the existing tests and ask Gemini to explain anything that is unclear.

## Task 4. Develop tests with the help of Gemini

In this task, you will write a test for the new products API in the backend with help from `Gemini`.

### Develop the test

1. Open the file **index.test.ts** under the backend folder. At the bottom of file add the below comments.

```typescript
// Create unit tests for the GET /newproducts endpoint
// Test that it returns a 200 status code
// Test that it returns an array of products
```

2. Select the newly added comment, and click on the yellow light bulb icon that appears. From the list, click on the following option: `Gemini: Generate code`. Hit `tab` to accept the suggestion.

This is an example of the generated code. You can also paste the code given below.

```typescript
describe('GET /newproducts', () => {
   it('should return a 200 status code', async () => {
       const response = await request(app)
           .get('/newproducts');
       expect(response.status).toBe(200);
   });

   it('should return a list of new products with length 8', async () => {
       const response = await request(app)
           .get('/newproducts');
       expect(response.body.length).toBe(8);
   });
});
```

### Run the test

1. Execute the below commands in **Cloud Shell** terminal.

```bash
cd ~/cymbal-superstore/backend
npm run test
```

**Your output will look similar to this:**

2. Investigate which test failed by scrolling the results in the terminal output.

**Note:** You should see this response indicating the test failed. The value 10 was the newproducts count including products with quantity 0. The new business requirements stated that items not in stock should be filtered, but the test reveals that something is wrong.

### Fix the bug

1. Open the **index.ts** under the backend folder and remove the comment for the filter that was added in the last task. The updated code should like this.

```typescript
//do not insert products that are out of stock
if (p.quantity > 0)
  productsArray.push(p);
```

2. Re-run the test from the **Cloud Shell** terminal.

```bash
cd ~/cymbal-superstore/backend
npm run test
```

**Your output will look similar to this:**

## Task 5. Boundary condition test

Boundary condition tests can be difficult. This difficulty stems from the need to consider unexpected situations, like empty lists or negative balances, that shouldn't occur but might arise during execution. In this context, let's see if Gemini can be of assistance.

1. To provide the most generic response, close all open files. Reset the Gemini Chat by clicking on the **New Chat** icon (+) above the chat, and enter the following prompt:

```
Can you help me create tests for boundary conditions for an API endpoint that returns products added in the last 7 days that are in stock?
```

**Your output will look similar to this:**

```
Yes, I can definitely help you create tests for boundary conditions!

Boundary value analysis is a crucial part of software testing.

It involves testing at the "edges" or "boundaries" of input domains.

These are often the places where errors lurk.



To help you best, I'd need a little more information. For example:



    - What programming language are you using?

    - Could you provide the code (or a snippet of it) that you'd like to test?

    - What are the inputs and their expected valid ranges?
```

2. Open the **index.ts** file under the `backend` folder to provide some background for Gemini. Ask Gemini about boundary tests for the `/newproducts` endpoint. Open the Gemini's Chat and enter:

```
What are some boundary conditions I should test for the /newproducts endpoint that returns products added in the last 7 days that are in stock?
```

**Your output will look similar to this:**

**Note:** Clearly some of these were generated based on the code itself (added in the last 7 days and are in stock) and more general boundary conditions that Gemini has found are typical for this type of code. This is very useful to get a start on creating a solid set of boundary conditions.

3. For turning into actual tests, open the **index.test.ts** file. Copy the below comment and add it at the end of the file.

```typescript
// Create boundary condition tests for the /newproducts endpoint
// Test that products with quantity 0 are not returned
// Test that products older than 7 days are not returned
```

**Your output will look similar to this:**

4. Add the code below after the above comment in **index.test.ts** file.

```typescript
describe('GET /newproducts', () => {
   it('should not return products that are out of stock', async () => {
       const response = await request(app)
           .get('/newproducts');
       response.body.forEach((product: any) => {
           expect(product.quantity).toBeGreaterThan(0);
       });
   });
});
```

5. Re-run the test in the **Cloud Shell** terminal. You should see the output as below.

**Your output will look similar to this:**

## Congratulations!

You have successfully implemented code generation, debugging, and unit testing with Gemini for Developers.

## Related Resources

- [Gemini for Developers Documentation](https://cloud.google.com/gemini/docs)
- [Jest Testing Framework](https://jestjs.io/)
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [Unit Testing Best Practices](https://martinfowler.com/bliki/UnitTest.html)

## Troubleshooting

### Common Issues

1. **Gemini Unable to Generate Code**
   - Ensure IAM roles are set correctly
   - Check Cloud AI Companion API is enabled
   - Verify comment format is correct

2. **Firestore Query Errors**
   - Firestore does not support multiple inequality filters
   - Use application logic for post-filtering
   - Consider creating composite indexes

3. **Test Failures**
   - Check test data in database
   - Verify endpoint logic is correct
   - Check response format

4. **Boundary Condition Tests**
   - Consider empty results
   - Test extreme values
   - Check error handling

## Next Steps

After completing this lab, you can:

- Explore more Gemini debugging features
- Learn advanced testing techniques
- Implement continuous integration pipelines
- Study test-driven development (TDD)
