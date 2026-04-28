-- CreateEnum
CREATE TYPE "TransportAssignmentStatus" AS ENUM ('ASSIGNED', 'ENROUTE', 'ARRIVED', 'COMPLETED');

-- CreateTable
CREATE TABLE "transport_assignments" (
    "id" TEXT NOT NULL,
    "shipment_id" TEXT NOT NULL,
    "transporter_id" TEXT,
    "truck_id" TEXT,
    "driver_name" TEXT,
    "driver_phone" TEXT,
    "dispatch_time" TIMESTAMP(3),
    "expected_arrival_time" TIMESTAMP(3),
    "actual_arrival_time" TIMESTAMP(3),
    "status" "TransportAssignmentStatus" NOT NULL DEFAULT 'ASSIGNED',
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transport_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "transport_assignments_shipment_id_key" ON "transport_assignments"("shipment_id");

-- CreateIndex
CREATE INDEX "transport_assignments_shipment_id_status_idx" ON "transport_assignments"("shipment_id", "status");

-- CreateIndex
CREATE INDEX "transport_assignments_transporter_id_idx" ON "transport_assignments"("transporter_id");

-- CreateIndex
CREATE INDEX "transport_assignments_dispatch_time_idx" ON "transport_assignments"("dispatch_time");

-- AddForeignKey
ALTER TABLE "transport_assignments" ADD CONSTRAINT "transport_assignments_shipment_id_fkey" FOREIGN KEY ("shipment_id") REFERENCES "shipments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transport_assignments" ADD CONSTRAINT "transport_assignments_transporter_id_fkey" FOREIGN KEY ("transporter_id") REFERENCES "shipment_participants"("id") ON DELETE SET NULL ON UPDATE CASCADE;
