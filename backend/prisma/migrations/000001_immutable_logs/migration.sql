-- Prisma can create the base schema from prisma/schema.prisma.
-- This migration adds a database-level guard for the immutable audit table.
CREATE OR REPLACE FUNCTION prevent_shipment_logs_update_or_delete()
RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'shipment_logs is immutable and cannot be updated or deleted';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS shipment_logs_no_update ON shipment_logs;
CREATE TRIGGER shipment_logs_no_update
BEFORE UPDATE OR DELETE ON shipment_logs
FOR EACH ROW EXECUTE FUNCTION prevent_shipment_logs_update_or_delete();
