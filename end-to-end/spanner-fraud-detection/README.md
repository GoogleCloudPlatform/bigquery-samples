# Spanner & BigQuery Graph Fraud Detection Sample

This directory contains the SQL DDL and DML statements used in the **Fraud Defense with Spanner and BigQuery Graph** lab (`dat005-spanner-bigquery-graph`), designed to be executed from the **Data Agent Kit** in Cloud Shell Editor or via CLI.

## Files

- `bq_create_tables.sql`: Creates the `GameplayTelemetry`, `AccountSignals`, `Players`, and `ChatLogs` tables in the `game_analytics` BigQuery dataset.
- `spanner_create_tables.sql`: Creates the `Players`, `AccountSignals`, and `Transactions` tables and `AvatarSearchIndex` vector index in the `game-db` Spanner database.
- `spanner_insert_data.sql`: Inserts sample players, transactions, and account signals into the `game-db` Spanner database.
- `bq_create_model.sql`: Creates the `game_analytics.multimodal_model` remote model in BigQuery using the `unicorn-connection` Cloud Resource connection.
