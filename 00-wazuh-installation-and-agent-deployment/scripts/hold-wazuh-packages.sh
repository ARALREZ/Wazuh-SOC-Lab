#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  echo "Usage: sudo $0 <server|agent>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
ROLE="$1"
[[ "$ROLE" == "server" || "$ROLE" == "agent" ]] || usage

if [[ ${EUID} -ne 0 ]]; then
  echo "ERROR: Run this script as root, for example: sudo bash $0 $ROLE" >&2
  exit 1
fi

command -v apt-mark >/dev/null || { echo "ERROR: apt-mark is unavailable." >&2; exit 1; }
command -v dpkg-query >/dev/null || { echo "ERROR: dpkg-query is unavailable." >&2; exit 1; }

if [[ "$ROLE" == "server" ]]; then
  PACKAGES=(wazuh-manager wazuh-indexer wazuh-dashboard filebeat)
else
  PACKAGES=(wazuh-agent)
fi

for package in "${PACKAGES[@]}"; do
  status="$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)"
  if [[ "$status" != "installed" ]]; then
    echo "ERROR: Required package '$package' is not installed on this host (status: ${status:-not found})." >&2
    exit 1
  fi
done

echo "Applying APT holds for role: $ROLE"
apt-mark hold "${PACKAGES[@]}"

WAZUH_SOURCE="/etc/apt/sources.list.d/wazuh.list"
if [[ -f "$WAZUH_SOURCE" ]]; then
  # Disable only active Wazuh package source entries in the dedicated Wazuh list.
  sed -i '/^[[:space:]]*deb .*packages\.wazuh\.com/s|^|# WAZUH-SOC-LAB DISABLED: |' "$WAZUH_SOURCE"
  echo "Disabled active Wazuh APT source entries in $WAZUH_SOURCE"
else
  echo "NOTICE: $WAZUH_SOURCE does not exist; package holds will still be applied."
fi

apt-get update

echo
echo "===== VERIFIED PACKAGE HOLDS ====="
apt-mark showhold | sort
for package in "${PACKAGES[@]}"; do
  if ! apt-mark showhold | grep -Fxq "$package"; then
    echo "ERROR: '$package' is not on hold." >&2
    exit 1
  fi
done

echo "===== INSTALLED PACKAGE VERSIONS ====="
for package in "${PACKAGES[@]}"; do
  dpkg-query -W -f='${binary:Package} ${Version}\n' "$package"
done

echo "Version lock applied successfully for role '$ROLE'."
