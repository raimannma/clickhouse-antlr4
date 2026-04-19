SELECT k, count(*) FROM t GROUP BY k HAVING count(*) > 10 ORDER BY k
