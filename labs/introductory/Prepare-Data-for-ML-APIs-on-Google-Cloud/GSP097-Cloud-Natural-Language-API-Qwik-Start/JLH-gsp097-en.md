# GSP097 - Cloud Natural Language API: Qwik Start

## Lab Overview
Learn how to use the Google Cloud Natural Language API to extract entities from text. Natural language is the language humans use to communicate. Natural language processing (NLP) is a field of computer science concerned with the interaction between computers and human language. The Cloud Natural Language API is a cloud-based service that provides natural language processing capabilities for analyzing text, identifying entities, extracting information, and answering questions.

## Prerequisites
- Google Cloud Platform account
- Basic GCP console navigation knowledge
- Understanding of natural language processing concepts

## Learning Objectives
By the end of this lab, you will be able to:
- Create an API key for accessing the Natural Language API
- Use the Cloud Natural Language API to extract entities (people, places, events) from text snippets

## Estimated Time
30 minutes

## Lab Steps

### Step 1: Create an API Key

**Description:**
Set up environment variables and create a service account to access the Natural Language API.

**Instructions:**
1. Set the PROJECT_ID environment variable:
```bash
export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value core/project)
```

2. Create a new service account:
```bash
gcloud iam service-accounts create my-natlang-sa \
  --display-name "my natural language service account"
```

3. Create credentials for the service account and save as JSON file:
```bash
gcloud iam service-accounts keys create ~/key.json \
  --iam-account my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
```

4. Set the GOOGLE_APPLICATION_CREDENTIALS environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/home/USER/key.json"
```
**Note:** Replace `/home/USER/key.json` with the actual path to your key file.

**Expected Result:**
- Service account and key file created successfully
- Environment variables set correctly

### Step 2: Make an Entity Analysis Request

**Description:**
Use the Natural Language API to analyze text and extract entity information.

**Instructions:**
1. Connect to the provisioned Linux instance:
   - Open the navigation menu in GCP console
   - Select Compute Engine
   - Locate the provisioned Linux instance
   - Click the SSH button to connect

2. Run the Natural Language API entity analysis command:
```bash
gcloud ml language analyze-entities --content="Michelangelo Caravaggio, Italian painter, is known for 'The Calling of Saint Matthew'." > result.json
```

3. View the analysis results:
```bash
cat result.json
```

**Expected Result:**
You should see a JSON response similar to the following:

```json
{
  "entities": [
    {
      "name": "Michelangelo Caravaggio",
      "type": "PERSON",
      "metadata": {
        "wikipedia_url": "http://en.wikipedia.org/wiki/Caravaggio",
        "mid": "/m/020bg"
      },
      "salience": 0.83047235,
      "mentions": [
        {
          "text": {
            "content": "Michelangelo Caravaggio",
            "beginOffset": 0
          },
          "type": "PROPER"
        },
        {
          "text": {
            "content": "painter",
            "beginOffset": 33
          },
          "type": "COMMON"
        }
      ]
    },
    {
      "name": "Italian",
      "type": "LOCATION",
      "metadata": {
        "mid": "/m/03rjj",
        "wikipedia_url": "http://en.wikipedia.org/wiki/Italy"
      },
      "salience": 0.13870546,
      "mentions": [
        {
          "text": {
            "content": "Italian",
            "beginOffset": 25
          },
          "type": "PROPER"
        }
      ]
    },
    {
      "name": "The Calling of Saint Matthew",
      "type": "EVENT",
      "metadata": {
        "mid": "/m/085_p7",
        "wikipedia_url": "http://en.wikipedia.org/wiki/The_Calling_of_St_Matthew_(Caravaggio)"
      },
      "salience": 0.030822212,
      "mentions": [
        {
          "text": {
            "content": "The Calling of Saint Matthew",
            "beginOffset": 69
          },
          "type": "PROPER"
        }
      ]
    }
  ],
  "language": "en"
}
```

## Verification
- Successfully received JSON response with entity information
- Response includes entity names, types, metadata, and salience scores
- Able to identify persons (Michelangelo Caravaggio), locations (Italian), and events (The Calling of Saint Matthew)

## Troubleshooting
- **API Key Errors**: Ensure GOOGLE_APPLICATION_CREDENTIALS points to the correct key file path
- **Permission Issues**: Verify service account has access to Natural Language API
- **Command Failures**: Check project ID is set correctly and Natural Language API is enabled

## Cleanup
After completing the lab, perform these cleanup steps to avoid additional charges:
1. Remove the created service account key:
```bash
rm ~/key.json
```

2. Delete the service account (optional, as needed):
```bash
gcloud iam service-accounts delete my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
```

## Additional Resources
- [Cloud Natural Language API Documentation](https://cloud.google.com/natural-language/docs/)
- [Natural Language API Getting Started](https://cloud.google.com/natural-language/docs/getting-started)
- [GCP Skill Boost Catalog](http://cloudskillsboost.google/catalog) - Find more Qwik Start labs

## Understanding Entity Analysis Results
For each entity in the response, you'll find:
- **name** and **type**: The entity name and type (PERSON, LOCATION, EVENT, etc.)
- **metadata**: Associated Wikipedia URL if available
- **salience**: Number in [0,1] range indicating entity importance to the text
- **mentions**: Where and how the entity appears in the text

## Notes
- This lab is part of the Qwik Starts series designed to give you a quick taste of Google Cloud features
- Natural Language API supports multiple languages and analysis types
- In production, properly manage service account key security
