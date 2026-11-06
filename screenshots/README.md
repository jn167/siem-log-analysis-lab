# Screenshots

Evidence captured during the build, referenced from the [build log](../docs/build-log.md) and the main README.

## Phase 1 and 2: wazuh-server setup

- `01-ubuntu-installer-boot.png` - Ubuntu Server 24.04 installer boot menu
- `02-static-ip.png` - static IP configured during install (10.0.50.10/24)
- `03-openssh.png` - OpenSSH server enabled
- `04-ip-a.png` - first boot, `ip a` confirming 10.0.50.10
- `05-disk-space-fix.png` - diagnosing and fixing the "no space left" error (LVM expand)
- `06-install-summary.png` - Wazuh install summary
- `07-wazuh-login.png` - Wazuh dashboard login page
- `08-wazuh-dashboard.png` - Wazuh dashboard overview after first login
- `09-linux-ip-a.png` - linux-endpoint on the lab network (10.0.50.30)
- `10-linux-agent-active.png` - linux-endpoint reporting as an active agent in Wazuh
- `11-both-agents-active.png` - both endpoints (linux-endpoint and win-endpoint) active in Wazuh
- `12-detection-encoded-ps-table.png` - custom rule 100100 firing (encoded PowerShell) in Threat Hunting
- `13-detection-encoded-ps-detail.png` - the 100100 alert detail with MITRE mapping
- `14-all-custom-rules.png` - rules 100101/100102/100110/100200 firing from the attack simulations
- `15-ssh-bruteforce.png` - SSH brute force chain: failed logins, brute-force alert (5763), and success (5715)
- `16-soc-dashboard.png` - the custom SIEM Lab Overview dashboard (top rules, alerts over time, MITRE techniques, total)
- `17-all-vms.png` - all four lab VMs in VirtualBox Manager
- `18-mitre-framework.png` - Wazuh MITRE ATT&CK framework view with techniques lit up
- `19-mitre-dashboard.png` - Wazuh MITRE ATT&CK dashboard (tactics/techniques by agent)
- `20-sysmon-event-1.png`, `21-sysmon-event-2.png` - a Sysmon process-creation event's full detail

## Still to capture (later phases)

- Wazuh dashboard after first login
- Both agents showing Active
- Custom detection rules firing (100100-100200)
- SSH brute-force alert (rule 5763) then success
- MITRE ATT&CK framework view and the SOC dashboard

Blur or crop anything sensitive before committing.
