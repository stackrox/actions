#!/usr/bin/env bash
set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Extract version from MAIN_IMAGE_TAG (e.g., "4.11.0-rc.2" -> "4.11")
version_major_minor=$(echo "${MAIN_IMAGE_TAG}" | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')

# Compare version to determine which script to use
# Use bc for floating point comparison
if (( $(echo "$version_major_minor >= 4.11" | bc -l) )); then
  echo "Using ACS 4.11+ secured cluster setup (version: ${version_major_minor})"
  exec "${SCRIPT_DIR}/start-secured-cluster-4.11plus.sh"
else
  echo "Using ACS pre-4.11 secured cluster setup (version: ${version_major_minor})"
  exec "${SCRIPT_DIR}/start-secured-cluster-pre4.11.sh"
fi
