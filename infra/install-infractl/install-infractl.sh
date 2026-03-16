#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/.local/bin
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  # If ~/.local/bin is not in $PATH already, make it so for this and subsequent steps.
  PATH="$HOME/.local/bin:$PATH"
  echo "$HOME/.local/bin" >> "$GITHUB_PATH"
fi
curl --fail -sL https://infra.rox.systems/v1/cli/linux/amd64/upgrade \
| jq -r ".result.fileChunk" \
| base64 -d \
> ~/.local/bin/infractl
chmod +x ~/.local/bin/infractl
infractl --version

echo "Hi there!"
