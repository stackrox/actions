#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/.local/bin
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  # If ~/.local/bin is not in $PATH already, make it so for this and subsequent steps.
  PATH="$HOME/.local/bin:$PATH"
  echo "$HOME/.local/bin" >> "$GITHUB_PATH"
fi
echo "Downloading infractl..."

upgrade_data="$(mktemp)"
trap 'rm -f "${upgrade_data}"' EXIT
curl --fail --silent --show-error --retry 20 --retry-all-errors --location \
  --output "${upgrade_data}" https://infra.rox.systems/v1/cli/linux/amd64/upgrade
# jq's @base64d is not binary-safe
jq -r .result.fileChunk "${upgrade_data}" | base64 -d > ~/.local/bin/infractl
chmod +x ~/.local/bin/infractl
infractl --version
