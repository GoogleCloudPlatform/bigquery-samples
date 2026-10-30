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
-- PART 0b: BIGQUERY CONSOLE SETUP SCRIPT (DATASET & BASE NODE/EDGE TABLES)
-- ==============================================================================
-- Run this script in BigQuery Studio / CLI to set up the base node and edge
-- tables before presenting the graph demo queries.
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS `kg_demo`;

CREATE OR REPLACE TABLE `kg_demo.products` AS
SELECT
  "FroZone Zenith 5000" AS product_name, "PROD_FZ5000" AS product_id, "Commercial Ice Cream Dispenser" AS category
UNION ALL SELECT "Arctic Swirl 5000", "PROD_AS5000", "Industrial Frozen Yogurt Dispenser"
UNION ALL SELECT "Blizzard Pro 300", "PROD_BP300", "Compact Beverage Chiller"
UNION ALL SELECT "FrostGuard Commercial 2000", "PROD_FGC2000", "Industrial Cold Storage Unit";

-- ------------------------------------------------------------------------------
-- 1. Chunk Engineering PDF Manuals Directly from Cloud Storage (`AI.CHUNK_DOCUMENT`)
-- ------------------------------------------------------------------------------
-- Requires `documentai.googleapis.com` enabled on the project. BigQuery automatically
-- provisions and reuses the `bq-created-layout-parser` Document AI processor.
-- Update the GCS bucket name below if staging manuals in your own project bucket.
CREATE OR REPLACE TABLE `kg_demo.document_chunks` AS
SELECT
  chunk_id,
  start_page,
  end_page,
  content,
  status,
  uri,
  AI.EMBED(content => content, endpoint => 'gemini-embedding-2').result AS embedding
FROM AI.CHUNK_DOCUMENT(
  'gs://<YOUR_PROJECT_ID>-kg-demo-manuals/manuals/*.pdf',
  chunk_size => 500
)
WHERE status = '' AND TRIM(content) != '';

-- ------------------------------------------------------------------------------
-- 2. Extract Knowledge Graph Triples from Document Chunks (`AI.GENERATE`)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE TABLE `kg_demo.extracted_knowledge_graph` AS
WITH RawTriples AS (
  SELECT
    uri AS source_document,
    r.subject,
    r.subject_entity_type,
    r.relationship,
    r.object,
    r.object_entity_type,
    r.confidence
  FROM (
    SELECT
      uri,
      AI.GENERATE(
        '''
        You are a technical manufacturing knowledge graph extractor.
        Extract explicit component and material specifications from the engineering manual chunk.
        Identify the ENTITY TYPE for both subject and object.
        Valid Entity Types: Product, Part, Material.

        ### REQUIRED RELATIONSHIP TYPES (ONLY extract these two):
        * **CONTAINS_PART**: Product -> Part (e.g., 'FroZone Zenith 5000' CONTAINS_PART 'COMP-809')
        * **MADE_OF**: Part -> Material (e.g., 'COMP-809' MADE_OF 'Fiberglass')

        ### NORMALIZATION RULES:
        * Use canonical material names in Title Case: e.g., 'Fiberglass' (not 'Fiberglass Core' or 'fiberglass'), 'Freon-12', 'Copper Alloy C101', 'Stainless Steel 316', 'Titanium Steel', 'R-410A Refrigerant'.
        * If a chunk has no component/material relationships, return an empty relationships array [].

        Document chunk:
        ''' || content,
        output_schema => '''
          relationships ARRAY<STRUCT<
            subject STRING,
            subject_entity_type STRING,
            relationship STRING,
            object STRING,
            object_entity_type STRING,
            confidence FLOAT64
          >>
        ''',
        endpoint => 'gemini-3.8-flash'
      ) AS extracted_data
    FROM `kg_demo.document_chunks`
  ),
  UNNEST(extracted_data.relationships) AS r
  WHERE r.subject IS NOT NULL
    AND r.object IS NOT NULL
    AND r.relationship IN ('CONTAINS_PART', 'MADE_OF')
)
SELECT
  subject,
  ANY_VALUE(subject_entity_type) AS subject_entity_type,
  relationship,
  object,
  ANY_VALUE(object_entity_type) AS object_entity_type,
  MAX(confidence) AS confidence,
  ANY_VALUE(source_document) AS source_document
FROM RawTriples
GROUP BY subject, relationship, object;

-- ------------------------------------------------------------------------------
-- 3. Create Graph Node & Edge Views
-- ------------------------------------------------------------------------------

CREATE OR REPLACE VIEW `kg_demo.part_nodes` AS
SELECT DISTINCT part_id AS part_name, 'Part' AS type
FROM
  (
    SELECT subject AS part_id
    FROM `kg_demo.extracted_knowledge_graph`
    WHERE subject_entity_type = 'Part'
    UNION DISTINCT
    SELECT object AS part_id
    FROM `kg_demo.extracted_knowledge_graph`
    WHERE object_entity_type = 'Part'
  )
WHERE part_id IS NOT NULL;

CREATE OR REPLACE VIEW `kg_demo.material_nodes` AS
SELECT DISTINCT object AS material_name, 'Material' AS type
FROM `kg_demo.extracted_knowledge_graph`
WHERE object_entity_type = 'Material' AND object IS NOT NULL;

CREATE OR REPLACE VIEW `kg_demo.edges_product_contains` AS
SELECT DISTINCT
  p.product_name AS product_name,
  ekg.object AS part_name
FROM `kg_demo.extracted_knowledge_graph` ekg
JOIN `kg_demo.products` p
  ON ekg.subject = p.product_name
WHERE ekg.relationship = 'CONTAINS_PART';

CREATE OR REPLACE VIEW `kg_demo.edges_part_material` AS
SELECT DISTINCT
  subject AS part_name,
  object AS material_name
FROM `kg_demo.extracted_knowledge_graph`
WHERE relationship = 'MADE_OF';

-- ------------------------------------------------------------------------------
-- 4. Materialize Node Embeddings for Semantic Search -> Graph Traversal
-- ------------------------------------------------------------------------------
-- `VECTOR_SEARCH` requires a materialized base table rather than a view.
CREATE OR REPLACE TABLE `kg_demo.part_node_embeddings` AS
SELECT
  part_name,
  type,
  AI.EMBED(content => part_name, endpoint => 'gemini-embedding-2').result AS embedding
FROM `kg_demo.part_nodes`
WHERE TRIM(part_name) != '';

