#!/usr/bin/env bash
#
# Sets some necessary variables up for local testing.
#
# Usage example:
#     test/local-env.sh test/test.sh args
#
export GITHUB_STEP_SUMMARY=/dev/stdout
export GITHUB_OUTPUT=/dev/stdout
GITHUB_ACTOR=$(git config --get user.email)
export GITHUB_ACTOR
export GITHUB_REPOSITORY=stackrox/stackrox
export GITHUB_SERVER_URL=https://github.com
GITHUB_REF_NAME=$(git branch --show-current)
export GITHUB_REF_NAME

main_branch=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
export main_branch

if [ -z "$DRY_RUN" ]; then
    export DRY_RUN=true
fi

ROOT=$(git rev-parse --show-toplevel)

CI="false" # true if running in GitHub context
export CI

# Supress shellcheck false warning:
# shellcheck source=/dev/null
source "$ROOT/common/common.sh"

SCRIPT="$ROOT/$1"
shift
bash "$SCRIPT" "$@"
