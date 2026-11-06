# Phase 4: Linux Endpoint

Goal: `linux-endpoint` (10.0.50.30) sends auth logs to Wazuh and has an SSH-reachable test account for the brute force simulation.

## 1. Update and set the timezone

```bash
sudo apt update && sudo apt full-upgrade -y
sudo timedatectl set-timezone America/Chicago
```

## 2. Install the Wazuh agent

```bash
sudo apt-get install -y gnupg apt-transport-https curl
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && sudo chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt-get update
sudo WAZUH_MANAGER="10.0.50.10" WAZUH_AGENT_NAME="linux-endpoint" apt-get install -y wazuh-agent
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent
```

Optional but recommended: stop the agent from being upgraded by accident, since agents should not be newer than the manager:

```bash
sudo apt-mark hold wazuh-agent
```

## 3. Confirm auth logs are collected

```bash
sudo grep -B1 -A2 "auth.log\|journald" /var/ossec/etc/ossec.conf
```

You should see a `<localfile>` block for `/var/log/auth.log` (or `journald`). If neither is there, add this inside `<ossec_config>` in `/var/ossec/etc/ossec.conf` and restart the agent:

```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/auth.log</location>
</localfile>
```

## 4. Make sure SSH password login works

The brute force simulation needs password authentication enabled:

```bash
sudo sshd -T | grep -i passwordauthentication
```

If it says `no`, edit `/etc/ssh/sshd_config.d/*.conf` and `/etc/ssh/sshd_config` so that `PasswordAuthentication yes`, then `sudo systemctl restart ssh`.

## 5. Create the brute force target account

```bash
sudo useradd -m -s /bin/bash labvictim
echo 'labvictim:Summer2026!' | sudo chpasswd
```

This weak password is deliberate and is the last entry in `scripts/lab-passwords.txt`. Only do this on the isolated lab network.

## 6. Confirm in the dashboard

**Agents management > Summary** should show `linux-endpoint` as **Active**. Then try a wrong SSH password once from the host:

```powershell
ssh labvictim@127.0.0.1 -p 2230
```

Search Threat Hunting for `agent.name:linux-endpoint and rule.groups:authentication_failed` and you should see the failure.

## 7. Take a snapshot

Name it `clean-baseline`.

## Screenshot checklist

- [x] `linux-endpoint` Active in Agents management (`screenshots/10-linux-agent-active.png`)
- [x] `win-endpoint` Active in Agents management (`screenshots/11-both-agents-active.png`)
- [ ] The failed SSH login alert
