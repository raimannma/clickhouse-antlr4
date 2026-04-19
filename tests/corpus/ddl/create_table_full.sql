CREATE TABLE IF NOT EXISTS db.events ON CLUSTER 'mycluster' (
    id UInt64 CODEC(Delta, LZ4),
    name String DEFAULT 'anon' COMMENT 'user display name',
    ts DateTime64(6, 'UTC') MATERIALIZED now(),
    data JSON,
    INDEX idx_name name TYPE bloom_filter GRANULARITY 3,
    PROJECTION proj_by_day (SELECT * ORDER BY toDate(ts)),
    CONSTRAINT ck_name_len CHECK length(name) < 256,
    PRIMARY KEY (id)
) ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/events', '{replica}')
  PARTITION BY toYYYYMM(ts)
  ORDER BY (id, ts)
  TTL ts + INTERVAL 30 DAY DELETE
  SETTINGS index_granularity = 8192
  COMMENT 'primary event store'
