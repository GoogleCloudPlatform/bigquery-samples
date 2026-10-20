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

-- Dataset for the BigQuery Graph Measures codelab: five tables, fictional music catalog.
-- setup.sh runs this file. Safe to re-run (CREATE OR REPLACE).
CREATE SCHEMA IF NOT EXISTS music OPTIONS (location = 'US');

CREATE OR REPLACE TABLE music.Labels (
  label_id INT64, label_name STRING, marketing_budget FLOAT64,
  PRIMARY KEY (label_id) NOT ENFORCED
);
INSERT INTO music.Labels (label_id, label_name, marketing_budget) VALUES
  (1, 'Cymbal Records', 5000000.0),
  (2, 'Northwind Audio', 3000000.0);

CREATE OR REPLACE TABLE music.Artists (
  artist_id INT64, artist_name STRING, label_id INT64,
  PRIMARY KEY (artist_id) NOT ENFORCED
);
INSERT INTO music.Artists (artist_id, artist_name, label_id) VALUES
  (10, 'Ava Sterling', 1),
  (11, 'Mina Okafor', 1),
  (12, 'Kai Nakamura', 2);

CREATE OR REPLACE TABLE music.Songs (
  song_id INT64, title STRING, artist_id INT64, streams INT64,
  PRIMARY KEY (song_id) NOT ENFORCED
);
INSERT INTO music.Songs (song_id, title, artist_id, streams) VALUES
  (100, 'Neon Summer', 10, 2000000000),
  (101, 'Paper Crown', 10, 1500000000),
  (102, 'Double Shot', 11, 1200000000),
  (103, 'Midnight Drive', 12, 4500000000),
  (104, 'Slow Arrow', 10, 400000000);

CREATE OR REPLACE TABLE music.Playlists (
  playlist_id INT64, playlist_name STRING, followers INT64,
  PRIMARY KEY (playlist_id) NOT ENFORCED
);
INSERT INTO music.Playlists (playlist_id, playlist_name, followers) VALUES
  (200, 'Hot Right Now', 35000000),
  (201, 'Road Trip', 5000000),
  (202, 'Gym Pump', 3000000),
  (203, 'Rising Pop', 2000000);

CREATE OR REPLACE TABLE music.PlaylistEntries (
  entry_id INT64, playlist_id INT64, song_id INT64,
  PRIMARY KEY (entry_id) NOT ENFORCED
);
INSERT INTO music.PlaylistEntries (entry_id, playlist_id, song_id) VALUES
  (1, 200, 100),
  (2, 201, 100),
  (3, 202, 100),
  (4, 203, 100),
  (5, 200, 101),
  (6, 203, 101),
  (7, 200, 102),
  (8, 202, 103),
  (9, 201, 103),
  (10, 201, 104);
