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

CREATE OR REPLACE TABLE `bff.daily_sales_timeseries`
OPTIONS (
  labels = [('goog-yardstick-devrel', '565014385')]
) AS
SELECT
  purchase_date,
  product_name,
  COUNT(transaction_id) AS total_shoes_sold
FROM
  `bff.transactions`
WHERE
  product_name != 'Fast Forward High-Top'  -- Filtering out the defective shoe
GROUP BY
  purchase_date,
  product_name
ORDER BY
  purchase_date ASC;