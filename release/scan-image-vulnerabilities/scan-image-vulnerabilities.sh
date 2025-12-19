#!/usr/bin/env bash
#
# Scans an image for vulnerabilities and prints a summary of the vulnerabilities.
# For the purpose of this script, a vulnerability is an image component in a version that is affected by a CVE.
#
# Local run:
#
#  test/local-env.sh release/scan-image-vulnerabilities/scan-image-vulnerabilities.sh <image> <summary-prefix>
#
set -euo pipefail

function main() {
  IMAGE="${1:-}"
  SUMMARY_PREFIX="${2:-}"
  local result_path="scan-result.json"

  check_not_empty \
      IMAGE \
      SUMMARY_PREFIX

  scan_image "$IMAGE" "$result_path"

  # Count the number of vulnerabilities and fixable vulnerabilities for each severity.
  # Use associative arrays to store counts by severity.
  # Arrays are used via nameref parameters in print_vulnerability_status function.
  # shellcheck disable=SC2034
  declare -A vuln_counts
  # shellcheck disable=SC2034
  declare -A fixable_counts

  # shellcheck disable=SC2034
  for severity in CRITICAL IMPORTANT MODERATE LOW; do
    vuln_counts[$severity]="$(count_vulnerabilities "$severity" "$result_path")"
    fixable_counts[$severity]="$(count_fixable_vulnerabilities "$severity" "$result_path")"
  done

  gh_summary "### $SUMMARY_PREFIX $IMAGE"
  print_vulnerability_status vuln_counts fixable_counts

  # Print the vulnerabilities table in a collapsible section.
  # For the table to render correctly, we need to add a newline after the summary.
  gh_summary "<details><summary>Click to expand details</summary>\n"
  gh_summary "$(print_vulnerabilities_table "$result_path")"
  gh_summary "</details>"

  # Fail the build if any fixable critical or important vulnerabilities are found.
  severities=( "CRITICAL" "IMPORTANT" )
  for severity in "${severities[@]}"; do
    if (( fixable_counts[$severity] > 0 )); then
      exit 1
    fi
  done
}

# Scans the image for vulnerabilities.
function scan_image() {
  local image="$1"
  local result_path="$2"
  roxctl image scan --output=json --force \
    --image="${image}" | tee "$result_path"
  gh_output result-path "$result_path"
}

# Counts the number of vulnerabilities for a given severity.
function count_vulnerabilities() {
  local severity="$1"
  local result_path="$2"
  jq "[.result.vulnerabilities // [] | .[] | select(.cveSeverity == \"$severity\")] | length" "$result_path"
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
    local message="Found fixable critical or important vulnerabilities."

    gh_log "error" "$message See the step summary for details."
    gh_summary "Status: ❌"
    gh_summary "> $message"
  else
    gh_summary "Status: ✅"
    gh_summary "> No fixable critical or important vulnerabilities found."
  fi

  gh_summary ""
  gh_summary "| Severity | Total | Fixable |"
  gh_summary "| --- | --- | --- |"
  for severity in CRITICAL IMPORTANT MODERATE LOW; do
    gh_summary "| $severity | ${vuln_counts_ref[$severity]} | ${fixable_counts_ref[$severity]} |"
  done
}

# Prints a markdown table of the vulnerabilities, sorted by severity with fixable findings first.
# Each row contains left, right and column separators added by jq's join function.
function print_vulnerabilities_table() {
  local result_path="$1"
  echo "| COMPONENT | VERSION | CVE | SEVERITY | FIXED_VERSION | LINK |"
  echo "| --- | --- | --- | --- | --- | --- |"
  jq -r '
      .result.vulnerabilities // []
      | sort_by([
        (if ((.componentFixedVersion // "") != "") then 0 else 1 end),
        ({"CRITICAL":0,"IMPORTANT":1,"MODERATE":2,"LOW":3}[.cveSeverity] // 4)
      ])
      | (.[] | [.componentName // "", .componentVersion // "", .cveId // "", .cveSeverity // "", .componentFixedVersion // "", .cveInfo // ""] | "| " + join(" | ") + " |")
  ' "$result_path"
}

main "$@"
