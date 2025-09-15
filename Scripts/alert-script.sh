#!/bin/bash

# Splunk API Credentials
SPLUNK_HOST="http://localhost:8089"
USERNAME="admin"
PASSWORD="yourpassword"

# Log file for storing anomalies
LOG_FILE="/var/log/splunk_anomalies.log"

# Thresholds for anomaly detection
FAILED_LOGIN_THRESHOLD=5
ADMIN_LOGIN_THRESHOLD=3

# Function to query Splunk API
query_splunk() {
    local search_query="$1"
    local search_url="${SPLUNK_HOST}/services/search/jobs"

    # Start a search job
    RESPONSE=$(curl -s -k -u "${USERNAME}:${PASSWORD}" --data-urlencode "search=search ${search_query}" \
        --data "output_mode=json&exec_mode=blocking" "${search_url}")

    SID=$(echo "$RESPONSE" | jq -r '.sid')
    
    if [[ -z "$SID" || "$SID" == "null" ]]; then
        echo "Error: Failed to retrieve SID for query: $search_query" >> "$LOG_FILE"
        return 1
    fi

    # Get search results
    RESULTS_URL="${SPLUNK_HOST}/services/search/jobs/${SID}/results?output_mode=json"
    RESULTS=$(curl -s -k -u "${USERNAME}:${PASSWORD}" "${RESULTS_URL}")

    echo "$RESULTS"
}

# Check for multiple failed logins from the same IP
check_failed_logins() {
    QUERY='index=endpoint EventCode=4625 | stats count by Client_IP | where count > '"${FAILED_LOGIN_THRESHOLD}"
    RESULTS=$(query_splunk "$QUERY")
    
    if echo "$RESULTS" | jq -e '.results | length > 0' >/dev/null; then
        echo "$(date) - 🚨 Anomaly Detected: Multiple failed logins detected!" >> "$LOG_FILE"
        echo "$RESULTS" | jq '.results[] | {IP: .Client_IP, Attempts: .count}' >> "$LOG_FILE"
    fi
}

# Check for excessive admin logins
check_admin_logins() {
    QUERY='index=endpoint EventCode=4672 | stats count by Account_Name | where count > '"${ADMIN_LOGIN_THRESHOLD}"
    RESULTS=$(query_splunk "$QUERY")
    
    if echo "$RESULTS" | jq -e '.results | length > 0' >/dev/null; then
        echo "$(date) - 🚨 Anomaly Detected: Unusual number of admin logins!" >> "$LOG_FILE"
        echo "$RESULTS" | jq '.results[] | {Admin: .Account_Name, Logins: .count}' >> "$LOG_FILE"
    fi
}

# Check for suspicious process execution (e.g., PowerShell)
check_process_execution() {
    QUERY='index=endpoint EventCode=1 | search CommandLine="*powershell*" | table _time, Parent_Process, New_Process, CommandLine'
    RESULTS=$(query_splunk "$QUERY")
    
    if echo "$RESULTS" | jq -e '.results | length > 0' >/dev/null; then
        echo "$(date) - 🚨 Anomaly Detected: Suspicious process execution detected!" >> "$LOG_FILE"
        echo "$RESULTS" | jq '.results[]' >> "$LOG_FILE"
    fi
}

# Run all anomaly checks
check_failed_logins
check_admin_logins
check_process_execution

echo "$(date) - ✅ Anomaly detection script completed." >> "$LOG_FILE"
