#!/bin/bash

set -e

FILE="/usr/share/perl5/PVE/API2/Qemu.pm"
BACKUP="/usr/share/perl5/PVE/API2/Qemu.pm.backup"
PATCH="qemu-unlock.patch"

echo "[*] Checking file..."

if [ ! -f "$FILE" ]; then
    echo "[-] Target file not found!"
    exit 1
fi

echo "[*] Creating backup..."
cp "$FILE" "$BACKUP"

echo "[*] Applying patch..."
patch -p1 < "$PATCH"

echo "[*] Restarting services..."
systemctl restart pvedaemon
systemctl restart pveproxy

echo "[+] Done."
echo "[+] Backup saved at: $BACKUP"
