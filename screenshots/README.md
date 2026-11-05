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

## Still to capture (later phases)

- Wazuh dashboard after first login
- Both agents showing Active
- Custom detection rules firing (100100-100200)
- SSH brute-force alert (rule 5763) then success
- MITRE ATT&CK framework view and the SOC dashboard

Blur or crop anything sensitive before committing.
