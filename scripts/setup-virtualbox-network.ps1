# Creates the SIEMLab NAT Network in VirtualBox with port forwards to the lab VMs.
# Run from PowerShell on the Windows host:  .\scripts\setup-virtualbox-network.ps1

# Note: not using $ErrorActionPreference = "Stop" because Windows PowerShell 5.1
# treats redirected stderr from VBoxManage as an error. Exit codes are checked instead.

$VBox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
if (-not (Test-Path $VBox)) {
    throw "VBoxManage.exe not found at $VBox. Update the path at the top of this script."
}

$NetName = "SIEMLab"
$Cidr    = "10.0.50.0/24"

$existing = & $VBox natnetwork list | Select-String -Pattern "Name:\s+$NetName$"
if ($existing) {
    Write-Host "NAT Network '$NetName' already exists, updating it."
} else {
    & $VBox natnetwork add --netname $NetName --network $Cidr --enable --dhcp off
    if ($LASTEXITCODE -ne 0) { throw "Failed to create NAT Network '$NetName'." }
    Write-Host "Created NAT Network '$NetName' ($Cidr)."
}

# Port forwards: name:protocol:[host ip]:host port:[guest ip]:guest port
$forwards = @(
    "wazuh-dashboard:tcp:[127.0.0.1]:8443:[10.0.50.10]:443",
    "wazuh-ssh:tcp:[127.0.0.1]:2210:[10.0.50.10]:22",
    "linux-endpoint-ssh:tcp:[127.0.0.1]:2230:[10.0.50.30]:22"
)

foreach ($rule in $forwards) {
    $name = $rule.Split(":")[0]
    # Remove the rule first if it exists so the script can be re-run safely
    & $VBox natnetwork modify --netname $NetName --port-forward-4 delete $name 2>$null
    & $VBox natnetwork modify --netname $NetName --port-forward-4 $rule
    if ($LASTEXITCODE -ne 0) { throw "Failed to add port forward: $rule" }
    Write-Host "Port forward added: $rule"
}

& $VBox natnetwork start --netname $NetName 2>$null

Write-Host ""
Write-Host "Done. Attach each VM's Adapter 1 to 'NAT Network: $NetName'."
Write-Host "Wazuh dashboard will be at https://localhost:8443 once installed."
