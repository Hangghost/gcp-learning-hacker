# Video Intelligence API Documentation

## Description
Official Google Cloud Video Intelligence API documentation. Learn how to use the Video Intelligence API to annotate videos stored in Cloud Storage, making videos searchable and discoverable by extracting metadata.

## URL
https://cloud.google.com/video-intelligence/docs/

## Category
documentation

## Target Audience
- Intermediate
- Advanced

## Prerequisites
- Google Cloud Platform account
- Basic knowledge of REST APIs
- Familiarity with Cloud Storage
- Programming experience (optional, can use REST API directly)

## Related Labs
- GSP154: Video Intelligence: Qwik Start

## Key Topics Covered
- API overview and capabilities
- Label detection and annotation
- Object tracking in videos
- Text detection in videos
- Explicit content detection
- Shot change detection
- Speech transcription
- Authentication and authorization
- Quota and pricing
- Best practices

## API Features
- **LABEL_DETECTION**: Identifies objects, locations, activities, and other relevant entities
- **SHOT_CHANGE_DETECTION**: Identifies shot changes in videos
- **EXPLICIT_CONTENT_DETECTION**: Detects explicit content in videos
- **TEXT_DETECTION**: Extracts text from videos
- **OBJECT_TRACKING**: Tracks objects throughout video sequences
- **SPEECH_TRANSCRIPTION**: Transcribes speech to text

## Usage Patterns
- Asynchronous processing for long videos
- Batch processing capabilities
- REST API and client libraries available
- Integration with other GCP services

## Notes
Video Intelligence API processes videos stored in Google Cloud Storage. Results are returned in JSON format with timestamps and confidence scores. API is particularly useful for content moderation, search indexing, and video analytics applications.
