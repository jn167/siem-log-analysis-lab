#!/usr/bin/env bash
# Safe attack simulation for the SIEM lab's Linux endpoint.
#   1. Read /etc/shadow with sudo           (T1003.008)  -> custom rule 100200
#   2. Create a local "backdoor" account    (T1136.001)  -> built-in rule 5902
#   3. Add it to the sudo group             (T1098)      -> built-in rules
#
# Run ONLY on your own lab VM:
#   sudo bash linux-attack-sim.sh            # run the simulation
#   sudo bash linux-attack-sim.sh --cleanup  # remove the test account
set -euo pipefail

TEST_USER="labbackdoor"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo bash $0" >&2
  exit 1
fi

if [[ "${1:-}" == "--cleanup" ]]; then
  echo "Cleanup: removing ${TEST_USER}"
  userdel -r "${TEST_USER}" 2>/dev/null || true
  echo "Cleanup complete."
  exit 0
fi

step() { echo; echo "[$(date +%H:%M:%S)] $*"; }

echo "Starting simulation at $(date). Note this time for your investigation timeline."

# The script itself runs as root, so run the shadow read as a normal sudo call
# from the invoking user to produce the auth.log line Wazuh expects.
step "Step 1: Reading /etc/shadow with sudo (T1003.008)"
sudo -u "${SUDO_USER:-root}" sudo cat /etc/shadow > /dev/null
sleep 5

step "Step 2: Creating account ${TEST_USER} (T1136.001)"
id "${TEST_USER}" &>/dev/null || useradd -m -s /bin/bash "${TEST_USER}"
sleep 5

step "Step 3: Adding ${TEST_USER} to the sudo group (T1098)"
usermod -aG sudo "${TEST_USER}"

echo
echo "Simulation finished at $(date)."
echo "Check the Wazuh dashboard, then run: sudo bash $0 --cleanup"
