import express from "express";
import { prisma } from "../services/prisma.js";
import { asyncHandler } from "../utils/asyncHandler.js";

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
        facility_name: r.facility.name,
        facility_address: r.facility.address,
        facility_phone: r.facility.phone,
        notes: r.notes,
        issued_at: r.issuedAt
      }))
    });
  })
);

export default router;
