# Proxmox VE - Custom API Endpoint: VM Unlock

## Goal

Add a new API endpoint:

POST /api2/json/nodes/{node}/qemu/{vmid}/status/unlock

Equivalent to:
qm unlock <vmid>

---

## File to Modify

/usr/share/perl5/PVE/API2/Qemu.pm

---

## Changes Required

### 1. Add Subdir

Locate the status subdir registration block:

    { subdir => 'start' },
    { subdir => 'stop' },
    { subdir => 'reboot' },

Add:

    { subdir => 'unlock' },

---

### 2. Add API Method

Insert AFTER vm_reboot method:

    name => 'vm_reboot',
    path => '{vmid}/status/reboot',

Add new method:

    vm_unlock

---

## Behavior

- Creates worker task: qmunlock
- Calls: PVE::QemuServer::unlock_vm($vmid)
- Logs action via syslog
- Uses permission: VM.Config.Disk

---

## Result

You can call:

    pvesh create /nodes/<node>/qemu/<vmid>/status/unlock

or via HTTP API.

---

## Notes

- Survives only until package update unless patch reapplied
- Safe, minimal, follows Proxmox patterns

---

## Ansible Automation

Two playbooks are provided under `ansible/` to automate applying the patch and testing the new API.

### Files

- `ansible/inventory.ini.sample` — example inventory; copy to `inventory.ini` and edit
- `ansible/apply_patch.yml` — backs up the file, verifies the patch can apply, applies it, restarts services
- `ansible/test_api.yml` — logs in to the Proxmox API and calls the new unlock endpoint

### Inventory

The real `ansible/inventory.ini` is git-ignored so your hosts/credentials stay local. Create it from the sample:

    cp ansible/inventory.ini.sample ansible/inventory.ini

Then edit it and set your host:

    [proxmox]
    pve1 ansible_host=1.2.3.4 ansible_user=root

### 1. Apply the Patch

Runs against the Proxmox host as root and does the following:

1. Verifies `/usr/share/perl5/PVE/API2/Qemu.pm` exists
2. Copies the patch to the remote host
3. Runs a **reverse dry-run** — if the patch is already applied, nothing else happens (idempotent)
4. Runs a **forward dry-run** — fails fast if the patch will not apply cleanly
5. Creates a timestamped backup like `Qemu.pm.backup-YYYYMMDDTHHMMSS`
6. Applies the patch
7. Restarts `pvedaemon` and `pveproxy`

Run:

    ansible-playbook -i ansible/inventory.ini ansible/apply_patch.yml

### 2. Test the API

Logs in via `/access/ticket`, then POSTs to `/nodes/{node}/qemu/{vmid}/status/unlock` using the ticket and CSRF token. HTTP calls run from the Ansible controller (`delegate_to: localhost`), and credentials are protected with `no_log`.

Required variables (pass with `-e`):

- `pve_password` — Proxmox password
- `vmid` — target VM ID

Optional overrides:

- `pve_user` (default `root@pam`)
- `node` (default: `inventory_hostname`)
- `pve_port` (default `8006`)

Run:

    ansible-playbook -i ansible/inventory.ini ansible/test_api.yml \
        -e "pve_password=YOUR-PASSWORD vmid=144"

### Requirements

- Ansible 2.10+ on the controller
- SSH access as root (or a sudo-enabled user) to the Proxmox host
- `patch` available on the Proxmox host (present by default)
- `jq` is **not** required — the test playbook parses JSON natively
