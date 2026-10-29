# 🔮 Predicting Customer Churn Risk Over Time with BigQuery Graph (GQL) & Distributed Graph Flow (DGF)

[![Open in Colab](https://img.shields.io/badge/Open_in_Colab-F9AB00?style=for-the-badge&logo=googlecolab&logoColor=white)](https://colab.research.google.com/github/GoogleCloudPlatform/bigquery-samples/blob/main/graph/ga4-churn-gnn/ga4_churn_gnn_bq_graph.ipynb)
[![Open in Colab Enterprise](https://img.shields.io/badge/Open_in_Colab_Enterprise-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)](https://console.cloud.google.com/vertex-ai/colab/import/https%3A%2F%2Fraw.githubusercontent.com%2FGoogleCloudPlatform%2Fbigquery-samples%2Fmain%2Fgraph%2Fga4-churn-gnn%2Fga4_churn_gnn_bq_graph.ipynb)
[![BigQuery Graph Docs](https://img.shields.io/badge/Docs-BigQuery_Graph-4285F4?style=for-the-badge&logo=googlebigquery&logoColor=white)](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)

An end-to-end enterprise **Temporal Graph Machine Learning (Graph Neural Network)** workflow on real-world **Google Analytics 4 (GA4) eCommerce** clickstream data, powered by **[BigQuery Graph (ISO GQL)](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)**, **BigQuery DataFrames (BigFrames)**, and **[Distributed Graph Flow (DGF)](https://dgf.readthedocs.io/en/latest/tutorial/timeseries_node_prediction.html)**.

---

## 📖 Overview

Customer churn prediction in digital commerce requires capturing not only **aggregate user features** (such as visit frequency, country, or device category), but also the **fine-grained, chronological sequence of user interaction journeys** and **cross-user behavioral similarity**.

Traditional tabular machine learning models flatten customer event streams into static summary statistics (RFM metrics), losing critical behavioral context:
1. **Action sequences and transition pathways** ($A \to B \to C$ vs. $A \to C \to B$).
2. **Dynamic inter-event temporal latency** ($\Delta t$ between consecutive actions).
3. **Recency decay** (events from today carry stronger predictive signals than events from weeks ago).
4. **Cross-user behavioral similarity** (collaborative signals between customers browsing the same product pages).

This lab demonstrates how to model GA4 clickstream sequences as a **heterogeneous temporal property graph with native `ARRAY` timeseries properties** directly in BigQuery, explore customer journeys with **ISO GQL**, and train a **Temporal Graph Neural Network (GNN)** with built-in sequence encoding (`time_aware=True`, `timeseries_encoder="cnn"`) using **Distributed Graph Flow (DGF)** to predict customer churn risk and write actionable risk scores back to BigQuery.

---

## 🏗️ Graph Schema & Architecture

We segment the GA4 event stream (`bigquery-public-data.ga4_obfuscated_sample_ecommerce`) into two non-overlapping windows to prevent target leakage:
- **Observation Window (Nov 1, 2020 – Dec 31, 2020 / 61 Days)**: Used to construct user profiles, aligned chronological event `ARRAY` timeseries, shared page nodes, and causal interaction timestamps.
- **Prediction Window (Jan 1, 2021 – Jan 31, 2021 / 31 Days)**: Used strictly to derive ground-truth `is_churn` labels (`0` = Retained, `1` = Churned).

### Heterogeneous Temporal Property Graph Topology

Rather than materializing every raw clickstream event as a separate graph node (which inflates a 5,000-user cohort by ~30x with ~178,000 event nodes and ~350,000 edges), we combine **node-level chronological `ARRAY` timeseries** (`group="events"`, `is_timeseries=True`) on `users` with **2-hop cross-user connectivity** via shared `pages`:

```mermaid
graph LR
    subgraph User Entity & Native Timeseries
        U["User Node (users)<br/>Static: total_events, sessions, device, country, recency_decay_weight<br/>Anchor: last_event_timestamp (is_creation_time=True)<br/>Timeseries (group='events'):<br/>• event_timestamps [t₁, t₂, ..., tₖ]<br/>• event_type_ids [page_view, view_item, add_to_cart, ...]<br/>• event_log_time_deltas [ln(1+Δt₁), ...]<br/>• event_recency_weights [w(t₁), ...]"]
    end

    subgraph Shared Pages
        P1["Page: /Apparel/Mens<br/>(total_views, unique_visitors,<br/>first_seen_timestamp)"]
        P2["Page: /basket.html<br/>(total_views, unique_visitors,<br/>first_seen_timestamp)"]
    end

    U2["Peer User Node (users)<br/>(Causally filtered at t ≤ t_seed)"]

    U -->|"VISITED (last_visit_timestamp ≤ t_seed)"| P1
    U -->|"VISITED (last_visit_timestamp ≤ t_seed)"| P2
    U2 -->|"VISITED (last_visit_timestamp ≤ t_seed)"| P1
    U2 -->|"VISITED (last_visit_timestamp ≤ t_seed)"| P2
```

| Entity Type | Table / Label | Description |
| :--- | :--- | :--- |
| **Node** | `users` (`user_nodes`) | Static & aggregate user attributes (`total_events`, `session_count`, `device_category`, `traffic_medium`, `country`, `last_event_name`, `recency_decay_weight`), entity timestamps (`first_event_timestamp`, `last_event_timestamp` with `is_creation_time=True`), aligned chronological `ARRAY` timeseries features (`event_timestamps`, `event_type_ids`, `event_log_time_deltas`, `event_recency_weights`, `event_names` in `group="events"`), and target label `is_churn`. |
| **Node** | `pages` (`page_nodes`) | Shared site pages (`page_location` with query strings stripped, filtered to exclude noisy global hub pages) with popularity attributes (`total_views`, `unique_visitors`) and creation timestamp `first_seen_timestamp` (`is_creation_time=True`), enabling 2-hop cross-user message passing ($U_i \to P_j \leftarrow U_k$). |
| **Edge** | `VISITED` (`user_visited_page_edges`) | Directed edge from a `User` to each distinct `Page` they viewed ($U_i \to P_j$), carrying `view_count`, `last_visit_recency`, and causal edge timestamp `last_visit_timestamp` (`is_creation_time=True`). |

---

## 📓 Notebook Walkthrough

| Section | Topic | Key Capabilities Demonstrated |
| :--- | :--- | :--- |
| **1. System Architecture & Temporal Graph Theory** | Window partitioning, node timeseries & causal GNN design | Preventing target leakage with non-overlapping observation/prediction windows; combining node-level `ARRAY` timeseries (`group="events"`, `is_timeseries=True`) with causal temporal sampling (`time_aware=True`, `is_creation_time=True`). |
| **2. BigQuery Extraction & Materialization** | Temporal node & edge table creation | SQL feature extraction from GA4 nested `event_params`, `ARRAY_AGG` chronological sequence materialization (`event_timestamps`, `event_type_ids`, $\ln(1 + \Delta t)$, exponential recency decay $w(t)$), and in-cloud exploration with **BigQuery DataFrames (`bigframes.pandas`)**. |
| **3. BigQuery Property Graph & ISO GQL** | Native graph DDL & querying | Declaring the graph via `CREATE OR REPLACE PROPERTY GRAPH`, interactive path visualization with `TO_JSON`, cross-user shared-page path discovery, and 3-step sequential funnel comparison via `GRAPH_TABLE` + `UNNEST`. |
| **4. Distributed Graph Flow (DGF) Ingestion & Temporal Schema** | Direct Property Graph loading & validation | Loading the BigQuery Property Graph into an `InMemoryGraph` with `dgf.io.read_bigquery_graph`, declaring `NUMERICAL`, `CATEGORICAL`, and `TIMESTAMP` (`is_creation_time=True`) semantics alongside `is_timeseries=True` (`group="events"`), and validating with `dgf.validate.validate_graph`. |
| **5. Temporal & Timeseries Node Classification (GNN)** | Model training | Training a causal 2-hop Temporal Graph Neural Network on `users` nodes (`dgf.learning.train_node_model(..., time_aware=True, timeseries_encoder="cnn", timeseries_embedding_dim=64)`) with strict train/validation/test seed node splits. |
| **6. Model Evaluation & Diagnostics** | Held-out test cohort metrics | Evaluating AUC-ROC (**~0.81**), accuracy, precision-recall curves, and confusion matrices on unseen test users. |
| **7. Churn Risk Scoring & BigQuery Export** | Tier segmentation & activation | Segmenting customers into *Low*, *Medium*, and *High* risk tiers and exporting scored predictions back to BigQuery via `bigframes.pandas.DataFrame.to_gbq()`. |
| **8. Behavioral Dossiers with ISO GQL** | Explainable graph analytics | Joining GNN risk predictions with `GRAPH_TABLE` + `UNNEST` queries to compare chronological touchpoint sequences of High-Risk vs. Low-Risk cohorts. |
| **9. Enterprise Best Practices & Cleanup** | Production MLOps | Rolling window schedules, causal temporal sampling, sequence encoder selection (`cnn` vs. `transformer`), CPU vs. GPU sizing, continuous GQL monitoring, and reservation cleanup. |

---

## 🚀 Getting Started

### Prerequisites

1. **Google Cloud Project** with billing enabled and the following APIs active:
   - BigQuery API (`bigquery.googleapis.com`)
   - BigQuery Reservation API (`bigqueryreservation.googleapis.com`)
   - Cloud Storage API (`storage.googleapis.com`)
2. **Cloud Storage Bucket** (used by DGF as a temporary staging `work_dir` when reading the BigQuery Property Graph).
3. **BigQuery Enterprise or Enterprise Plus Reservation**:
   > [!IMPORTANT]
   > **[BigQuery Graph (GQL)](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other) requires an Enterprise or Enterprise Plus reservation** and does not run under on-demand pricing. You can create a cost-efficient autoscaling reservation (`--slots=0 --autoscale_max_slots=100`) that costs nothing when idle:
   ```bash
   # Enable the BigQuery Reservation API
   gcloud services enable bigqueryreservation.googleapis.com --project=<PROJECT_ID>

   # Create an Enterprise reservation with 0 baseline slots and 100 max autoscaling slots
   bq mk --reservation \
     --project_id=<PROJECT_ID> \
     --location=US \
     --edition=ENTERPRISE \
     --slots=0 \
     --autoscale_max_slots=100 \
     --ignore_idle_slots=true \
     ga4-churn-reservation

   # Assign your project to the reservation for QUERY jobs
   bq mk --reservation_assignment \
     --project_id=<PROJECT_ID> \
     --location=US \
     --reservation_id=ga4-churn-reservation \
     --job_type=QUERY \
     --assignee_type=PROJECT \
     --assignee_id=<PROJECT_ID>
   ```

### Running the Lab

1. Open [ga4_churn_gnn_bq_graph.ipynb](./ga4_churn_gnn_bq_graph.ipynb) in **Vertex AI Colab Enterprise**, **Google Colab**, or a local Jupyter environment.
2. In **Section 1**, set your `PROJECT_ID`, `DATASET_ID`, `LOCATION` (`US`), and `GCS_BUCKET`.
3. Run the cells sequentially to materialize the temporal node/edge tables, create and query the BigQuery Property Graph with ISO GQL, train the Temporal GNN with DGF, and export churn risk scores back to BigQuery.

---

## 📚 Resources

- [BigQuery Graph Overview Documentation](https://docs.cloud.google.com/bigquery/docs/graph-overview?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)
- [Distributed Graph Flow (DGF): Temporal Node Prediction with Timeseries Data](https://dgf.readthedocs.io/en/latest/tutorial/timeseries_node_prediction.html)
- [Google Analytics 4 BigQuery Public Dataset](https://console.cloud.google.com/marketplace/product/obfuscated-ga360-data/obfuscated-ga4?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)
- [BigQuery DataFrames (BigFrames) Documentation](https://cloud.google.com/python/docs/reference/bigframes/latest?utm_campaign=CDR_0x6cb6c9c7_default_b549221282&utm_medium=external&utm_source=other)
