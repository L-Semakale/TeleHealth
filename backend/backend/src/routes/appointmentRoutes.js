import express from "express";
import { prisma } from "../services/prisma.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { throwError } from "../utils/errors.js";

const router = express.Router();
const PAGE_SIZE = 20;

function mapAppointment(a) {
  return {
    appointment_id: a.id,
    id: a.id,
    patient_id: a.patientId,
    patient_anonymous_id: a.patient?.anonymousId ?? "",
    provider_id: a.providerId,
    provider_name: a.provider?.fullName ?? "",
    facility_id: a.facilityId,
    facility_name: a.facility?.name ?? null,
    facility_address: a.facility?.address ?? null,
    scheduled_at: a.scheduledAt,
    duration: a.duration,
    status: a.status,
    type: a.type,
    notes: a.notes,
    created_at: a.createdAt,
    updated_at: a.updatedAt,
  };
}

// Get available providers with their schedules
router.get(
  "/providers/available",
  asyncHandler(async (req, res) => {
    const { date } = req.query;
    const targetDate = date ? new Date(date) : new Date();
    const dayOfWeek = targetDate.getDay();

    const providers = await prisma.user.findMany({
      where: { role: "provider", isActive: true },
      include: {
        providerSchedules: {
          where: { dayOfWeek, isAvailable: true },
        },
        providerAppointments: {
          where: {
            scheduledAt: {
              gte: new Date(targetDate.setHours(0, 0, 0, 0)),
              lt: new Date(targetDate.setHours(23, 59, 59, 999)),
            },
            status: { in: ["scheduled", "confirmed"] },
          },
        },
      },
    });

    const mapped = providers.map((p) => ({
      provider_id: p.id,
      full_name: p.fullName,
      anonymous_id: p.anonymousId,
      schedules: p.providerSchedules.map((s) => ({
        schedule_id: s.id,
        day_of_week: s.dayOfWeek,
        start_time: s.startTime,
        end_time: s.endTime,
      })),
      booked_slots: p.providerAppointments.map((a) => ({
        scheduled_at: a.scheduledAt,
        duration: a.duration,
      })),
    }));

    res.status(200).json({ providers: mapped });
  })
);

// Get patient's appointments
router.get(
  "/my-appointments",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "patient") {
      throw throwError("FORBIDDEN", "Only patients can access this endpoint", 403);
    }

    const page = Math.max(1, Number(req.query.page || 1));
    const skip = (page - 1) * PAGE_SIZE;
    const status = req.query.status;

    const where = {
      patientId: req.user.id,
      ...(status ? { status } : {}),
    };

    const [appointments, total] = await Promise.all([
      prisma.appointment.findMany({
        where,
        orderBy: { scheduledAt: "desc" },
        skip,
        take: PAGE_SIZE,
        include: {
          provider: { select: { fullName: true, anonymousId: true } },
          facility: { select: { name: true, address: true, phone: true } },
        },
      }),
      prisma.appointment.count({ where }),
    ]);

    res.status(200).json({
      appointments: appointments.map(mapAppointment),
      total,
      page,
      pages: Math.ceil(total / PAGE_SIZE),
    });
  })
);

// Get provider's appointments
router.get(
  "/provider-appointments",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") {
      throw throwError("FORBIDDEN", "Only providers can access this endpoint", 403);
    }

    const page = Math.max(1, Number(req.query.page || 1));
    const skip = (page - 1) * PAGE_SIZE;
    const status = req.query.status;

    const where = {
      providerId: req.user.id,
      ...(status ? { status } : {}),
    };

    const [appointments, total] = await Promise.all([
      prisma.appointment.findMany({
        where,
        orderBy: { scheduledAt: "desc" },
        skip,
        take: PAGE_SIZE,
        include: {
          patient: { select: { anonymousId: true } },
          facility: { select: { name: true, address: true } },
        },
      }),
      prisma.appointment.count({ where }),
    ]);

    res.status(200).json({
      appointments: appointments.map(mapAppointment),
      total,
      page,
      pages: Math.ceil(total / PAGE_SIZE),
    });
  })
);

