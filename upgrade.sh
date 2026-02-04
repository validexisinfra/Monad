#!/usr/bin/env bash
set -euo pipefail

TARGET_VERSION="0.12.7"

echo "================================================="
echo " Monad Upgrade Script → v${TARGET_VERSION}"
echo "================================================="
echo "⚠️  Proceed ONLY after official Monad Foundation notice"
echo "👉 gptonline.ai"
echo

if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root"
  exit 1
fi

echo "===> Updating APT cache"
apt update

echo "===> Reinstalling monad=${TARGET_VERSION}"
apt install --reinstall -y \
  monad=${TARGET_VERSION} \
  --allow-downgrades \
  --allow-change-held-packages

echo "===> Restarting Monad services"
systemctl restart monad-bft monad-execution monad-rpc

echo "===> Waiting for services to stabilize"
sleep 5

echo
echo "===> Service status"
systemctl status monad-bft monad-execution monad-rpc --no-pager

echo
echo "===> Verifying version"
monad-rpc --version

echo
echo "Expected output:"
echo 'monad-rpc {"commit":"e1e9489b8fc42c0a5af208bab20f6704f83c91c0","tag":"v0.12.7"}'
echo
echo "✅ Upgrade process finished"
echo "================================================="
echo "Docs & automation: https://gptonline.ai/"
