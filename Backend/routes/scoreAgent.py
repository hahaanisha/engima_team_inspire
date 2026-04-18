from flask import Blueprint, request, jsonify
from pymongo import MongoClient
from bson.objectid import ObjectId
import os
from dotenv import load_dotenv

load_dotenv()

score_bp = Blueprint("score", __name__)

# DB connection
MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)
db = client["biosync"]

users_collection = db["users"]
profiles_collection = db["profiles"]


# -------------------------
# Helper: Get user from token
# -------------------------
def get_user_from_token(request):
    auth_header = request.headers.get("Authorization")

    if not auth_header:
        return None, jsonify({"error": "Token missing"}), 401

    try:
        token = auth_header.split(" ")[1]
        user = users_collection.find_one({"_id": ObjectId(token)})

        if not user:
            return None, jsonify({"error": "Invalid token"}), 401

        return user, None, None

    except:
        return None, jsonify({"error": "Invalid token format"}), 401


# -------------------------
# Score Calculation Logic
# -------------------------
def calculate_score(profile):

    # -------- Activity Score (25) --------
    steps = profile.get("daily_steps", 0) or 0

    if steps > 8000:
        activity_score = 25
    elif steps > 6000:
        activity_score = 20
    elif steps > 4000:
        activity_score = 15
    elif steps > 2000:
        activity_score = 10
    else:
        activity_score = 5

    # -------- Sleep Score (20) --------
    sleep = profile.get("sleep_duration", 0) or 0

    if sleep >= 7:
        sleep_score = 20
    elif sleep >= 6:
        sleep_score = 15
    elif sleep >= 5:
        sleep_score = 10
    else:
        sleep_score = 5

    # -------- BMI Score (20) --------
    height = profile.get("height_cm")
    weight = profile.get("weight_kg")

    bmi_score = 10  # default

    if height and weight:
        bmi = weight / ((height / 100) ** 2)

        if 18.5 <= bmi <= 24.9:
            bmi_score = 20
        elif 25 <= bmi <= 29.9:
            bmi_score = 15
        elif bmi >= 30:
            bmi_score = 8
        else:
            bmi_score = 10

    # -------- Lifestyle Score (15) --------
    smoking = profile.get("smoking")
    alcohol = profile.get("alcohol")

    lifestyle_score = 0

    # Smoking
    if smoking == "No":
        lifestyle_score += 8
    elif smoking == "Occasionally":
        lifestyle_score += 4
    else:
        lifestyle_score += 0

    # Alcohol
    if alcohol == "None":
        lifestyle_score += 7
    elif alcohol == "Occasional":
        lifestyle_score += 4
    else:
        lifestyle_score += 0

    # -------- Stress Score (10) --------
    stress = profile.get("stress_level")

    if stress == "Low":
        stress_score = 10
    elif stress == "Moderate":
        stress_score = 6
    else:
        stress_score = 2

    # -------- Heart Rate Score (10) --------
    hr = profile.get("resting_heart_rate")

    if hr:
        if 60 <= hr <= 80:
            heart_score = 10
        elif 80 < hr <= 100:
            heart_score = 6
        else:
            heart_score = 2
    else:
        heart_score = 5  # default if not available

    # -------- Total --------
    total_score = (
        activity_score +
        sleep_score +
        bmi_score +
        lifestyle_score +
        stress_score +
        heart_score
    )

    # -------- Category --------
    if total_score >= 80:
        category = "Excellent"
    elif total_score >= 60:
        category = "Good"
    elif total_score >= 40:
        category = "Average"
    else:
        category = "Poor"

    return {
        "health_score": total_score,
        "category": category,
        "breakdown": {
            "activity": activity_score,
            "sleep": sleep_score,
            "bmi": bmi_score,
            "lifestyle": lifestyle_score,
            "stress": stress_score,
            "heart": heart_score
        }
    }


# -------------------------
# API: Get Health Score
# -------------------------
@score_bp.route("/twin/score", methods=["GET"])
def get_health_score():

    user, error_response, status = get_user_from_token(request)
    if error_response:
        return error_response, status

    profile = profiles_collection.find_one({"user_id": str(user["_id"])})

    if not profile:
        return jsonify({"error": "Profile not found"}), 404

    result = calculate_score(profile)

    return jsonify(result)