// Book an appointment
router.post(
  "/",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "patient") {
      throw throwError("FORBIDDEN", "Only patients can book appointments", 403);
    }

    const { provider_id, facility_id, scheduled_at, duration = 30, type = "in_person", notes } = req.body;

    if (!provider_id || !scheduled_at) {
      throw throwError("INVALID_INPUT", "Provider and scheduled time are required", 400);
    }

    const scheduledDate = new Date(scheduled_at);
    if (isNaN(scheduledDate.getTime()) || scheduledDate < new Date()) {
      throw throwError("INVALID_INPUT", "Invalid or past scheduled time", 400);
    }

    // Verify provider exists and is active
    const provider = await prisma.user.findFirst({
      where: { id: provider_id, role: "provider", isActive: true },
    });
    if (!provider) {
      throw throwError("PROVIDER_NOT_FOUND", "Provider not found or inactive", 404);
    }

    // Check for conflicts
    const conflict = await prisma.appointment.findFirst({
      where: {
        providerId: provider_id,
        scheduledAt: scheduledDate,
        status: { in: ["scheduled", "confirmed"] },
      },
    });
    if (conflict) {
      throw throwError("SLOT_UNAVAILABLE", "This time slot is already booked", 409);
    }

    // Verify facility if provided
    if (facility_id) {
      const facility = await prisma.facility.findFirst({
        where: { id: facility_id, isActive: true },
      });
      if (!facility) {
        throw throwError("FACILITY_NOT_FOUND", "Facility not found", 404);
      }
    }

    const appointment = await prisma.appointment.create({
      data: {
        patientId: req.user.id,
        providerId: provider_id,
        facilityId: facility_id || null,
        scheduledAt: scheduledDate,
        duration,
        type,
        notes: notes || null,
        status: "scheduled",
      },
      include: {
        provider: { select: { fullName: true, anonymousId: true } },
        facility: { select: { name: true, address: true, phone: true } },
        patient: { select: { anonymousId: true } },
      },
    });

    res.status(201).json({
      message: "Appointment booked successfully",
      appointment: mapAppointment(appointment),
    });
  })
);

// Cancel an appointment (patient can cancel their own, provider can cancel theirs)
router.put(
  "/:appointment_id/cancel",
  asyncHandler(async (req, res) => {
    const { appointment_id } = req.params;
    const { reason } = req.body;

    const appointment = await prisma.appointment.findUnique({
      where: { id: appointment_id },
    });

    if (!appointment) {
      throw throwError("NOT_FOUND", "Appointment not found", 404);
    }

    // Check authorization
    if (req.user.role === "patient" && appointment.patientId !== req.user.id) {
      throw throwError("FORBIDDEN", "Cannot cancel another patient's appointment", 403);
    }
    if (req.user.role === "provider" && appointment.providerId !== req.user.id) {
      throw throwError("FORBIDDEN", "Cannot cancel another provider's appointment", 403);
    }

    if (appointment.status === "cancelled") {
      throw throwError("ALREADY_CANCELLED", "Appointment is already cancelled", 400);
    }

    if (appointment.status === "completed") {
      throw throwError("ALREADY_COMPLETED", "Cannot cancel a completed appointment", 400);
    }

    const updated = await prisma.appointment.update({
      where: { id: appointment_id },
      data: {
        status: "cancelled",
        notes: reason ? `${appointment.notes || ""}\n[Cancelled]: ${reason}`.trim() : appointment.notes,
      },
    });

    res.status(200).json({
      message: "Appointment cancelled successfully",
      appointment_id: updated.id,
      status: updated.status,
    });
  })
);

// Confirm an appointment (provider only)
router.put(
  "/:appointment_id/confirm",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") {
      throw throwError("FORBIDDEN", "Only providers can confirm appointments", 403);
    }

    const { appointment_id } = req.params;

    const appointment = await prisma.appointment.findUnique({
      where: { id: appointment_id },
    });

    if (!appointment || appointment.providerId !== req.user.id) {
      throw throwError("NOT_FOUND", "Appointment not found", 404);
    }

    if (appointment.status !== "scheduled") {
      throw throwError("INVALID_STATUS", "Only scheduled appointments can be confirmed", 400);
    }

    const updated = await prisma.appointment.update({
      where: { id: appointment_id },
      data: { status: "confirmed" },
    });

    res.status(200).json({
      message: "Appointment confirmed",
      appointment_id: updated.id,
      status: updated.status,
    });
  })
);

