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
-- PART 3: GENERATING GRAPH INSIGHTS IN BIGQUERY FOR REVERSE ETL (11:00 - 16:00)
-- ==============================================================================
-- This script runs graph analytical queries in BigQuery to generate actionable
-- product advisories and customer risk insights, formatted for Reverse ETL
-- back into the Cloud Spanner transactional database.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Generate Product Advisories from the Knowledge Graph
-- ------------------------------------------------------------------------------

CREATE OR REPLACE TABLE `kg_demo.product_advisories_export` AS
WITH HazardGraph AS (
  SELECT DISTINCT
    product_id,
    product_name,
    part_name,
    material_name
  FROM GRAPH_TABLE(
    `kg_demo.manufacturing_kg`
    MATCH (p:Product)-[:CONTAINS_PART]->(pt:Part)-[:IS_MADE_OF]->(mat:Material)
    WHERE mat.material_name IN ('Fiberglass', 'Freon-12')
    COLUMNS (p.product_id, p.product_name, pt.part_name, mat.material_name)
  )
),
AggregatedHazards AS (
  SELECT
    product_id,
    product_name,
    ARRAY_AGG(DISTINCT CONCAT(part_name, ' (', material_name, ')')) AS affected_components,
    ARRAY_TO_STRING(ARRAY_AGG(DISTINCT CONCAT(part_name, ' (', material_name, ')')), ', ') AS components_summary
  FROM HazardGraph
  GROUP BY product_id, product_name
)
SELECT
  product_id,
  product_name,
  affected_components,
  ai_assessment.risk_severity AS risk_severity,
  ai_assessment.advisory_action AS advisory_action,
  CURRENT_TIMESTAMP() AS generated_at
FROM (
  SELECT
    product_id,
    product_name,
    affected_components,
    AI.GENERATE(
      CONCAT(
        'You are an AI product safety compliance engineer. Assess the hazardous components found in this manufacturing product:\n',
        'Product Name: ', product_name, '\n',
        'Affected Components & Materials: ', components_summary, '\n',
        'Determine the risk_severity (must be strictly one of: CRITICAL, HIGH, MEDIUM, LOW) based on environmental and physical hazards (e.g. Freon-12 is CFC refrigerant ozone-depleting; Fiberglass causes seal erosion and respiratory irritation).\n',
        'Provide a concise 1-sentence engineering advisory_action recommending specific remediation or retrofit steps.'
      ),
      output_schema => 'risk_severity STRING, advisory_action STRING',
      endpoint => 'gemini-3.8-flash'
    ) AS ai_assessment
  FROM AggregatedHazards
);

-- ------------------------------------------------------------------------------
-- 2. Generate Customer Risk Insights for Reverse ETL
-- ------------------------------------------------------------------------------
-- In a production architecture, transactions are synced from Spanner via
-- BigQuery Federated Query or Analytics Engine. Here we join the generated
-- graph advisories with customer transaction history to prepare the Reverse ETL payload.

CREATE OR REPLACE TABLE `kg_demo.customer_risk_insights_export` AS
WITH CustomerPurchases AS (
  SELECT
    "CUST_001" AS customer_id, "PROD_FZ5000" AS product_id, 37500.0 AS total_spend
  UNION ALL SELECT "CUST_001", "PROD_AS5000", 28400.0
  UNION ALL SELECT "CUST_002", "PROD_AS5000", 71000.0
  UNION ALL SELECT "CUST_003", "PROD_FZ5000", 50000.0
  UNION ALL SELECT "CUST_003", "PROD_FGC2000", 28000.0
  UNION ALL SELECT "CUST_005", "PROD_FZ5000", 25000.0
)
SELECT
  cp.customer_id,
  cp.affected_products_count,
  cp.total_spend_at_risk,
  cp.highest_risk_level,
  ai_rec.support_recommendation AS support_recommendation,
  CURRENT_TIMESTAMP() AS last_sync_time
FROM (
  SELECT
    cp.customer_id,
    COUNT(DISTINCT cp.product_id) AS affected_products_count,
    ROUND(SUM(cp.total_spend), 2) AS total_spend_at_risk,
    MAX(pa.risk_severity) AS highest_risk_level,
    STRING_AGG(DISTINCT CONCAT(pa.product_name, ' [', pa.risk_severity, ']'), ', ') AS hazard_summary
  FROM CustomerPurchases cp
  JOIN `kg_demo.product_advisories_export` pa
    ON cp.product_id = pa.product_id
  GROUP BY cp.customer_id
) cp,
UNNEST([
  AI.GENERATE(
    CONCAT(
      'You are a senior customer success manager and technical account director for industrial equipment.\n',
      'Customer ID: ', cp.customer_id, '\n',
      'Total Spend at Risk: $', CAST(cp.total_spend_at_risk AS STRING), '\n',
      'Highest Risk Level: ', cp.highest_risk_level, '\n',
      'Affected Equipment & Severity: ', cp.hazard_summary, '\n',
      'Write a professional, action-oriented 1-sentence support_recommendation advising our field service team on the exact outreach strategy, SLA priority, and upgrade kit to offer.'
    ),
    output_schema => 'support_recommendation STRING',
    endpoint => 'gemini-3.8-flash'
  )
]) AS ai_rec;

