# ✨ BigQuery AI Functions & Generative AI Samples

[![BigQuery Generative AI Documentation](https://img.shields.io/badge/Documentation-BigQuery_Generative_AI-4285F4?style=for-the-badge&logo=googlebigquery&logoColor=white)](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)

This directory contains samples, SQL workflows, and notebooks demonstrating how to build generative AI, semantic search, structured extraction, and forecasting pipelines directly inside BigQuery using **[BigQuery AI Functions](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)** and Vertex AI models.

---

## 🌟 About BigQuery AI Functions

**BigQuery Generative AI** lets you analyze unstructured text, documents, audio, images, and structured enterprise tables at petabyte scale using familiar SQL queries and Python DataFrames—without moving data out of BigQuery:

- **Task-Specific AI Functions**: Generate free-form responses (`AI.GENERATE`), extract strongly-typed structured schemas (`AI.GENERATE_TABLE`), evaluate conditions (`AI.GENERATE_BOOL`), and extract numeric attributes (`AI.GENERATE_INT`, `AI.GENERATE_DOUBLE`) powered by Gemini models on Vertex AI.
- **Embeddings & Semantic Vector Search**: Automatically generate and maintain vector embeddings (`AI.EMBED`, `ML.GENERATE_EMBEDDING`) and perform high-speed similarity lookups using `VECTOR_SEARCH` and `ML.DISTANCE`.
- **Time-Series Foundation Models**: Run zero-shot forecasting at scale using `AI.FORECAST` with Google's TimesFM foundation model.
- **Multimodal Analytics**: Combine BigQuery **Object Tables** over Cloud Storage with AI functions to classify, caption, and extract structured insights from PDFs, images, audio, and video alongside tabular warehouse data.

📖 **Learn more**: [BigQuery Generative AI Overview Documentation](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)

---

## 🧰 Core Capabilities Covered

| Capability | Primary SQL / BigQuery Functions | Example Use Cases |
| :--- | :--- | :--- |
| **Text Generation & Summarization** | `AI.GENERATE`, `ML.GENERATE_TEXT` | Customer review summarization, personalized outreach, automated ticket triage |
| **Structured Data Extraction** | `AI.GENERATE_TABLE`, `AI.GENERATE_BOOL`, `AI.GENERATE_INT`, `AI.GENERATE_DOUBLE` | Extracting JSON/table schemas from unstructured logs, contracts, and support transcripts |
| **Embeddings & Vector Search** | `AI.EMBED`, `VECTOR_SEARCH`, `ML.DISTANCE` | Semantic product search, RAG pipelines, deduplication, and anomaly clustering |
| **Zero-Shot Forecasting** | `AI.FORECAST` | Demand forecasting, capacity planning, and financial trend projection without custom training |

---

## 📂 Samples

*New BigQuery AI Functions samples are coming soon! Interested in adding a sample? Check out our [Contributing Guidelines](../docs/contributing.md).*
