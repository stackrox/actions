#!/usr/bin/env bash
#
# Counts the number of fixable vulnerabilities in the scan result.
#
# Local run:
#
#  test/local-env.sh release/check-image-vulnerabilities/check-image-vulnerabilities.sh <image> <version>
#
set -euo pipefail

IMAGE="${1:-}"
VERSION="${2:-}"

check_not_empty \
    IMAGE \
    VERSION

function count_fixable_vulnerabilities() {
  local severity="$1"
  local result_path="$2"
  jq "[.result.vulnerabilities[] | select(.cveSeverity == \"$severity\" and .componentFixedVersion != \"\")] | length" "$result_path"
}

function count_vulnerabilities() {
  local severity="$1"
  local result_path="$2"
  jq ".result.summary.$severity" "$result_path"
}

function scan_image() {
  local image="$1"
  local version="$2"
  local result_path="$3"
  roxctl image scan --output=json --force \
    --severity="MODERATE,IMPORTANT,CRITICAL" \
    --image="quay.io/${image}:${version}" > "$result_path"
  gh_output result-path "$result_path"
}

# Prints a markdown table of the vulnerabilities, sorted by severity.
function print_table() {
  local result_path="$1"
    jq -r '
        .result.vulnerabilities // []
        | (["COMPONENT","VERSION","CVE","SEVERITY","FIXED_VERSION","LINK"] | @csv),
        (["---","---","---","---","---","---"] | @csv),
        (.[] | [.componentName // "", .componentVersion // "", .cveId // "", .cveSeverity // "", .componentFixedVersion // "", .cveInfo // ""] | @csv)
    ' <(cat "$result_path") \
    | sed 's/,/ | /g' \
    | sed 's/^/| /' \
    | sed 's/$/ |/' \
    | sed 's/"//g'
}

function print_summary_message() {
  local severity="$1"
  local cnt="$2"
  local fixable_cnt="$3"
  gh_summary "* Found $cnt $severity vulnerabilities, of which $fixable_cnt are fixable."
}

result_path="scan-result.json"
scan_image "$IMAGE" "$VERSION" "$result_path"

CRITICAL_CNT=$(count_vulnerabilities "CRITICAL" "$result_path")
CRITICAL_FIXABLE_CNT=$(count_fixable_vulnerabilities "CRITICAL" "$result_path")

IMPORTANT_CNT=$(count_vulnerabilities "IMPORTANT" "$result_path")
IMPORTANT_FIXABLE_CNT=$(count_fixable_vulnerabilities "IMPORTANT" "$result_path")

MODERATE_CNT=$(count_vulnerabilities "MODERATE" "$result_path")
MODERATE_FIXABLE_CNT=$(count_fixable_vulnerabilities "MODERATE" "$result_path")

gh_summary "### $IMAGE:$VERSION"
print_summary_message "CRITICAL" "$CRITICAL_CNT" "$CRITICAL_FIXABLE_CNT"
print_summary_message "IMPORTANT" "$IMPORTANT_CNT" "$IMPORTANT_FIXABLE_CNT"
print_summary_message "MODERATE" "$MODERATE_CNT" "$MODERATE_FIXABLE_CNT"

# Print the vulnerabilities table in a collapsible section.
# For the table to render correctly, we need to add a newline after the summary.
gh_summary "<details><summary>Vulnerabilities</summary>\n"
gh_summary "$(print_table "$result_path")"
gh_summary "</details>"

if [[ "$CRITICAL_FIXABLE_CNT" -gt 0 || "$IMPORTANT_FIXABLE_CNT" -gt 0 ]]; then
  gh_log "error" "Found fixable critical or important vulnerabilities. See the step summary for details."
  exit 1
fi
