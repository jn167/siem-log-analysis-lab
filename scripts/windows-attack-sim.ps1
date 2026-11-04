<#
.SYNOPSIS
  Safe attack simulation for the SIEM lab's Windows endpoint.

.DESCRIPTION
  Generates realistic logs for Wazuh to detect, using harmless commands:
    1. Brute force: 10 failed logons for a local test account   (T1110.001)
    2. Account creation + added to Administrators              (T1136.001, T1098)
    3. Discovery commands (whoami, net, ipconfig)               (T1033, T1087.001)
    4. PowerShell with an encoded command (runs "whoami")       (T1059.001)
    5. PowerShell web download of example.com                   (T1105)
    6. Scheduled task persistence (task just echoes text)       (T1053.005)

  Run ONLY on your own lab VM. Run in PowerShell as Administrator.

.EXAMPLE
  .\windows-attack-sim.ps1            # run the simulation
  .\windows-attack-sim.ps1 -Cleanup   # remove the test account, task, and file
#>

param(
    [switch]$Cleanup
)

$TestUser   = "labuser"
$TaskName   = "LabUpdater"
$Download   = Join-Path $env:TEMP "lab-download.html"

function Write-Step($text) {
    Write-Host ""
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $text" -ForegroundColor Cyan
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw "Run this script in PowerShell as Administrator." }

if ($Cleanup) {
    Write-Step "Cleanup: removing scheduled task, test account, and downloaded file"
    schtasks /delete /tn $TaskName /f 2>$null | Out-Null
    if (Get-LocalUser -Name $TestUser -ErrorAction SilentlyContinue) { Remove-LocalUser -Name $TestUser }
    Remove-Item $Download -ErrorAction SilentlyContinue
    Write-Host "Cleanup complete."
    return
}

Write-Host "Starting simulation at $(Get-Date). Note this time for your investigation timeline." -ForegroundColor Yellow

# 1. Create the test account first so the failed logons target a real user
Write-Step "Step 1: Creating local account '$TestUser' (T1136.001)"
$pw = ConvertTo-SecureString ("Lab-" + [guid]::NewGuid().ToString("N").Substring(0, 12) + "!") -AsPlainText -Force
if (-not (Get-LocalUser -Name $TestUser -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $TestUser -Password $pw -Description "SIEM lab test account" | Out-Null
}
Start-Sleep -Seconds 5

# 2. Brute force: 10 wrong passwords. Wazuh rule 60204 fires after 8 failures in 4 minutes.
#    Windows 11 locks an account after 10 failures by default, which only affects labuser.
Write-Step "Step 2: 10 failed logons for '$TestUser' (T1110.001)"
for ($i = 1; $i -le 10; $i++) {
    $bad  = ConvertTo-SecureString "WrongPassword$i!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($TestUser, $bad)
    try {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c exit" -Credential $cred -WorkingDirectory "C:\" -ErrorAction Stop
    } catch {
        Write-Host "  Attempt $i failed (expected)"
    }
    Start-Sleep -Seconds 1
}
Start-Sleep -Seconds 5

# 3. Privilege escalation via group membership
Write-Step "Step 3: Adding '$TestUser' to Administrators (T1098)"
Add-LocalGroupMember -Group "Administrators" -Member $TestUser -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

# 4. Discovery
Write-Step "Step 4: Discovery commands (T1033, T1087.001)"
whoami /all | Out-Null
net user | Out-Null
net localgroup administrators | Out-Null
ipconfig /all | Out-Null
Start-Sleep -Seconds 5

# 5. Encoded PowerShell. The encoded text is just: whoami; hostname
Write-Step "Step 5: PowerShell with an encoded command (T1059.001)"
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("whoami; hostname"))
powershell.exe -NoProfile -EncodedCommand $encoded
Start-Sleep -Seconds 5

# 6. Web download (harmless page)
Write-Step "Step 6: PowerShell downloading a web page (T1105)"
powershell.exe -NoProfile -Command "Invoke-WebRequest https://example.com -OutFile '$Download' -UseBasicParsing"
Start-Sleep -Seconds 5

# 7. Scheduled task persistence (the task only echoes text)
Write-Step "Step 7: Creating scheduled task '$TaskName' (T1053.005)"
schtasks /create /tn $TaskName /tr "cmd.exe /c echo lab" /sc daily /st 09:00 /f | Out-Null

Write-Host ""
Write-Host "Simulation finished at $(Get-Date)." -ForegroundColor Green
Write-Host "Check the Wazuh dashboard, then run with -Cleanup (or restore the clean-baseline snapshot)."
