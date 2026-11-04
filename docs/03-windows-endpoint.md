# Phase 3: Windows Endpoint + Sysmon

Goal: `win-endpoint` (10.0.50.20) sends Windows Security, Sysmon, and PowerShell logs to Wazuh.

Run everything below in **PowerShell as Administrator** on the Windows VM.

## 1. Turn on the audit policies we need

```powershell
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable
```

These make sure failed logons (4625), new accounts (4720), and group changes (4732) are logged.

## 2. Turn on PowerShell Script Block Logging

```powershell
$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
New-Item -Path $key -Force | Out-Null
Set-ItemProperty -Path $key -Name EnableScriptBlockLogging -Value 1
```

This records the actual code PowerShell runs (Event ID 4104), even when it was encoded.

## 3. Install Sysmon

```powershell
New-Item -ItemType Directory -Path C:\Tools\Sysmon -Force | Out-Null
Invoke-WebRequest https://download.sysinternals.com/files/Sysmon.zip -OutFile C:\Tools\Sysmon.zip
Expand-Archive C:\Tools\Sysmon.zip -DestinationPath C:\Tools\Sysmon -Force
Invoke-WebRequest https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml -OutFile C:\Tools\Sysmon\sysmonconfig-export.xml
C:\Tools\Sysmon\Sysmon64.exe -accepteula -i C:\Tools\Sysmon\sysmonconfig-export.xml
```

Check it is running:

```powershell
Get-Service Sysmon64
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
```

## 4. Install the Wazuh agent

```powershell
Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.9-1.msi" -OutFile "$env:TEMP\wazuh-agent.msi"
msiexec.exe /i "$env:TEMP\wazuh-agent.msi" /q WAZUH_MANAGER="10.0.50.10" WAZUH_AGENT_NAME="win-endpoint"
Start-Sleep -Seconds 15
Start-Service wazuhsvc
```

If that exact version 404s, a newer 4.14.x has been released: get the current MSI link from the Wazuh docs ("Installing Wazuh agents on Windows endpoints").

## 5. Confirm the agent is connected

- In the dashboard: **Agents management > Summary**. `win-endpoint` should show **Active**.
- On the agent: `Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 20` should show it connected to 10.0.50.10.

The agent downloads `agent.conf` from the server (Phase 2, step 5), which adds the Sysmon and PowerShell event channels. To confirm it arrived:

```powershell
Get-Content "C:\Program Files (x86)\ossec-agent\shared\agent.conf"
```

If the file is missing, restart the agent (`Restart-Service wazuhsvc`) and check again after a minute.

## 6. Confirm Sysmon events reach Wazuh

In the dashboard, go to **Threat Hunting > Events**, select the `win-endpoint` agent, and search:

```
data.win.system.channel:"Microsoft-Windows-Sysmon/Operational"
```

Open Notepad on the Windows VM. Within a minute you should see a Sysmon Event ID 1 (process creation) for `notepad.exe`.

## 7. Take a snapshot

In VirtualBox: **Machine > Take Snapshot** and name it `clean-baseline`. You can roll back to it after the attack simulations.

## Screenshot checklist

- [ ] Agent showing Active in the dashboard
- [ ] A Sysmon Event 1 for notepad.exe in Threat Hunting
