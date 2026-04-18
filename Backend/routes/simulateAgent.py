from flask import Blueprint, request, jsonify
from pymongo import MongoClient
from bson.objectid import ObjectId
import os
import requests
from dotenv import load_dotenv
import re
import json
import base64

load_dotenv()

simulate_bp = Blueprint("simulate", __name__)

# -------------------------
# ENV
# -------------------------
VERIFY_TOKEN = os.getenv("VERIFY_TOKEN")
ACCESS_TOKEN = os.getenv("ACCESS_TOKEN")
PHONE_NUMBER_ID = os.getenv("PHONE_NUMBER_ID")
FEATHERLESS_API_KEY = os.getenv("FEATHERLESS_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")          # Add to your .env

# -------------------------
# DB
# -------------------------
client = MongoClient(os.getenv("MONGO_URI"))
db = client["biosync"]

users_collection = db["users"]
profiles_collection = db["profiles"]

# -------------------------
# In-memory session store
# Key  : mobile (full WhatsApp number with country code)
# Value: dict with mode, state, and temp data
# -------------------------
sessions = {}

# -------------------------
# Diet Preference Map
# -------------------------
DIET_PREFERENCES = {
    "1": "Vegetarian",
    "2": "Non-Vegetarian",
    "3": "Jain",
    "4": "Vegan",
}

DIET_PREF_MENU = (
    "🌿 *Select your diet preference:*\n\n"
    "1️⃣ Vegetarian\n"
    "2️⃣ Non-Vegetarian\n"
    "3️⃣ Jain\n"
    "4️⃣ Vegan\n\n"
    "Reply with *1, 2, 3 or 4*"
)

MAIN_MENU = (
    "👋 Welcome to *Health Twin Bot*!\n\n"
    "What would you like to do?\n\n"
    "1️⃣  What-If Scenario Simulator\n"
    "2️⃣  Diet Agent\n"
    "3️⃣  Food Photo Analyser\n"
    "4️⃣  My Health Profile\n\n"
    "Reply with *1, 2, 3 or 4*"
)


# ============================================================
# HELPERS
# ============================================================

def strip_country_code(mobile):
    """WhatsApp sends 919876543210 → returns last 10 digits."""
    if len(mobile) > 10:
        return mobile[-10:]
    return mobile


def get_user_and_profile(mobile_raw):
    mobile = strip_country_code(mobile_raw)
    user = users_collection.find_one({"mobile": mobile})
    if not user:
        return None, None, mobile
    profile = profiles_collection.find_one({"user_id": str(user["_id"])})
    return user, profile, mobile


def format_profile(profile):
    """Returns (profile_text_str, list_of_missing_field_names)."""
    fields = {
        "Age": profile.get("age"),
        "Gender": profile.get("gender"),
        "Height (cm)": profile.get("height_cm"),
        "Weight (kg)": profile.get("weight_kg"),
        "Daily Steps": profile.get("daily_steps"),
        "Sleep Duration": profile.get("sleep_duration"),
        "Sitting Time": profile.get("sitting_time"),
        "Exercise Frequency": profile.get("exercise_frequency"),
        "Medical Conditions": profile.get("medical_conditions"),
        "Family History": profile.get("family_history"),
        "Resting Heart Rate": profile.get("resting_heart_rate"),
        "Smoking": profile.get("smoking"),
        "Alcohol": profile.get("alcohol"),
        "Stress Level": profile.get("stress_level"),
    }
    lines, missing = [], []
    for key, val in fields.items():
        if val is not None and val != "" and val != []:
            lines.append(f"{key}: {val}")
        else:
            missing.append(key)
    return "\n".join(lines), missing


def clean_json(raw):
    cleaned = re.sub(r"```json|```", "", raw).strip()
    return json.loads(cleaned)


def send_whatsapp_message(to, message):
    url = f"https://graph.facebook.com/v18.0/{PHONE_NUMBER_ID}/messages"
    requests.post(
        url,
        json={
            "messaging_product": "whatsapp",
            "to": to,
            "type": "text",
            "text": {"body": message},
        },
        headers={
            "Authorization": f"Bearer {ACCESS_TOKEN}",
            "Content-Type": "application/json",
        },
    )


