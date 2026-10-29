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
-- PART 1: CLOUD SPANNER OPERATIONAL & TRANSACTIONAL GRAPH STATEMENTS (00:00 - 05:00)
-- ==============================================================================
-- Prerequisite:
-- Run `./setup_demo.sh` first to create the Spanner database and tables
-- (`Customers`, `Products`, `Transactions`) and insert the sample records.
--
-- This script defines the Spanner Property Graph (`TransactionalGraph`)
-- and executes GQL pattern matching queries over live transactions.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Define the Spanner Property Graph (`TransactionalGraph`)
-- ------------------------------------------------------------------------------

CREATE OR REPLACE PROPERTY GRAPH TransactionalGraph
  NODE TABLES (
    Customers AS Customer
      KEY (customer_id)
      LABEL Customer
      PROPERTIES (customer_id, company, tier, annual_support_allowance, region),
    Products AS Product
      KEY (product_id)
      LABEL Product
      PROPERTIES (product_id, product_name, category, unit_price, status)
  )
  EDGE TABLES (
    Transactions AS PURCHASED
      KEY (transaction_id)
      SOURCE KEY (customer_id) REFERENCES Customer (customer_id)
      DESTINATION KEY (product_id) REFERENCES Product (product_id)
      LABEL PURCHASED
      PROPERTIES (transaction_id, order_date, quantity, total_amount, status)
  );

-- ------------------------------------------------------------------------------
-- 2. DEMO QUERIES: LIVE TRANSACTIONAL GRAPH IN CLOUD SPANNER
-- ------------------------------------------------------------------------------

-- Demo Query 1.1: Explore recent customer purchases via Spanner Graph GQL
-- Run this in Cloud Spanner Studio / CLI:
GRAPH TransactionalGraph
MATCH (c:Customer)-[t:PURCHASED]->(p:Product)
RETURN
    c.company AS customer_company,
    c.tier AS customer_tier,
    t.order_date AS transaction_date,
    p.product_name AS purchased_product,
    t.quantity AS quantity_ordered,
    t.total_amount AS total_spend
ORDER BY t.order_date DESC;

-- Demo Query 1.2: Aggregate spend per customer using GQL pattern matching
GRAPH TransactionalGraph
MATCH (c:Customer)-[t:PURCHASED]->(p:Product)
RETURN
    c.customer_id,
    c.company,
    COUNT(t.transaction_id) AS total_orders,
    SUM(t.total_amount) AS total_revenue
GROUP BY c.customer_id, c.company
ORDER BY total_revenue DESC;

-- Demo Query 1.3: Analyze product adoption across customer regions
GRAPH TransactionalGraph
MATCH (c:Customer)-[t:PURCHASED]->(p:Product)
WHERE c.region IN ('US-WEST', 'US-CENTRAL')
RETURN
    c.region AS customer_region,
    p.product_name AS product_model,
    SUM(t.quantity) AS total_units_sold,
    SUM(t.total_amount) AS regional_revenue
GROUP BY c.region, p.product_name
ORDER BY c.region, regional_revenue DESC;
