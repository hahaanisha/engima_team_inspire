from flask import Flask, request, jsonify
from flask_cors import CORS
from routes.auth import auth_bp
from routes.makeTwin import make_twin_bp
from routes.scoreAgent import score_bp
from routes.InsightsAgent import insights_bp
from routes.simulateAgent import simulate_bp

app = Flask(__name__)
CORS(app)


app.register_blueprint(auth_bp)
app.register_blueprint(make_twin_bp)
app.register_blueprint(score_bp)
app.register_blueprint(insights_bp)
app.register_blueprint(simulate_bp)

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "Flask API is running"
    })
@app.route('/favicon.ico')
def favicon():
    return '', 204

# Health Check Route
@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "success",
        "message": "API working properly"
    })


# Example POST API
@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json()

        # Example processing
        response = {
            "received_data": data,
            "result": "Processing successful"
        }

        return jsonify(response), 200

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500




# Run Server
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
    