def download_whatsapp_media(media_id):
    """Returns (base64_str, mime_type) for a WhatsApp media object."""
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    meta = requests.get(
        f"https://graph.facebook.com/v18.0/{media_id}", headers=headers
    ).json()
    media_url = meta.get("url")
    mime_type = meta.get("mime_type", "image/jpeg")
    if not media_url:
        return None, None
    img_bytes = requests.get(media_url, headers=headers).content
    return base64.b64encode(img_bytes).decode("utf-8"), mime_type


# ============================================================
# AI CALLS
# ============================================================

def call_ai_whatif(profile_text, scenario):
    prompt = f"""
You are a strict health simulation engine.

Decide if the user's profile has ENOUGH data to answer the scenario.

If SUFFICIENT → return ONLY this JSON:
{{
  "sufficient": true,
  "impact": "positive/negative/neutral",
  "score_change": "+X or -X",
  "risk_change": {{
    "diabetes": "increase/decrease/no change",
    "heart": "increase/decrease/no change",
    "hypertension": "increase/decrease/no change"
  }},
  "advice": ["suggestion 1", "suggestion 2"]
}}

If NOT SUFFICIENT → return ONLY this JSON:
{{
  "sufficient": false,
  "missing_fields": ["field1", "field2"],
  "message": "human-readable explanation of what is needed and why"
}}

User Profile:
{profile_text}

Scenario:
{scenario}
"""
    resp = requests.post(
        "https://api.featherless.ai/v1/chat/completions",
        headers={"Authorization": f"Bearer {FEATHERLESS_API_KEY}"},
        json={
            "model": "deepseek-ai/DeepSeek-V3-0324",
            "messages": [{"role": "user", "content": prompt}],
        },
    )
    return clean_json(resp.json()["choices"][0]["message"]["content"])


def call_ai_diet(profile_text, preference, query=None):
    user_query = query or "Give me a personalised diet plan."
    prompt = f"""
You are a professional diet and nutrition advisor.

The user follows a *{preference}* diet. Strictly respect this — do NOT suggest anything outside this category.

Return ONLY this JSON (no extra text):
{{
  "diet_plan": {{
    "breakfast": "detailed suggestion",
    "lunch": "detailed suggestion",
    "dinner": "detailed suggestion",
    "snacks": "detailed suggestion"
  }},
  "foods_to_avoid": ["item1", "item2", "item3"],
  "tips": ["tip1", "tip2", "tip3"],
  "note": "important medical/health note based on their profile"
}}

User Profile:
{profile_text}

Diet Preference: {preference}

User Query: {user_query}
"""
    resp = requests.post(
        "https://api.featherless.ai/v1/chat/completions",
        headers={"Authorization": f"Bearer {FEATHERLESS_API_KEY}"},
        json={
            "model": "deepseek-ai/DeepSeek-V3-0324",
            "messages": [{"role": "user", "content": prompt}],
        },
    )
    return clean_json(resp.json()["choices"][0]["message"]["content"])


def call_gemini_food_analysis(image_b64, mime_type, profile_text, preference):
    # Use the same model + URL pattern as the working dfu.py
    GEMINI_URL = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-3.1-flash-image-preview:generateContent?key={GEMINI_API_KEY}"
    )

    prompt_text = f"""
You are a nutrition expert and health coach.

The user has sent a photo of their food/meal. Analyse it carefully.

Diet preference: {preference}
Health profile:
{profile_text}

Tasks:
1. Identify all visible food items.
2. Estimate nutritional breakdown (calories, protein, carbs, fats, fibre).
3. Flag any item that conflicts with their diet preference ({preference}).
4. Based on their health profile and medical conditions, give personalised feedback.

Respond ONLY in JSON format:
{{
  "food_items": ["item1", "item2"],
  "nutrition_estimate": {{
    "calories": "~XXX kcal",
    "protein": "~Xg",
    "carbs": "~Xg",
    "fats": "~Xg",
    "fibre": "~Xg"
  }},
  "preference_conflicts": [],
  "health_feedback": {{
    "positives": ["what is good for their profile"],
    "concerns": ["concerns given their medical conditions"],
    "alternatives": ["healthier swap suggestions"]
  }},
  "overall_rating": "Healthy / Moderate / Needs Improvement",
  "summary": "2-3 line plain-language summary for the user"
}}
"""

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt_text},
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": image_b64
                        }
                    }
                ]
            }
        ]
    }

    resp = requests.post(
        GEMINI_URL,
        headers={"Content-Type": "application/json"},
        json=payload,
        timeout=20
    )

    resp_json = resp.json()

    # Log full response for debugging
    print("Gemini raw response:", json.dumps(resp_json, indent=2))

    # Check for API-level error (e.g. wrong model, bad key)
    if "error" in resp_json:
        raise Exception(f"Gemini API error: {resp_json['error'].get('message', str(resp_json['error']))}")

    raw = resp_json["candidates"][0]["content"]["parts"][0]["text"]
    return clean_json(raw)


