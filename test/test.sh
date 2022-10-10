#!/usr/bin/env bash

set -euo pipefail

gh_log notice "Test script called on ref $GITHUB_REF_NAME"
gh_summary "Test script arguments:"
for arg in "$@"; do
    gh_summary "* \`$arg\`";
done
