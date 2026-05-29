import express from "express";
import { prisma } from "../services/prisma.js";
import { redis } from "../services/redis.js";
import { asyncHandler } from "../utils/asyncHandler.js";

const router = express.Router();

router.get(
  "/",
  asyncHandler(async (req, res) => {
    const search = req.query.search || "";
    const key = `facilities:${search.toLowerCase()}`;
    const cached = await redis.get(key);
    if (cached) {
      return res.status(200).json(JSON.parse(cached));
    }

    const where = {
      isActive: true,
      ...(search ? { name: { contains: search } } : {})
    };

    const facilities = await prisma.facility.findMany({
      where,
      orderBy: { name: "asc" }
    });
    const payload = {
      facilities: facilities.map((f) => ({
        facility_id: f.id,
        id: f.id,
        name: f.name,
        address: f.address,
        phone: f.phone,
        latitude: f.latitude,
        longitude: f.longitude
      }))
    };
    await redis.set(key, JSON.stringify(payload), "EX", 3600);
    return res.status(200).json(payload);
  })
);

export default router;
