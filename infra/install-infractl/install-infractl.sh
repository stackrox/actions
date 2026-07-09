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
curl --fail --silent --show-error --retry 5 --retry-all-errors --retry-delay 5 --location \
  -o "${upgrade_data}" https://infra.rox.systems/v1/cli/linux/amd64/upgrade
jq -r ".result.fileChunk | @base64d" "${upgrade_data}" > ~/.local/bin/infractl
chmod +x ~/.local/bin/infractl
infractl --version
