from flask import Blueprint, request, jsonify
from pymongo import MongoClient
from bson.objectid import ObjectId
import os
from dotenv import load_dotenv

load_dotenv()

make_twin_bp = Blueprint("make_twin", __name__)

# DB connection
MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)
db = client["biosync"]

profiles_collection = db["profiles"]
users_collection = db["users"]


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
# Create / Update Profile
# -------------------------
@make_twin_bp.route("/twin/profile", methods=["POST"])
def create_or_update_profile():

    user, error_response, status = get_user_from_token(request)
    if error_response:
        return error_response, status

    data = request.json

    profile_data = {
        "user_id": str(user["_id"]),

        # Basic
        "full_name": data.get("full_name"),
        "gender": data.get("gender"),
        "age": data.get("age"),
        "height_cm": data.get("height_cm"),
        "weight_kg": data.get("weight_kg"),

        # Activity
        "daily_steps": data.get("daily_steps"),
        "step_length": data.get("step_length"),
        "sitting_time": data.get("sitting_time"),
        "exercise_frequency": data.get("exercise_frequency"),
        "sleep_duration": data.get("sleep_duration"),

        # Health
        "medical_conditions": data.get("medical_conditions", []),
        "family_history": data.get("family_history", []),
        "resting_heart_rate": data.get("resting_heart_rate"),

        # Behavioral
        "smoking": data.get("smoking"),
        "alcohol": data.get("alcohol"),
        "stress_level": data.get("stress_level"),

        # Environment
        "location": {
            "lat": data.get("lat"),
            "long": data.get("long")
        }
    }

    # Upsert (update if exists, else create)
    existing = profiles_collection.find_one({"user_id": str(user["_id"])})

    if existing:
        profiles_collection.update_one(
            {"user_id": str(user["_id"])},
            {"$set": profile_data}
        )
        return jsonify({"message": "Profile updated successfully"})
    else:
        profiles_collection.insert_one(profile_data)
        return jsonify({"message": "Profile created successfully"})