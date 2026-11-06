# Phase 6: Attack Simulations

Goal: generate realistic telemetry so the detections in Phase 5 fire, then investigate them in Phase 7.

Everything here runs against your own VMs on the isolated lab network. The scripts use harmless stand-in commands (for example, the "encoded command" just runs `whoami`) so you get authentic logs without real damage. Take a VirtualBox snapshot named `clean-baseline` before you start, so you can roll back.

**Write down the start time of each run.** You will use it to build an investigation timeline.

## A. Windows host activity

On `win-endpoint`, in PowerShell as Administrator, from the repo's `scripts` folder:

```powershell
.\windows-attack-sim.ps1
```

What it does and what should fire:

| Step | Activity | Expected alert | ATT&CK |
|---|---|---|---|
| 1 | Create local account `labuser` | rule 60109, User account created | T1136.001 |
| 2 | 10 failed logons for `labuser` | rule 60204, Multiple logon failures (after 8 in 4 min) | T1110.001 |
| 3 | Add `labuser` to Administrators | **rule 100110** (custom) | T1098 |
| 4 | whoami / net / ipconfig discovery | Sysmon process-creation events | T1033, T1087 |
| 5 | PowerShell encoded command | **rule 100100** (custom) | T1059.001 |
| 6 | PowerShell web download | **rule 100101** (custom) | T1105 |
| 7 | Scheduled task `LabUpdater` | **rule 100102** (custom) | T1053.005 |

Clean up afterward:

```powershell
.\windows-attack-sim.ps1 -Cleanup
```

(Or just restore the `clean-baseline` snapshot.)

## B. Linux host activity

On `linux-endpoint`:

```bash
sudo bash scripts/linux-attack-sim.sh
```

| Step | Activity | Expected alert | ATT&CK |
|---|---|---|---|
| 1 | Read `/etc/shadow` with sudo | **rule 100200** (custom) | T1003.008 |
| 2 | Create account `labbackdoor` | rule 5902, New user added | T1136.001 |
| 3 | Add it to the sudo group | rule 5901/5903 group-change alerts | T1098 |

Clean up:

```bash
sudo bash scripts/linux-attack-sim.sh --cleanup
```

## C. SSH login-failure burst from Kali

This exercises Wazuh's built-in brute-force correlation (rule 5763: 8 failed SSH logins in 120 seconds). The target account `labvictim` was created in [Phase 4](04-linux-endpoint.md), and the last entry in `lab-passwords.txt` is its real password, so the run ends in a successful login. That gives you the most instructive pattern to investigate: a burst of failures followed by a success from the same source IP.

Run it from `kali-attacker`:

```bash
bash scripts/ssh-bruteforce.sh 10.0.50.30
```

Expected alerts, in order:

| Alert | Meaning | ATT&CK |
|---|---|---|
| rule 5760 (repeated) | SSH authentication failed | T1110.001 |
| rule 5763 | SSH brute force (8 failures in 120s) | T1110.001 |
| rule 5715 | Successful SSH login | T1078 |

The script refuses to run against anything outside 10.0.50.0/24, so it can only touch the lab.

## What "good" looks like

After all three runs, **Threat Hunting** filtered to the lab rules should show a cluster of alerts with timestamps matching your notes. Export or screenshot that view for each investigation write-up in Phase 7.

## Screenshot checklist

- [x] Windows: custom rules 100100, 100101, 100102, 100110 in the alert list (`screenshots/12-detection-encoded-ps-table.png`, `screenshots/14-all-custom-rules.png`)
- [x] Linux: custom rule 100200 in the alert list (`screenshots/14-all-custom-rules.png`)
- [x] SSH: the 5763 brute-force alert followed by the 5715 success (`screenshots/15-ssh-bruteforce.png`)
