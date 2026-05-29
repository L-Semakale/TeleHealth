import express from "express";
import { prisma } from "../services/prisma.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { throwError } from "../utils/errors.js";
import { decrypt, encrypt } from "../utils/crypto.js";

const router = express.Router();
const PAGE_SIZE = 20;
const MESSAGE_PAGE_SIZE = 30;

function mapConsultation(c, decryptBody) {
  const lastMsg = c.messages?.[0];
  const triage = c.report?.triageResults?.[0];
  let preview = "";
  if (lastMsg) {
    try {
      preview = decryptBody(lastMsg.encryptedBody).slice(0, 120);
    } catch {
      preview = "";
    }
  }
  return {
    consultation_id: c.id,
    status: c.status,
    patient_anonymous_id: c.patient?.anonymousId ?? "",
    assigned_provider_id: c.providerId,
    triage_classification: triage?.classification ?? "routine",
    created_at: c.startedAt,
    started_at: c.startedAt,
    closed_at: c.closedAt,
    last_message_at: lastMsg?.sentAt ?? null,
    last_message_preview: preview,
    unread_count: 0
  };
}

router.post(
  "/",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "patient") {
      throw throwError("FORBIDDEN", "Forbidden", 403);
    }
    const { report_id } = req.body;
    if (report_id) {
      const report = await prisma.symptomReport.findFirst({
        where: { id: report_id, userId: req.user.id }
      });
      if (!report) throw throwError("FORBIDDEN", "Forbidden", 403);
    }

    const open = await prisma.consultation.findFirst({
      where: { patientId: req.user.id, status: "open" }
    });
    if (open) {
      throw throwError("CONSULTATION_ALREADY_OPEN", "You already have an open consultation.", 409);
    }

    const provider = await prisma.user.findFirst({
      where: { role: "provider", isActive: true },
      orderBy: { createdAt: "asc" }
    });
    if (!provider) throw throwError("NO_PROVIDER", "No provider available.", 503);

    const consultation = await prisma.consultation.create({
      data: {
        patientId: req.user.id,
        providerId: provider.id,
        reportId: report_id || null,
        status: "open"
      },
      include: {
        patient: { select: { anonymousId: true } },
        report: {
          include: { triageResults: { orderBy: { createdAt: "desc" }, take: 1 } }
        }
      }
    });

    const triage = consultation.report?.triageResults?.[0];
    res.status(201).json({
      consultation_id: consultation.id,
      status: consultation.status,
      patient_anonymous_id: consultation.patient.anonymousId,
      assigned_provider_id: consultation.providerId,
      triage_classification: triage?.classification ?? "routine",
      created_at: consultation.startedAt,
      started_at: consultation.startedAt
    });
  })
);

router.post(
  "/:consultation_id/messages",
  asyncHandler(async (req, res) => {
    const { consultation_id } = req.params;
    const { body } = req.body;
    const consultation = await prisma.consultation.findUnique({ where: { id: consultation_id } });
    if (!consultation) throw throwError("NOT_FOUND", "Consultation not found.", 404);
    if (![consultation.patientId, consultation.providerId].includes(req.user.id)) {
      throw throwError("FORBIDDEN", "Forbidden", 403);
    }
    if (consultation.status === "closed") {
      throw throwError("CONSULTATION_CLOSED", "This consultation is closed.", 400);
    }

    const message = await prisma.message.create({
      data: {
        consultationId: consultation_id,
        senderId: req.user.id,
        encryptedBody: encrypt(body)
      }
    });
    res.status(201).json({ message_id: message.id, sent_at: message.sentAt });
  })
);

router.get(
  "/:consultation_id/messages",
  asyncHandler(async (req, res) => {
    const { consultation_id } = req.params;
    const page = Math.max(1, Number(req.query.page || 1));
    const skip = (page - 1) * MESSAGE_PAGE_SIZE;

    const consultation = await prisma.consultation.findUnique({ where: { id: consultation_id } });
    if (!consultation) throw throwError("NOT_FOUND", "Consultation not found.", 404);
    if (![consultation.patientId, consultation.providerId].includes(req.user.id)) {
      throw throwError("FORBIDDEN", "Forbidden", 403);
    }

    const messages = await prisma.message.findMany({
      where: { consultationId: consultation_id },
      include: { sender: true },
      orderBy: { sentAt: "asc" },
      skip,
      take: MESSAGE_PAGE_SIZE
    });

    const mapped = messages.map((msg) => ({
      message_id: msg.id,
      id: msg.id,
      sender_role: msg.sender.role,
      sender_name:
        req.user.role === "patient" && msg.sender.role === "provider"
          ? "Healthcare Provider"
          : msg.sender.fullName,
      body: decrypt(msg.encryptedBody),
      sent_at: msg.sentAt,
      created_at: msg.sentAt
    }));

    res.status(200).json({ consultation_id, messages: mapped });
  })
);

router.get(
  "/",
  asyncHandler(async (req, res) => {
    const page = Math.max(1, Number(req.query.page || 1));
    const limit = PAGE_SIZE;
    const skip = (page - 1) * limit;
    const status = req.query.status;

    const where = {
      ...(req.user.role === "patient" ? { patientId: req.user.id } : { providerId: req.user.id }),
      ...(status ? { status } : {})
    };

    const consultations = await prisma.consultation.findMany({
      where,
      orderBy: { startedAt: "desc" },
      skip,
      take: limit,
      include: {
        patient: { select: { anonymousId: true } },
        report: {
          include: { triageResults: { orderBy: { createdAt: "desc" }, take: 1 } }
        },
        messages: {
          orderBy: { sentAt: "desc" },
          take: 1
        }
      }
    });

    res.status(200).json({
      consultations: consultations.map((c) => mapConsultation(c, decrypt))
    });
  })
);

router.put(
  "/:consultation_id/close",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") throw throwError("FORBIDDEN", "Forbidden", 403);
    const { consultation_id } = req.params;
    const consultation = await prisma.consultation.findUnique({ where: { id: consultation_id } });
    if (!consultation || consultation.providerId !== req.user.id) throw throwError("FORBIDDEN", "Forbidden", 403);
    const updated = await prisma.consultation.update({
      where: { id: consultation_id },
      data: { status: "closed", closedAt: new Date() }
    });
    res.status(200).json({
      message: "Consultation closed successfully",
      closed_at: updated.closedAt
    });
  })
);

router.post(
  "/:consultation_id/referrals",
  asyncHandler(async (req, res) => {
    if (req.user.role !== "provider") throw throwError("FORBIDDEN", "Forbidden", 403);
    const { consultation_id } = req.params;
    const { facility_id, notes } = req.body;
    const consultation = await prisma.consultation.findUnique({ where: { id: consultation_id } });
    if (!consultation || consultation.providerId !== req.user.id) throw throwError("FORBIDDEN", "Forbidden", 403);
    const facility = await prisma.facility.findFirst({ where: { id: facility_id, isActive: true } });
    if (!facility) throw throwError("FACILITY_NOT_FOUND", "Facility not found.", 404);
    const existing = await prisma.referral.findFirst({ where: { consultationId: consultation_id } });
    if (existing) throw throwError("REFERRAL_EXISTS", "Active referral already exists.", 409);

    const referral = await prisma.referral.create({
      data: { consultationId: consultation_id, facilityId: facility_id, notes }
    });
    res.status(201).json({
      referral_id: referral.id,
      facility_name: facility.name,
      issued_at: referral.issuedAt
    });
  })
);

export default router;