# ============================================================
# FORMATTERS
# ============================================================

def format_whatif(result):
    try:
        rc = result["risk_change"]
        return (
            f"📊 *What-If Simulation Result*\n\n"
            f"*Impact:* {result.get('impact', 'N/A').capitalize()}\n"
            f"*Health Score Change:* {result.get('score_change', 'N/A')}\n\n"
            f"*Risk Changes:*\n"
            f"  🩸 Diabetes: {rc['diabetes']}\n"
            f"  ❤️ Heart: {rc['heart']}\n"
            f"  💉 Hypertension: {rc['hypertension']}\n\n"
            f"*Advice:*\n"
            f"  ✅ {result['advice'][0]}\n"
            f"  ✅ {result['advice'][1]}"
        )
    except Exception:
        return "⚠️ Error processing simulation result."


def format_diet(result, preference):
    try:
        dp = result.get("diet_plan", {})
        avoid = "\n".join(f"  ❌ {i}" for i in result.get("foods_to_avoid", []))
        tips = "\n".join(f"  💡 {t}" for t in result.get("tips", []))
        return (
            f"🥗 *Your Personalised {preference} Diet Plan*\n\n"
            f"🌅 *Breakfast:* {dp.get('breakfast', 'N/A')}\n\n"
            f"☀️ *Lunch:* {dp.get('lunch', 'N/A')}\n\n"
            f"🌙 *Dinner:* {dp.get('dinner', 'N/A')}\n\n"
            f"🍎 *Snacks:* {dp.get('snacks', 'N/A')}\n\n"
            f"*Foods to Avoid:*\n{avoid}\n\n"
            f"*Tips:*\n{tips}\n\n"
            f"📝 *Note:* {result.get('note', '')}"
        )
    except Exception:
        return "⚠️ Error processing diet result."


def format_food_analysis(result):
    try:
        items = ", ".join(result.get("food_items", []))
        nu = result.get("nutrition_estimate", {})
        conflicts = result.get("preference_conflicts", [])
        hf = result.get("health_feedback", {})

        positives = "\n".join(f"  ✅ {p}" for p in hf.get("positives", []))
        concerns = "\n".join(f"  ⚠️ {c}" for c in hf.get("concerns", []))
        alternatives = "\n".join(f"  🔄 {a}" for a in hf.get("alternatives", []))

        conflict_block = ""
        if conflicts:
            conflict_block = "\n*Diet Preference Conflicts:*\n" + "\n".join(
                f"  🚫 {c}" for c in conflicts
            ) + "\n"

        return (
            f"🍽️ *Food Analysis Result*\n\n"
            f"*Detected Items:* {items}\n\n"
            f"*Nutrition Estimate:*\n"
            f"  🔥 Calories: {nu.get('calories', 'N/A')}\n"
            f"  💪 Protein:  {nu.get('protein', 'N/A')}\n"
            f"  🍞 Carbs:    {nu.get('carbs', 'N/A')}\n"
            f"  🧈 Fats:     {nu.get('fats', 'N/A')}\n"
            f"  🌾 Fibre:    {nu.get('fibre', 'N/A')}\n"
            f"{conflict_block}\n"
            f"*What's Good:*\n{positives}\n\n"
            f"*Watch Out For:*\n{concerns}\n\n"
            f"*Healthier Alternatives:*\n{alternatives}\n\n"
            f"*Overall Rating:* {result.get('overall_rating', 'N/A')}\n\n"
            f"📋 *Summary:* {result.get('summary', '')}"
        )
    except Exception:
        return "⚠️ Error processing food analysis."


