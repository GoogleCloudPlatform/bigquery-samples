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

CREATE OR REPLACE TABLE `bff.pdf_insights`
OPTIONS (
  labels = [('goog-yardstick-devrel', '565014385')]
) AS
SELECT
  REGEXP_EXTRACT(uri, r'(RET-\d+)') AS return_id,
  sentiment AS customer_sentiment,
  reason AS extracted_reason
FROM AI.GENERATE_TABLE(
  MODEL `bff.gemini_flash`,
  (
    SELECT
      uri,
      (uri, 'Read this return authorization slip and extract the sentiment (POSITIVE, NEUTRAL, or NEGATIVE) and the reason (a short 2-3 word phrase describing the return reason, like "Wrong Size" or "Defective").') AS prompt
    FROM `bff.return_pdfs`
  ),
  STRUCT(
    'sentiment STRING, reason STRING' AS output_schema
  )
);