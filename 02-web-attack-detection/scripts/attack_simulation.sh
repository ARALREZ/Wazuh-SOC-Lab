#!/usr/bin/env bash
# Safe HTTP-only web attack-pattern simulation for the local Wazuh lab.
# No payload is executed on the server; requests only place strings in the URI.
set -Eeuo pipefail

TARGET_URL="${TARGET_URL:-http://192.168.122.208}"
PHASE="${1:-single}"

if [[ "$TARGET_URL" != "http://192.168.122.208" && "$TARGET_URL" != "https://192.168.122.208" ]]; then
  echo "ERROR: this lab script is intentionally restricted to 192.168.122.208." >&2
  echo "Set TARGET_URL only to the confirmed Project 02 Apache endpoint." >&2
  exit 2
fi

request() {
  local path="$1" ua="${2:-curl/8.5.0}" code
  code="$(curl --silent --show-error --globoff --path-as-is --max-time 5 \
    --output /dev/null --write-out '%{http_code}' \
    --user-agent "$ua" "$TARGET_URL$path" 2>/dev/null || true)"
  printf 'HTTP %s  %s\n' "${code:-NO-RESPONSE}" "$path"
}

scanner_burst() {
  request "/" "Nikto/2.1.6"
  request "/robots.txt" "Nikto/2.1.6"
  request "/admin/" "Nikto/2.1.6"
  request "/backup/" "Nikto/2.1.6"
  request "/test/" "Nikto/2.1.6"
}

case "$PHASE" in
  single)
    echo "[+] Single-event detections against $TARGET_URL"
    request "/" "Nikto/2.1.6"
    request "/?id=1%20UNION%20SELECT%201"
    request "/?q=%3Cscript%3Ealert%281%29%3C%2Fscript%3E"
    request "/?file=%2e%2e%2f%2e%2e%2fetc%2fpasswd"
    request "/?cmd=%3Bid"
    request "/?x=php%3A%2F%2Ffilter%2Fresource%3Dindex.php"
    ;;
  scanner-correlation)
    echo "[+] Five scanner requests: expect 100020 and correlation 100025."
    scanner_burst
    ;;
  multi-attack-correlation)
    echo "[!] This phase is expected to trigger 100026 and may block Kali (.112) for 600 seconds."
    echo "[+] Sending three high-severity patterns, then stopping."
    request "/?id=1%20UNION%20SELECT%201"
    sleep 2
    request "/?q=%3Cscript%3Ealert%281%29%3C%2Fscript%3E"
    sleep 2
    request "/?file=%2e%2e%2f%2e%2e%2fetc%2fpasswd"
    ;;
  scanner-then-exploit)
    echo "[!] This phase is expected to trigger 100027 and may block Kali (.112) for 600 seconds."
    request "/" "Nikto/2.1.6"
    sleep 2
    request "/robots.txt" "Nikto/2.1.6"
    sleep 2
    request "/?id=1%20UNION%20SELECT%201"
    ;;
  *)
    echo "Usage: $0 [single|scanner-correlation|multi-attack-correlation|scanner-then-exploit]" >&2
    exit 2
    ;;
esac

echo "[+] Simulation phase finished. Check Wazuh alerts and the Agent active-responses log."
echo "[+] Do not infer Active Response success from a rule alert alone."
