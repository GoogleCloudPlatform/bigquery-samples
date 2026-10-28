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
  pdf.extracted_reason,
  COUNT(t.transaction_id) AS total_returns
FROM
  `bff.transactions` t
JOIN
  `bff.pdf_insights` pdf
  ON t.return_id = pdf.return_id
WHERE 
  t.product_name = 'BFF Sole-Mate Low'
GROUP BY
  t.product_name,
  pdf.extracted_reason
ORDER BY
  total_returns DESC;