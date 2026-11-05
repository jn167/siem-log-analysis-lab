# Build Log

A chronological record of building this lab: what I set up, what broke, and how I fixed it. Kept as a running journal so the problems (and solutions) are documented, not just the happy path.

---

## Phase 1: Host, network, and VM shells

**Host:** Windows 10, 32 GB RAM, running VirtualBox 7.1.4.

- Created an isolated VirtualBox NAT network, `SIEMLab` (10.0.50.0/24, DHCP off), with host port forwards for the Wazuh dashboard and SSH.
- Created three VM shells and attached each one's Adapter 1 to the `SIEMLab` network: `wazuh-server` (Ubuntu, 8 GB / 4 vCPU / 60 GB), `win-endpoint` (Windows 11, 6 GB / 2 vCPU / 64 GB), `linux-endpoint` (Ubuntu, 2 GB / 1 vCPU / 25 GB).
- Downloaded the OS media: Ubuntu Server 24.04.5 LTS, Windows 11 Enterprise (evaluation), and Kali Linux.

> 💡 Chose Ubuntu 24.04 LTS over the newer 26.04 on purpose: 24.04 is the newest release on Wazuh's supported-OS list, so the install stays friction-free. A lab is for learning the SIEM, not debugging an unsupported base OS.

### Issue: VirtualBox only offered 32-bit guest types

When creating the Ubuntu VMs, the **Version** dropdown didn't show a 64-bit Ubuntu option at first. Two parts to this:

- In VirtualBox 7.1 the wizard has a **Subtype** field between Type and Version. I had to set **Subtype = Ubuntu** before the Version list showed the Ubuntu entries.
- 64-bit guest types only appear once hardware virtualization is enabled on the host (see the VT-x issue below). With it disabled, VirtualBox hides them.

---

## Phase 2: wazuh-server OS install

Installed Ubuntu Server 24.04.5 on the `wazuh-server` VM.

- Set a **static IP during install**: address `10.0.50.10/24`, gateway `10.0.50.1`, DNS `10.0.50.1` (the NAT network has DHCP off, so each host gets a fixed address).
- Checked **Install OpenSSH server** so the box can be managed by SSH from the host.
- Skipped the **Ubuntu Pro** prompt ("Skip for now") and the featured snaps; neither is needed here.
- Verified networking after first boot with `ip a`, which showed `10.0.50.10/24`.

[![Ubuntu Server installer boot menu](../screenshots/01-ubuntu-installer-boot.png)](../screenshots/01-ubuntu-installer-boot.png)
*Booting the Ubuntu Server 24.04 installer in VirtualBox.*

[![Static IP configuration](../screenshots/02-static-ip.png)](../screenshots/02-static-ip.png)
*Static IP set during install: address 10.0.50.10/24, gateway and DNS 10.0.50.1 (the NAT network has DHCP off).*

[![OpenSSH server install](../screenshots/03-openssh.png)](../screenshots/03-openssh.png)
*Enabling the OpenSSH server so the host can manage the VM over SSH.*

[![ip a output showing the static address](../screenshots/04-ip-a.png)](../screenshots/04-ip-a.png)
*First boot: `ip a` confirms `enp0s3` has the static address 10.0.50.10/24, running Ubuntu 24.04.5 LTS.*

---

## Troubleshooting

### 1. VT-x disabled in BIOS (VM would not start)

**Symptom.** Starting `wazuh-server` failed immediately with:

```
not in a hypervisor partition (HVP=0) (VERR_NEM_NOT_AVAILABLE)
VT-x is disabled in the BIOS for all CPU modes (VERR_VMX_MSR_ALL_VMX_DISABLED)
```

**Cause.** Hardware virtualization (Intel VT-x) was turned off in the host's BIOS. VirtualBox needs it to run 64-bit guests, so the VM could not launch (and, as noted above, 64-bit guest types were hidden in the VM wizard).

**Fix.** Enabled virtualization in UEFI firmware:

1. Windows **Settings > System > Recovery > Advanced startup > Restart now**.
2. **Troubleshoot > Advanced options > UEFI Firmware Settings > Restart**.
3. In the firmware, enabled **Intel (VMX) Virtualization Technology** (VMX is Intel's internal name for VT-x, which is exactly what `VERR_VMX_...` refers to).
4. Save and exit (F10), reboot.

After enabling it, the VM started and the installer booted normally.

> 💡 Lesson: enable VT-x first. Without it, VirtualBox both refuses to start VMs and hides the 64-bit guest options, which makes the earlier "no 64-bit Ubuntu" symptom look like a separate problem when it is the same root cause.

### 2. "Failed unmounting cdrom.mount - /cdrom" on post-install reboot

**Symptom.** At the end of the Ubuntu install, on the reboot, the console printed:

```
[FAILED] Failed unmounting cdrom.mount - /cdrom.
```

**Meaning.** Harmless. The installer could not cleanly unmount the install ISO because it was still attached to the VM's virtual optical drive. It is not an installation failure.

**Fix.** Powered the VM off, confirmed the optical drive was empty under **Settings > Storage** (VirtualBox had already auto-ejected the ISO), and booted again. The VM then came up to the normal login prompt instead of relaunching the installer.

> 💡 Lesson: this message at install-reboot is expected in VirtualBox and safe to ignore. If the VM boots back into the installer, the ISO is still attached; remove it from the optical drive and boot again.

---

## Next up

- Install Ubuntu on `linux-endpoint` and Windows 11 on `win-endpoint`, import the Kali VM.
- Deploy Wazuh (manager, indexer, dashboard) on `wazuh-server` and reach the dashboard from the host.