def format_health_profile_readable(profile):
    def val(key):
        v = profile.get(key)
        return v if (v is not None and v != "" and v != []) else "Not provided"

    bmi_line = ""
    try:
        h = float(profile.get("height_cm") or 0)
        w = float(profile.get("weight_kg") or 0)
        if h > 0 and w > 0:
            bmi = w / ((h / 100) ** 2)
            cat = (
                "Underweight" if bmi < 18.5
                else "Normal" if bmi < 25
                else "Overweight" if bmi < 30
                else "Obese"
            )
            bmi_line = f"  📐 BMI: {bmi:.1f} ({cat})\n"
    except Exception:
        pass

    return (
        f"👤 *Your Health Profile*\n\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"*Basic Info*\n"
        f"  🎂 Age: {val('age')}\n"
        f"  🧍 Gender: {val('gender')}\n"
        f"  📏 Height: {val('height_cm')} cm\n"
        f"  ⚖️ Weight: {val('weight_kg')} kg\n"
        f"{bmi_line}"
        f"\n━━━━━━━━━━━━━━━━━━━━\n"
        f"*Daily Activity*\n"
        f"  🚶 Daily Steps: {val('daily_steps')}\n"
        f"  🏋️ Exercise Frequency: {val('exercise_frequency')}\n"
        f"  🪑 Sitting Time: {val('sitting_time')}\n"
        f"  😴 Sleep Duration: {val('sleep_duration')}\n"
        f"\n━━━━━━━━━━━━━━━━━━━━\n"
        f"*Vitals*\n"
        f"  ❤️ Resting Heart Rate: {val('resting_heart_rate')}\n"
        f"\n━━━━━━━━━━━━━━━━━━━━\n"
        f"*Medical Info*\n"
        f"  🏥 Medical Conditions: {val('medical_conditions')}\n"
        f"  🧬 Family History: {val('family_history')}\n"
        f"\n━━━━━━━━━━━━━━━━━━━━\n"
        f"*Lifestyle*\n"
        f"  🚬 Smoking: {val('smoking')}\n"
        f"  🍺 Alcohol: {val('alcohol')}\n"
        f"  😰 Stress Level: {val('stress_level')}\n"
        f"\n━━━━━━━━━━━━━━━━━━━━\n"
        f"Type *Menu* to go back anytime."
    )


# ============================================================
# VERIFY WEBHOOK (GET)
# ============================================================
@simulate_bp.route("/webhook", methods=["GET"])
def verify_webhook():
    token = request.args.get("hub.verify_token")
    challenge = request.args.get("hub.challenge")
    if token == VERIFY_TOKEN:
        return challenge, 200
    return "Verification failed", 403


