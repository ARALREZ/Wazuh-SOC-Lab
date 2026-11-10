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

if [[ "$ROLE" == "server" ]]; then
  PACKAGES=(wazuh-manager wazuh-indexer wazuh-dashboard filebeat)
else
  PACKAGES=(wazuh-agent)
fi

WAZUH_SOURCE="/etc/apt/sources.list.d/wazuh.list"
if [[ -f "$WAZUH_SOURCE" ]]; then
  sed -i 's/^# WAZUH-SOC-LAB DISABLED: //' "$WAZUH_SOURCE"
  echo "Re-enabled Wazuh APT source entries in $WAZUH_SOURCE"
else
  echo "NOTICE: $WAZUH_SOURCE does not exist. Restore the official Wazuh APT source before upgrading."
fi

apt-get update
apt-mark unhold "${PACKAGES[@]}"

echo "Packages are no longer held. No package has been upgraded by this script."
echo "Review the official Wazuh upgrade guide and coordinate versions before installing updates."
echo "Current holds:"
apt-mark showhold | sort
