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


SELECT *,
  -- This lets you color-code historical data vs. future predictions in the next step
  CONCAT(product_name, ' - ', time_series_type) AS product_phase
FROM (
  SELECT *
  FROM AI.FORECAST(
    TABLE `bff.daily_sales_timeseries`,
    horizon => 30,
    timestamp_col => 'purchase_date',
    data_col => 'total_shoes_sold',
    id_cols => ['product_name'],
    output_historical_time_series => TRUE
  )
)
-- Zoom in: Only show the last 90 days of history + the new 30-day forecast
WHERE CAST(time_series_timestamp AS DATE) >= DATE_SUB((SELECT MAX(purchase_date) FROM `bff.daily_sales_timeseries`), INTERVAL 90 DAY)