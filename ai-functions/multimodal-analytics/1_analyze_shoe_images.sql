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

CREATE OR REPLACE TABLE `bff.image_insights`
OPTIONS (
  labels = [('goog-yardstick-devrel', '565014385')]
) AS
SELECT
  REGEXP_EXTRACT(uri, r'(RET-\d+)') AS return_id,
  AI.GENERATE(
    ('You are a QA inspector for Best Foot Forward. Look at this image of a returned sneaker. What is the primary visible defect? Choose exactly one from this list: [Sole Separation, Scuffed/Dirty, No Defect]. Respond with just the category name.', ref),
    endpoint => 'gemini-3.8-flash',
    connection_id => 'us.bff'
  ).result AS defect_category
FROM `bff.return_images`;