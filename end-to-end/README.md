# 🚀 End-to-End BigQuery Solutions & Reference Architectures

[![BigQuery Documentation](https://img.shields.io/badge/Documentation-BigQuery-4285F4?style=for-the-badge&logo=googlebigquery&logoColor=white)](https://cloud.google.com/bigquery/docs?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)

This directory contains comprehensive, **end-to-end reference solutions** that combine multiple BigQuery capabilities—such as **[BigQuery Graph](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)**, **[BigQuery AI Functions](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)**, **BigQuery DataFrames (BigFrames)**, **Continuous Queries**, and **Vertex AI**—into unified production workflows.

---

## 🌟 What Belongs in `end-to-end/`

Samples in this folder go beyond single-feature snippets to showcase complete architectures from data ingestion to intelligent activation:

- **Graph + Generative AI (GraphRAG)**: Combining ISO GQL multi-hop traversal (`GRAPH_TABLE`) with `AI.EMBED`, `VECTOR_SEARCH`, and `AI.GENERATE` to ground LLMs and AI agents in enterprise relationship graphs.
- **Lakehouse & Multimodal Pipelines**: Unifying structured tables, Apache Iceberg / BigLake tables, and unstructured Cloud Storage assets via Object Tables for automated enrichment and analytics.
- **Real-Time & Agentic Workflows**: End-to-end applications connecting BigQuery data pipelines with Vertex AI Agent Engine, ADK, Looker, and operational databases.

---

## 📂 Samples

| Sample | Overview |
| :--- | :--- |
| **[Real-Time Fraud Defense with BigQuery Graph, Spanner Graph & Reverse ETL](./spanner-fraud-detection/)** | Combines **BigQuery Continuous Queries (Reverse ETL)**, **Spanner Graph**, **Spanner Vector Search**, and **BigQuery Graph (ISO GQL)** with multimodal embeddings to detect, trace, and investigate a coordinated fraud ring across operational and analytical data. <br/><br/> 📄 [Sample README](./spanner-fraud-detection/README.md) · 👤 [SAMPLEOWNERS](./spanner-fraud-detection/SAMPLEOWNERS) |
