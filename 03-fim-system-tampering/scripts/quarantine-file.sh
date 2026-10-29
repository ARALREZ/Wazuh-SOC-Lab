#!/bin/bash
# quarantine-file.sh
# Active Response script for FIM critical file changes
# Quarantines the modified file (chmod 000 + chattr +i + move)



# remember chmod +x scripts/quarantine-file.sh
# sudo chmod 750 /var/ossec/active-response/bin/quarantine-file.sh
# sudo chown root:wazuh /var/ossec/active-response/bin/quarantine-file.sh



LOG_FILE="/var/ossec/logs/active-responses.log"
QUARANTINE_DIR="/var/ossec/quarantine"

mkdir -p "$QUARANTINE_DIR"

# Read JSON input from Wazuh
read -r INPUT

echo "$(date) - quarantine-file.sh started" >> "$LOG_FILE"
echo "$(date) - INPUT: $INPUT" >> "$LOG_FILE"

# Extract file path from the alert (multiple fallback methods)
FILE=$(echo "$INPUT" | grep -oP '"path":"\K[^"]+' || true)

if [ -z "$FILE" ]; then
  FILE=$(echo "$INPUT" | grep -oP '"file":"\K[^"]+' || true)
fi

if [ -z "$FILE" ]; then
  FILE=$(echo "$INPUT" | grep -oP '/etc/[^"]+' | head -1 || true)
fi

echo "$(date) - Detected FILE: $FILE" >> "$LOG_FILE"

if [ -z "$FILE" ] || [ ! -e "$FILE" ]; then
  echo "$(date) - ERROR: File not found or empty: '$FILE'" >> "$LOG_FILE"
  exit 1
fi

# Lock the file
chmod 000 "$FILE" 2>/dev/null
chattr +i "$FILE" 2>/dev/null

# Move to quarantine
BASENAME=$(basename "$FILE")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mv "$FILE" "$QUARANTINE_DIR/${BASENAME}_${TIMESTAMP}" 2>/dev/null

echo "$(date) - SUCCESS: Quarantined $FILE -> $QUARANTINE_DIR/${BASENAME}_${TIMESTAMP}" >> "$LOG_FILE"
exit 0
