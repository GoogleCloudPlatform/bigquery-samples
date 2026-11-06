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
-- PART 0: SPANNER CONSOLE SETUP SCRIPT (SCHEMA, DATA & PROPERTY GRAPHS)
-- ==============================================================================
-- Run this script in Google Cloud Spanner Studio / CLI to set up all tables,
-- insert sample records, and define the Spanner Property Graphs before
-- presenting the demo queries.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Create Tables (OLTP Transactional Schema & Reverse ETL Destination Tables)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Customers (
    customer_id STRING(36) NOT NULL,
    company STRING(100) NOT NULL,
    contact_name STRING(100),
    email STRING(100),
    tier STRING(20),
    annual_support_allowance FLOAT64,
    region STRING(20)
) PRIMARY KEY (customer_id);

CREATE TABLE IF NOT EXISTS Products (
    product_id STRING(36) NOT NULL,
    product_name STRING(100) NOT NULL,
    category STRING(100),
    unit_price FLOAT64,
    release_year INT64,
    status STRING(20)
) PRIMARY KEY (product_id);

CREATE TABLE IF NOT EXISTS Transactions (
    transaction_id STRING(36) NOT NULL,
    customer_id STRING(36) NOT NULL,
    product_id STRING(36) NOT NULL,
    order_date TIMESTAMP NOT NULL,
    quantity INT64 NOT NULL,
    total_amount FLOAT64 NOT NULL,
    status STRING(20),
    CONSTRAINT FK_Transactions_Customer FOREIGN KEY (customer_id) REFERENCES Customers (customer_id),
    CONSTRAINT FK_Transactions_Product FOREIGN KEY (product_id) REFERENCES Products (product_id)
) PRIMARY KEY (transaction_id);

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
-- 2. Insert Sample Data into OLTP Tables
-- ------------------------------------------------------------------------------

INSERT INTO Customers (customer_id, company, contact_name, email, tier, annual_support_allowance, region)
VALUES
    ('CUST_001', 'Royal Soft Serve', 'Alice Henderson', 'a.henderson@royalsoftserve.com', 'PLATINUM', 120000.0, 'US-WEST'),
    ('CUST_002', 'Freeze King Corp', 'Bob Vance', 'bvance@freezeking.com', 'GOLD', 85000.0, 'US-EAST'),
    ('CUST_003', 'Arctic Ice Cream Express', 'Carol Danvers', 'cdanvers@arcticicecream.com', 'PLATINUM', 150000.0, 'US-CENTRAL'),
    ('CUST_004', 'ColdChain Logistics', 'David Miller', 'dmiller@coldchainlog.com', 'SILVER', 45000.0, 'EU-WEST'),
    ('CUST_005', 'Polar Breeze Bakeries', 'Elena Rostova', 'erostova@polarbreeze.com', 'GOLD', 75000.0, 'US-WEST');

INSERT INTO Products (product_id, product_name, category, unit_price, release_year, status)
VALUES
    ('PROD_FZ5000', 'FroZone Zenith 5000', 'Commercial Ice Cream Dispenser', 12500.0, 2023, 'ACTIVE'),
    ('PROD_AS5000', 'Arctic Swirl 5000', 'Industrial Frozen Yogurt Dispenser', 14200.0, 2024, 'ACTIVE'),
    ('PROD_BP300', 'Blizzard Pro 300', 'Compact Beverage Chiller', 6800.0, 2022, 'ACTIVE'),
    ('PROD_FGC2000', 'FrostGuard Commercial 2000', 'Industrial Cold Storage Unit', 28000.0, 2023, 'ACTIVE');

INSERT INTO Transactions (transaction_id, customer_id, product_id, order_date, quantity, total_amount, status)
VALUES
    ('TXN_10001', 'CUST_001', 'PROD_FZ5000', '2025-11-15T10:30:00Z', 3, 37500.0, 'COMPLETED'),
    ('TXN_10002', 'CUST_001', 'PROD_AS5000', '2026-01-20T14:15:00Z', 2, 28400.0, 'COMPLETED'),
    ('TXN_10003', 'CUST_002', 'PROD_AS5000', '2026-02-10T09:00:00Z', 5, 71000.0, 'COMPLETED'),
    ('TXN_10004', 'CUST_003', 'PROD_FZ5000', '2026-03-05T16:45:00Z', 4, 50000.0, 'COMPLETED'),
    ('TXN_10005', 'CUST_003', 'PROD_FGC2000', '2026-04-12T11:20:00Z', 1, 28000.0, 'COMPLETED'),
    ('TXN_10006', 'CUST_004', 'PROD_BP300', '2026-05-18T13:10:00Z', 10, 68000.0, 'COMPLETED'),
    ('TXN_10007', 'CUST_005', 'PROD_FZ5000', '2026-06-22T15:30:00Z', 2, 25000.0, 'COMPLETED');

-- ------------------------------------------------------------------------------
-- 3. Define the Spanner Property Graphs
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
