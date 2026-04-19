SELECT * FROM quotes ASOF LEFT JOIN trades USING (ticker, time)
