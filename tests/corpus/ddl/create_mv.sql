CREATE MATERIALIZED VIEW mv TO target ENGINE = SummingMergeTree() ORDER BY k AS SELECT k, sum(v) AS v FROM src GROUP BY k
