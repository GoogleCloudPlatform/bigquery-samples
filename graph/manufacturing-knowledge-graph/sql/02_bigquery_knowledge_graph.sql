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
-- PART 2: BIGQUERY ANALYTICAL KNOWLEDGE GRAPH STATEMENTS (05:00 - 11:00)
-- ==============================================================================
-- Prerequisite:
-- Run `./setup_demo.sh` first to create the BigQuery dataset `kg_demo` and
-- stand up the base node and edge tables (`products`, `part_nodes`, `material_nodes`, etc.).
--
-- This script defines the BigQuery Property Graph (`kg_demo.manufacturing_kg`)
-- and runs GQL pattern matching queries to discover hazardous materials.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Define the BigQuery Property Graph (`manufacturing_kg`)
-- ------------------------------------------------------------------------------

CREATE OR REPLACE PROPERTY GRAPH `kg_demo.manufacturing_kg`
  NODE TABLES (
    `kg_demo.products` AS product_node KEY (product_name) LABEL Product PROPERTIES (product_name, product_id, category),
    `kg_demo.part_nodes` AS part_node KEY (part_name) LABEL Part PROPERTIES (part_name, type),
    `kg_demo.material_nodes` AS material_node KEY (material_name) LABEL Material PROPERTIES (material_name, type)
  )
  EDGE TABLES (
    `kg_demo.edges_product_contains` AS product_parts KEY (product_name, part_name)
      SOURCE KEY (product_name) REFERENCES product_node
      DESTINATION KEY (part_name) REFERENCES part_node
      LABEL CONTAINS_PART,

    `kg_demo.edges_part_material` AS part_materials KEY (part_name, material_name)
      SOURCE KEY (part_name) REFERENCES part_node
      DESTINATION KEY (material_name) REFERENCES material_node
      LABEL IS_MADE_OF
  );

-- ==============================================================================
-- DEMO QUERIES: BIGQUERY KNOWLEDGE GRAPH EXPLORATION
-- ==============================================================================

-- Demo Query 2.1: Discover product-part-material bill of materials (BOM)
GRAPH `kg_demo.manufacturing_kg`
MATCH (p:Product)-[e:CONTAINS_PART]->(pt:Part)-[m:IS_MADE_OF]->(mat:Material)
RETURN
  p.product_name AS product,
  pt.part_name AS part,
  mat.material_name AS material
ORDER BY product, part;

-- Demo Query 2.2: Identify products containing hazardous or restricted materials
-- (e.g., Fiberglass or Freon-12)
GRAPH `kg_demo.manufacturing_kg`
MATCH (p:Product)-[:CONTAINS_PART]->(pt:Part)-[:IS_MADE_OF]->(mat:Material)
WHERE mat.material_name IN ('Fiberglass', 'Freon-12')
RETURN DISTINCT
  p.product_id,
  p.product_name,
  pt.part_name AS affected_part,
  mat.material_name AS hazard_material
ORDER BY product_name;

-- ==============================================================================
-- GRAPHRAG QUERIES: SEMANTIC VECTOR SEARCH -> MULTI-HOP GRAPH TRAVERSAL
-- ==============================================================================

-- Demo Query 2.3: Node-Level Semantic Search -> Multi-Hop Graph Traversal
-- Find the top-3 Part nodes semantically matching a natural-language query, then
-- traverse upstream to Products and downstream to Materials in `manufacturing_kg`.
SELECT
  hits.base.part_name AS matched_seed_part,
  ROUND(hits.distance, 4) AS cosine_distance,
  g.product_id,
  g.product_name,
  g.material_name
FROM VECTOR_SEARCH(
  TABLE `kg_demo.part_node_embeddings`,
  'embedding',
  (
    SELECT AI.EMBED(
      content => 'refrigeration cooling compressor unit',
      endpoint => 'gemini-embedding-2'
    ).result AS embedding
  ),
  top_k => 3,
  distance_type => 'COSINE'
) AS hits
JOIN GRAPH_TABLE(
  `kg_demo.manufacturing_kg`
  MATCH (p:Product)-[:CONTAINS_PART]->(pt:Part)-[:IS_MADE_OF]->(m:Material)
  COLUMNS (p.product_id, p.product_name, pt.part_name, m.material_name)
) AS g
  ON hits.base.part_name = g.part_name
ORDER BY cosine_distance ASC, g.product_name;

-- Demo Query 2.4: Chunk-Level Semantic Search (`AI.CHUNK_DOCUMENT`) -> Cross-Product Graph Blast Radius
-- Search unstructured troubleshooting prose chunks for a field symptom ("abnormal compressor
-- vibration and oil mist leakage"), map the top matching manual chunk to its Product node,
-- and traverse `Product -> Part -> Material <- Part <- Product` to find OTHER product lines
-- in the fleet that share the same underlying material!
WITH TopChunks AS (
  SELECT
    base.uri AS source_document,
    base.chunk_id,
    SUBSTR(base.content, 1, 160) AS chunk_snippet,
    distance
  FROM VECTOR_SEARCH(
    TABLE `kg_demo.document_chunks`,
    'embedding',
    (
      SELECT AI.EMBED(
        content => 'abnormal compressor vibration and oil mist leakage at high temperature',
        endpoint => 'gemini-embedding-2'
      ).result AS embedding
    ),
    top_k => 2,
    distance_type => 'COSINE'
  )
),
SeedProducts AS (
  SELECT
    ekg.subject AS seed_product,
    ANY_VALUE(tc.chunk_id) AS matched_chunk_id,
    ANY_VALUE(tc.chunk_snippet) AS chunk_snippet,
    MIN(tc.distance) AS chunk_distance
  FROM TopChunks tc
  JOIN `kg_demo.extracted_knowledge_graph` ekg
    ON tc.source_document = ekg.source_document
    OR ENDS_WITH(tc.source_document, '/' || ekg.source_document)
  WHERE ekg.subject_entity_type = 'Product'
  GROUP BY ekg.subject
)
SELECT DISTINCT
  sp.seed_product,
  sp.matched_chunk_id,
  ROUND(sp.chunk_distance, 4) AS chunk_distance,
  g.part_name AS seed_part,
  g.material_name AS shared_material,
  g.other_affected_product
FROM SeedProducts sp
JOIN GRAPH_TABLE(
  `kg_demo.manufacturing_kg`
  MATCH (p:Product)-[:CONTAINS_PART]->(pt:Part)-[:IS_MADE_OF]->(m:Material)<-[:IS_MADE_OF]-(:Part)<-[:CONTAINS_PART]-(p2:Product)
  WHERE p.product_name != p2.product_name
  COLUMNS (
    p.product_name AS seed_product,
    pt.part_name,
    m.material_name,
    p2.product_name AS other_affected_product
  )
) AS g
  ON sp.seed_product = g.seed_product
ORDER BY chunk_distance ASC, shared_material, other_affected_product;

