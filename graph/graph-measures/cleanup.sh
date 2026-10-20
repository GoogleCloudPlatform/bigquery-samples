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

# Removes everything the codelab created in BigQuery: the dataset, its tables and the property graph.
# The data agent from the optional chat step is deleted in the console (Agents → Agent catalog).
set -euo pipefail
PROJECT="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"
PROJECT="$(printf '%s' "$PROJECT" | tr -d '[:space:]')"
if [ -z "$PROJECT" ] || [ "$PROJECT" = "(unset)" ]; then
  printf '\n\033[1m✗ No Google Cloud project selected.\033[0m\n' >&2
  printf 'Point gcloud at the project the lab used, then re-run:\n  gcloud config set project YOUR_PROJECT_ID\n' >&2
  exit 1
fi
DATASET="music"
bq --project_id="$PROJECT" rm -r -f -d "$PROJECT:$DATASET" && printf '  ✓ dropped %s.%s (tables and graph)\n' "$PROJECT" "$DATASET"
