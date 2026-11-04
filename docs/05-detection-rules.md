# Phase 5: Custom Detection Rules

Goal: load the five custom rules in `configs/local_rules.xml` and confirm each one fires.

These rules sit on top of Wazuh's built-in ruleset. They raise the alert level and tag the lab's specific techniques with MITRE ATT&CK IDs so they stand out in the dashboard.

## The rules

| Rule ID | Level | Fires on | Log source | ATT&CK |
|---|---|---|---|---|
| 100100 | 13 | PowerShell with an encoded command | Sysmon Event 1 | T1059.001 |
| 100101 | 10 | PowerShell downloading from the web | Sysmon Event 1 | T1105 |
| 100102 | 10 | Scheduled task created with schtasks | Sysmon Event 1 | T1053.005 |
| 100110 | 12 | Account added to local Administrators (4732) | Windows Security | T1098 |
| 100200 | 12 | `/etc/shadow` read with sudo | Linux auth.log | T1003.008 |

## How Wazuh picks a rule

Two things are worth understanding, because they explain the level choices:

1. **Rules are organized in a tree.** A rule with `<if_group>sysmon_event1</if_group>` is only evaluated for events that already matched the built-in Sysmon Event 1 rule (61603). `<if_sid>5402,5403</if_sid>` means "only consider this after rule 5402 or 5403 matched". This is why the custom rules are cheap: they only run on relevant events.

2. **On a tie, order matters; otherwise level wins.** When several sibling rules could match one event, Wazuh evaluates them from highest level to lowest. Rule 100100 is set to **level 13** on purpose, so it is checked before the built-in encoded-PowerShell rule 92057 (level 12) and becomes the alert you see.

## Load the rules

Covered in [Phase 2, step 5](02-wazuh-server.md). In short, on the server:

```bash
sudo cp local_rules.xml /var/ossec/etc/rules/local_rules.xml
sudo chown wazuh:wazuh /var/ossec/etc/rules/local_rules.xml
sudo /var/ossec/bin/verify-agent-conf
sudo systemctl restart wazuh-manager
```

## Test a rule without running the full attack: `wazuh-logtest`

`wazuh-logtest` lets you paste a log line and see which rule it matches, without generating real events. Start it on the server:

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Then paste a sample Linux auth line for the shadow rule:

```
Jan 15 10:30:00 linux-endpoint sudo:  labuser : TTY=pts/0 ; PWD=/home/labuser ; USER=root ; COMMAND=/usr/bin/cat /etc/shadow
```

You should see it decode as sudo and match **rule id 100200**. Press Ctrl+C to exit.

For the Windows rules, the easiest test is to run the simulation in Phase 6 and watch the alerts, since Sysmon events are JSON and awkward to paste by hand. If you want to logtest them anyway, copy a real event's `full_log` from the dashboard and paste that.

## Verify each rule fired

After Phase 6, in the dashboard go to **Threat Hunting** and filter by rule ID, for example:

```
rule.id:100100 OR rule.id:100101 OR rule.id:100102 OR rule.id:100110 OR rule.id:100200
```

Record the result in the table below.

| Rule | Fired? | Alert timestamp | Notes |
|---|---|---|---|
| 100100 | | | |
| 100101 | | | |
| 100102 | | | |
| 100110 | | | |
| 100200 | | | |

## If a rule does not fire

- **Check the event arrived at all.** Search Threat Hunting for the agent and the raw channel first (for example `data.win.system.channel:"Microsoft-Windows-Sysmon/Operational"`). No raw event means a collection problem (Phase 3/4), not a rule problem.
- **Check field names.** Open a real matching event in the dashboard and confirm the field path (for example `data.win.eventdata.commandLine`) matches what the rule keys on. Field names can vary slightly by Windows build.
- **Re-run `wazuh-logtest`** with the real `full_log` and read which rule it stops on.
- **Check ownership and syntax**: `sudo /var/ossec/bin/wazuh-analysisd -t` validates the whole ruleset and names the file and line of any error.
