# Google Cloud BigQuery Samples

[![BigQuery Docs](https://img.shields.io/badge/Docs-BigQuery-4285F4?style=for-the-badge&logo=googlebigquery&logoColor=white)](https://cloud.google.com/bigquery/docs?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)
[![BigQuery Graph](https://img.shields.io/badge/Docs-BigQuery_Graph-34A853?style=for-the-badge&logo=googlecloud&logoColor=white)](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)
[![BigQuery AI Functions](https://img.shields.io/badge/Docs-AI_Functions-FBBC04?style=for-the-badge&logo=googlegemini&logoColor=black)](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)
[![License](https://img.shields.io/badge/License-Apache_2.0-EA4335?style=for-the-badge)](LICENSE)

Welcome to the **BigQuery Samples** repository! This repository hosts hands-on notebooks, SQL workflows, and reference architectures that showcase how to build modern data analytics, graph intelligence, and generative AI applications directly on **BigQuery**.

---

## 🗺️ Repository Structure

This repository is organized into three core categories:

```text
bigquery-samples/
├── graph/          # Property Graph analytics (ISO GQL) & Graph Machine Learning (GNNs)
├── ai-functions/   # Generative AI, embeddings, vector search & foundation models in SQL
└── end-to-end/     # Multi-product reference architectures & full-stack data-to-AI pipelines
```

| Category | Directory | Documentation | Focus Area |
| :--- | :--- | :--- | :--- |
| **🕸️ Graph** | [`graph/`](./graph/) | [BigQuery Graph Overview](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other) | Property graph modeling, ISO GQL pattern matching, multi-hop path analysis, and Graph Neural Networks (GNNs). |
| **✨ AI Functions** | [`ai-functions/`](./ai-functions/) | [Generative AI Overview](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other) | In-warehouse LLMs (`AI.GENERATE`, `AI.GENERATE_TABLE`), autonomous embeddings (`AI.EMBED`), `VECTOR_SEARCH`, and `AI.FORECAST`. |
| **🚀 End-to-End** | [`end-to-end/`](./end-to-end/) | [BigQuery Documentation](https://cloud.google.com/bigquery/docs?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other) | Production-grade workflows combining BigQuery Graph, AI Functions, BigFrames, Vertex AI, and agentic systems. |

---

## 🕸️ Graph (`graph/`)

> 📖 **Documentation**: [BigQuery Graph Overview](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)

[**BigQuery Graph**](./graph/) enables native property graph analytics directly over your existing BigQuery relational tables using the **ISO GQL (Graph Query Language)** standard—with zero data movement. Define node and edge tables via `CREATE PROPERTY GRAPH`, traverse multi-hop relationships using `MATCH` and `GRAPH_TABLE`, visualize interactive subgraphs, and train Graph Neural Networks (GNNs) at scale with **Distributed Graph Flow (DGF)**.

### Featured Graph Samples

| Sample | Overview | Launch |
| :--- | :--- | :--- |
| **[Predicting Customer Churn Risk Over Time with BigQuery Graph (GQL) & DGF](./graph/ga4-churn-gnn/)** | Models real-world Google Analytics 4 (GA4) eCommerce clickstreams as a heterogeneous temporal property graph (`User`, `Event`, and shared `Page` nodes), explores multi-hop customer journeys with ISO GQL, and trains a supervised **Graph Neural Network (GNN)** using Distributed Graph Flow (DGF) to score customer churn risk. <br/><br/> 📄 [Lab README](./graph/ga4-churn-gnn/README.md) · 📓 [Notebook](./graph/ga4-churn-gnn/ga4_churn_gnn_bq_graph.ipynb) · 👤 [SAMPLEOWNERS](./graph/ga4-churn-gnn/SAMPLEOWNERS) | [![Open in Colab](https://img.shields.io/badge/Colab-F9AB00?style=flat-square&logo=googlecolab&logoColor=white)](https://colab.research.google.com/github/GoogleCloudPlatform/bigquery-samples/blob/main/graph/ga4-churn-gnn/ga4_churn_gnn_bq_graph.ipynb) <br/> [![Colab Enterprise](https://img.shields.io/badge/Colab_Enterprise-4285F4?style=flat-square&logo=googlecloud&logoColor=white)](https://console.cloud.google.com/vertex-ai/colab/import/https%3A%2F%2Fraw.githubusercontent.com%2FGoogleCloudPlatform%2Fbigquery-samples%2Fmain%2Fgraph%2Fga4-churn-gnn%2Fga4_churn_gnn_bq_graph.ipynb) |

---

## ✨ AI Functions (`ai-functions/`)

> 📖 **Documentation**: [BigQuery Generative AI Overview](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)

[**BigQuery AI Functions**](./ai-functions/) bring Vertex AI foundation models (including **Gemini**, text/multimodal embeddings, and **TimesFM**) directly into BigQuery SQL and Python DataFrames. Process unstructured documents, images, audio, and structured tables at scale without complex ETL pipelines:

- **Generative & Structured Extraction**: Use `AI.GENERATE`, `AI.GENERATE_TABLE`, `AI.GENERATE_BOOL`, `AI.GENERATE_INT`, and `AI.GENERATE_DOUBLE` to summarize text, classify records, and extract strongly-typed schemas.
- **Embeddings & Semantic Search**: Generate embeddings with `AI.EMBED` (including autonomous generated columns) and run high-speed similarity search with `VECTOR_SEARCH` and `ML.DISTANCE`.
- **Zero-Shot Time-Series Forecasting**: Predict future metrics directly in SQL using `AI.FORECAST`.

👉 Explore the **[`ai-functions/` directory](./ai-functions/)** for details and upcoming samples.

---

## 🚀 End-to-End (`end-to-end/`)

[**End-to-End Solutions**](./end-to-end/) showcase comprehensive architectures that unify multiple Google Cloud and BigQuery capabilities into complete business workflows—such as **GraphRAG** (combining [BigQuery Graph](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other) with [BigQuery AI Functions](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)), multimodal lakehouse pipelines with BigLake and Object Tables, and real-time AI agent integrations.

### Featured End-to-End Samples

| Sample | Overview |
| :--- | :--- |
| **[Real-Time Fraud Defense with BigQuery Graph, Spanner Graph & Reverse ETL](./end-to-end/spanner-fraud-detection/)** | Unifies analytical and operational graph intelligence to catch a coordinated fraud ring in an online game. Uses **BigQuery Continuous Queries (Reverse ETL)** to stream real-time anomaly alerts to **Spanner**, **Spanner Graph** and vector search to trace multi-hop financial transactions and bot accounts, and **BigQuery Graph (ISO GQL)** with multimodal embeddings to analyze communication networks. <br/><br/> 📄 [Sample README](./end-to-end/spanner-fraud-detection/README.md) · 🗄️ [BigQuery Tables DDL](./end-to-end/spanner-fraud-detection/bq_create_tables.sql) · ⚡ [Spanner Tables DDL](./end-to-end/spanner-fraud-detection/spanner_create_tables.sql) · 🤖 [Multimodal Model DDL](./end-to-end/spanner-fraud-detection/bq_create_model.sql) · 👤 [SAMPLEOWNERS](./end-to-end/spanner-fraud-detection/SAMPLEOWNERS) |

👉 Explore the **[`end-to-end/` directory](./end-to-end/)** for details and upcoming reference architectures.

---

## 🛠️ Getting Started

### Clone the Repository

```bash
git clone https://github.com/GoogleCloudPlatform/bigquery-samples.git
cd bigquery-samples
```

### Download a Single Sample

To download a specific sample folder (for example, `graph/ga4-churn-gnn`) without cloning the entire repository, use [`giget`](https://github.com/unjs/giget):

```bash
npx -y giget@latest gh+git:GoogleCloudPlatform/bigquery-samples/graph/ga4-churn-gnn ga4-churn-gnn
```

---

## 🌐 Additional Client Library Samples

For BigQuery client library snippets by programming language, refer to the following repositories:
- **Python**: [GoogleCloudPlatform/python-docs-samples](https://github.com/GoogleCloudPlatform/python-docs-samples)
- **Node.js**: [GoogleCloudPlatform/nodejs-docs-samples](https://github.com/GoogleCloudPlatform/nodejs-docs-samples)
- **Java**: [GoogleCloudPlatform/java-docs-samples](https://github.com/GoogleCloudPlatform/java-docs-samples)
- **Go**: [GoogleCloudPlatform/golang-samples](https://github.com/GoogleCloudPlatform/golang-samples)

---

## 🤝 Governance & Contributing

### Code of Conduct
Please review our [Code of Conduct](docs/code-of-conduct.md).

### Contributing
We welcome contributions! If you are interested in adding a sample or improving existing labs, please review the [Contributing Guide](docs/contributing.md).

### Licensing
All code in this repository is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.

### Source Code Headers
Every file containing source code must include copyright and license information. This includes any JS/CSS files that you might be serving out to browsers. (This is to help well-intentioned people avoid accidental copying that doesn't comply with the license.)