from flask import Flask, request, jsonify
import time
import random

app = Flask(__name__)

# Mock data
alerts = []

def generate_random_id():
    return random.randint(1000,99999)

@app.route("/v2/alerts", methods=["POST"])
def create_alert():
    data = request.get_json()
    alert_id = generate_random_id()
    data["id"] = alert_id

    alerts.append(data)

    #return jsonify({"result": "Alert created successfully"}), 202
    return jsonify({"data": data}), 202

@app.route("/v2/alerts/close", methods=["POST"])
def close_alert():
    data = request.get_json()
    identifier = data.get("indentifier")
    for alert in alerts:
        if alert.get("indentifier") == identifier or alert.get("message") == ide
ntifier:
            alerts.remove(alert)
            return jsonify({"result": "Alert closed successfully",})
    return jsonify({"result": "Alert not found"})

@app.route("/v2/alerts", methods=["GET"])
def list_alerts():
    query = request.args.get("query")
    print (query)
    filtered_alerts = []
    for alert in alerts:
        print (alert)
        if alert.get("message") == query:
            filtered_alerts.append(alert)
    return jsonify({"data": filtered_alerts})

if __name__ == "__main__":
    app.run()
