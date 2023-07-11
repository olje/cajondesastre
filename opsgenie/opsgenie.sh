#!/bin/bash

api_key=$OPSGENIE_API_KEY

create_alert_url="https://api.eu.opsgenie.com/v2/alerts"
close_alert_url="https://api.eu.opsgenie.com/v2/alerts/"
list_alerts_url="https://api.eu.opsgenie.com/v2/alerts"

send_opsgenie_alert() {
priority="$1"
message="$2"

headers=(
    "Authorization: GenieKey $api_key"
)

headercontent=(
    "Content-type: application/json"
)

payload=$(cat <<EOF
{
"message": "$message",
"priority": "$priority",
"responders":[
        {"username":"jesusjavier.olearos@bit.admin.ch", "type":"user"},
        {"name":"APP-ABN", "type":"team"}
    ]
}
EOF
)

response=$(curl -X POST -H "$headers" -H "$headercontent" -d "$payload" "$create_alert_url")
alert_id=$(jq -r '.requestId' <<<"$response")
if [[ -n $alert_id ]]; then
    echo "Alert sent to Opsgenie successfully!"
    #echo "response: $response"
    #echo "$alert_id"
else
    echo "Failed to send alert to Opsgenie. RequestID: $(jq -r '.requestId' <<<"$response")"
    echo "Response: $response"
    return 1 
fi
}

close_opsgenie_alert() {
alertId="$1"

headers=(
    "Authorization: GenieKey $api_key"
)

payload=$(cat <<EOF
{
    "user":"Monitoring Script",
    "source":"automatic script TODO URL bitbucket",
    "note":"Action executed via Alert API"
}
EOF
)

response=$(curl -X POST -H "${headers[@]}" -H "Content-Type: application/json" -d "$payload" "$
close_alert_url/$alertId/close")

if [[ -z $(jq -r '.requestId' <<<"$response") ]]; then
    echo "Alert closed successfully!"
else
    echo "Failed to close alert. Status Code: "$response")"
fi
}

get_related_alerts() {
incident_message="$1"

headers=(
    "Authorization: GenieKey $api_key"
)

params=(
    "query=message:%20"$incident_message"%20AND%20status:%20open&limit=10&sort=createdAt&order=
desc"
)

response=$(curl -X GET -H "${headers[@]}" "$list_alerts_url?${params[@]}")

data=$(jq -r '.data[].id' <<<"$response")
 
if [[ -n $data ]]; then
  echo "$data"
else
  echo ""
  return -1
fi
}

print_usage() {
  echo "Usage: $0 <message> <priority P1-P4 or close>" 
  echo "Parameters:"
  echo " <message> The incident message to check"
  echo " <priority> Priority of the alert (P1, P2, P3, P4) or (close) to close the alert"
  exit 1
}

# Validate and retrieve command-line arguments
if [[ $# != 2 ]]; then
  print_usage
fi

priority="$2"
incident_message="$1"

# Validate priority parameter
valid_priorities=("P1" "P2" "P3" "P4" "close")
if [[ ! " ${valid_priorities[@]} " =~ " $priority " ]]; then
  echo "Invalid value for <priority>. Use one of: ${valid_priorities[@]}"
  print_usage
fi

# Check if there are related alerts
related_alerts=$(get_related_alerts "$incident_message")

if [[ $priority == "close" ]]; then
# Here we check if there are related alerts and if we close them
  if [ ${#related_alerts[@]} -ne 0 ]; then
  # Close related alerts
  while IFS= read -r alert; do
    close_opsgenie_alert "$alert"
  done <<<"$related_alerts"
    echo "Resolved incident. Closed related alerts."
  else
    echo "Resolved incident. No related alerts to close."
  fi
else
 if [[ -n $related_alerts ]]; then
   echo "Incident still exists. Related alerts already present."
 else
  # Send a new alert
    send_opsgenie_alert "$priority" "$incident_message"
  fi
fi
