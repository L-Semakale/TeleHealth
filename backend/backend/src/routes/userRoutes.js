import express from "express";
import bcrypt from "bcrypt";
import { prisma } from "../services/prisma.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { throwError } from "../utils/errors.js";

const router = express.Router();

router.get(
  "/profile",
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        role: true,
        anonymousId: true,
        createdAt: true
      }
    });
    res.status(200).json({
      full_name: user.fullName,
      phone_number: user.phoneNumber,
      role: user.role,
      anonymous_id: user.anonymousId,
      created_at: user.createdAt
    });
  })
);

router.put(
  "/profile",
  asyncHandler(async (req, res) => {
    const { full_name, phone_number, current_password, new_password } = req.body;
    const userId = req.user.id;
    const updates = {};

    if (full_name) updates.fullName = full_name;
    if (phone_number) {
      const existing = await prisma.user.findUnique({ where: { phoneNumber: phone_number } });
      if (existing && existing.id !== userId) {
        throw throwError("PHONE_EXISTS", "Phone number already exists.", 409);
      }
      updates.phoneNumber = phone_number;
    }

    if (new_password) {
      if (!current_password) {
        throw throwError("VALIDATION_ERROR", "current_password is required.", 400);
      }
      if (new_password.length < 8) {
        throw throwError("WEAK_PASSWORD", "Password must be at least 8 characters.", 400);
      }
      const currentUser = await prisma.user.findUnique({ where: { id: userId } });
      const matches = await bcrypt.compare(current_password, currentUser.hashedPassword);
      if (!matches) {
        throw throwError("INVALID_CURRENT_PASSWORD", "Current password is incorrect.", 401);
      }
      updates.hashedPassword = await bcrypt.hash(new_password, 12);
    }

    await prisma.user.update({ where: { id: userId }, data: updates });
    res.status(200).json({ message: "Profile updated successfully" });
  })
);

export default router;
