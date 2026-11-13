#!/usr/bin/env bash
# Read-only firewall and Wazuh Active Response inspection for Project 02.
set -Eeuo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run on my-agent as root: sudo $0" >&2
  exit 1
fi

echo "========== INPUT CHAIN (iptables) =========="
iptables -S INPUT

echo
echo "========== INPUT COUNTERS =========="
iptables -nvL INPUT --line-numbers

echo
echo "========== PROJECT 02 ACTIVE RESPONSE LOG =========="
AR_LOG="/var/ossec/logs/active-responses.log"
if [[ -r "$AR_LOG" ]]; then
  grep -E '100026|100027|firewall-drop|192\.168\.122\.112|command.*(add|delete)' "$AR_LOG" | tail -n 80 || true
else
  echo "Active Response log not readable: $AR_LOG"
fi

echo
echo "========== AGENT SERVICE =========="
systemctl is-active wazuh-agent || true
