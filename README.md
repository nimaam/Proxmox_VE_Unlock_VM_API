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
