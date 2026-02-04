# Monad

# Monad Full Node Installer

A set of automated scripts for installing and bootstrapping a **Monad Full Node** on **bare-metal Ubuntu servers (24.04+)**.

This repository is designed for node operators, infrastructure providers, and validators who need a **safe, reproducible, and auditable** installation process that follows Monad best practices.

---

## 🚀 Features

- Official APT-based installation of Monad
- systemd services:
  - `monad-bft` (consensus client)
  - `monad-execution` (execution client)
  - `monad-rpc` (RPC server)
  - `monad-mpt` (TrieDB initialization)
  - `monad-cruft` (artifact cleanup)
  - `otelcol` (OpenTelemetry collector)
- Mainnet and Testnet support
- Dedicated NVMe TrieDB setup
- Secure keystore generation with backups
- Firewall configuration (UFW + iptables)

---

## 🧱 Requirements

### Hardware
- Bare-metal server (VMs not supported)
- Dedicated NVMe SSD for TrieDB (no RAID, no filesystem)
- Hyper-Threading / SMT **disabled in BIOS**

### Software
- **Ubuntu 24.04+**
- **Linux kernel ≥ 6.8.0.60**
  > ⚠️ Kernel versions 6.8.0.56–6.8.0.59 contain a known bug causing Monad clients to hang
- Root access

---

## Monad Setup & Upgrade Scripts

### 🌟 Testnet Setup 

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Story/main/install_testnet.sh)
~~~


### 🌟 Mainnet Setup

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Monad/main/install_fullnode.sh)
~~~

---

### 🔄 Upgrade Scripts


~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Monad/main/upgrade.sh)
~~~

---

# 💾 TrieDB Setup (Required)

Monad uses a dedicated **TrieDB** to store blockchain state.  
For performance and stability reasons, TrieDB **must be placed on a separate NVMe drive** and initialized **before starting the node**.

> ⚠️ **WARNING**  
> This step **formats the selected NVMe device**.  
> Selecting the wrong disk will result in **irreversible data loss**.  
> Proceed only if you are absolutely sure which device is used for TrieDB.

---

### 📌 Requirements

- Dedicated NVMe SSD
- No filesystem mounted
- No RAID / LVM
- 512-byte LBA enabled
- Disk must **NOT** be the OS/root disk

---

### 🧰 TrieDB Initialization Script

The TrieDB setup script performs the following actions:

- Creates a GPT partition table
- Allocates the full disk for TrieDB
- Creates a persistent `/dev/triedb` symlink via udev
- Verifies and enforces **512-byte LBA**
- Runs the one-time `monad-mpt` initialization service

Run the script **as root**:

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Monad/main/triedb_setup.sh)
~~~

---

### ✅ Verification

After successful execution, verify:

- `/dev/triedb` exists and points to the correct NVMe partition
- `monad-mpt` completed without errors

Check logs:

~~~bash
journalctl -u monad-mpt --no-pager
~~~

---

### ❌ Common Mistakes

- Using the OS disk instead of a dedicated NVMe
- Running on virtual machines (VMs)
- Using disks with 4K LBA instead of 512-byte LBA
- Starting Monad services before TrieDB initialization

---

### 🔁 Reinitializing TrieDB

If TrieDB needs to be rebuilt (e.g. after corruption or full reset):

1. Stop all Monad services
2. Re-run the TrieDB setup script
3. Import a fresh snapshot (if applicable)
4. Restart the node

---

### 📝 Notes

- TrieDB is **not mounted** and must not be formatted with a filesystem
- All access to TrieDB is handled directly by Monad via `/dev/triedb`
- TrieDB initialization is a **one-time operation per disk**
