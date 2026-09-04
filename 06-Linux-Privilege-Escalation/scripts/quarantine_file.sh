#!/bin/bash
# ==============================================================================
# Script Name   : quarantine_file.sh
# Description   : SOAR Active Response script to quarantine malicious files.
#                 Parses JSON alert payload from Wazuh Manager, removes all 
#                 permissions (chmod 000), and sets the immutable attribute.
# Location      : /var/ossec/active-response/bin/quarantine_file.sh (on Agent)
# Author        : ARALREZ 
# ==============================================================================

# Read JSON payload passed by Wazuh Manager via standard input
read -r INPUT_JSON

# Extract the modified/created file path using 'jq'
FILE_PATH=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.syscheck.path // empty')

# Fallback: Check alternative JSON path for custom alerts
if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.data.file // empty')
fi

# Safety Validation: Ensure path exists and is NOT a critical system binary directory
if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    if [[ "$FILE_PATH" != /bin/* && "$FILE_PATH" != /sbin/* && "$FILE_PATH" != /usr/* && "$FILE_PATH" != /lib/* ]]; then
        
        # Action 1: Remove all read, write, and execute permissions for everyone
        chmod 000 "$FILE_PATH" 2>/dev/null
        
        # Action 2: Set file as immutable to prevent unauthorized modification or deletion
        chattr +i "$FILE_PATH" 2>/dev/null
        
        # Log local action for auditing
        echo "$(date) - Quarantined file: $FILE_PATH" >> /var/ossec/logs/active-responses.log
    fi
fi
