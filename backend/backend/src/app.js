import "dotenv/config";
import express from "express";
import cors from "cors";
import morgan from "morgan";
import authRoutes from "./routes/authRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import symptomRoutes from "./routes/symptomRoutes.js";
import consultationRoutes from "./routes/consultationRoutes.js";
import referralRoutes from "./routes/referralRoutes.js";
import facilityRoutes from "./routes/facilityRoutes.js";
import appointmentRoutes from "./routes/appointmentRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
import { authMiddleware } from "./middleware/auth.js";
import { errorResponse } from "./utils/errors.js";

const app = express();
app.use(cors());
app.use(morgan("dev"));
app.use(express.json());

app.get("/api/health", (_, res) => res.status(200).json({ status: "ok" }));

app.use("/api/auth", authRoutes);
app.use(authMiddleware);
app.use("/api/users", userRoutes);
app.use("/api/symptoms", symptomRoutes);
app.use("/api/consultations", consultationRoutes);
app.use("/api/referrals", referralRoutes);
app.use("/api/facilities", facilityRoutes);
app.use("/api/appointments", appointmentRoutes);
app.use("/api/admin", adminRoutes);

app.use((err, _req, res, _next) => {
  const response = errorResponse(err);
  res.status(response.status).json(response.body);
});

export default app;
