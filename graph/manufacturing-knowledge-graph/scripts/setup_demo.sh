#!/usr/bin/env bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prompts for (or reads) the target Google Cloud Project ID, replaces
# <YOUR_PROJECT_ID> placeholders across the demo SQL scripts and notebook,
# sets up an isolated Python environment via uv, enables required APIs,
# stages the PDF manuals to GCS, and initializes the BigQuery dataset.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAMPLE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${SCRIPT_DIR}"

USER_PROJECT_ID="${PROJECT_ID:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project)
      USER_PROJECT_ID="${2:-}"
      shift 2
      ;;
    --project=*)
      USER_PROJECT_ID="${1#*=}"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--project PROJECT_ID]"
      exit 0
      ;;
    *)
      if [[ -z "${USER_PROJECT_ID}" ]]; then
        USER_PROJECT_ID="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

DETECTED_PROJECT="$(gcloud config get-value project 2>/dev/null | sed 's/^(unset)$//' || true)"

if [[ -z "${USER_PROJECT_ID}" ]]; then
  if [[ -t 0 ]]; then
    if [[ -n "${DETECTED_PROJECT}" ]]; then
      read -r -p "Enter your Google Cloud Project ID [${DETECTED_PROJECT}]: " INPUT_PROJECT_ID
      PROJECT_ID="${INPUT_PROJECT_ID:-${DETECTED_PROJECT}}"
    else
      read -r -p "Enter your Google Cloud Project ID: " PROJECT_ID
    fi
  else
    PROJECT_ID="${DETECTED_PROJECT}"
  fi
else
  PROJECT_ID="${USER_PROJECT_ID}"
fi

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Error: Google Cloud Project ID is required. Re-run interactively or pass --project YOUR_PROJECT_ID." >&2
  exit 1
fi

if [[ ! "${PROJECT_ID}" =~ ^[a-zA-Z0-9.:-]+$ ]]; then
  echo "Error: Invalid Google Cloud Project ID '${PROJECT_ID}'." >&2
  exit 1
fi

LOCATION="${LOCATION:-us}"
DATASET_ID="${DATASET_ID:-kg_demo}"
GCS_BUCKET_NAME="${GCS_BUCKET_NAME:-${PROJECT_ID}-kg-demo-manuals}"
SPANNER_INSTANCE="${SPANNER_INSTANCE:-kg-demo-instance}"
SPANNER_DATABASE="${SPANNER_DATABASE:-manufacturing-db}"
SPANNER_CONFIG="${SPANNER_CONFIG:-regional-us-central1}"

GCLOUD=(gcloud --project="${PROJECT_ID}" --quiet)
if [[ -n "${GCLOUD_ACCOUNT:-}" ]]; then
  GCLOUD+=(--account="${GCLOUD_ACCOUNT}")
fi

echo "==> Project:        ${PROJECT_ID}"
echo "==> BQ Dataset:     ${PROJECT_ID}.${DATASET_ID} (${LOCATION})"
echo "==> Manuals Bucket: gs://${GCS_BUCKET_NAME}"

# 1. Replace <YOUR_PROJECT_ID> placeholders across SQL scripts and notebook
echo "==> Configuring <YOUR_PROJECT_ID> placeholders across SQL scripts and notebook..."
python3 - "${SAMPLE_ROOT}" "${PROJECT_ID}" <<'PYEOF'
from pathlib import Path
import sys

sample_root = Path(sys.argv[1])
project_id = sys.argv[2]
placeholder = "<YOUR_" + "PROJECT_ID>"

targets = list((sample_root / "sql").glob("*.sql")) + list(
    (sample_root / "notebooks").glob("*.ipynb")
)
updated = 0
for path in sorted(targets):
    content = path.read_text(encoding="utf-8")
    if placeholder in content:
        path.write_text(content.replace(placeholder, project_id), encoding="utf-8")
        updated += 1
        print(f"   • Updated {path.relative_to(sample_root)}")
if updated == 0:
    print("   • Placeholders already configured.")
PYEOF

# 2. Create an isolated environment with uv so Cloud Shell system packages never
#    conflict and no hardcoded library version pins are needed.
export PATH="${HOME}/.local/bin:${PATH}"
if ! command -v uv >/dev/null 2>&1; then
  echo "==> Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
echo "==> Resolving and installing Python dependencies into scripts/.venv with uv..."
uv sync
uv run python -m ipykernel install --user --name kg-demo --display-name "Python (KG Demo - uv)" >/dev/null
echo "✅ Python environment ready via uv (scripts/.venv + Jupyter kernel 'Python (KG Demo - uv)')."

# 3. Enable required Google Cloud APIs (including Document AI for AI.CHUNK_DOCUMENT)
echo "==> Enabling BigQuery, Document AI, Vertex AI, Storage, and Spanner APIs..."
"${GCLOUD[@]}" services enable \
  bigquery.googleapis.com \
  bigqueryconnection.googleapis.com \
  documentai.googleapis.com \
  aiplatform.googleapis.com \
  storage.googleapis.com \
  spanner.googleapis.com

# 4. Stage engineering manual PDFs in Cloud Storage
if ! "${GCLOUD[@]}" storage buckets describe "gs://${GCS_BUCKET_NAME}" >/dev/null 2>&1; then
  echo "==> Creating bucket gs://${GCS_BUCKET_NAME}..."
  "${GCLOUD[@]}" storage buckets create "gs://${GCS_BUCKET_NAME}" \
    --location="${LOCATION}" \
    --uniform-bucket-level-access
fi

if [[ -d "${SAMPLE_ROOT}/manuals" ]]; then
  echo "==> Uploading engineering PDF manuals to gs://${GCS_BUCKET_NAME}/manuals/..."
  "${GCLOUD[@]}" storage rsync "${SAMPLE_ROOT}/manuals" "gs://${GCS_BUCKET_NAME}/manuals"
fi

# 5. Ensure BigQuery dataset exists
if ! bq --project_id="${PROJECT_ID}" show --dataset "${PROJECT_ID}:${DATASET_ID}" >/dev/null 2>&1; then
  echo "==> Creating BigQuery dataset ${PROJECT_ID}:${DATASET_ID}..."
  bq --project_id="${PROJECT_ID}" --location="${LOCATION}" mk --dataset "${PROJECT_ID}:${DATASET_ID}"
fi

cat <<EOF

✅ Cloud Shell environment, SQL/notebook project IDs, & GCS manuals staged!

Next steps:
  1. Open notebooks/kg_demo_manufacturing.ipynb in BigQuery Studio (Colab Enterprise) or
     Cloud Shell Editor (select kernel "Python (KG Demo - uv)") to chunk manuals
     with AI.CHUNK_DOCUMENT and extract triples.
  2. Run SQL setup & demo scripts:
       - sql/00_setup_spanner_schema_and_data.sql     (Spanner Studio)
       - sql/00_setup_bigquery_tables.sql             (BigQuery Studio - uses AI.CHUNK_DOCUMENT)
       - sql/01_spanner_transactional_graph.sql       (Spanner Studio)
       - sql/02_bigquery_knowledge_graph.sql          (BigQuery Studio)
       - sql/03_bq_generate_insights_reverse_etl.sql  (BigQuery Studio)
       - uv --directory scripts run reverse_etl_sync.py --project="${PROJECT_ID}"
       - sql/04_spanner_operational_insights_graph.sql (Spanner Studio)
EOF
