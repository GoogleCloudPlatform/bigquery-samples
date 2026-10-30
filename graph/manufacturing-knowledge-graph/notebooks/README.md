# Notebooks — Manufacturing Knowledge Graph Demo

- [`kg_demo_manufacturing.ipynb`](./kg_demo_manufacturing.ipynb): Interactive walkthrough showing how to semantically chunk an engineering PDF manual in Cloud Storage with BigQuery's `AI.CHUNK_DOCUMENT`, extract `(Product)-[:CONTAINS_PART]->(Part)-[:MADE_OF]->(Material)` Knowledge Graph triples with `AI.GENERATE` (`gemini-3.8-flash`), and load them into BigQuery for `GRAPH_TABLE` traversal.

See the root [`README.md`](../README.md) for full end-to-end setup and execution instructions.
