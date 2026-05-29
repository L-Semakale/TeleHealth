import express from "express";
import { prisma } from "../services/prisma.js";
import { predictTriage } from "../services/mlService.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { recommendedActionByClass } from "../utils/triage.js";
import { throwError } from "../utils/errors.js";

const router = express.Router();

router.post(
  "/",
  asyncHandler(async (req, res) => {
    const { symptoms, duration_days, additional_notes } = req.body;
    const symptomList = Array.isArray(symptoms) ? symptoms : [];
    const report = await prisma.symptomReport.create({
      data: {
        userId: req.user.id,
        symptoms: JSON.stringify(symptomList),
        durationDays: Number(duration_days) || 0,
        additionalNotes: additional_notes
      }
    });

    const prediction = await predictTriage({ symptoms: symptomList, duration_days });
    const triage = await prisma.triageResult.create({
      data: {
        reportId: report.id,
        classification: prediction.classification,
        confidenceScore: prediction.confidence_score
      }
    });

    res.status(201).json({
      report_id: report.id,
      triage: {
        classification: triage.classification,
        confidence_score: triage.confidenceScore,
        recommended_action: recommendedActionByClass[triage.classification] || recommendedActionByClass.routine
      }
    });
  })
);

router.get(
  "/:report_id/triage",
  asyncHandler(async (req, res) => {
    const { report_id } = req.params;
    const result = await prisma.triageResult.findFirst({
      where: {
        reportId: report_id,
        report: { userId: req.user.id }
      }
    });
    if (!result) {
      throw throwError("NOT_FOUND", "Triage result not found.", 404);
    }
    res.status(200).json({
      report_id,
      classification: result.classification,
      confidence_score: result.confidenceScore,
      recommended_action: recommendedActionByClass[result.classification] || recommendedActionByClass.routine,
      created_at: result.createdAt
    });
  })
);

export default router;
