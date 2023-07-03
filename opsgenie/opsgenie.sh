#!/bin/bash

api_key="YOUR_OPSGENIE_API_KEY"

create_alert_url="http://localhost:5000/v2/alerts"
close_alert_url="http://localhost:5000/v2/alerts/close"
list_alerts_url="http://localhost:5000/v2/alerts"

send_opsgenie_alert() {
priority="$1"
message="$2"

bash
Copy code
headers=(
    "Content-Type: application/json"
    "Authorization: GenieKey $api_key"
)

payload=$(cat <<EOF
{
"message": "$message",
"priority": "$priority"
}
EOF
)

bash
Copy code
response=$(curl -s -X POST -H "${headers[@]}" -d "$payload" "$create_alert_url")

if [[ $(jq -r '.status_code' <<<"$response") == 202 ]]; then
    echo "Alert sent to Opsgenie successfully!"
    alert_id=$(jq -r '.data.id' <<<"$response")
    echo "$alert_id"
else
    echo "Failed to send alert to Opsgenie. Status Code: $(jq -r '.status_code' <<<"$response")"
    echo "Response: $(jq -r '.text' <<<"$response")"
fi
}

close_opsgenie_alert() {
alert_id="$1"

bash
Copy code
headers=(
    "Content-Type: application/json"
    "Authorization: GenieKey $api_key"
)

payload=$(cat <<EOF
{
"id": "$alert_id"
}
EOF
)

bash
Copy code
response=$(curl -s -X POST -H "${headers[@]}" -d "$payload" "$close_alert_url")

if [[ $(jq -r '.status_code' <<<"$response") == 200 ]]; then
    echo "Alert closed successfully!"
else
    echo "Failed to close alert. Status Code: $(jq -r '.status_code' <<<"$response")"
    echo "Response: $(jq -r '.text' <<<"$response")"
fi
}

get_related_alerts() {
incident_message="$1"

bash
Copy code
headers=(
    "Content-Type: application/json"
    "Authorization: GenieKey $api_key"
)

params=(
    "query=$incident_message"
)

response=$(curl -s -X GET -H "${headers[@]}" "$list_alerts_url?${params[*]}")

if [[ $(jq -r '.status_code' <<<"$response") == 200 ]]; then
    data=$(jq -r '.data' <<<"$response")
    echo "$data"
else
    echo "Failed to get related alerts. Status Code: $(jq -r '.status_code' <<<"$response")"
    echo "Response: $(jq -r '.text' <<<"$response")"
fi
}

print_usage() {
  echo "Usage: ./script.sh <priority> <message> <incident_still_exists>"
  echo "Parameters:"
  echo " <priority> Priority of the alert (P1, P2, P3, P4)"
  echo " <message> The incident message to check"
  echo " <incident_still_exists> Incident existence status (true/false)"
  exit 1
}

Validate and retrieve command-line arguments
if [[ $# != 3 ]]; then
  print_usage
fi

priority="$1"
incident_message="$2"
incident_still_exists="${3,,}"

Validate incident parameter
if [[ ! $incident_still_exists =~ ^(true|false)$ ]]; then
  echo "Invalid value for <incident_still_exists>. Use 'true' or 'false'."
  echo "Value: $incident_still_exists"
  print_usage
fi

Validate priority parameter
valid_priorities=("P1" "P2" "P3" "P4")
if [[ ! " ${valid_priorities[]} " =~ " $priority " ]]; then
  echo "Invalid value for <priority>. Use one of: ${valid_priorities[]}"
  print_usage
fi

if [[ $incident_still_exists == "false" ]]; then
# Check if there are related alerts
 related_alerts=$(get_related_alerts "$incident_message")
  if [[ -n $related_alerts ]]; then
  # Close related alerts
  while IFS= read -r alert; do
    close_opsgenie_alert "$alert"
  done <<<"$related_alerts"
  echo "Resolved incident. Closed related alerts."
  else
   echo "Resolved incident. No related alerts to close."
  fi
else
# Check if there are related alerts
  related_alerts=$(get_related_alerts "$incident_message")
  if [[ -n $related_alerts ]]; then
    echo "Incident still exists. Related alerts already present."
  else
  # Send a new alert
    send_opsgenie_alert "$priority" "$incident_message"
  fi
fi
