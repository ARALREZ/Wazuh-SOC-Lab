#!/usr/bin/env bash
# Narrow emergency cleanup for the Kali test-source block only.
# This script never flushes chains or changes firewall policies.
set -Eeuo pipefail

TEST_SOURCE="192.168.122.112"
RULE_SPEC=( -s "$TEST_SOURCE" -j DROP )

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run on my-agent as root: sudo $0 --remove-kali-drop" >&2
  exit 1
fi

if [[ "${1:-}" != "--remove-kali-drop" ]]; then
  echo "No changes made. This helper only removes an exact INPUT DROP for $TEST_SOURCE."
  echo "Inspect first: sudo ./scripts/inspect_firewall.sh"
  echo "To request the narrow cleanup: sudo $0 --remove-kali-drop"
  exit 0
fi

echo "Current matching INPUT rules:"
iptables -S INPUT | grep -F -- "-s $TEST_SOURCE" | grep -F -- "-j DROP" || true

if ! iptables -C INPUT "${RULE_SPEC[@]}" 2>/dev/null; then
  echo "No exact INPUT DROP rule for $TEST_SOURCE found. Nothing to remove."
  exit 0
fi

read -r -p "Remove ONLY the exact INPUT DROP rule for $TEST_SOURCE? Type YES: " answer
if [[ "$answer" != "YES" ]]; then
  echo "Cancelled. No changes made."
  exit 0
fi

while iptables -C INPUT "${RULE_SPEC[@]}" 2>/dev/null; do
  iptables -D INPUT "${RULE_SPEC[@]}"
done

echo "Removed exact test-source DROP rule(s) for $TEST_SOURCE."
echo "No other rules or firewall policies were modified."
echo "Re-check with: sudo ./scripts/inspect_firewall.sh"
