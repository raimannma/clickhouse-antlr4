SELECT x, row_number() OVER (PARTITION BY g ORDER BY t) AS rn FROM t QUALIFY rn = 1
