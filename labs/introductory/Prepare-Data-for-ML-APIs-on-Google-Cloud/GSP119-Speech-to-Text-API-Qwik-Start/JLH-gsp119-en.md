# GSP119 - Speech-to-Text API: Qwik Start

## Lab Overview

The Speech-to-Text API enables easy integration of Google speech recognition technologies into developer applications. The Speech-to-Text API allows you to send audio and receive a text transcription from the service.

## Learning Objectives

In this lab, you learn how to:

- Create an API key
- Create a Speech-to-Text API request
- Call the Speech-to-Text API

## Estimated Time

30 minutes

## Prerequisites

- Google Cloud Platform account
- Basic command line knowledge
- Familiarity with curl commands

## Lab Steps

### Step 1: Create an API Key

Since you'll be using `curl` to send a request to the Speech-to-Text API, you need to generate an API key to pass in our request URL.

1. To create an API key, click **Navigation menu** > **APIs & services** > **Credentials**.
2. Then click **Create credentials**.
3. In the drop down menu, select **API key**.
4. Copy the key you just generated and click **Close**.

**Expected Result:**
- Successfully created API key

### Step 2: Connect to Linux Instance and Set Environment Variable

Now that you have an API key, save it as an environment variable to avoid having to insert the value of your API key in each request.

1. In the **Navigation menu**, select **Compute Engine**. You should see a `linux-instance` listed in the **VM instances** window.
2. Click on the **SSH** button in line with the `linux-instance`. You will be brought to an interactive shell.
3. In the command line, enter in the following, replacing `<YOUR_API_KEY>` with the API key you copied from previously generated:

```bash
export API_KEY=<YOUR_API_KEY>
```

**Expected Result:**
- Successfully connected via SSH and set API_KEY environment variable

### Step 3: Create your Speech-to-Text API Request

**Note:** You will use a pre-recorded file that's available on Cloud Storage: `gs://cloud-samples-tests/speech/brooklyn.flac`. [Listen to the audio file before sending it to the Speech-to-Text API](https://storage.cloud.google.com/cloud-samples-tests/speech/brooklyn.flac).

1. Create `request.json` in the SSH command line:

```bash
touch request.json
```

2. Open the `request.json` with nano:

```bash
nano request.json
```

**Note:** You can use your preferred command line editor (`nano`, `vim`, `emacs`) or `gcloud`. This lab will provide instructions for `nano`.

3. Add the following to your `request.json` file, using the `uri` value of the sample raw audio file:

```json
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-samples-tests/speech/brooklyn.flac"
  }
}
```

4. Press `control` + `x` and then `y` to save and click `Enter` to close the `request.json` file.

The request body has a `config` and `audio` object.

In `config`, you tell the Speech-to-Text API how to process the request. The `encoding` parameter tells the API which type of audio encoding you're using while the file is being sent to the API. `FLAC` is the encoding type for .raw files. Learn more about encoding types in the [RecognitionConfig Guide](https://cloud.google.com/speech/reference/rest/v1/RecognitionConfig).

There are other parameters you can add to your `config` object, but `encoding` is the only required one.

In the `audio` object, you pass the API the uri of the audio file in Cloud Storage.

**Expected Result:**
- Successfully created request.json file with correct JSON configuration

### Step 4: Call the Speech-to-Text API

1. Pass your request body, along with the API key environment variable, to the Speech-to-Text API with the following `curl` command (all in one single command line):

```bash
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}"
```

Your response should look something like this:

```json
{
  "results": [
    {
      "alternatives": [
        {
          "transcript": "how old is the Brooklyn Bridge",
          "confidence": 0.98267895
        }
      ]
    }
  ]
}
```

The `transcript` value will return the Speech-to-Text API's text transcription of your audio file, and the `confidence` value indicates how sure the API is that it has accurately transcribed your audio.

You'll notice that you called the `syncrecognize` method in the request above. The Speech-to-Text API supports both synchronous and asynchronous speech to text transcription. In this example you sent it a complete audio file, but you can also use the `syncrecognize` method to perform streaming speech to text transcription while the user is still speaking.

2. Run the following command to save the response in a `result.json` file:

```bash
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json
```

**Expected Result:**
- Successfully called the API and received JSON response with transcript text
- result.json file contains the API response

## Verification

To verify that the lab was completed successfully:

1. Check that the API response contains transcript text
2. Verify that the confidence value is in a reasonable range (typically > 0.8)
3. Confirm that result.json file was created and contains proper JSON structure

## Troubleshooting

Common issues and their solutions:

- **Invalid API key error**: Ensure the API_KEY environment variable is set correctly and the key is valid
- **Permission error**: Ensure the Speech-to-Text API is enabled and the key has appropriate permissions
- **File not found error**: Verify that request.json file exists and JSON syntax is correct
- **Network error**: Check network connectivity and retry the request

## Cleanup

No special cleanup is required for this lab as it only used API calls without creating persistent resources.

## Additional Resources

- [Speech-to-Text API Official Documentation](https://cloud.google.com/speech-to-text/docs)
- [Speech-to-Text API Reference](https://cloud.google.com/speech/reference/rest/v1/RecognitionConfig)
- [Google Cloud Speech-to-Text Tutorials](https://cloud.google.com/speech-to-text/docs/tutorials)
- [Speech Recognition Best Practices](https://cloud.google.com/speech-to-text/docs/best-practices)
- Related labs:
  - GSP097: Cloud Natural Language API: Qwik Start
  - Other AI/ML API related labs

## Notes

- Speech-to-Text API supports multiple audio formats and languages
- Can handle both synchronous and streaming speech transcription
- API keys should be stored securely, never hard-coded in source code
- For production environments, service account authentication is recommended over API keys
