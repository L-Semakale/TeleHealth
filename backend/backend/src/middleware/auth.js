import jwt from "jsonwebtoken";
import { prisma } from "../services/prisma.js";
import { throwError } from "../utils/errors.js";

export const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next(throwError("UNAUTHORIZED", "Unauthorized", 401));
  }

  const token = authHeader.split(" ")[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await prisma.user.findUnique({
      where: { id: decoded.user_id },
      select: { id: true, role: true, anonymousId: true, isActive: true }
    });

    if (!user || !user.isActive) {
      return next(
        throwError(
          "ACCOUNT_DEACTIVATED",
          "Your account has been deactivated. Contact the administrator.",
          403
        )
      );
    }

    req.user = {
      id: user.id,
      role: user.role,
      anonymous_id: user.anonymousId
    };
    return next();
  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return next(throwError("TOKEN_EXPIRED", "Session expired. Please log in again.", 401));
    }
    return next(throwError("FORBIDDEN", "Forbidden", 403));
  }
};

export const allowRoles = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return next(throwError("FORBIDDEN", "Forbidden", 403));
  }
  return next();
};
