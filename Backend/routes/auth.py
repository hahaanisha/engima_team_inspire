from flask import Blueprint, request, jsonify
from pymongo import MongoClient
import bcrypt
import os
from bson.objectid import ObjectId
from dotenv import load_dotenv

# Load env variables
load_dotenv()

auth_bp = Blueprint("auth", __name__)

# MongoDB connection
MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)
db = client["biosync"]
users_collection = db["users"]


# -------------------------
# Validate Mobile
# -------------------------
def is_valid_mobile(mobile):
    return mobile.isdigit() and len(mobile) == 10


# -------------------------
# Register users
# -------------------------
@auth_bp.route("/auth/register", methods=["POST"])
def register():
    data = request.json

    mobile = data.get("mobile")
    pin = data.get("pin")

    if not mobile or not pin:
        return jsonify({"error": "Mobile and PIN required"}), 400

    if not is_valid_mobile(mobile):
        return jsonify({"error": "Mobile number must be exactly 10 digits"}), 400

    if len(pin) != 4 or not pin.isdigit():
        return jsonify({"error": "PIN must be 4 digits"}), 400

    existing = users_collection.find_one({"mobile": mobile})

    if existing:
        return jsonify({"error": "User already registered"}), 400

    hashed_pin = bcrypt.hashpw(pin.encode("utf-8"), bcrypt.gensalt())

    user = {
        "mobile": mobile,
        "pin": hashed_pin
    }

    result = users_collection.insert_one(user)

    # Use ObjectId as token
    token = str(result.inserted_id)

    return jsonify({
        "message": "User registered successfully",
        "token": token
    })


# -------------------------
# Login
# -------------------------
@auth_bp.route("/auth/login", methods=["POST"])
def login():
    data = request.json

    mobile = data.get("mobile")
    pin = data.get("pin")

    if not mobile or not pin:
        return jsonify({"error": "Mobile and PIN required"}), 400

    if not is_valid_mobile(mobile):
        return jsonify({"error": "Invalid mobile number"}), 400

    user = users_collection.find_one({"mobile": mobile})

    if not user:
        return jsonify({"error": "User not found"}), 404

    stored_pin = user["pin"]

    if bcrypt.checkpw(pin.encode("utf-8"), stored_pin):

        token = str(user["_id"])  # ObjectId as token

        return jsonify({
            "message": "Login successful",
            "token": token
        })

    else:
        return jsonify({"error": "Invalid PIN"}), 401


# -------------------------
# Get user from token
# -------------------------
def get_user_from_token(request):
    auth_header = request.headers.get("Authorization")

    if not auth_header:
        return None, jsonify({"error": "Token missing"}), 401

    try:
        token = auth_header.split(" ")[1]  # Bearer <token>
        user = users_collection.find_one({"_id": ObjectId(token)})

        if not user:
            return None, jsonify({"error": "Invalid token"}), 401

        return user, None, None

    except:
        return None, jsonify({"error": "Invalid token format"}), 401
    