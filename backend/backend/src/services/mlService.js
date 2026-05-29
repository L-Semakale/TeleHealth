import axios from "axios";

const mlClient = axios.create({
  baseURL: process.env.ML_SERVICE_URL,
  timeout: 5000
});

export const predictTriage = async ({ symptoms, duration_days }) => {
  try {
    const response = await mlClient.post("/predict", { symptoms, duration_days });
    return response.data;
  } catch (error) {
    return { classification: "routine", confidence_score: 0.0 };
  }
};

export const mlHealth = async () => {
  try {
    await mlClient.get("/health");
    return "ok";
  } catch (error) {
    return "degraded";
  }
};
