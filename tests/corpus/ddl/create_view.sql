CREATE VIEW daily AS SELECT toDate(ts) AS d, count() FROM events GROUP BY d
