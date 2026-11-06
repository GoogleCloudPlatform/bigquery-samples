# 🕸️ BigQuery Graph Samples

[![BigQuery Graph Documentation](https://img.shields.io/badge/Documentation-BigQuery_Graph-4285F4?style=for-the-badge&logo=googlebigquery&logoColor=white)](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)

This directory contains notebooks, SQL scripts, and reference architectures demonstrating how to model, query, visualize, and run machine learning on connected data using **[BigQuery Graph](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)** and the **ISO GQL (Graph Query Language)** standard.

---

## 🌟 About BigQuery Graph

**BigQuery Graph** brings native property graph analytics directly to your existing relational tables in BigQuery—without requiring data movement or a separate graph database:

- **Zero-Copy Property Graph DDL**: Define property graphs (`CREATE PROPERTY GRAPH`) directly over existing BigQuery tables by mapping node and edge tables, primary keys, and foreign keys.
- **Standards-Based ISO GQL**: Query complex multi-hop relationships, customer journeys, financial transaction rings, and supply chain dependencies using standard `GRAPH` and `MATCH` patterns.
- **Seamless SQL + AI Interoperability**: Combine graph pattern matching (`GRAPH_TABLE`) with standard BigQuery SQL, [BigQuery AI functions](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other), vector search, and **BigQuery DataFrames (BigFrames)**.
- **Graph Machine Learning**: Ingest BigQuery Property Graphs directly into **Distributed Graph Flow (DGF)** to train Graph Neural Networks (GNNs) for node classification, link prediction, and risk scoring.

📖 **Learn more**: [BigQuery Graph Overview Documentation](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)

---

## 📂 Available Samples

| Sample | Description | Key Technologies | Links |
| :--- | :--- | :--- | :--- |
| **[Predicting Customer Churn Risk Over Time with BigQuery Graph & DGF](./ga4-churn-gnn/)** | End-to-end Graph Neural Network (GNN) churn prediction pipeline on GA4 eCommerce clickstream data. Models users, sequential event touchpoints, and shared pages as a heterogeneous property graph, explores multi-hop customer journeys with ISO GQL, and trains a supervised GNN with Distributed Graph Flow (DGF). | `BigQuery Graph (ISO GQL)` · `DGF` · `BigFrames` · `GA4 Public Dataset` | [README](./ga4-churn-gnn/README.md) · [Notebook](./ga4-churn-gnn/ga4_churn_gnn_bq_graph.ipynb) |
| **[Get Started with BigQuery Graph Measures](./graph-measures/)** | Beginner, SQL-only lab. Builds a five-table music catalog, puts a measure on a property graph, and shows why the same question returns 12.6 billion with `SUM` but 5.1 billion with `AGG`. Covers what `GRAPH_EXPAND` flattens, the four ways a measure read fails (run on purpose), the six supported aggregates, and optional GQL path queries. Every query is a numbered `.sql` file; setup and cleanup are Cloud Shell scripts. | `BigQuery Graph` · `Graph Measures` · `GRAPH_EXPAND` / `AGG` · `ISO GQL` | [README](./graph-measures/README.md) · [SQL](./graph-measures/sql/) |
| **[Manufacturing Knowledge Graph (`AI.CHUNK_DOCUMENT` + GraphRAG + Spanner Graph)](./manufacturing-knowledge-graph/)** | End-to-end GraphRAG and Reverse ETL pipeline over unstructured PDF engineering manuals. Semantically chunks PDFs with `AI.CHUNK_DOCUMENT`, extracts component-material BOM triples with `AI.GENERATE`, combines `VECTOR_SEARCH` (`gemini-embedding-2`) with multi-hop `GRAPH_TABLE` traversal, and exports AI safety advisories to Cloud Spanner operational property graphs. | `BigQuery Graph (ISO GQL)` · `AI.CHUNK_DOCUMENT` · `VECTOR_SEARCH` · `Spanner Graph` · `Reverse ETL` | [README](./manufacturing-knowledge-graph/README.md) · [Notebook](./manufacturing-knowledge-graph/notebooks/kg_demo_manufacturing.ipynb) · [SQL](./manufacturing-knowledge-graph/sql/) |
