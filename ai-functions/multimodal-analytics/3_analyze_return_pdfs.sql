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
  JSON_VALUE(ml_generate_text_llm_result, '$.sentiment') AS customer_sentiment,
  JSON_VALUE(ml_generate_text_llm_result, '$.reason') AS extracted_reason
FROM ML.GENERATE_TEXT(
  MODEL `bff.gemini_flash`,
  TABLE `bff.return_pdfs`,
  STRUCT(
    'Read this return authorization slip. Return a valid JSON object with exactly two keys: "sentiment" (value must be POSITIVE, NEUTRAL, or NEGATIVE) and "reason" (a short 2-3 word phrase describing the return reason, like "Wrong Size" or "Defective"). Do not include any markdown formatting.' AS prompt,
    TRUE AS flatten_json_output,
    0.0 AS temperature
  )
);