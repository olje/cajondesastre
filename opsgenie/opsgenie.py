import sys
import requests
import json

# Opsgenie API key
api_key = "YOUR_OPSGENIE_API_KEY"

# Opsgenie API endpoints
#create_alert_url = "https://api.opsgenie.com/v2/alerts"
#close_alert_url = "https://api.opsgenie.com/v2/alerts/close"
#list_alerts_url = "https://api.opsgenie.com/v2/alerts"

# Opsgenie API endpoints
create_alert_url = "http://localhost:5000/v2/alerts"
close_alert_url = "http://localhost:5000/v2/alerts/close"
list_alerts_url = "http://localhost:5000/v2/alerts"

def send_opsgenie_alert(priority, message):
    headers = {
        "Content-Type": "application/json",
        "Authorization": "GenieKey " + api_key
    }

    payload = {
        "message": message,
        "priority": priority
    }

    try:
        response = requests.post(create_alert_url, headers=headers, data=json.du
mps(payload))
        if response.status_code == 202:
            print("Alert sent to Opsgenie successfully!")
            return response.json().get("data").get("id")  # Return the alert ID
        else:
            print("Failed to send alert to Opsgenie. Status Code: {}".format(res
ponse.status_code))
            print("Response: {}".format(response.text))
    except requests.exceptions.RequestException as e:
        print("Failed to send alert to Opsgenie: {}".format(str(e)))

def close_opsgenie_alert(alert_id):
    headers = {
        "Content-Type": "application/json",
        "Authorization": "GenieKey " + api_key
    }

    payload = {
        "id": alert_id
    }

    try:
        response = requests.post(close_alert_url, headers=headers, data=json.dum
ps(payload))
        if response.status_code == 200:
            print("Alert closed successfully!")
        else:
            print("Failed to close alert. Status Code: {}".format(response.statu
s_code))
            print("Response: {}".format(response.text))
    except requests.exceptions.RequestException as e:
        print("Failed to close alert: {}".format(str(e)))

def get_related_alerts(incident_message):
    headers = {
        "Content-Type": "application/json",
        "Authorization": "GenieKey " + api_key
    }

    params = {
        "query": incident_message
    }

    try:
        response = requests.get(list_alerts_url, headers=headers, params=params)
        if response.status_code == 200:
            data = response.json().get("data", [])
            return data
        else:
            print("Failed to get related alerts. Status Code: {}".format(respons
e.status_code))
            print("Response: {}".format(response.text))
    except requests.exceptions.RequestException as e:
        print("Failed to get related alerts: {}".format(str(e)))

def print_usage():
    print("Usage: python script.py <priority> <message> <incident_still_exists>"
)
    print("Parameters:")
    print("  <priority>             Priority of the alert (P1, P2, P3, P4)")
    print("  <message>              The incident message to check")
    print("  <incident_still_exists>   Incident existence status (true/false)")
    sys.exit(1)

# Validate and retrieve command-line arguments
if len(sys.argv) != 4:
    print_usage()

priority = sys.argv[1]
incident_message = sys.argv[2]
incident_still_exists = sys.argv[3].lower()

# Validate incident parameter
if incident_still_exists not in ["true", "false"]:
    print("Invalid value for <incident_still_exists>. Use 'true' or 'false'.")
    print("Value: ", incident_still_exists)
    print_usage()

# Validate priority parameter
valid_priorities = ["P1", "P2", "P3", "P4"]
if priority not in valid_priorities:
    print("Invalid value for <priority>. Use one of: {}".format(", ".join(valid_
priorities)))
    print_usage()
print (incident_still_exists)

if incident_still_exists == "false" :
    # Check if there are related alerts
    print(incident_message)
    related_alerts = get_related_alerts(incident_message)
    print (related_alerts)
    if related_alerts:
        # Close related alerts
        for alert in related_alerts:
            close_opsgenie_alert(alert.get("message"))
        print("Resolved incident. Closed related alerts.")
    else:
        print("Resolved incident. No related alerts to close.")
else:
    # Check if there are related alerts
    related_alerts = get_related_alerts(incident_message)
    if related_alerts:
        print("Incident still exists. Related alerts already present.")
    else:
        # Send a new alert
        send_opsgenie_alert(priority, incident_message)
