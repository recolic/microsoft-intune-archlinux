#!/bin/bash
# This is a one-click script to fix the known BadCertificate problem. (Details in README.md)
set -e

echo "-------------------------"
echo "--   fix libssl        --"
echo "-------------------------"

mkdir -p /tmp/.ossl332
curl -L https://archive.archlinux.org/packages/o/openssl/openssl-3.3.2-1-x86_64.pkg.tar.zst | tar --zstd -x -C /tmp/.ossl332

sudo cp /tmp/.ossl332/usr/lib/libcrypto.so.3 /usr/lib/libcrypto-332.so
sudo cp /tmp/.ossl332/usr/lib/libssl.so.3    /usr/lib/libssl-332.so

if command -v intune-portal >/dev/null 2>&1; then
    b=intune-portal
elif [ -f /opt/microsoft/intune/bin/intune-portal ]; then
    b=/opt/microsoft/intune/bin/intune-portal
else
    b="</path/to/intune-portal>"
fi

echo "Please run intune-portal like this:"
echo "  env LD_PRELOAD=/usr/lib/libcrypto-332.so:/usr/lib/libssl-332.so $b"


