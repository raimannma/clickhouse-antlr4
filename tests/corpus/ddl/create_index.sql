CREATE INDEX IF NOT EXISTS idx_name ON db.tbl (lower(name)) TYPE ngrambf_v1(3, 512, 1, 0) GRANULARITY 4
