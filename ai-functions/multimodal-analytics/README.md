# Multimodal Analytics and Zero-Shot Forecasting with BigQuery

## Overview
This sample demonstrates how to use BigQuery's Object Tables and AI Functions to analyze unstructured data (images and PDFs) alongside tabular data, all without moving your data out of BigQuery. Then it uses Google's foundational TimesFM model for zero-shot time-series forecasting to predict future sales volume.

If you prefer going through this as a step-by-step tutorial, check out the [codelab](https://codelabs.developers.google.com/multimodal-analytics-zero-shot-forecasting).

### The Scenario: Best Foot Forward (BFF)
Imagine you are a Data Engineer at a fictional shoe company called Best Foot Forward (BFF). The company works with many different types of data:
*   **Images** of the returned shoes.
*   **PDFs** containing return authorization slips.
*   **Tabular data** containing transaction histories.

In this sample, you will create object tables from a public dataset in GCS, and then use BigQuery's `AI.GENERATE_TEXT` AI function to analyze the shoe return images and the reason for the return from the PDFs. You will then join these insights with tabular transaction data to , and use `AI.FORECAST` to predict future inventory needs based on the cleaned data. The sample includes setup commands in the Setup section below, followed by a series of SQL queries.

## What You'll Learn
1.  **BigQuery Object Tables:** Create secure references to images and PDFs stored in Cloud Storage.
2.  **BigQuery AI Functions:** Use `AI.GENERATE_TEXT` to extract insights from images and PDFs stored in object tables
4.  **Zero-Shot Forecasting:** Use `AI.FORECAST` (TimesFM) to predict the next 30 days of sales volume.

## Prerequisites

To run this notebook, you will need:
*   A Google Cloud Project with an active billing account.
*   The following APIs enabled:
    *   `bigquery.googleapis.com`
    *   `aiplatform.googleapis.com`
    *   `storage.googleapis.com`
    *   `bigqueryconnection.googleapis.com`
* The `gcloud` CLI installed. You can follow the installation instructions [here](https://docs.cloud.google.com/sdk/docs/install-sdk).

## Setup

Follow these steps before executing the SQL queries included in this directory.

### Set environment variables

Set the following environment variables used throughout the sample:

```bash
export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project)
export GOOGLE_CLOUD_LOCATION="us"
```

### Create the BigQuery dataset

Create the following dataset which will be used throughout the SQL queries in this sample:

```bash
bq mk --location=$GOOGLE_CLOUD_LOCATION bff
```

### Create the Cloud Resource Connection

In order to create the Object Tables used in this sample, you first need to create a [Cloud Resource Connection](https://docs.cloud.google.com/bigquery/docs/create-cloud-resource-connection) and give it the relevant IAM permissions.

```bash
# Create the Cloud Resource Connection
bq mk --connection --location=us --project_id=$GOOGLE_CLOUD_PROJECT \
    --connection_type=CLOUD_RESOURCE bff

# Retrieve the service account created for the connection
SA=$(bq show --format=json --connection us.bff | jq -r '.cloudResource.serviceAccountId')

# Grant Storage Object Viewer and Agent Platform User roles
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:$SA" \
    --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:$SA" \
    --role="roles/aiplatform.user"
```

Now you're ready to execute the SQL queries! The SQL files are numbered so you can go through them in order.


