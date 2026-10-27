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

SELECT
  t.product_name,
  img.defect_category,
  COUNT(t.transaction_id) as total_returns
FROM
  `bff.transactions` t
JOIN
  `bff.image_insights` img
  ON t.return_id = img.return_id
GROUP BY
  t.product_name,
  img.defect_category
ORDER BY
  total_returns DESC;