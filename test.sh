#!/bin/bash
# Exmaple:
# ./test.sh 1.2.3.4 root@pam YOUR-PASSWORD pve-name 144
set -e

HOST="$1"
USERNAME="$2"
PASSWORD="$3"
NODE="$4"
VMID="$5"

# Validate input
if [ -z "$HOST" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$NODE" ] || [ -z "$VMID" ]; then
    echo "Usage: $0 <HOST> <USERNAME> <PASSWORD> <NODE> <VMID>"
    exit 1
fi

API="https://${HOST}:8006/api2/json"

echo "[*] Logging in to Proxmox..."

LOGIN_RESPONSE=$(curl -sk -X POST \
    -d "username=${USERNAME}&password=${PASSWORD}" \
    "${API}/access/ticket")

# Extract ticket and CSRF token using jq
TICKET=$(echo "$LOGIN_RESPONSE" | jq -r '.data.ticket')
CSRF=$(echo "$LOGIN_RESPONSE" | jq -r '.data.CSRFPreventionToken')

# Validate login
if [ "$TICKET" = "null" ] || [ -z "$TICKET" ]; then
    echo "[-] Login failed. Check credentials."
    exit 1
fi

echo "[+] Login successful"

echo "[*] Sending unlock request for VM ${VMID}..."

RESPONSE=$(curl -sk -X POST \
    -H "CSRFPreventionToken: ${CSRF}" \
    -b "PVEAuthCookie=${TICKET}" \
    "${API}/nodes/${NODE}/qemu/${VMID}/status/unlock")

# Check response
ERROR=$(echo "$RESPONSE" | jq -r '.message')

if [ "$ERROR" != "null" ] && [ -n "$ERROR" ]; then
    echo "[-] Unlock failed: $ERROR"
    echo "$RESPONSE"
    exit 1
fi

echo "[+] VM $VMID unlocked successfully"
echo "[+] Task ID: $SUCCESS"
