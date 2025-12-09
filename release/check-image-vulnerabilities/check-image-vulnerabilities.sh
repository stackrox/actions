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

function print_vulnerability_status() {
  local -n vuln_counts_ref=$1
  local -n fixable_counts_ref=$2

  if (( fixable_counts_ref[CRITICAL] > 0 || fixable_counts_ref[IMPORTANT] > 0 )); then
    gh_log "error" "Found fixable critical or important vulnerabilities. See the step summary for details."
    touch failure_flag
    gh_summary "Status: ❌"
  else
    gh_summary "Status: ✅"
  fi

  gh_summary ""
  gh_summary "| Severity | Total | Fixable |"
  gh_summary "| --- | --- | --- |"
  for severity in CRITICAL IMPORTANT MODERATE; do
    gh_summary "| $severity | ${vuln_counts_ref[$severity]} | ${fixable_counts_ref[$severity]} |"
  done
}

result_path="scan-result.json"
scan_image "$IMAGE" "$VERSION" "$result_path"

# Count the number of vulnerabilities and fixable vulnerabilities for each severity.
# Use associative arrays to store counts by severity.
# Arrays are used via nameref parameters in print_vulnerability_status function.
# shellcheck disable=SC2034
declare -A vuln_counts
# shellcheck disable=SC2034
declare -A fixable_counts

# shellcheck disable=SC2034
for severity in CRITICAL IMPORTANT MODERATE; do
  vuln_counts[$severity]=$(count_vulnerabilities "$severity" "$result_path")
  fixable_counts[$severity]=$(count_fixable_vulnerabilities "$severity" "$result_path")
done

# Print the summary of the vulnerabilities.
gh_summary "### $IMAGE:$VERSION"
print_vulnerability_status vuln_counts fixable_counts

# Print the vulnerabilities table in a collapsible section.
# For the table to render correctly, we need to add a newline after the summary.
gh_summary "<details><summary>Click to expand details</summary>\n"
gh_summary "$(print_table "$result_path")"
gh_summary "</details>"

if [[ -f failure_flag ]]; then
  exit 1
fi