-- ------------------------------------------------------------------------------
-- 3. Native BigQuery Reverse ETL to Cloud Spanner (Enterprise Edition Feature)
-- ------------------------------------------------------------------------------
-- With BigQuery Enterprise or Enterprise Plus reservations, you can perform
-- native Reverse ETL directly from BigQuery to Cloud Spanner operational tables
-- using the built-in EXPORT DATA statement with format = 'CLOUD_SPANNER':
-- (Note: For On-Demand or Standard edition projects, run `python3 reverse_etl_sync.py`).

/*
-- Export Product Advisories natively to Cloud Spanner
EXPORT DATA
  OPTIONS (
    uri = 'https://spanner.googleapis.com/projects/<YOUR_PROJECT_ID>/instances/kg-demo-instance/databases/manufacturing-db',
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

-- Export Customer Risk Insights natively to Cloud Spanner
EXPORT DATA
  OPTIONS (
    uri = 'https://spanner.googleapis.com/projects/<YOUR_PROJECT_ID>/instances/kg-demo-instance/databases/manufacturing-db',
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
*/

-- ==============================================================================
-- DEMO QUERIES: REVIEW REVERSE ETL PAYLOAD IN BIGQUERY
-- ==============================================================================

-- Demo Query 3.1: Check the generated product advisories
SELECT
  product_id,
  product_name,
  risk_severity,
  advisory_action,
  affected_components
FROM `kg_demo.product_advisories_export`
ORDER BY risk_severity DESC, product_name;

-- Demo Query 3.2: Check customer risk insights before exporting to Spanner
SELECT
  customer_id,
  affected_products_count,
  total_spend_at_risk,
  highest_risk_level,
  support_recommendation
FROM `kg_demo.customer_risk_insights_export`
ORDER BY total_spend_at_risk DESC;

-- ==============================================================================
-- 4. COMMENTED-OUT FALLBACKS: CREATE SPANNER TABLES & INSERT ADVISORY DATA
-- ==============================================================================
-- If you need to manually create the Spanner operational tables or insert the
-- exported advisory data directly in Cloud Spanner Studio / CLI (without
-- running `python3 reverse_etl_sync.py` or BigQuery EXPORT DATA), uncomment
-- and run the following GoogleSQL statements inside Cloud Spanner (`manufacturing-db`):

/*
-- ------------------------------------------------------------------------------
-- 4A. SPANNER DDL: Create the ProductAdvisories & CustomerInsights tables
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ProductAdvisories (
    advisory_id STRING(36) NOT NULL,
    product_id STRING(36) NOT NULL,
    product_name STRING(100) NOT NULL,
    risk_severity STRING(20) NOT NULL,
    advisory_action STRING(500) NOT NULL,
    affected_components STRING(200),
    last_updated_from_bq TIMESTAMP NOT NULL,
    CONSTRAINT FK_Advisories_Product FOREIGN KEY (product_id) REFERENCES Products (product_id)
) PRIMARY KEY (advisory_id);

CREATE TABLE IF NOT EXISTS CustomerInsights (
    insight_id STRING(36) NOT NULL,
    customer_id STRING(36) NOT NULL,
    affected_products_count INT64 NOT NULL,
    total_spend_at_risk FLOAT64 NOT NULL,
    highest_risk_level STRING(20) NOT NULL,
    support_recommendation STRING(500) NOT NULL,
    last_sync_time TIMESTAMP NOT NULL,
    CONSTRAINT FK_Insights_Customer FOREIGN KEY (customer_id) REFERENCES Customers (customer_id)
) PRIMARY KEY (insight_id);

-- ------------------------------------------------------------------------------
-- 4B. SPANNER DML: Insert Fallback Advisory Exported Data into Cloud Spanner
-- ------------------------------------------------------------------------------
INSERT OR UPDATE INTO ProductAdvisories (
    advisory_id, product_id, product_name, risk_severity, advisory_action,
    affected_components, last_updated_from_bq
)
VALUES
  (
    'ADV-PROD_FZ5000',
    'PROD_FZ5000',
    'FroZone Zenith 5000',
    'CRITICAL',
    'PROACTIVE RECALL: Replace Thermal Insulation Panel & upgrade Freon-12 compressor seals immediately.',
    'Compressor Unit-XZ (Freon-12), Thermal Insulation Panel (Fiberglass)',
    CURRENT_TIMESTAMP()
  ),
  (
    'ADV-PROD_FGC2000',
    'PROD_FGC2000',
    'FrostGuard Commercial 2000',
    'CRITICAL',
    'Mandate immediate retrofit of HeavyDuty Compressor-99 units to replace Freon-12 with approved HFC refrigerant.',
    'HeavyDuty Compressor-99 (Freon-12)',
    CURRENT_TIMESTAMP()
  );

INSERT OR UPDATE INTO CustomerInsights (
    insight_id, customer_id, affected_products_count, total_spend_at_risk,
    highest_risk_level, support_recommendation, last_sync_time
)
VALUES
  (
    'INS-CUST_001',
    'CUST_001',
    1,
    37500.0,
    'CRITICAL',
    'ALERT: Customer owns 1 product(s) with identified material hazards. Recommend immediate outreach with upgrade kit.',
    CURRENT_TIMESTAMP()
  ),
  (
    'INS-CUST_003',
    'CUST_003',
    2,
    78000.0,
    'CRITICAL',
    'Immediately dispatch a field service technician for a critical-priority service call on CUST_003 equipment and offer thermal sensor upgrade kit.',
    CURRENT_TIMESTAMP()
  );
*/
