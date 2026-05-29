from flask import Flask, jsonify, request
import logging
import os
import numpy as np
import joblib

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

MODEL_PATH = os.getenv("MODEL_PATH", "model.joblib")
model = None
vocabulary = {}
class_names = ["urgent", "routine", "self-care"]


def load_model():
    global model
    global vocabulary
    try:
        model_bundle = joblib.load(MODEL_PATH)
        model = model_bundle.get("model")
        vocabulary = model_bundle.get("vocabulary", {})
        app.logger.info("ML model loaded from disk.")
    except Exception as exc:
        app.logger.warning("Failed to load model; using rule fallback: %s", exc)
        model = None
        vocabulary = {}


def vectorize(symptoms, duration_days):
    if not vocabulary:
        return np.array([[len(symptoms), duration_days]])

    features = [0] * (len(vocabulary) + 1)
    for symptom in symptoms:
        idx = vocabulary.get(symptom.strip().lower())
        if idx is not None:
            features[idx] = 1
    features[-1] = duration_days
    return np.array([features], dtype=float)


def fallback_predict(symptoms, duration_days):
    normalized = [s.lower() for s in symptoms]
    urgent_signals = {"chest pain", "shortness of breath", "confusion", "coughing blood"}
    if any(s in urgent_signals for s in normalized) or duration_days >= 14:
        return "urgent", 0.65
    if duration_days >= 5 or len(symptoms) >= 3:
        return "routine", 0.60
    return "self-care", 0.55


@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200


@app.post("/predict")
def predict():
    payload = request.get_json(silent=True) or {}
    symptoms = payload.get("symptoms", [])
    duration_days = int(payload.get("duration_days", 0))
    try:
        if model is None:
            label, score = fallback_predict(symptoms, duration_days)
            return jsonify({"classification": label, "confidence_score": score}), 200

        x = vectorize(symptoms, duration_days)
        pred = model.predict(x)[0]
        proba = 0.0
        if hasattr(model, "predict_proba"):
            probabilities = model.predict_proba(x)[0]
            proba = float(np.max(probabilities))
        label = str(pred) if str(pred) in class_names else "routine"
        return jsonify({"classification": label, "confidence_score": proba}), 200
    except Exception as exc:
        app.logger.error("Prediction failed: %s", exc)
        return jsonify({"classification": "routine", "confidence_score": 0.0}), 200


if __name__ == "__main__":
    load_model()
    app.run(host="0.0.0.0", port=5001)
