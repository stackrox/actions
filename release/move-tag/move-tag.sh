#!/usr/bin/env bash
#
# Moves a remote tag to a new reference, identified by name.
#
# Local wet run:
#
#   DRY_RUN=false test/local-env.sh release/move-tag/move-tag.sh <sliding-tag> <github-ref>
#
set -euo pipefail

SLIDING_TAG="$1"
GITHUB_REF_NAME="$2"

check_not_empty \
    SLIDING_TAG \
    GITHUB_REF_NAME \
    DRY_RUN

git config user.name "Robot Rox"
git config user.email noreply@github.com

git tag --force \
    --annotate -m "Move tag ${SLIDING_TAG} after publication of ${GITHUB_REF_NAME}" \
    "${MAJOR_VERSION}" ${GITHUB_REF_NAME}

if [ "$DRY_RUN" = "false" ]; then
    git push --force origin "${SLIDING_TAG}"
fi
