#!/usr/bin/env bash

set -euo pipefail

os=$(uname -s)
if [[ "$os" != "Linux" ]]; then
    echo "::error::Unsupported operating system: $os"
    exit 1
fi

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

base_url="https://github.com/stackrox/roxie/releases/download/${ROXIE_VERSION}"
binary="roxie-linux-${arch}"
echo "::notice::Downloading roxie ${ROXIE_VERSION} (linux/${arch}) from ${base_url}/${binary}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -fsSL --retry 5 --retry-all-errors -o "$tmpdir/roxie" "${base_url}/${binary}"
curl -fsSL --retry 5 --retry-all-errors -o "$tmpdir/checksums.txt" "${base_url}/checksums.txt"

expected=$(awk "/  ${binary}\$/ {print \$1}" "$tmpdir/checksums.txt")
actual=$(sha256sum "$tmpdir/roxie" | awk '{print $1}')
if [[ "$expected" != "$actual" ]]; then
    echo "::error::Checksum mismatch: expected ${expected}, got ${actual}"
    exit 1
fi

mkdir -p ~/.local/bin
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    PATH="$HOME/.local/bin:$PATH"
    echo "$HOME/.local/bin" >> "$GITHUB_PATH"
fi

mv "$tmpdir/roxie" ~/.local/bin/roxie
chmod +x ~/.local/bin/roxie

roxie version
