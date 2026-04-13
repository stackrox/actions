#!/bin/bash
#
# Enables auto-merge for eligible PRs with specified labels.
# PRs can be filtered by labels, base branches, and allowed author.
# Required status checks must pass for auto-merge to be enabled.
#
# Local run:
#
#  test/local-env.sh automerge/automerge.sh <repository> <limit> <label1,label2,...> <allowed-author> <required-checks> <allowed-base-branches>
#

set -euo pipefail

function main() {
    REPOSITORY="${1:-}"
    LIMIT="${2:-}"
    LABELS="${3:-}"
    ALLOWED_AUTHORS="${4:-}"
    REQUIRED_CHECKS="${5:-}"
    ALLOWED_BASE_BRANCHES="${6:-}"

    check_not_empty \
        DRY_RUN GH_TOKEN \
        REPOSITORY LIMIT LABELS ALLOWED_AUTHORS REQUIRED_CHECKS ALLOWED_BASE_BRANCHES

    gh_log notice "Querying PRs with '${LABELS}' label(s) in '${REPOSITORY}', allowed authors: '${ALLOWED_AUTHORS}', required checks: '${REQUIRED_CHECKS}', allowed base branches: '${ALLOWED_BASE_BRANCHES}'"
    gh_log notice "DRY_RUN: ${DRY_RUN}"

    # Extract repo owner and name
    IFS='/' read -r OWNER REPO <<< "${REPOSITORY}"

    # Get all PRs with auto-merge labels (non-draft, mergeable only)
    PR_DATA=$(gh pr list \
        --repo "${REPOSITORY}" \
        --label "${LABELS}" \
        --draft=false \
        --state open \
        --limit "${LIMIT}" \
        --json number,mergeable,author,baseRefName \
        --jq ".[] | select(.mergeable == \"MERGEABLE\") | {number, author: .author.login, baseRefName: .baseRefName}")

    if [[ -z "${PR_DATA}" ]]; then
        gh_log notice "No eligible PRs found with '${LABELS}' labels"
        exit 0
    fi

    # Process each PR
    echo "${PR_DATA}" | jq -c '.' | while read -r PR_JSON; do
        PR_NUMBER=$(echo "$PR_JSON" | jq -r '.number')
        AUTHOR=$(echo "$PR_JSON" | jq -r '.author')
        BASE_BRANCH=$(echo "$PR_JSON" | jq -r '.baseRefName')

        echo "[DEBUG] PR #${PR_NUMBER} - author='${AUTHOR}', base branch='${BASE_BRANCH}'"
        if [[ ! "${BASE_BRANCH}" =~ ^(${ALLOWED_BASE_BRANCHES})$ ]]; then
            echo "[DEBUG] PR #${PR_NUMBER} skipped - base branch '${BASE_BRANCH}' not allowed"
            continue
        fi

        STATUS="$(get_combined_success_status "${PR_NUMBER}")"

        # Only proceed if the required checks have passed
        if [[ "${STATUS}" == "true" ]]; then
            echo "[DEBUG] ✓ PR #${PR_NUMBER} - all required checks passed or skipped"
        else
            echo "[DEBUG] x PR #${PR_NUMBER} skipped - not all required checks passed or skipped"
            continue
        fi

        # Enable auto-merge for all PRs with the label(s)
        if [[ "${DRY_RUN}" == "true" ]]; then
            echo "[DEBUG] ✓ PR #${PR_NUMBER} - would have enabled auto-merge [DRY RUN]"
        else
            gh pr merge --repo "${REPOSITORY}" \
            --auto --squash "${PR_NUMBER}"
            echo "[DEBUG] ✓ PR #${PR_NUMBER} - auto-merge enabled"
        fi

        # Approve only PRs by allowed authors
        IFS=',' read -r -a ALLOWED_AUTHORS_ARRAY <<< "${ALLOWED_AUTHORS}"
        if [[ " ${ALLOWED_AUTHORS_ARRAY[*]} " == *"${AUTHOR}"* ]]; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                echo "[DEBUG] ✓ PR #${PR_NUMBER} - would have approved [DRY RUN]"
            else
                gh pr review --repo "${REPOSITORY}" \
                    --approve "${PR_NUMBER}"
                echo "[DEBUG] ✓ PR #${PR_NUMBER} - approved"
            fi
        else
            echo "[DEBUG] x PR #${PR_NUMBER} not approved - author '${AUTHOR}' not in allowed authors"
        fi
    done
}

# Collects all status checks and checkruns for the PR and returns a boolean indicating if all required checks have passed or been skipped.
# The REQUIRED_CHECKS regex parameter must return at least one check.
function get_combined_success_status() {
    PAGE_SIZE=100
    CURSOR=""
    NODES_JSON='[]'

    # shellcheck disable=SC2016
    QUERY='
    query($owner: String!, $repo: String!, $number: Int!, $first: Int!, $after: String) {
        repository(owner: $owner, name: $repo) {
            pullRequest(number: $number) {
                commits(last: 1) {
                    nodes {
                        commit {
                            statusCheckRollup {
                                contexts(first: $first, after: $after) {
                                    pageInfo {
                                        hasNextPage
                                        endCursor
                                    }
                                    nodes {
                                        ... on CheckRun {
                                            name
                                            status
                                            conclusion
                                        }
                                        ... on StatusContext {
                                            context
                                            state
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    '

    while true; do
        ARGS=(
            graphql
            -F owner="$OWNER"
            -F repo="$REPO"
            -F number="$PR_NUMBER"
            -F first="$PAGE_SIZE"
            -f query="$QUERY"
        )
        if [[ -n "${CURSOR}" ]]; then
            ARGS+=(-F after="${CURSOR}")
        fi

        RESP=$(gh api "${ARGS[@]}")

        PAGE_NODES=$(echo "${RESP}" | jq '.data.repository.pullRequest.commits.nodes[0].commit.statusCheckRollup.contexts.nodes // []')
        NODES_JSON=$(jq -n --argjson acc "${NODES_JSON}" --argjson page "${PAGE_NODES}" '$acc + $page')

        HAS_NEXT=$(echo "${RESP}" | jq -r '.data.repository.pullRequest.commits.nodes[0].commit.statusCheckRollup.contexts.pageInfo.hasNextPage // false')
        if [[ "${HAS_NEXT}" != "true" ]]; then
            break
        fi
        CURSOR=$(echo "${RESP}" | jq -r '.data.repository.pullRequest.commits.nodes[0].commit.statusCheckRollup.contexts.pageInfo.endCursor // empty')
        if [[ -z "${CURSOR}" ]]; then
            gh_log error "Pagination indicated hasNextPage but endCursor is empty"
            exit 1
        fi
    done

    echo "$NODES_JSON" | jq -r --arg pattern "${REQUIRED_CHECKS}" '
        [.[]
        | select(
            (.name != null and (.name | test($pattern)))
            or (.context != null and (.context | test($pattern)))
          )
        | if .name != null then {conclusion: .conclusion}
          else {conclusion: .state}
          end
        ]
        | length > 0 and all(.conclusion == "SUCCESS" or .conclusion == "SKIPPED")
    '
}

main "$@"
