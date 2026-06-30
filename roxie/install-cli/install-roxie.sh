#!/usr/bin/env bash

set -euo pipefail

arch=$(uname -m)
case "$arch" in
    x86_64)  arch=amd64 ;;
    aarch64) arch=arm64 ;;
    *)
        echo "::error::Unsupported architecture: $arch"
        exit 1
        ;;
esac

if [[ -z "${ROXIE_VERSION:-}" ]]; then
    ROXIE_VERSION=$(curl -fsSL --retry 5 --retry-all-errors \
        https://api.github.com/repos/stackrox/roxie/releases/latest | jq -r '.tag_name')
    echo "::notice::Resolved latest roxie version: ${ROXIE_VERSION}"
fi

mkdir -p ~/.local/bin
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    PATH="$HOME/.local/bin:$PATH"
    echo "$HOME/.local/bin" >> "$GITHUB_PATH"
fi

url="https://github.com/stackrox/roxie/releases/download/${ROXIE_VERSION}/roxie-linux-${arch}"
echo "::notice::Downloading roxie ${ROXIE_VERSION} (linux/${arch}) from ${url}"

curl -fsSL --retry 5 --retry-all-errors -o ~/.local/bin/roxie "$url"
chmod +x ~/.local/bin/roxie

curl -fsSL --retry 5 --retry-all-errors -o /tmp/roxie-checksums.txt \
    "https://github.com/stackrox/roxie/releases/download/${ROXIE_VERSION}/checksums.txt"
expected=$(grep "roxie-linux-${arch}$" /tmp/roxie-checksums.txt | awk '{print $1}')
actual=$(sha256sum ~/.local/bin/roxie | awk '{print $1}')
if [[ "$expected" != "$actual" ]]; then
    echo "::error::Checksum mismatch: expected ${expected}, got ${actual}"
    exit 1
fi

roxie version
