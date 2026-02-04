#!/usr/bin/env bash
set -euo pipefail

MONAD_VERSION="0.12.7"
OTEL_VERSION="0.139.0"
MONAD_USER="monad"

echo "===> Monad Full Node Installer"
echo "===> gptonline.ai"

if [[ $EUID -ne 0 ]]; then
  echo "❌ Run as root"
  exit 1
fi

### 1. System update
echo "===> Updating system"
apt update
apt upgrade -y
apt install -y curl nvme-cli aria2 jq ufw gpg

### 2. APT repo
echo "===> Adding Monad APT repository"
mkdir -p /etc/apt/keyrings

cat <<EOF > /etc/apt/sources.list.d/category-labs.sources
Types: deb
URIs: https://pkg.category.xyz/
Suites: noble
Components: main
Signed-By: /etc/apt/keyrings/category-labs.gpg
EOF

curl -fsSL https://pkg.category.xyz/keys/public-key.asc \
  | gpg --dearmor --yes -o /etc/apt/keyrings/category-labs.gpg

apt update
apt install -y monad=${MONAD_VERSION}
apt-mark hold monad

### 3. Create monad user
if ! id monad &>/dev/null; then
  echo "===> Creating monad user"
  useradd -m -s /bin/bash ${MONAD_USER}
fi

### 4. Directory structure
echo "===> Creating directories"
mkdir -p /home/monad/monad-bft/config/{forkpoint,validators}
mkdir -p /home/monad/monad-bft/ledger
mkdir -p /opt/monad/backup

chown -R monad:monad /home/monad /opt/monad

### 5. Install OTEL Collector
echo "===> Installing OTEL Collector"
OTEL_PKG="/tmp/otelcol.deb"
curl -fsSL \
  "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol_${OTEL_VERSION}_linux_amd64.deb" \
  -o ${OTEL_PKG}

dpkg -i ${OTEL_PKG}
cp /opt/monad/scripts/otel-config.yaml /etc/otelcol/config.yaml
systemctl restart otelcol

### 6. Download configs (Mainnet Full Node)
echo "===> Downloading configuration files"
MF_BUCKET="https://bucket.monadinfra.com"

curl -o /home/monad/.env \
  ${MF_BUCKET}/config/mainnet/latest/.env.example

curl -o /home/monad/monad-bft/config/node.toml \
  ${MF_BUCKET}/config/mainnet/latest/full-node-node.toml

chown monad:monad /home/monad/.env \
  /home/monad/monad-bft/config/node.toml

### 7. Enable services
echo "===> Enabling services"
systemctl enable monad-bft monad-execution monad-rpc

echo ""
echo "✅ Base installation completed"
echo ""
echo "⚠️  NEXT MANUAL STEPS REQUIRED:"
echo "   1. Configure TrieDB NVMe (run triedb_setup.sh)"
echo "   2. Generate keystores (run keystore.sh)"
echo "   3. Configure firewall (firewall.sh)"
echo "   4. Edit node.toml (node_name, beneficiary)"
echo "   5. Hard reset & snapshot import"
echo ""
echo "Docs & scripts: https://gptonline.ai/"