// Complete an appointment (provider only)
router.put(
  "/:appointment_id/complete",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") {
      throw throwError("FORBIDDEN", "Only providers can complete appointments", 403);
    }

    const { appointment_id } = req.params;
    const { notes } = req.body;

    const appointment = await prisma.appointment.findUnique({
      where: { id: appointment_id },
    });

    if (!appointment || appointment.providerId !== req.user.id) {
      throw throwError("NOT_FOUND", "Appointment not found", 404);
    }

    if (!["scheduled", "confirmed"].includes(appointment.status)) {
      throw throwError("INVALID_STATUS", "Cannot complete this appointment", 400);
    }

    const updated = await prisma.appointment.update({
      where: { id: appointment_id },
      data: {
        status: "completed",
        notes: notes ? `${appointment.notes || ""}\n[Notes]: ${notes}`.trim() : appointment.notes,
      },
    });

    res.status(200).json({
      message: "Appointment completed",
      appointment_id: updated.id,
      status: updated.status,
    });
  })
);

// Provider schedule management
router.get(
  "/provider-schedule",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") {
      throw throwError("FORBIDDEN", "Only providers can access their schedule", 403);
    }

    const schedules = await prisma.providerSchedule.findMany({
      where: { providerId: req.user.id },
      orderBy: { dayOfWeek: "asc" },
    });

    res.status(200).json({
      schedules: schedules.map((s) => ({
        schedule_id: s.id,
        day_of_week: s.dayOfWeek,
        start_time: s.startTime,
        end_time: s.endTime,
        is_available: s.isAvailable,
      })),
    });
  })
);

router.post(
  "/provider-schedule",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") {
      throw throwError("FORBIDDEN", "Only providers can set their schedule", 403);
    }

    const { day_of_week, start_time, end_time } = req.body;

    if (day_of_week === undefined || !start_time || !end_time) {
      throw throwError("INVALID_INPUT", "Day of week, start time and end time are required", 400);
    }

    if (day_of_week < 0 || day_of_week > 6) {
      throw throwError("INVALID_INPUT", "Day of week must be 0-6 (Sunday-Saturday)", 400);
    }

    // Check for overlapping schedules
    const existing = await prisma.providerSchedule.findFirst({
      where: {
        providerId: req.user.id,
        dayOfWeek: day_of_week,
        isAvailable: true,
      },
    });

    if (existing) {
      throw throwError("SCHEDULE_EXISTS", "Schedule for this day already exists. Update instead.", 409);
    }

    const schedule = await prisma.providerSchedule.create({
      data: {
        providerId: req.user.id,
        dayOfWeek: day_of_week,
        startTime: start_time,
        endTime: end_time,
        isAvailable: true,
      },
    });

    res.status(201).json({
      message: "Schedule added successfully",
      schedule: {
        schedule_id: schedule.id,
        day_of_week: schedule.dayOfWeek,
        start_time: schedule.startTime,
        end_time: schedule.endTime,
      },
    });
  })
);

router.put(
  "/provider-schedule/:schedule_id",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") {
      throw throwError("FORBIDDEN", "Only providers can update their schedule", 403);
    }

    const { schedule_id } = req.params;
    const { start_time, end_time, is_available } = req.body;

    const schedule = await prisma.providerSchedule.findFirst({
      where: { id: schedule_id, providerId: req.user.id },
    });

    if (!schedule) {
      throw throwError("NOT_FOUND", "Schedule not found", 404);
    }

    const updated = await prisma.providerSchedule.update({
      where: { id: schedule_id },
      data: {
        ...(start_time && { startTime: start_time }),
        ...(end_time && { endTime: end_time }),
        ...(is_available !== undefined && { isAvailable: is_available }),
      },
    });

    res.status(200).json({
      message: "Schedule updated",
      schedule: {
        schedule_id: updated.id,
        day_of_week: updated.dayOfWeek,
        start_time: updated.startTime,
        end_time: updated.endTime,
        is_available: updated.isAvailable,
      },
    });
  })
);

router.delete(
  "/provider-schedule/:schedule_id",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") {
      throw throwError("FORBIDDEN", "Only providers can delete their schedule", 403);
    }

    const { schedule_id } = req.params;

    const schedule = await prisma.providerSchedule.findFirst({
      where: { id: schedule_id, providerId: req.user.id },
    });

    if (!schedule) {
      throw throwError("NOT_FOUND", "Schedule not found", 404);
    }

    await prisma.providerSchedule.delete({
      where: { id: schedule_id },
    });

    res.status(200).json({ message: "Schedule deleted successfully" });
  })
);

export default router;
