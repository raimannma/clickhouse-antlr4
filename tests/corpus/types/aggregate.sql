CAST(x AS AggregateFunction(quantile(0.5), Float64)) + CAST(y AS SimpleAggregateFunction(sum, UInt64))
