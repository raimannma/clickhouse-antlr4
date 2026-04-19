count(DISTINCT x) + sum(y) FILTER (WHERE y > 0) + avg(z) OVER (PARTITION BY p ORDER BY t ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) + quantile(0.5)(x) + quantileIf(0.9)(x, x > 10)
