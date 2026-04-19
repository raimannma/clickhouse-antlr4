SELECT a, b, count(*) FROM t GROUP BY GROUPING SETS ((a, b), (a), ())
