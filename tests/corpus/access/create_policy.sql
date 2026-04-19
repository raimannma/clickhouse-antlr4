CREATE ROW POLICY p1 ON db.t AS PERMISSIVE FOR SELECT USING tenant_id = currentTenant() TO analyst
