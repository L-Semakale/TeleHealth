import express from "express";
import { prisma } from "../services/prisma.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { throwError } from "../utils/errors.js";

const router = express.Router();

router.get(
  "/",
  asyncHandler(async (req, res) => {
    const referrals = await prisma.referral.findMany({
      where: { consultation: { patientId: req.user.id } },
      include: { facility: true },
      orderBy: { issuedAt: "desc" }
    });

    res.status(200).json({
      referrals: referrals.map((r) => ({
        referral_id: r.id,
        id: r.id,
        facility_name: r.facility.name,
        facility_address: r.facility.address,
        facility_phone: r.facility.phone,
        address: r.facility.address,
        phone: r.facility.phone,
        notes: r.notes,
        issued_at: r.issuedAt,
        issued_date: r.issuedAt,
        status: r.viewedAt ? "viewed" : "new"
      }))
    });
  })
);

router.put(
  "/:referral_id/viewed",
  asyncHandler(async (req, res) => {
    const { referral_id } = req.params;
    const referral = await prisma.referral.findFirst({
      where: { id: referral_id, consultation: { patientId: req.user.id } }
    });
    if (!referral) throw throwError("NOT_FOUND", "Referral not found.", 404);

    await prisma.referral.update({
      where: { id: referral_id },
      data: { viewedAt: new Date() }
    });
    res.status(200).json({ message: "Referral marked as viewed" });
  })
);

export default router;
