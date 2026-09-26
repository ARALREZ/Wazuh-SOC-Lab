#!/usr/bin/env python3
import sys
import json
import subprocess
import logging
from datetime import datetime

# Logging configuration for Active Response debugging and auditing
LOG_FILE = "/var/ossec/logs/active-responses.log"
logging.basicConfig(filename=LOG_FILE, level=logging.INFO, 
                    format='%(asctime)s active-response/bin/docker_quarantine.py: %(message)s')

def read_alert():
    """Wazuh 4.x passes the JSON alert via standard input (STDIN)."""
    try:
        alert_input = sys.stdin.read()
        return json.loads(alert_input)
    except Exception as e:
        logging.error(f"Failed to read or parse Wazuh alert: {e}")
        sys.exit(1)

def kill_and_quarantine_container(container_id, container_name):
    """Stops the container and renames it to a blocked state for forensics analysis."""
    try:
        # 1. Forcefully terminate the container (SIGKILL)
        subprocess.run(["docker", "kill", container_id], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.info(f"Successfully killed unauthorized container. ID: {container_id}")

        # 2. Rename the container for audit/forensics purposes
        quarantine_name = f"QUARANTINED_{container_name}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        subprocess.run(["docker", "rename", container_name, quarantine_name], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.info(f"Container {container_id} renamed to {quarantine_name}")

    except subprocess.CalledProcessError as e:
        logging.error(f"Docker command failed: {e.stderr.decode().strip()}")
    except Exception as e:
        logging.error(f"Unexpected error during quarantine: {e}")

def main():
    # Retrieve alert data
    alert_data = read_alert()
    
    # Extract the command passed by Active Response (add / delete)
    command = alert_data.get("command", "")
    if command != "add":
        logging.info("Command is not 'add'. No action taken.")
        sys.exit(0)

    # Extract details from the docker-listener integration in Wazuh
    parameters = alert_data.get("parameters", {})
    alert = parameters.get("alert", {})
    data = alert.get("data", {})
    docker_context = data.get("docker", {})

    container_id = docker_context.get("id")
    container_name = docker_context.get("name")

    if container_id and container_name:
        logging.info(f"Triggering SOAR action for Privileged/Dangerous Container: {container_name} ({container_id})")
        kill_and_quarantine_container(container_id, container_name)
    else:
        logging.error("Container ID or Name not found in the alert payload.")

if __name__ == "__main__":
    main()
