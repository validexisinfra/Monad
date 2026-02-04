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
- Snapshot / hard-reset compatible
- **Dangerous steps isolated into explicit scripts**

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

# Monad Setup & Upgrade Scripts

## 🌟 Testnet Setup 

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Story/main/install_testnet.sh)
~~~


## 🌟 Mainnet Setup

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Monad/main/install_fullnode.sh)
~~~

---

## 🔄 Upgrade Scripts


~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Monad/main/upgrade.sh)
~~~

---

