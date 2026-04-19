CAST('a' AS String) + CAST('it''s' AS String) + CAST(x'DEADBEEF' AS String) + CAST(b'1010' AS String) + CAST($$plain$$ AS String) + CAST($tag$payload with $ signs$tag$ AS String)
