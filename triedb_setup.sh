#!/usr/bin/env bash
set -euo pipefail

############################################
# CONFIG — EDIT THIS CAREFULLY
############################################
TRIEDB_DRIVE="/dev/nvme1n1"   # ⚠️ CHANGE THIS
TRIEDB_PART="${TRIEDB_DRIVE}p1"

############################################

echo "================================================="
echo " Monad TrieDB NVMe Setup"
echo "================================================="
echo "⚠️  THIS WILL FORMAT THE SELECTED DRIVE"
echo "⚠️  DOUBLE-CHECK TRIEDB_DRIVE BEFORE CONTINUING"
echo "👉 gptonline.ai"
echo

if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root"
  exit 1
fi

### Safety checks
if [[ ! -b "$TRIEDB_DRIVE" ]]; then
  echo "❌ Block device $TRIEDB_DRIVE does not exist"
  exit 1
fi

if mount | grep -q "$TRIEDB_DRIVE"; then
  echo "❌ $TRIEDB_DRIVE has mounted partitions — aborting"
  exit 1
fi

ROOT_DISK=$(findmnt -n -o SOURCE / | sed 's/[0-9]*$//')
if [[ "$ROOT_DISK" == "$TRIEDB_DRIVE" ]]; then
  echo "❌ Selected drive is the OS root disk — aborting"
  exit 1
fi

lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL "$TRIEDB_DRIVE"
echo
read -rp "Type YES to continue: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted by user"
  exit 1
fi

### Partitioning
echo "===> Creating GPT partition table"
parted -s "$TRIEDB_DRIVE" mklabel gpt
parted -s "$TRIEDB_DRIVE" mkpart triedb 0% 100%

partprobe "$TRIEDB_DRIVE"
sleep 2

### udev rule
PARTUUID=$(lsblk -no PARTUUID "$TRIEDB_PART")

if [[ -z "$PARTUUID" ]]; then
  echo "❌ Failed to detect PARTUUID"
  exit 1
fi

echo "===> Creating udev rule for /dev/triedb"
cat <<EOF > /etc/udev/rules.d/99-triedb.rules
ENV{ID_PART_ENTRY_UUID}=="$PARTUUID", MODE="0666", SYMLINK+="triedb"
EOF

udevadm trigger
udevadm control --reload
udevadm settle

if [[ ! -e /dev/triedb ]]; then
  echo "❌ /dev/triedb symlink not created"
  exit 1
fi

ls -l /dev/triedb

### LBA verification
echo "===> Verifying LBA format (512 bytes required)"
if ! nvme id-ns -H "$TRIEDB_DRIVE" | grep -q "Data Size: 512 bytes.*in use"; then
  echo "⚠️  512-byte LBA not enabled"
  echo "===> Formatting NVMe to LBAF=0 (512 bytes)"

  nvme format --lbaf=0 "$TRIEDB_DRIVE"
  sleep 5
fi

echo "===> Rechecking LBA configuration"
nvme id-ns -H "$TRIEDB_DRIVE" | grep 'LBA Format' | grep 'in use'

### Run monad-mpt
echo
echo "===> Initializing TrieDB with monad-mpt"
systemctl start monad-mpt

sleep 3
journalctl -u monad-mpt -n 20 -o cat

echo
echo "✅ TrieDB setup completed successfully"
echo "================================================="
echo "You can now proceed with keystore generation"
echo "Docs: https://gptonline.ai/"
