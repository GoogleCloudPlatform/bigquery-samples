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
  pdf_data.sentiment AS customer_sentiment,
  pdf_data.reason AS extracted_reason
FROM (
  SELECT
    uri,
    AI.GENERATE(
      ('Read this return authorization slip and extract the sentiment (POSITIVE, NEUTRAL, or NEGATIVE) and the reason (a short 2-3 word phrase describing the return reason, like "Wrong Size" or "Defective").', ref),
      endpoint => 'gemini-3.8-flash',
      connection_id => 'us.bff',
      output_schema => 'sentiment STRING, reason STRING'
    ).*
  FROM `bff.return_pdfs`
) AS pdf_data;