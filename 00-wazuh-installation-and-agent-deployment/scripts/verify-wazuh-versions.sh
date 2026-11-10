#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  echo "Usage: EXPECTED_WAZUH_VERSION=<version> $0 <server|agent>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
ROLE="$1"
[[ "$ROLE" == "server" || "$ROLE" == "agent" ]] || usage

get_version() {
  local package="$1"
  dpkg-query -W -f='${Version}' "$package" 2>/dev/null || {
    echo "ERROR: Package '$package' is not installed." >&2
    return 1
  }
}

if [[ "$ROLE" == "server" ]]; then
  WAZUH_PACKAGES=(wazuh-manager wazuh-indexer wazuh-dashboard)
else
  WAZUH_PACKAGES=(wazuh-agent)
fi

printf '===== %s VERSION CHECK =====\n' "${ROLE^^}"
for package in "${WAZUH_PACKAGES[@]}"; do
  version="$(get_version "$package")"
  printf '%-20s %s\n' "$package" "$version"
done

if [[ "$ROLE" == "server" ]]; then
  expected="$(get_version wazuh-manager)"
  for package in wazuh-indexer wazuh-dashboard; do
    actual="$(get_version "$package")"
    if [[ "$actual" != "$expected" ]]; then
      echo "ERROR: Central component version mismatch: $package=$actual, wazuh-manager=$expected" >&2
      exit 1
    fi
  done
  printf '\nCentral Wazuh components match: %s\n' "$expected"
  if dpkg-query -W -f='${db:Status-Status}' filebeat 2>/dev/null | grep -qx installed; then
    dpkg-query -W -f='${binary:Package} ${Version}\n' filebeat
    echo "Note: Filebeat uses a separate version scheme and is not compared to the Wazuh version."
  fi
fi

if [[ -n "${EXPECTED_WAZUH_VERSION:-}" ]]; then
  for package in "${WAZUH_PACKAGES[@]}"; do
    actual="$(get_version "$package")"
    if [[ "$actual" != "$EXPECTED_WAZUH_VERSION" ]]; then
      echo "ERROR: Expected $package=$EXPECTED_WAZUH_VERSION but found $actual" >&2
      exit 1
    fi
  done
  printf 'Expected Wazuh version confirmed: %s\n' "$EXPECTED_WAZUH_VERSION"
fi