# ============================================================
# RECEIVE MESSAGE (POST)
# ============================================================
@simulate_bp.route("/webhook", methods=["POST"])
def webhook():
    data = request.get_json()

    # ── Parse incoming payload ──────────────────────────────
    try:
        message = data["entry"][0]["changes"][0]["value"]["messages"][0]
        mobile = message["from"]
        msg_type = message.get("type", "text")
    except Exception:
        return "No message", 200

    user_msg = ""
    media_id = None
    media_mime = None

    if msg_type == "text":
        user_msg = message["text"]["body"].strip()
    elif msg_type == "image":
        media_id = message["image"]["id"]
        media_mime = message["image"].get("mime_type", "image/jpeg")
        user_msg = message["image"].get("caption", "").strip()
    else:
        send_whatsapp_message(mobile, "⚠️ Please send text or an image. Type *Hi* to start.")
        return "OK", 200

    user_msg_lower = user_msg.lower()
    session = sessions.get(mobile, {})

    # ============================================================
    # GLOBAL RESET: Hi / menu keywords
    # ============================================================
    if user_msg_lower in ["hi", "hello", "start", "menu", "help"]:
        sessions[mobile] = {}
        send_whatsapp_message(mobile, MAIN_MENU)
        return "OK", 200

    # ============================================================
    # TOP-LEVEL OPTION SELECTION (no active session)
    # ============================================================
    if not session and user_msg_lower in ["1", "2", "3", "4"]:

        if user_msg_lower == "1":
            # ── What-If ────────────────────────────────────────
            sessions[mobile] = {"mode": "whatif", "state": "awaiting_scenario"}
            send_whatsapp_message(
                mobile,
                "🔮 *What-If Scenario Simulator*\n\n"
                "Ask me anything like:\n"
                "  • What if I walk 10,000 steps daily?\n"
                "  • What if I quit smoking?\n"
                "  • What if I sleep 8 hours every night?\n\n"
                "Go ahead, ask your scenario! 👇",
            )

        elif user_msg_lower == "2":
            # ── Diet Agent: first ask preference ───────────────
            sessions[mobile] = {"mode": "diet", "state": "awaiting_preference"}
            send_whatsapp_message(mobile, "🥗 *Diet Agent*\n\n" + DIET_PREF_MENU)

        elif user_msg_lower == "3":
            # ── Food Photo: first ask preference ───────────────
            sessions[mobile] = {"mode": "photo", "state": "awaiting_preference"}
            send_whatsapp_message(
                mobile,
                "📸 *Food Photo Analyser*\n\n"
                "First, let me know your diet preference so I can flag any conflicts.\n\n"
                + DIET_PREF_MENU,
            )

        elif user_msg_lower == "4":
            # ── Health Profile: instant display ────────────────
            user, profile, m = get_user_and_profile(mobile)
            if not user:
                send_whatsapp_message(mobile, f"❌ No account found for your number ({m}).\n\nType *Hi* to restart.")
            elif not profile:
                send_whatsapp_message(mobile, "❌ No health profile found. Please complete your profile first.")
            else:
                send_whatsapp_message(mobile, format_health_profile_readable(profile))
            sessions.pop(mobile, None)

        return "OK", 200

    # ============================================================
    # MODE: WHAT-IF
    # ============================================================
    if session.get("mode") == "whatif":
        state = session.get("state")

        # ── Receive scenario ────────────────────────────────────
        if state == "awaiting_scenario":
            scenario = user_msg
            sessions[mobile]["scenario"] = scenario
            sessions[mobile]["state"] = "processing"
            send_whatsapp_message(mobile, "⏳ Analysing your scenario, please wait...")

            user, profile, m = get_user_and_profile(mobile)
            if not user:
                send_whatsapp_message(mobile, f"❌ No account found ({m}).\n\nType *Hi* to restart.")
                sessions.pop(mobile, None)
                return "OK", 200
            if not profile:
                send_whatsapp_message(mobile, "❌ Profile not found.\n\nType *Hi* to restart.")
                sessions.pop(mobile, None)
                return "OK", 200

            profile_text, _ = format_profile(profile)
            result = call_ai_whatif(profile_text, scenario)

            if not result.get("sufficient", True):
                missing_str = ", ".join(result.get("missing_fields", []))
                sessions[mobile]["state"] = "awaiting_extra_data"
                sessions[mobile]["missing_fields"] = result.get("missing_fields", [])
                send_whatsapp_message(
                    mobile,
                    f"🤔 I need a bit more info to answer that!\n\n"
                    f"📋 *Missing:* {missing_str}\n\n"
                    f"ℹ️ {result.get('message', '')}\n\n"
                    f"Please provide the missing details like this:\n"
                    f"_daily_steps: 5000, sleep_duration: 6 hours_",
                )
                return "OK", 200

            send_whatsapp_message(mobile, format_whatif(result))
            send_whatsapp_message(mobile, "Try another scenario? Type *1*\nOr go back to *Menu*")
            sessions.pop(mobile, None)
            return "OK", 200

        # ── Receive extra data after insufficient ───────────────
        if state == "awaiting_extra_data":
            extra_data = {}
            try:
                for pair in user_msg.split(","):
                    if ":" in pair:
                        k, v = pair.split(":", 1)
                        extra_data[k.strip().lower().replace(" ", "_")] = v.strip()
            except Exception:
                send_whatsapp_message(mobile, "⚠️ Use format: _field: value, field: value_")
                return "OK", 200

            scenario = session.get("scenario")
            sessions[mobile]["state"] = "processing"
            send_whatsapp_message(mobile, "⏳ Got it! Re-analysing with updated data...")

            user, profile, m = get_user_and_profile(mobile)
            if profile:
                profile.update(extra_data)
            profile_text, _ = format_profile(profile)
            result = call_ai_whatif(profile_text, scenario)

            send_whatsapp_message(mobile, format_whatif(result))
            send_whatsapp_message(mobile, "Try another scenario? Type *1*\nOr go back to *Menu*")
            sessions.pop(mobile, None)
            return "OK", 200

    # ============================================================
    # MODE: DIET AGENT
    # ============================================================
    if session.get("mode") == "diet":
        state = session.get("state")

        # ── Select preference ───────────────────────────────────
        if state == "awaiting_preference":
            pref = DIET_PREFERENCES.get(user_msg_lower)
            if not pref:
                send_whatsapp_message(mobile, "⚠️ Please reply with *1, 2, 3 or 4* to select your diet preference.")
                return "OK", 200

            sessions[mobile]["preference"] = pref
            sessions[mobile]["state"] = "awaiting_query"
            send_whatsapp_message(
                mobile,
                f"✅ Got it! *{pref}* diet selected.\n\n"
                f"🥗 What kind of diet plan do you need?\n\n"
                f"Examples:\n"
                f"  • Give me a weight loss diet\n"
                f"  • What should I eat for better heart health?\n"
                f"  • Meal plan for high blood pressure\n\n"
                f"Or reply *go* for a general personalised plan! 👇",
            )
            return "OK", 200

        # ── Receive query, generate plan ────────────────────────
        if state == "awaiting_query":
            query = None if user_msg_lower == "go" else user_msg
            preference = session.get("preference", "Vegetarian")
            send_whatsapp_message(mobile, f"⏳ Preparing your {preference} diet plan...")

            user, profile, m = get_user_and_profile(mobile)
            if not user:
                send_whatsapp_message(mobile, f"❌ No account found ({m}).\n\nType *Hi* to restart.")
                sessions.pop(mobile, None)
                return "OK", 200
            if not profile:
                send_whatsapp_message(mobile, "❌ Profile not found.\n\nType *Hi* to restart.")
                sessions.pop(mobile, None)
                return "OK", 200

            profile_text, _ = format_profile(profile)
            result = call_ai_diet(profile_text, preference, query)
            send_whatsapp_message(mobile, format_diet(result, preference))
            send_whatsapp_message(mobile, "Want another plan? Type *2*\nOr go back to *Menu*")
            sessions.pop(mobile, None)
            return "OK", 200

    # ============================================================
    # MODE: FOOD PHOTO ANALYSER
    # ============================================================
    if session.get("mode") == "photo":
        state = session.get("state")

        # ── Select preference ───────────────────────────────────
        if state == "awaiting_preference":
            pref = DIET_PREFERENCES.get(user_msg_lower)
            if not pref:
                send_whatsapp_message(mobile, "⚠️ Please reply with *1, 2, 3 or 4* to select your diet preference.")
                return "OK", 200

            sessions[mobile]["preference"] = pref
            sessions[mobile]["state"] = "awaiting_photo"
            send_whatsapp_message(
                mobile,
                f"✅ *{pref}* preference noted!\n\n"
                f"📸 Now send me a photo of your food/meal and I'll analyse it!\n\n"
                f"_(Make sure the food is clearly visible in the image)_ 👇",
            )
            return "OK", 200

        # ── Receive photo → Gemini analysis ────────────────────
        if state == "awaiting_photo":
            if msg_type != "image" or not media_id:
                send_whatsapp_message(
                    mobile,
                    "📷 Please *send a photo* of your food.\n"
                    "Text messages won't work here — share an image!",
                )
                return "OK", 200

            preference = session.get("preference", "Vegetarian")
            send_whatsapp_message(mobile, "🔍 Analysing your food photo, please wait...")

            user, profile, m = get_user_and_profile(mobile)
            if not user:
                send_whatsapp_message(mobile, f"❌ No account found ({m}).\n\nType *Hi* to restart.")
                sessions.pop(mobile, None)
                return "OK", 200
            if not profile:
                send_whatsapp_message(mobile, "❌ Profile not found.\n\nType *Hi* to restart.")
                sessions.pop(mobile, None)
                return "OK", 200

            profile_text, _ = format_profile(profile)

            image_b64, mime_type = download_whatsapp_media(media_id)
            if not image_b64:
                send_whatsapp_message(mobile, "❌ Could not download the image. Please try again.")
                sessions.pop(mobile, None)
                return "OK", 200

            try:
                result = call_gemini_food_analysis(image_b64, mime_type, profile_text, preference)
                send_whatsapp_message(mobile, format_food_analysis(result))
            except Exception as e:
                print("⚠️ Gemini food analysis exception:", str(e))
                send_whatsapp_message(
                    mobile,
                    f"❌ Could not analyse the image.\n\n"
                    f"Reason: {str(e)}\n\n"
                    f"Please try again with a clearer photo, or type *Hi* to restart."
                )
                sessions.pop(mobile, None)
                return "OK", 200

            send_whatsapp_message(mobile, "Analyse another photo? Type *3*\nOr go back to *Menu*")
            sessions.pop(mobile, None)
            return "OK", 200

    # ============================================================
    # FALLBACK
    # ============================================================
    send_whatsapp_message(mobile, "❓ I didn't understand that.\n\nType *Hi* to see the main menu.")
    return "OK", 200