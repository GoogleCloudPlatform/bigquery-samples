# BigQuery Graph Measures — get-started lab

Companion sample for the codelab *Get started with BigQuery Graph Measures*. It builds a small
music catalog in BigQuery so you can put one measure on a property graph and watch the same
question return two different answers: **12.6 billion** with `SUM`, **5.1 billion** with `AGG`.

## Setup

In Cloud Shell:

```bash
cd ~
rm -rf ~/bigquery-samples
git clone https://github.com/GoogleCloudPlatform/bigquery-samples.git
cd ~/bigquery-samples/graph/graph-measures
./setup_project.sh   # skip if you already have a billing-linked project selected
./setup.sh
```

`setup_project.sh` is for readers who do not have a project yet. It picks a billing account
(preferring the newest `[YYYY-MM-DD] GDP Credit:` one), creates `bq-graph-XXXX` on it, records the
ID in `~/project_id.txt`, selects it with `gcloud config set project`, and then waits until the
brand new project is actually allowed to serve — a project created seconds ago answers
`403 IAM_PERMISSION_DENIED` while its IAM policy propagates. It is safe to re-run: a second run
reuses the project in `~/project_id.txt` instead of creating another one.

Already have a project? Skip it and run `gcloud config set project YOUR_PROJECT_ID` instead.
You need the **BigQuery Admin** role on it.

`setup.sh` enables the BigQuery API, creates the `music` dataset in the US multi-region with five
tables, and checks the row counts before it says it is done:

```
  ✓ music.Labels              2 rows
  ✓ music.Artists             3 rows
  ✓ music.Songs               5 rows
  ✓ music.Playlists           4 rows
  ✓ music.PlaylistEntries    10 rows
```

Then open BigQuery Studio and follow the codelab. Every query in it is also here, numbered by step:

| file | step |
|---|---|
| `setup_project.sh` | a project with billing on it (optional; skip if you have one) |
| `sql/setup/00_dataset.sql` | the five tables (what `setup.sh` runs) |
| `sql/01_graph_with_measure.sql` | the property graph, with measures |
| `sql/02_sum_vs_agg.sql` | SUM and AGG side by side |
| `sql/03_one_row_becomes_four.sql` | why SUM overcounts |
| `sql/04a…04d_*.sql` | the four ways to read a measure that fail |
| `sql/05_six_aggregates.sql`, `sql/05_read_all_six.sql` | every aggregate a measure supports |
| `sql/06_regroup_by_playlist.sql` | the same measure, grouped differently |
| `sql/07_show_schema.sql` | what `GRAPH_EXPAND` will give you |
| `sql/08_gql_where_streams_reach.sql`, `sql/09_gql_paths.sql` | GQL (needs an Enterprise edition reservation) |

Run one from Cloud Shell instead of pasting it:

```bash
bq query --nouse_legacy_sql < sql/02_sum_vs_agg.sql
```

## Clean up

```bash
./cleanup.sh
```

Drops the `music` dataset, its tables and the property graph.

## Notes

Graph measures, the visual graph modeler and graph visualization are in Preview; BigQuery Graph
itself is generally available. `GRAPH_EXPAND` and `AGG` run under on-demand pricing. The dataset is
a few kilobytes, so the whole lab costs a fraction of a cent.

The data is fictional — Cymbal Records, Northwind Audio, the artists, songs and playlists don't
exist. The numbers are round on purpose, so you can check every result in your head.
