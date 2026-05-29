import express from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";
import { prisma } from "../services/prisma.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { throwError } from "../utils/errors.js";

const router = express.Router();

router.post(
  "/register",
  asyncHandler(async (req, res) => {
    const { full_name, phone_number, password } = req.body;
    if (!full_name || !phone_number || !password) {
      throw throwError("VALIDATION_ERROR", "Missing required fields", 400);
    }
    if (password.length < 8) {
      throw throwError("WEAK_PASSWORD", "Password must be at least 8 characters.", 400);
    }

    const exists = await prisma.user.findUnique({ where: { phoneNumber: phone_number } });
    if (exists) {
      throw throwError("PHONE_EXISTS", "Phone number already exists.", 409);
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const anonymousId = `anon-${uuidv4().slice(0, 8)}`;

    await prisma.user.create({
      data: {
        fullName: full_name,
        phoneNumber: phone_number,
        hashedPassword,
        role: "patient",
        anonymousId
      }
    });

    res.status(201).json({
      message: "Registration successful",
      anonymous_id: anonymousId
    });
  })
);

router.post(
  "/login",
  asyncHandler(async (req, res) => {
    const { phone_number, password } = req.body;
    const user = await prisma.user.findUnique({ where: { phoneNumber: phone_number } });
    if (!user) {
      throw throwError("INVALID_CREDENTIALS", "Invalid credentials", 401);
    }

    if (!user.isActive) {
      throw throwError(
        "ACCOUNT_DEACTIVATED",
        "Your account has been deactivated. Contact the administrator.",
        403
      );
    }

    const isValid = await bcrypt.compare(password, user.hashedPassword);
    if (!isValid) {
      throw throwError("INVALID_CREDENTIALS", "Invalid credentials", 401);
    }

    const token = jwt.sign(
      { user_id: user.id, role: user.role, anonymous_id: user.anonymousId },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    );

    res.status(200).json({
      token,
      role: user.role,
      anonymous_id: user.anonymousId
    });
  })
);

export default router;
