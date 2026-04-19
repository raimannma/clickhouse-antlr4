PREPARE get_user AS SELECT * FROM users WHERE id = {pid:UInt64}
