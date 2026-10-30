# Manufacturing Knowledge Graph Demo (`AI.CHUNK_DOCUMENT` + BigQuery Graph + Spanner Graph)

End-to-end demo showing how unstructured PDF engineering manuals in Cloud Storage are semantically chunked with BigQuery's [`AI.CHUNK_DOCUMENT`](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-ai-chunk-document?utm_campaign=CDR_0x6cb6c9c7_default_b542779815&utm_medium=external&utm_source=social), transformed into structured Knowledge Graph triples with `AI.GENERATE` (`gemini-3.8-flash`), queried via BigQuery Property Graphs (`GRAPH_TABLE` / GQL), and synced back to Cloud Spanner operational graphs via Reverse ETL.

## Directory Structure

```text
.
├── README.md
├── SAMPLEOWNERS
├── manuals/      # Sample unstructured PDF engineering manuals
├── notebooks/    # Interactive Colab Enterprise / Cloud Shell walkthrough notebook
├── scripts/      # Cloud Shell setup script, Reverse ETL Python sync, and uv config
└── sql/          # Ordered BigQuery Graph & Spanner Graph DDL and GQL query scripts
```

## Quickstart in Cloud Shell

1. Run the setup script (uses [`uv`](https://docs.astral.sh/uv/) to create an isolated `.venv` and resolve compatible packages dynamically without hardcoded version pins, enables `documentai.googleapis.com` and BigQuery/Vertex AI APIs, and stages the PDF manuals to GCS):

   ```bash
   export PROJECT_ID=$(gcloud config get-value project)
   chmod +x scripts/setup_demo.sh
   ./scripts/setup_demo.sh
   ```

2. Run [`notebooks/kg_demo_manufacturing.ipynb`](./notebooks/kg_demo_manufacturing.ipynb) in **BigQuery Studio (Colab Enterprise)** or **Cloud Shell Editor**:
   - **No `google-cloud-documentai` client package needed**: `AI.CHUNK_DOCUMENT` automatically creates and reuses the `bq-created-layout-parser` Document AI Layout Parser processor in your project.
   - **Dynamic resolution via `uv` (no pinned versions)**: In Cloud Shell, `./scripts/setup_demo.sh` registers the isolated `Python (KG Demo - uv)` Jupyter kernel so Cloud Shell's pre-installed system packages never conflict as Cloud Shell images evolve. In Colab Enterprise (or any other kernel), Cell 2 reuses pre-installed client libraries directly or resolves missing packages cleanly via `uv` without version pins.

## How to Run This Demo in Your Own Project

Follow these steps in order after running `./scripts/setup_demo.sh` above:

### 1. Provision Spanner & Load Operational Data (`Spanner Studio` / `Cloud Shell`)
You can use the [trial version of Spanner](https://docs.cloud.google.com/spanner/docs/free-trial-instance?utm_campaign=CDR_0x6cb6c9c7_default_b542779815&utm_medium=external&utm_source=social) if available. Spanner Graph requires the **Enterprise** or **Enterprise Plus** edition. Create an instance and database if you don't already have one, then apply [`sql/00_setup_spanner_schema_and_data.sql`](./sql/00_setup_spanner_schema_and_data.sql) to create the OLTP tables (`Customers`, `Products`, `Transactions`, `ProductAdvisories`, `CustomerInsights`), insert sample orders, and define the Spanner Property Graphs:

```bash
gcloud spanner instances create kg-demo-instance \
  --config=regional-us-central1 \
  --edition=ENTERPRISE \
  --processing-units=100 \
  --description="Manufacturing KG Demo"

gcloud spanner databases create manufacturing-db \
  --instance=kg-demo-instance
```

Open **Spanner Studio** for `manufacturing-db` and run [`sql/00_setup_spanner_schema_and_data.sql`](./sql/00_setup_spanner_schema_and_data.sql).

### 2. Create a reservation for BigQuery

Use the [Cloud Console](https://docs.cloud.google.com/bigquery/docs/reservations-get-started?utm_campaign=CDR_0x6cb6c9c7_default_b542779815&utm_medium=external&utm_source=social) or the following command to setup an Enterprise reservation requried to run Graph operations in BigQuery:

```bash
bq mk --reservation \
  --project_id=<<your_project_id>> \
  --location=US \
  --edition=ENTERPRISE \
  --slots=0 \
  --autoscale_max_slots=100 \
  --ignore_idle_slots=true \
  kg-demo-reservation

bq mk --reservation_assignment \
  --project_id=<<your_project_id>> \
  --location=US \
  --reservation_id=kg-demo-reservation \
  --job_type=QUERY \
  --assignee_type=PROJECT \
  --assignee_id=<<your_project_id>>
```

### 3. Chunk Manuals, Embed Content & Build Base Graph Tables (`BigQuery Studio`)
1. Open [`sql/00_setup_bigquery_tables.sql`](./sql/00_setup_bigquery_tables.sql) in **BigQuery Studio**.
2. Replace `<YOUR_PROJECT_ID>` in `'gs://<YOUR_PROJECT_ID>-kg-demo-manuals/manuals/*.pdf'` with your Google Cloud project ID.
3. Run the script to:
   - Semantically chunk all four PDF manuals with `AI.CHUNK_DOCUMENT` and generate `gemini-embedding-2` vectors via `AI.EMBED` (`kg_demo.document_chunks`).
   - Extract structured `(Product)-[:CONTAINS_PART]->(Part)-[:MADE_OF]->(Material)` triples with `AI.GENERATE` (`gemini-3.8-flash`) into `kg_demo.extracted_knowledge_graph`.
   - Create the graph node/edge views and materialize `kg_demo.part_node_embeddings` for vector search.

### 4. (Optional) Interactive Single-Manual Walkthrough (`Notebook`)
Upload or open [`notebooks/kg_demo_manufacturing.ipynb`](./notebooks/kg_demo_manufacturing.ipynb) in **BigQuery Studio (Colab Enterprise)** or **Cloud Shell Editor** and run all cells. It automatically detects your active `gcloud` project and walks step-by-step through chunking `manual_frozone_zenith_5000.pdf` (`chunk_size => 250`), extracting BOM triples, and merging them into `kg_demo.extracted_knowledge_graph`.

### 5. Query the Live Transactional Graph (`Spanner Studio`)
Open [`sql/01_spanner_transactional_graph.sql`](./sql/01_spanner_transactional_graph.sql) in **Spanner Studio** (`manufacturing-db`) and run the GQL queries against `TransactionalGraph` to inspect customer orders, regional adoption, and spend by tier.

### 6. Create & Query the Analytical Knowledge Graph + GraphRAG (`BigQuery Studio`)
Open [`sql/02_bigquery_knowledge_graph.sql`](./sql/02_bigquery_knowledge_graph.sql) in **BigQuery Studio** and run each section:
- **Create Property Graph**: Defines `kg_demo.manufacturing_kg` over your extracted product, part, and material tables/views.
- **Queries 2.1 – 2.2 (GQL)**: Traverse multi-hop bills of materials and flag products containing restricted materials (`Fiberglass`, `Freon-12`).
- **Queries 2.3 – 2.4 (GraphRAG)**: Run semantic `VECTOR_SEARCH` (`gemini-embedding-2`) over part nodes and unstructured `AI.CHUNK_DOCUMENT` troubleshooting text first, then join into `GRAPH_TABLE` to traverse affected products across the fleet.

### 7. Generate AI Product Advisories & Customer Risk Insights (`BigQuery Studio`)
Run [`sql/03_bq_generate_insights_reverse_etl.sql`](./sql/03_bq_generate_insights_reverse_etl.sql) in **BigQuery Studio**. This combines `GRAPH_TABLE` hazard findings with `AI.GENERATE` (`gemini-3.8-flash`) to populate `kg_demo.product_advisories_export` and `kg_demo.customer_risk_insights_export`.

### 8. Sync Insights Back to Spanner via Reverse ETL (`Cloud Shell` or `BigQuery Studio`)
Choose either option depending on your BigQuery edition:
- **Any BigQuery edition (`uv run` from Cloud Shell)**:
  ```bash
  uv --directory scripts run reverse_etl_sync.py \
    --project="${PROJECT_ID}" \
    --dataset="kg_demo" \
    --instance="kg-demo-instance" \
    --database="manufacturing-db"
  ```
- **BigQuery Enterprise / Enterprise Plus (Native SQL Reverse ETL)**: Update the Spanner database URI in [`sql/03_bq_native_reverse_etl_export.sql`](./sql/03_bq_native_reverse_etl_export.sql) (`projects/<YOUR_PROJECT_ID>/instances/kg-demo-instance/databases/manufacturing-db`) and run the `EXPORT DATA ... OPTIONS (format = 'CLOUD_SPANNER')` statements in **BigQuery Studio**.

### 9. Query the Enriched Operational Graph (`Spanner Studio`)
Run [`sql/04_spanner_operational_insights_graph.sql`](./sql/04_spanner_operational_insights_graph.sql) in **Spanner Studio** (`manufacturing-db`) to query `OperationalInsightsGraph`, joining live customer transactions with the AI safety advisories and VIP outreach plans synced from BigQuery.
