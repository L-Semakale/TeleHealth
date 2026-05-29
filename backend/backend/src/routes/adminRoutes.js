import express from "express";
import { prisma } from "../services/prisma.js";
import { invalidateByPrefix, redis } from "../services/redis.js";
import { mlHealth } from "../services/mlService.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { allowRoles } from "../middleware/auth.js";
import { throwError } from "../utils/errors.js";

const router = express.Router();

router.use(allowRoles("admin"));

router.get(
  "/users",
  asyncHandler(async (req, res) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const skip = (page - 1) * limit;
    const [total, users] = await Promise.all([
      prisma.user.count(),
      prisma.user.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          fullName: true,
          phoneNumber: true,
          role: true,
          createdAt: true,
          isActive: true
        }
      })
    ]);
    res.status(200).json({
      total,
      page,
      users: users.map((u) => ({
        user_id: u.id,
        full_name: u.fullName,
        phone_number: u.phoneNumber,
        role: u.role,
        created_at: u.createdAt,
        is_active: u.isActive
      }))
    });
  })
);

router.put(
  "/users/:user_id/role",
  asyncHandler(async (req, res) => {
    const { user_id } = req.params;
    const { role } = req.body;
    if (!["patient", "provider"].includes(role)) {
      throw throwError("INVALID_ROLE", "Role must be patient or provider.", 400);
    }
    const existing = await prisma.user.findUnique({ where: { id: user_id } });
    const updated = await prisma.user.update({ where: { id: user_id }, data: { role } });
    await prisma.roleChangeAudit.create({
      data: {
        targetUserId: user_id,
        adminUserId: req.user.id,
        oldRole: existing.role,
        newRole: updated.role
      }
    });
    res.status(200).json({
      message: `Role updated to ${role}`,
      updated_at: new Date().toISOString()
    });
  })
);

router.put(
  "/users/:user_id/status",
  asyncHandler(async (req, res) => {
    const { user_id } = req.params;
    const { is_active } = req.body;
    await prisma.user.update({ where: { id: user_id }, data: { isActive: !!is_active } });
    res.status(200).json({ message: "User status updated successfully" });
  })
);

router.get(
  "/consultations",
  asyncHandler(async (req, res) => {
    const status = req.query.status;
    const consultations = await prisma.consultation.findMany({
      where: status ? { status } : {},
      include: {
        patient: { select: { anonymousId: true } },
        messages: { select: { id: true } }
      },
      orderBy: { startedAt: "desc" }
    });
    res.status(200).json({
      consultations: consultations.map((c) => ({
        consultation_id: c.id,
        patient_anonymous_id: c.patient.anonymousId,
        provider_id: c.providerId,
        status: c.status,
        started_at: c.startedAt,
        message_count: c.messages.length
      }))
    });
  })
);

router.get(
  "/analytics/triage",
  asyncHandler(async (req, res) => {
    const key = "analytics:triage";
    const cached = await redis.get(key);
    if (cached) return res.status(200).json(JSON.parse(cached));

    const [totalReports, grouped, avg, last7] = await Promise.all([
      prisma.triageResult.count(),
      prisma.triageResult.groupBy({ by: ["classification"], _count: true }),
      prisma.triageResult.aggregate({ _avg: { confidenceScore: true } }),
      prisma.triageResult.count({
        where: { createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } }
      })
    ]);

    const byClass = { urgent: 0, routine: 0, "self-care": 0 };
    grouped.forEach((g) => {
      byClass[g.classification] = g._count;
    });
    const payload = {
      total_reports: totalReports,
      by_classification: byClass,
      average_confidence_score: avg._avg.confidenceScore || 0,
      reports_last_7_days: last7
    };
    await redis.set(key, JSON.stringify(payload), "EX", 900);
    return res.status(200).json(payload);
  })
);

router.post(
  "/facilities",
  asyncHandler(async (req, res) => {
    const created = await prisma.facility.create({
      data: {
        name: req.body.name,
        address: req.body.address,
        phone: req.body.phone,
        latitude: req.body.latitude,
        longitude: req.body.longitude
      }
    });
    await invalidateByPrefix("facilities:");
    res.status(201).json({ facility_id: created.id });
  })
);

router.put(
  "/facilities/:facility_id",
  asyncHandler(async (req, res) => {
    const { facility_id } = req.params;
    await prisma.facility.update({
      where: { id: facility_id },
      data: {
        name: req.body.name,
        address: req.body.address,
        phone: req.body.phone,
        latitude: req.body.latitude,
        longitude: req.body.longitude
      }
    });
    await invalidateByPrefix("facilities:");
    res.status(200).json({ message: "Facility updated successfully" });
  })
);

router.delete(
  "/facilities/:facility_id",
  asyncHandler(async (req, res) => {
    const { facility_id } = req.params;
    const referrals = await prisma.referral.count({ where: { facilityId: facility_id } });
    if (referrals > 0) {
      await prisma.facility.update({ where: { id: facility_id }, data: { isActive: false } });
    } else {
      await prisma.facility.delete({ where: { id: facility_id } });
    }
    await invalidateByPrefix("facilities:");
    res.status(200).json({ message: "Facility deleted successfully" });
  })
);

router.get(
  "/health",
  asyncHandler(async (req, res) => {
    const result = {
      api_status: "ok",
      database_status: "ok",
      ml_service_status: "ok",
      redis_status: "ok",
      uptime_seconds: Math.floor(process.uptime())
    };

    try {
      await prisma.$queryRaw`SELECT 1`;
    } catch (error) {
      result.database_status = "degraded";
    }
    try {
      await redis.ping();
    } catch (error) {
      result.redis_status = "degraded";
    }
    result.ml_service_status = await mlHealth();
    res.status(200).json(result);
  })
);

export default router;
