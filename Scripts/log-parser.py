import os
import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

SPLUNK_HOST = "https://your-splunk-server:8089"
USERNAME = "admin"
PASSWORD = "your-password"
SEARCH_URL = f"{SPLUNK_HOST}/services/search/jobs/export"

# Define multiple queries
queries = {
    "failed_logins": 'search index=endpoint EventCode=4625 | table _time, Account_Name, Client_IP',
    "admin_logins": 'search index=endpoint EventCode=4672 | table _time, Account_Name, Logon_Type',
    "process_execution": 'search index=endpoint EventCode=1 | table _time, Parent_Process, New_Process, CommandLine'
}

# Define the shared folder mount point
DC_FOLDER = "/mnt/dc_logs"  # This is where the Windows share is mounted

# Ensure the mounted folder is accessible
if not os.path.exists(DC_FOLDER):
    print(f"Error: {DC_FOLDER} is not accessible. Is the share mounted?")
    exit()

# Function to decode any nested JSON fields
def decode_nested_json(entry):
    """Recursively decode JSON strings inside JSON fields."""
    for key, value in entry.items():
        if isinstance(value, str):  # Check if the value is a string
            try:
                decoded_value = json.loads(value)  # Try decoding it as JSON
                entry[key] = decoded_value  # Replace with parsed JSON
            except (json.JSONDecodeError, TypeError):
                pass  # Skip if it's not valid JSON
    return entry

# Loop through each query
for query_name, search_query in queries.items():
    print(f"Running query: {query_name}")

    params = {
        "search": search_query,
        "output_mode": "json"
    }

    response = requests.post(SEARCH_URL, auth=(USERNAME, PASSWORD), verify=False, data=params)

    try:
        # Process newline-separated JSON (Splunk returns multiple JSON objects on new lines)
        json_objects = [json.loads(line) for line in response.text.strip().split("\n") if line]

        # Decode nested JSON inside results
        cleaned_results = [decode_nested_json(entry) for entry in json_objects]

        # Save results in the mounted DC shared folder
        filename = os.path.join(DC_FOLDER, f"{query_name}.json")
        with open(filename, "a", encoding="utf-8") as log_file:
            for entry in cleaned_results:
                json.dump(entry, log_file)  # Append each entry as valid JSON
                log_file.write("\n")  # Newline for JSONL format

        print(f"Successfully appended results to {filename} on the Domain Controller")

    except json.JSONDecodeError as e:
        print(f"JSON Decode Error for {query_name}: {e}")
        print("Raw Response:", response.text)
    except Exception as e:
        print(f"Unexpected Error for {query_name}: {e}")
