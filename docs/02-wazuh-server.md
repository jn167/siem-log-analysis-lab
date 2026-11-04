# Phase 2: Wazuh Server

Goal: Wazuh 4.14 (manager, indexer, dashboard) running on `wazuh-server` (10.0.50.10), reachable at https://localhost:8443 from the host.

## 1. Update the server

SSH in from the host (`ssh <your-user>@127.0.0.1 -p 2210`) or use the VM console:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo timedatectl set-timezone America/Chicago
sudo reboot
```

Setting the timezone keeps alert timestamps easy to read in write-ups.

## 2. Install Wazuh (all-in-one)

```bash
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh && sudo bash ./wazuh-install.sh -a
```

This takes roughly 10 to 20 minutes. When it finishes, it prints a summary like:

```
INFO: --- Summary ---
INFO: You can access the web interface https://<wazuh-dashboard-ip>:443
    User: admin
    Password: <ADMIN_PASSWORD>
```

**Save the admin password in a password manager.** If you lose it, recover it with:

```bash
sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
```

(Run it in the same folder where you ran the installer.)

## 3. Log in to the dashboard

On your Windows host, open **https://localhost:8443**.

- The browser will warn about the self-signed certificate. That is expected for a lab: choose **Advanced > Continue**.
- Log in as `admin` with the password from the installer.

## 4. Check services

```bash
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard --no-pager
```

All three should show `active (running)`.

## 5. Load the centralized agent config and custom rules

Copy the two files from this repo's `configs/` folder to the server (from the host, in the repo folder):

```powershell
scp -P 2210 configs/agent.conf configs/local_rules.xml <your-user>@127.0.0.1:/tmp/
```

Then on the server:

```bash
sudo cp /tmp/agent.conf /var/ossec/etc/shared/default/agent.conf
sudo cp /tmp/local_rules.xml /var/ossec/etc/rules/local_rules.xml
sudo chown wazuh:wazuh /var/ossec/etc/shared/default/agent.conf /var/ossec/etc/rules/local_rules.xml
sudo /var/ossec/bin/verify-agent-conf
sudo systemctl restart wazuh-manager
```

`verify-agent-conf` should report no errors. Agents in the `default` group pick up `agent.conf` automatically.

Note: `local_rules.xml` replaces the example file that ships with Wazuh. That file only contains a sample rule, so nothing is lost.

## Troubleshooting

- **Dashboard not loading:** check the port forward exists (`VBoxManage natnetwork list`) and that `wazuh-dashboard` is running.
- **Installer fails on low resources:** make sure the VM really has 4 vCPU and 8 GB RAM.
- **Manager will not restart after copying rules:** check `sudo tail -n 50 /var/ossec/logs/ossec.log` for an XML error, usually a typo in `local_rules.xml`.

## Screenshot checklist

- [ ] Installer summary (blur the password)
- [ ] Wazuh dashboard home page after login
