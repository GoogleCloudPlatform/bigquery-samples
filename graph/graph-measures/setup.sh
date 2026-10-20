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

# BigQuery Graph Measures codelab — Cloud Shell setup.
# Creates the `music` dataset and its five tables in your current project.
# Safe to re-run any number of times: every table is CREATE OR REPLACE.
set -euo pipefail
cd "$(dirname "$0")"

say()  { printf '\n\033[1m%s\033[0m\n' "$1"; }
tick() { printf '  ✓ %s\n' "$1"; }
die()  { printf '\n\033[1m✗ %s\033[0m\n' "$1" >&2; shift; for l in "$@"; do printf '%s\n' "$l" >&2; done; exit 1; }

say "BigQuery Graph Measures · setup"

command -v bq >/dev/null 2>&1 || die "bq not found." \
  "This script is written for Cloud Shell, where the bq CLI is preinstalled." \
  "On a laptop, install the Google Cloud SDK first: https://cloud.google.com/sdk/docs/install"

PROJECT="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"
PROJECT="$(printf '%s' "$PROJECT" | tr -d '[:space:]')"
if [ -z "$PROJECT" ] || [ "$PROJECT" = "(unset)" ]; then
  die "No Google Cloud project selected." "Point gcloud at one, then re-run:" "  gcloud config set project YOUR_PROJECT_ID"
fi
tick "project: $PROJECT"

DATASET="${DATASET:-music}"

gcloud services enable bigquery.googleapis.com --project "$PROJECT" >/dev/null 2>&1 \
  && tick "BigQuery API enabled" \
  || die "Could not enable bigquery.googleapis.com on $PROJECT." "Check that billing is linked and that you can edit the project."

say "Creating dataset $DATASET (US) and five tables…"
SQL="$(cat sql/setup/00_dataset.sql)"
if [ "$DATASET" != "music" ]; then
  SQL="$(printf '%s' "$SQL" | perl -pe "s/(?<![\w.])music\./$DATASET./g; s/EXISTS music\b/EXISTS $DATASET/")"
fi
printf '%s' "$SQL" | bq --headless=true --project_id="$PROJECT" --location=US query --nouse_legacy_sql --quiet >/dev/null \
  || die "The setup SQL failed." "Re-run with the output visible:" "  bq query --nouse_legacy_sql < sql/setup/00_dataset.sql"

expected="Labels:2 Artists:3 Songs:5 Playlists:4 PlaylistEntries:10"
for pair in $expected; do
  t="${pair%%:*}"; want="${pair##*:}"
  got="$(bq --headless=true --project_id="$PROJECT" query --nouse_legacy_sql --quiet --format=csv \
        "SELECT COUNT(*) FROM \`$PROJECT.$DATASET.$t\`" | tail -1 | tr -d '[:space:]')"
  [ "$got" = "$want" ] || die "$DATASET.$t has $got rows, expected $want." "Re-run ./setup.sh; the tables are CREATE OR REPLACE."
  tick "$(printf '%-24s %2s rows' "$DATASET.$t" "$got")"
done

printf '\n🎉 ready — open BigQuery Studio: https://console.cloud.google.com/bigquery?project=%s\n\n' "$PROJECT"
