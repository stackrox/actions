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
SUMMARY_PREFIX="${3:-}"

check_not_empty \
    IMAGE \
    VERSION \
    SUMMARY_PREFIX

function main() {
  local image="$1"
  local version="$2"
  local summary_prefix="$3"
  local result_path="scan-result.json"

  # Scan the image for vulnerabilities.
  scan_image "$image" "$version" "$result_path"

  # Count the number of vulnerabilities and fixable vulnerabilities for each severity.
  # Use associative arrays to store counts by severity.
  # Arrays are used via nameref parameters in print_vulnerability_status function.
  # shellcheck disable=SC2034
  declare -A vuln_counts
  # shellcheck disable=SC2034
  declare -A fixable_counts

  # shellcheck disable=SC2034
  for severity in CRITICAL IMPORTANT MODERATE; do
    vuln_counts[$severity]="$(count_vulnerabilities "$severity" "$result_path")"
    fixable_counts[$severity]="$(count_fixable_vulnerabilities "$severity" "$result_path")"
  done

  # Print the summary of the vulnerabilities.
  gh_summary "### $summary_prefix $image:$version"
  print_vulnerability_status vuln_counts fixable_counts

  # Print the vulnerabilities table in a collapsible section.
  # For the table to render correctly, we need to add a newline after the summary.
  gh_summary "<details><summary>Click to expand details</summary>\n"
  gh_summary "$(print_vulnerabilities_table "$result_path")"
  gh_summary "</details>"

  # If the failure flag is produced by print_vulnerability_status,
  # exit with a failure status.
  if [[ -f failure_flag ]]; then
    exit 1
  fi
}

# Scans the image for vulnerabilities.
function scan_image() {
  local image="$1"
  local version="$2"
  local result_path="$3"
  roxctl image scan --output=json --force \
    --severity="MODERATE,IMPORTANT,CRITICAL" \
    --image="quay.io/${image}:${version}" > "$result_path"
  gh_output result-path "$result_path"
}

# Counts the number of vulnerabilities for a given severity.
function count_vulnerabilities() {
  local severity="$1"
  local result_path="$2"
  jq ".result.summary.$severity" "$result_path"
}

# Counts the number of fixable vulnerabilities for a given severity.
function count_fixable_vulnerabilities() {
  local severity="$1"
  local result_path="$2"
  jq "[.result.vulnerabilities // [] | .[] | select(.cveSeverity == \"$severity\" and .componentFixedVersion != \"\")] | length" "$result_path"
}

# Prints the vulnerability status and an overview table of the vulnerabilities counts.
function print_vulnerability_status() {
  local -n vuln_counts_ref=$1
  local -n fixable_counts_ref=$2

  if (( fixable_counts_ref[CRITICAL] > 0 || fixable_counts_ref[IMPORTANT] > 0 )); then
    local message="Found fixable critical or important vulnerabilities. See the step summary for details."

    gh_log "error" "$message"
    touch failure_flag
    gh_summary "Status: ❌"
    gh_summary "> $message"
  else
    gh_summary "Status: ✅"
    gh_summary "> No fixable critical or important vulnerabilities found."
  fi

  gh_summary ""
  gh_summary "| Severity | Total | Fixable |"
  gh_summary "| --- | --- | --- |"
  for severity in CRITICAL IMPORTANT MODERATE; do
    gh_summary "| $severity | ${vuln_counts_ref[$severity]} | ${fixable_counts_ref[$severity]} |"
  done
}

# Prints a markdown table of the vulnerabilities, sorted by severity.
function print_vulnerabilities_table() {
  local result_path="$1"
  # Convert jq CSV output to markdown table format:
  # - Replace commas with markdown column separators
  # - Add left and right borders to create table rows
  # - Remove CSV quotes
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

main "$IMAGE" "$VERSION" "$SUMMARY_PREFIX"
