SELECT a, b FROM (SELECT id AS a, name AS b FROM t WHERE active) s WHERE a > 0
