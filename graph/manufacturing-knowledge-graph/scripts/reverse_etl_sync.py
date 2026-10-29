#!/usr/bin/env python3
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

"""Syncs BigQuery AI Product Advisories and Customer Risk Insights into Cloud Spanner."""

import argparse
import subprocess
from google.cloud import bigquery
from google.cloud import spanner


def get_default_project() -> str:
    try:
        out = subprocess.run(
            ["gcloud", "config", "get-value", "project"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        ).stdout.strip()
        return out or "bq-dea"
    except Exception:
        return "bq-dea"


def sync_insights(
    project_id: str,
    bq_dataset: str,
    spanner_instance: str,
    spanner_database: str,
) -> None:
    bq_client = bigquery.Client(project=project_id)
    spanner_client = spanner.Client(project=project_id)
    instance = spanner_client.instance(spanner_instance)
    database = instance.database(spanner_database)

    advisories_sql = f"""
        SELECT
          CONCAT('ADV-', product_id) AS advisory_id,
          product_id,
          product_name,
          risk_severity,
          advisory_action,
          ARRAY_TO_STRING(affected_components, ', ') AS affected_components,
          generated_at AS last_updated_from_bq
        FROM `{project_id}.{bq_dataset}.product_advisories_export`
    """
    advisory_rows = [
        (
            r.advisory_id,
            r.product_id,
            r.product_name,
            r.risk_severity,
            r.advisory_action,
            r.affected_components,
            r.last_updated_from_bq,
        )
        for r in bq_client.query(advisories_sql).result()
    ]

    if advisory_rows:
        with database.batch() as batch:
            batch.insert_or_update(
                table="ProductAdvisories",
                columns=(
                    "advisory_id",
                    "product_id",
                    "product_name",
                    "risk_severity",
                    "advisory_action",
                    "affected_components",
                    "last_updated_from_bq",
                ),
                values=advisory_rows,
            )
    print(f"Synced {len(advisory_rows)} row(s) to Spanner ProductAdvisories.")

    insights_sql = f"""
        SELECT
          CONCAT('INS-', customer_id) AS insight_id,
          customer_id,
          affected_products_count,
          total_spend_at_risk,
          highest_risk_level,
          support_recommendation,
          last_sync_time
        FROM `{project_id}.{bq_dataset}.customer_risk_insights_export`
    """
    insight_rows = [
        (
            r.insight_id,
            r.customer_id,
            r.affected_products_count,
            float(r.total_spend_at_risk),
            r.highest_risk_level,
            r.support_recommendation,
            r.last_sync_time,
        )
        for r in bq_client.query(insights_sql).result()
    ]

    if insight_rows:
        with database.batch() as batch:
            batch.insert_or_update(
                table="CustomerInsights",
                columns=(
                    "insight_id",
                    "customer_id",
                    "affected_products_count",
                    "total_spend_at_risk",
                    "highest_risk_level",
                    "support_recommendation",
                    "last_sync_time",
                ),
                values=insight_rows,
            )
    print(f"Synced {len(insight_rows)} row(s) to Spanner CustomerInsights.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default=get_default_project(), help="GCP Project ID")
    parser.add_argument("--dataset", default="kg_demo", help="BigQuery Dataset ID")
    parser.add_argument("--instance", default="kg-demo-instance", help="Spanner Instance ID")
    parser.add_argument("--database", default="manufacturing-db", help="Spanner Database ID")
    args = parser.parse_args()

    sync_insights(args.project, args.dataset, args.instance, args.database)


if __name__ == "__main__":
    main()
