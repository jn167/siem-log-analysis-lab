# Phase 1: Network and VMs

Goal: an isolated VirtualBox network with four VMs on static IPs.

## Tip: enable host-to-guest copy/paste first

You will paste a lot of commands into these VMs, so set up shared clipboard before anything else. It saves a lot of retyping.

For each VM, once it is installed and running:

1. **Install Guest Additions in the guest** (required for clipboard sharing):
   - **Windows guest:** VirtualBox menu **Devices > Insert Guest Additions CD image**, then in the VM run `VBoxWindowsAdditions-amd64.exe` from the CD drive and reboot. (VirtualBox's unattended Windows install often installs this for you.)
   - **Ubuntu guest:** `sudo apt install -y virtualbox-guest-utils`, then reboot. (Or use the inserted Guest Additions CD.)
2. **Turn the clipboard on:** VirtualBox menu **Devices > Shared Clipboard > Bidirectional** (optionally **Devices > Drag and Drop > Bidirectional** too).
3. **Paste with `Ctrl+V`.** In Windows Terminal, right-click may open a menu instead of pasting, so use `Ctrl+V`.

Two gotchas worth knowing:

- If paste still does not work after enabling Bidirectional, reinstall Guest Additions (above) and reboot; the clipboard service sometimes needs it.
- VirtualBox's default **Host key** is **Right Ctrl**. If your keyboard has no right Ctrl (for example a compact or custom/QMK board), either rebind it under **File > Preferences > Input > Virtual Machine** in VirtualBox Manager, or reach a full-screen VM's menu by moving the mouse to the screen edge to reveal the toolbar.

Alternatively, once a VM has OpenSSH and a host port forward (set up below), you can SSH into it from your host terminal, where copy/paste works natively.

## 1. Download the ISOs

| VM | Download |
|---|---|
| wazuh-server, linux-endpoint | Ubuntu Server 24.04 LTS: https://ubuntu.com/download/server |
| win-endpoint | Windows 11 Enterprise evaluation (90 days, free): https://www.microsoft.com/evalcenter |
| kali-attacker | Kali Linux "Virtual Machines" prebuilt VirtualBox image: https://www.kali.org/get-kali/ |

Tip: the Kali prebuilt VirtualBox image (`.7z` with a `.vbox` file) is faster than installing from the ISO. Default login is `kali` / `kali`.

## 2. Create the NAT Network

Run this in PowerShell on your Windows host (normal user is fine):

```powershell
.\scripts\setup-virtualbox-network.ps1
```

It creates a NAT Network named `SIEMLab` (10.0.50.0/24, DHCP off) and forwards:

| Host | Goes to | Purpose |
|---|---|---|
| 127.0.0.1:8443 | 10.0.50.10:443 | Wazuh dashboard in your host browser |
| 127.0.0.1:2210 | 10.0.50.10:22 | SSH into wazuh-server from the host |
| 127.0.0.1:2230 | 10.0.50.30:22 | SSH into linux-endpoint from the host |

## 3. Create the VMs

In VirtualBox: **Machine > New** for each VM using the specs below. In the wizard, check **Skip Unattended Installation** for the Ubuntu VMs so you can set a static IP during install.

| VM | vCPU | RAM | Disk | Network |
|---|---|---|---|---|
| wazuh-server | 4 | 8192 MB | 60 GB | NAT Network: SIEMLab |
| win-endpoint | 2 | 6144 MB | 64 GB | NAT Network: SIEMLab |
| linux-endpoint | 1 | 2048 MB | 25 GB | NAT Network: SIEMLab |
| kali-attacker | 2 | 4096 MB | (prebuilt) | NAT Network: SIEMLab |

To set the network: **Settings > Network > Adapter 1 > Attached to: NAT Network > Name: SIEMLab**.

## 4. Static IPs

All VMs use gateway **10.0.50.1** and DNS **10.0.50.1** (VirtualBox provides both).

### Ubuntu VMs (during install)

On the installer's **Network configuration** screen: select the adapter > **Edit IPv4** > **Manual**:

- Subnet: `10.0.50.0/24`
- Address: `10.0.50.10` (wazuh-server) or `10.0.50.30` (linux-endpoint)
- Gateway: `10.0.50.1`
- Name servers: `10.0.50.1`

Also check **Install OpenSSH server** when the installer offers it.

If you already installed with DHCP, edit `/etc/netplan/50-cloud-init.yaml` (check the interface name with `ip a`, usually `enp0s3`):

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses: [10.0.50.10/24]
      routes:
        - to: default
          via: 10.0.50.1
      nameservers:
        addresses: [10.0.50.1]
```

Then run `sudo netplan apply`.

### Windows 11

**Settings > Network & internet > Ethernet > IP assignment > Edit > Manual > IPv4 on**:

- IP: `10.0.50.20`, Subnet mask: `255.255.255.0`, Gateway: `10.0.50.1`, DNS: `10.0.50.1`

### Kali

```bash
sudo nmcli con mod "Wired connection 1" ipv4.method manual ipv4.addresses 10.0.50.40/24 ipv4.gateway 10.0.50.1 ipv4.dns 10.0.50.1
sudo nmcli con up "Wired connection 1"
```

(Run `nmcli con show` first if the connection has a different name.)

## 5. Check connectivity

From each VM, ping the others and the internet:

```bash
ping -c 2 10.0.50.10
ping -c 2 google.com
```

Note: Windows blocks ping by default, so pings **to** 10.0.50.20 failing is normal.

## Screenshot checklist

- [x] VirtualBox Manager showing all four VMs (`screenshots/17-all-vms.png`)
- [x] `ip a` on wazuh-server showing 10.0.50.10 (`screenshots/04-ip-a.png`)
