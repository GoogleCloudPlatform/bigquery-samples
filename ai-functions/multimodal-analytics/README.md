# Multimodal Analytics and Zero-Shot Forecasting with BigQuery

## Overview
This sample demonstrates how to use BigQuery's Object Tables and AI Functions to analyze unstructured data (images and PDFs) alongside tabular data, all without moving your data out of BigQuery. Finally, it uses Google's foundational TimesFM model for zero-shot time-series forecasting to predict future sales volume.

### The Scenario: Best Foot Forward (BFF)
Imagine you are a Data Engineer at a fictional shoe company called Best Foot Forward (BFF). The company works with many different types of data:
*   **Images** of the returned shoes.
*   **PDFs** containing return authorization slips.
*   **Tabular data** containing transaction histories.

In this notebook, you will create object tables from a public dataset in GCS, and then use BigQuery's `ML.GENERATE_TEXT` AI function to analyze the shoe return images and the reason for the return from the PDFs. You will then join these insights with tabular transaction data to , and use `AI.FORECAST` to predict future inventory needs based on the cleaned data.

## What You'll Learn
1.  **BigQuery Object Tables:** Create secure references to images and PDFs stored in Cloud Storage.
2.  **BigQuery AI Functions:** Use `ML.GENERATE_TEXT` to extract insights from images and PDFs stored in object tables
4.  **Zero-Shot Forecasting:** Use `AI.FORECAST` (TimesFM) to predict the next 30 days of sales volume.

## Prerequisites

To run this notebook, you will need:
*   A Google Cloud Project with an active billing account.
*   The following APIs enabled:
    *   `bigquery.googleapis.com`
    *   `aiplatform.googleapis.com`
    *   `storage.googleapis.com`
*   Proper IAM permissions (`roles/aiplatform.user` and `roles/storage.objectViewer`) granted to the BigQuery Cloud Resource Connection service account (handled programmatically in the notebook).
