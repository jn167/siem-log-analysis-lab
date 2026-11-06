# Phase 7: Dashboard and Investigations

Goal: build a view of the lab's detections and write up each one the way a SOC analyst would.

## 1. A filtered Threat Hunting view

In the dashboard, open **Threat Hunting**. Add a search filter for the lab rules:

```
rule.id:(100100 OR 100101 OR 100102 OR 100110 OR 100200) OR rule.id:(5763 OR 60204)
```

Set the time range to cover your simulation runs. Save it (**Save** in the top bar) as `Lab detections` so you can reopen it.

Useful columns to add: `timestamp`, `agent.name`, `rule.id`, `rule.level`, `rule.description`, `rule.mitre.id`.

## 2. The MITRE ATT&CK view

Wazuh ships a MITRE module: **Modules > MITRE ATT&CK > Framework**. After the simulations it should light up the techniques your rules tagged (T1059.001, T1105, T1053.005, T1098, T1003.008, T1110.001). This is a good screenshot for the README: it shows the lab exercising a spread of tactics, not just one.

## 3. Build a simple dashboard (optional but worth it)

**Dashboard > Create > Create new dashboard**, then add visualizations from the `wazuh-alerts-*` index pattern:

- **Top rules**: a data table of `rule.description` by count
- **Alerts over time**: a date histogram, split by `agent.name`
- **Alert level gauge**: max of `rule.level`
- **Techniques**: a tag cloud or table of `rule.mitre.id`

Save it as `SIEM Lab Overview`. Screenshot it for the README.

## 4. Investigation write-ups

For each detection, write a short investigation. The point is to practice the analyst workflow: what fired, what actually happened, and what you would do about it. Use this template (one per detection, saved under `docs/investigations/` if you want to keep them separate):

```markdown
### Investigation: <short title>

- **Alert:** rule <id> - <description> (level <n>)
- **ATT&CK:** <technique id and name>
- **Agent / host:** <agent.name>
- **Time:** <alert timestamp>

**What triggered it**
<the log line or event, and which field matched the rule>

**What happened**
<the story, reconstructed from surrounding events: parent process, user, source IP, what came before and after>

**Is it malicious?**
<in this lab, yes and it was me; in the real world, what would make this benign vs malicious?>

**Response**
<what a SOC analyst would do: isolate host, disable account, kill task, etc.>

**How to tune the detection**
<false positive sources, whether the level is right, what context would help>
```

### Example: encoded PowerShell (rule 100100)

```markdown
### Investigation: Encoded PowerShell command

- **Alert:** rule 100100 - PowerShell launched with an encoded command (level 13)
- **ATT&CK:** T1059.001 Command and Scripting Interpreter: PowerShell
- **Agent / host:** win-endpoint
- **Time:** <fill in from your run>

**What triggered it**
Sysmon Event 1 (process creation). The commandLine field contained
"-EncodedCommand dwBoAG8AYQBtAGkA..." which decodes to "whoami; hostname".

**What happened**
powershell.exe was spawned (in the lab, by the simulation script). I decoded
the base64 to confirm the intent. Here it was a harmless discovery command,
but encoding is a common way to hide malicious commands from casual log review.

**Is it malicious?**
In this lab, yes and it was me. In the real world, encoded commands are not
always malicious (some management tools use them), but they warrant a look,
especially with an unusual parent process or an external download nearby.

**Response**
Decode the command, identify the parent process and user, check what ran
before and after on the same host, and if unexplained, isolate the host and
reset the user's credentials.

**How to tune the detection**
Legit automation can use -EncodedCommand. To cut false positives, pair this
with parent-process context or correlate with a network download (rule 100101)
before escalating.
```

Fill in the rest for the other detections (web download, scheduled task, admin-group change, shadow read, SSH brute force).

## 5. Finish the README

Back in `README.md`:

- Check off the **Progress** boxes as you complete each phase.
- Drop your best screenshots into `screenshots/` and link them.
- Fill in the **Findings** section with links to your investigation write-ups.
- Fill in **What I Learned**: what surprised you, what was harder than expected, what you would add next (a good lead-in to the Network Traffic Analysis lab).

## Screenshot checklist

- [ ] Saved `Lab detections` Threat Hunting view
- [x] MITRE ATT&CK framework view with techniques lit up (`screenshots/18-mitre-framework.png`, `screenshots/19-mitre-dashboard.png`)
- [x] `SIEM Lab Overview` dashboard (`screenshots/16-soc-dashboard.png`)
