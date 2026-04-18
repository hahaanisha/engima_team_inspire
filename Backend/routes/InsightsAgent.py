from flask import Blueprint, request, jsonify
from pymongo import MongoClient
from bson.objectid import ObjectId
import os
import requests
from dotenv import load_dotenv

load_dotenv()

insights_bp = Blueprint("insights", __name__)

# DB
MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)
db = client["biosync"]

users_collection = db["users"]
profiles_collection = db["profiles"]

# AI API
FEATHERLESS_API_KEY = os.getenv("FEATHERLESS_API_KEY")



import json
import re

def format_ai_response(raw_text):
    try:
        # Remove ```json ``` and ```
        cleaned = re.sub(r"```json|```", "", raw_text).strip()

        # Convert string → JSON
        parsed = json.loads(cleaned)

        return parsed
    except Exception as e:
        return {
            "error": "Failed to parse AI response",
            "raw": raw_text
        }

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
# Format profile for AI
# -------------------------
def format_profile(profile):
    return f"""
User Health Data:

Age: {profile.get("age")}
Gender: {profile.get("gender")}
Height: {profile.get("height_cm")} cm
Weight: {profile.get("weight_kg")} kg

Daily Steps: {profile.get("daily_steps")}
Sleep Duration: {profile.get("sleep_duration")} hours
Sitting Time: {profile.get("sitting_time")}
Exercise Frequency: {profile.get("exercise_frequency")}

Medical Conditions: {profile.get("medical_conditions")}
Family History: {profile.get("family_history")}

Resting Heart Rate: {profile.get("resting_heart_rate")}

Smoking: {profile.get("smoking")}
Alcohol: {profile.get("alcohol")}
Stress Level: {profile.get("stress_level")}
"""


# -------------------------
# AI Call
# -------------------------
def get_ai_insights(profile_text):

    prompt = f"""
You are a strict medical risk analysis assistant.

ONLY do the following:
1. Predict risk levels for:
   - Diabetes
   - Heart Disease
   - Hypertension

2. Give 3-5 short, specific health insights.

Rules:
- Be concise
- No explanations
- No extra text
- No disclaimers
- Output ONLY valid JSON

Format:
{{
  "risks": {{
    "diabetes": "Low/Medium/High",
    "heart": "Low/Medium/High",
    "hypertension": "Low/Medium/High"
  }},
  "insights": [
    "short sentence",
    "short sentence"
  ]
}}

User Data:
{profile_text}
"""

    response = requests.post(
        url="https://api.featherless.ai/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {FEATHERLESS_API_KEY}"
        },
        json={
            "model": "deepseek-ai/DeepSeek-V3-0324",
            "messages": [
                {"role": "user", "content": prompt}
            ]
        }
    )

    try:
        result = response.json()
        content = result["choices"][0]["message"]["content"]
        return content
    except:
        return None


# -------------------------
# API: Risks + Insights
# -------------------------
@insights_bp.route("/twin/insights", methods=["GET"])
def get_insights():

    user, error_response, status = get_user_from_token(request)
    if error_response:
        return error_response, status

    profile = profiles_collection.find_one({"user_id": str(user["_id"])})

    if not profile:
        return jsonify({"error": "Profile not found"}), 404

    profile_text = format_profile(profile)

    ai_output = get_ai_insights(profile_text)

    if not ai_output:
        return jsonify({"error": "AI service failed"}), 500

    formatted = format_ai_response(ai_output)
    return jsonify(formatted)