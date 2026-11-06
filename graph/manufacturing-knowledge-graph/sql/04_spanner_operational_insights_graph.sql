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
-- PART 4: SPANNER OPERATIONAL INSIGHTS PROPERTY GRAPH & QUERIES (16:00 - 20:00)
-- ==============================================================================
-- Prerequisite:
-- Run `reverse_etl_sync.py` after generating insights in BigQuery to populate
-- Spanner's `ProductAdvisories` and `CustomerInsights` tables.
--
-- This script defines the enriched Spanner Property Graph (`OperationalInsightsGraph`)
-- and runs GQL queries linking live customer purchases to AI Reverse ETL advisories.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Define the Enriched Operational Insights Property Graph
-- ------------------------------------------------------------------------------

CREATE OR REPLACE PROPERTY GRAPH OperationalInsightsGraph
  NODE TABLES (
    Customers AS Customer
      KEY (customer_id)
      LABEL Customer
      PROPERTIES (customer_id, company, tier, annual_support_allowance, region),
    Products AS Product
      KEY (product_id)
      LABEL Product
      PROPERTIES (product_id, product_name, category, unit_price, status),
    ProductAdvisories AS Advisory
      KEY (advisory_id)
      LABEL Advisory
      PROPERTIES (advisory_id, risk_severity, advisory_action, affected_components, last_updated_from_bq),
    CustomerInsights AS CustomerInsight
      KEY (insight_id)
      LABEL CustomerInsight
      PROPERTIES (insight_id, affected_products_count, total_spend_at_risk, highest_risk_level, support_recommendation)
  )
  EDGE TABLES (
    Transactions AS PURCHASED
      KEY (transaction_id)
      SOURCE KEY (customer_id) REFERENCES Customer (customer_id)
      DESTINATION KEY (product_id) REFERENCES Product (product_id)
      LABEL PURCHASED
      PROPERTIES (transaction_id, order_date, quantity, total_amount, status),

    ProductAdvisories AS HAS_ADVISORY
      KEY (advisory_id)
      SOURCE KEY (product_id) REFERENCES Product (product_id)
      DESTINATION KEY (advisory_id) REFERENCES Advisory (advisory_id)
      LABEL HAS_ADVISORY,

    CustomerInsights AS HAS_INSIGHT
      KEY (insight_id)
      SOURCE KEY (customer_id) REFERENCES Customer (customer_id)
      DESTINATION KEY (insight_id) REFERENCES CustomerInsight (insight_id)
      LABEL HAS_INSIGHT
  );

-- ------------------------------------------------------------------------------
-- 2. DEMO QUERIES: LIVE OPERATIONAL GRAPH ENRICHED BY REVERSE ETL
-- ------------------------------------------------------------------------------

-- Demo Query 4.1: Live Operational Support Dashboard
-- Find all customer transactions for products that have an active AI Product Advisory.
GRAPH OperationalInsightsGraph
MATCH (c:Customer)-[t:PURCHASED]->(p:Product)-[a_rel:HAS_ADVISORY]->(a:Advisory)
RETURN
    c.company AS customer_company,
    c.tier AS customer_tier,
    p.product_name AS purchased_product,
    t.order_date AS transaction_date,
    a.risk_severity AS risk_level,
    a.affected_components AS hazard_components,
    a.advisory_action AS required_action
ORDER BY 
    CASE a.risk_severity 
      WHEN 'CRITICAL' THEN 1 
      WHEN 'HIGH' THEN 2 
      ELSE 3 
    END,
    t.order_date DESC;

-- Demo Query 4.2: Proactive VIP Customer Outreach List
-- Find Platinum/Gold tier customers with active AI customer risk insights.
GRAPH OperationalInsightsGraph
MATCH (c:Customer)-[i_rel:HAS_INSIGHT]->(ins:CustomerInsight)
WHERE c.tier IN ('PLATINUM', 'GOLD')
RETURN
    c.customer_id,
    c.company AS customer_company,
    c.tier AS vip_tier,
    ins.highest_risk_level AS risk_severity,
    ins.affected_products_count AS products_affected,
    ins.total_spend_at_risk AS revenue_at_risk,
    ins.support_recommendation AS ai_action_plan
ORDER BY ins.total_spend_at_risk DESC;

-- Demo Query 4.3: End-to-End Operational Remediation Tracking
-- Trace from VIP customer down to specific order and product advisory.
GRAPH OperationalInsightsGraph
MATCH (c:Customer)-[t:PURCHASED]->(p:Product)-[r:HAS_ADVISORY]->(a:Advisory)
WHERE a.risk_severity IN ('CRITICAL', 'HIGH')
RETURN
    c.company AS customer,
    c.region AS region,
    t.transaction_id AS order_reference,
    p.product_name AS product,
    t.quantity AS quantity_sold,
    a.advisory_action AS remediation_protocol
ORDER BY c.company, t.order_date;
