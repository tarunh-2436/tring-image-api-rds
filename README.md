# Tring Image Processing API

A serverless image processing application built on AWS using Terraform. The system allows authenticated users to upload images through a web interface, stores them in Amazon S3 using presigned URLs, processes upload events asynchronously through Amazon SQS and AWS Lambda, stores image metadata in Amazon DynamoDB, and sends processing notifications using Amazon SNS.

---

## Architecture

```text
Frontend (HTML / JavaScript)
            │
            ▼
      CloudFront
            │
            ▼
     API Gateway (HTTP API)
            │
            ▼
        API Lambda
            │
            ▼
   Presigned S3 Upload URL
            │
            ▼
         Amazon S3
            │
            ▼
     S3 Event Notification
            │
            ▼
         Amazon SQS
            │
            ▼
    Processor Lambda
            │
     ┌──────┴──────┐
     ▼             ▼
 DynamoDB         SNS
```

---

## Features

### Authentication

* Amazon Cognito User Pool
* Cognito Hosted UI
* OAuth 2.0 Authorization Code Flow
* JWT-based API authorization
* User-specific image ownership enforcement

### Image Upload

* Secure direct browser uploads using presigned S3 URLs
* No image data passes through API Gateway or Lambda
* Upload progress and preview support

### Asynchronous Processing

* S3 ObjectCreated events trigger processing workflow
* SQS decouples storage and processing layers
* Processor Lambda extracts metadata
* DynamoDB updated after successful processing

### Metadata Management

* Stores:

  * Image ID
  * User ID
  * Filename
  * Content Type
  * Extension
  * File Size
  * Processing Status
  * Created Timestamp
  * Processed Timestamp

### Notifications

* SNS notifications sent when processing completes successfully

### Frontend

* Cognito login/logout
* Upload image preview
* Image listing dashboard
* Image metadata viewer
* Full image preview modal

---

# AWS Services Used

| Service              | Purpose                            |
| -------------------- | ---------------------------------- |
| Amazon Cognito       | Authentication and user management |
| API Gateway HTTP API | REST API                           |
| AWS Lambda           | Business logic and processing      |
| Amazon S3            | Image storage                      |
| Amazon DynamoDB      | Metadata storage                   |
| Amazon SQS           | Event buffering                    |
| Amazon SNS           | Notifications                      |
| Amazon CloudFront    | Frontend hosting                   |
| Terraform            | Infrastructure as Code             |

---

# API Endpoints

## Create Image Upload

### Request

```http
POST /images
Authorization: Bearer <token>
```

### Body

```json
{
  "filename": "example.jpg",
  "contentType": "image/jpeg"
}
```

### Response

```json
{
  "imageId": "uuid",
  "uploadUrl": "presigned-url"
}
```

---

## List User Images

### Request

```http
GET /images
Authorization: Bearer <token>
```

### Response

```json
{
  "images": [
    {
      "imageId": "uuid",
      "filename": "example.jpg",
      "status": "COMPLETED",
      "createdAt": "2026-06-19T05:57:17.598344+00:00"
    }
  ]
}
```

---

## Get Image Details

### Request

```http
GET /images/{imageId}
Authorization: Bearer <token>
```

### Response

```json
{
  "image": {
    "imageId": "uuid",
    "filename": "example.jpg",
    "contentType": "image/jpeg",
    "extension": "jpg",
    "fileSize": 29222,
    "status": "COMPLETED",
    "createdAt": "2026-06-19T05:57:17.598344+00:00",
    "processedAt": "2026-06-19T05:57:30.326139+00:00"
  },
  "downloadUrl": "presigned-url"
}
```

---

# DynamoDB Schema

## Table

ImageMetadata

### Partition Key

```text
userId
```

### Sort Key

```text
imageId
```

### Local Secondary Index

```text
CreatedAtIndex

Partition Key: userId
Sort Key: createdAt
```

---

# S3 Object Structure

```text
uploads/
└── {userId}/
    └── {imageId}/
        └── {filename}
```

Example:

```text
uploads/
└── 2478c428-0091-70f3-8115-6ebfb24685e8/
    └── 92e0e3c9-a32c-41de-ac6d-7c67668e89c6/
        └── image.jpg
```

---

# Processing Workflow

1. User authenticates through Cognito.
2. Frontend requests upload URL from API Gateway.
3. API Lambda creates metadata record in DynamoDB.
4. API Lambda returns presigned S3 upload URL.
5. Browser uploads image directly to S3.
6. S3 generates ObjectCreated event.
7. Event is sent to SQS.
8. Processor Lambda consumes SQS message.
9. Lambda retrieves image metadata from S3.
10. DynamoDB record updated with processing details.
11. SNS notification published.
12. Image appears as COMPLETED in frontend.

---

# Frontend Features

### Upload

* Image selection
* Local image preview
* Upload status indicator

### Dashboard

* List uploaded images
* Display processing status
* Refresh image list

### Image Viewer

* Full image preview
* Metadata display
* Processing information

### Authentication Status

* Logged In indicator
* Logged Out indicator

---

# Terraform Deployment

Initialize Terraform:

```bash
terraform init
```

Review changes:

```bash
terraform plan
```

Deploy infrastructure:

```bash
terraform apply
```

Destroy infrastructure:

```bash
terraform destroy
```

---

# Project Structure

```text
.
├── frontend/
│   ├── index.html
│   ├── scripts.js
│   ├── styles.css
│   └── config.js
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│
├── lambda/
│   └── image-api/
│       └── lambda_function.py
│
├── processor/
│   └── lambda_function.py
│
└── README.md
```

---

# Security Considerations

* Direct S3 uploads through presigned URLs
* No public bucket access
* JWT-based authorization
* User ownership validation
* IAM least-privilege permissions
* CloudFront HTTPS delivery
* SQS decoupled processing architecture

---

# Future Enhancements

* Image thumbnail generation
* Multiple image formats
* Image transformations
* Metadata search functionality
* User-specific notifications
* CloudWatch dashboards and alarms
* CI/CD pipeline using AWS SAM or GitHub Actions

---

# Author

Tarun Harish
