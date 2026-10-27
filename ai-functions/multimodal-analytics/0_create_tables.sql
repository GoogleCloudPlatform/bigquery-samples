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

-- 1. Create the Object Table for the Sneaker Images
CREATE OR REPLACE EXTERNAL TABLE `bff.return_images`
WITH CONNECTION `us.bff`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://sample-data-and-media/retail-shoes/sneaker_returns/images/*']
);

-- 2. Create the Object Table for the PDF Return Slips
CREATE OR REPLACE EXTERNAL TABLE `bff.return_pdfs`
WITH CONNECTION `us.bff`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://sample-data-and-media/retail-shoes/sneaker_returns/pdfs/*']
);

-- 3. Load the structured transactions data
LOAD DATA OVERWRITE `bff.transactions`
FROM FILES (
  format = 'CSV',
  uris = ['gs://sample-data-and-media/retail-shoes/transactions/transactions.csv']
);
