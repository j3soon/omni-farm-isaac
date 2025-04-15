#!/bin/bash -e

show_help() {
    echo ""
    echo "Usage: $0 <job_definition>"
    echo "  job_definition:    Name of the job definition to save. A corresponding JSON file must exist under the 'job_definitions' directory with the corresponding name ('<job_definition>.json')."
    echo ""
    echo "Environment variables required:"
    echo "  FARM_URL:          Omniverse Farm URL"
    echo "  FARM_API_KEY:      Omniverse Farm API Key"
    echo "  NUCLEUS_IP:        Nucleus IP address"
    echo "  NUCLEUS_HOSTNAME:  Nucleus hostname"
}

check_environment_variable() {
    local var_name=$1
    if [ -z "${!var_name}" ]; then
        echo "Error: Environment variable $var_name is not defined."
        show_help
        exit 1
    fi
}

check_environment_variable "FARM_URL"
check_environment_variable "FARM_API_KEY"
check_environment_variable "NUCLEUS_IP"
check_environment_variable "NUCLEUS_HOSTNAME"

if [ "$#" -ne 1 ]; then
    echo "Error: Incorrect number of arguments. Expected 1, got $#."
    show_help
    exit 1
fi

# Using an undocumented API endpoint
echo "Parsing job definition..."
json_content=$(jq --arg name "$1" --arg ip "$NUCLEUS_IP" --arg hostname "$NUCLEUS_HOSTNAME" '
  .name = $name |
  .capacity_requirements.hostAliases = [
    {
      ip: $ip,
      hostnames: [$hostname]
    }
  ]
' "job_definitions/$1.json")
echo "Trying to remove job definition in case of job definition update..."
curl -X "POST" "${FARM_URL}/queue/management/jobs/remove" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-API-KEY: ${FARM_API_KEY}" \
    -d '{
        "job_definition_name": "'"$1"'"
    }'
echo -e "\nSaving job definition..."
curl -X "POST" "${FARM_URL}/queue/management/jobs/save" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-API-KEY: ${FARM_API_KEY}" \
    -d "$json_content"
