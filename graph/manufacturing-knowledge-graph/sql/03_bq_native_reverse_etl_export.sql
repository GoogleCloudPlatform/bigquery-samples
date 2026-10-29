-- Copyright 2026 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- ==============================================================================
-- PART 3B: NATIVE BIGQUERY REVERSE ETL TO CLOUD SPANNER (ENTERPRISE EDITION)
-- ==============================================================================
-- With BigQuery Enterprise or Enterprise Plus reservations, you can perform
-- native, zero-ETL Reverse ETL directly from BigQuery analytical tables into
-- Cloud Spanner operational tables using the EXPORT DATA statement with
-- format = 'CLOUD_SPANNER'.
--
-- Prerequisite:
-- Ensure your project/reservation is BigQuery Enterprise Edition or higher, and
-- run `03_bq_generate_insights_reverse_etl.sql` first to create the source tables.
-- ==============================================================================

-- 1. Export Product Advisories natively to Cloud Spanner
EXPORT DATA
  OPTIONS (
    uri = 'https://spanner.googleapis.com/projects/bq-dea/instances/kg-demo-instance/databases/manufacturing-db',
    format = 'CLOUD_SPANNER',
    spanner_options = """{ "table": "ProductAdvisories" }"""
  ) AS
(
  SELECT
    CONCAT('ADV-', product_id) AS advisory_id,
    product_id,
    product_name,
    risk_severity,
    advisory_action,
    ARRAY_TO_STRING(affected_components, ', ') AS affected_components,
    generated_at AS last_updated_from_bq
  FROM `kg_demo.product_advisories_export`
);

-- 2. Export Customer Risk Insights natively to Cloud Spanner
EXPORT DATA
  OPTIONS (
    uri = 'https://spanner.googleapis.com/projects/bq-dea/instances/kg-demo-instance/databases/manufacturing-db',
    format = 'CLOUD_SPANNER',
    spanner_options = """{ "table": "CustomerInsights" }"""
  ) AS
(
  SELECT
    CONCAT('INS-', customer_id) AS insight_id,
    customer_id,
    affected_products_count,
    total_spend_at_risk,
    highest_risk_level,
    support_recommendation,
    last_sync_time
  FROM `kg_demo.customer_risk_insights_export`
);
