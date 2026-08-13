#!/usr/bin/env bash
#
# Helper functions for the junit2jira composite action.
#
# This script is self-contained: it relies only on common/common.sh (sourced by
# the action wrapper) and standard CLI tools. It is dispatched by subcommand,
# e.g.:
#
#   junit2jira.sh capture_job_failure_as_junit <directory> <job_name> ...
#   junit2jira.sh save_test_metrics <csv> <bucket> <subdir>
#
# Local run:
#
#   test/local-env.sh test/junit2jira/junit2jira.sh save_test_metrics ...
#
set -euo pipefail

_JUNIT_RESULT_FAILURE="FAILURE"

get_junit_misc_dir() {
  echo "${ARTIFACT_DIR}/junit-misc"
}

# Returns 0 if any *.xml file under the directory contains a JUnit <failure>.
junit_contains_failure() {
  local dir="$1"
  if [[ ! -d $dir ]]; then
    return 1
  fi
  local f
  while IFS= read -r -d '' f; do
    # Match both <failure> and <failure ...> formats.
    if grep -q '<failure[ >]' "$f"; then
      return 0
    fi
  done < <(find "$dir" -type f -iname '*.xml' -print0)
  return 1
}

# Writes a synthetic JUnit failure record into ${ARTIFACT_DIR}/junit-misc.
save_junit_failure() {
  if [[ "$#" -ne 3 ]]; then
    gh_log error "missing args. usage: save_junit_failure <class> <description> <details>"
    exit 1
  fi
  _save_junit_record "${_JUNIT_RESULT_FAILURE}" "$@"
}

_save_junit_record() {
  local disposition="$1"
  local class="$2"
  local description="$3"
  local details="${4:-}"

  if [[ -z "${ARTIFACT_DIR:-}" ]]; then
    gh_log warning "_save_junit_record requires the ARTIFACT_DIR variable to be set"
    return
  fi

  local junit_dir
  junit_dir="$(get_junit_misc_dir)"
  mkdir -p "${junit_dir}"

  # XML escape description.
  description="${description//&/\&amp;}"
  description="${description//\"/\&quot;}"
  description="${description//\'/\&#39;}"
  description="${description//</\&lt;}"
  description="${description//>/\&gt;}"

  local failures=0
  if [[ "${disposition}" == "${_JUNIT_RESULT_FAILURE}" ]]; then
    failures=1
  fi

  local junit_file="${junit_dir}/junit-${class}.xml"
  {
    echo "<testsuite name=\"${class}\" tests=\"1\" skipped=\"0\" failures=\"${failures}\" errors=\"0\">"
    echo "  <testcase name=\"${description}\" classname=\"${class}\">"
    if [[ "${disposition}" == "${_JUNIT_RESULT_FAILURE}" ]]; then
      echo "    <failure><![CDATA[${details}]]></failure>"
    fi
    echo "  </testcase>"
    echo "</testsuite>"
  } > "${junit_file}"
}

# If the GitHub job failed but produced no JUnit <failure> records, synthesise a
# JUnit failure so infrastructure/setup failures still get reported to Jira.
capture_job_failure_as_junit() {
  if [[ "$#" -ne 5 ]]; then
    gh_log error "missing args. usage: capture_job_failure_as_junit <directory> <job_name> <job_status> <steps_json> <workflow_run_url>"
    exit 1
  fi

  local directory="$1"
  local job_name="$2"
  local job_status="$3"
  local steps_json="$4"
  local workflow_run_url="$5"

  export ARTIFACT_DIR="${directory}"

  # Only process failures.
  if [[ "$job_status" != "failure" ]]; then
    gh_log debug "Job status: ${job_status} - no failure record needed"
    return 0
  fi

  # Check if JUnit test failures already exist.
  if junit_contains_failure "$directory"; then
    gh_log debug "JUnit test failures already exist - skipping failure record"
    return 0
  fi

  gh_log debug "Job failed but no JUnit test failures found - looking for failed step"

  # Try to find a specific failed step from the steps context (only includes steps with id).
  local failed_step
  failed_step=$(echo "$steps_json" | jq -r 'to_entries[] | select(.value.outcome == "failure") | .key' | head -1)

  if [[ -n "$failed_step" ]]; then
    local step_outcome step_conclusion
    step_outcome=$(echo "$steps_json" | jq -r ".[\"$failed_step\"].outcome")
    step_conclusion=$(echo "$steps_json" | jq -r ".[\"$failed_step\"].conclusion")

    local failure_details
    failure_details=$(cat <<EOF
Step failed during workflow execution.
Outcome: ${step_outcome}
Conclusion: ${step_conclusion}

Check workflow logs for details: ${workflow_run_url}
EOF
    )

    save_junit_failure "$job_name" "$failed_step" "$failure_details"
    gh_log debug "Created JUnit failure record for step: $failed_step"
    return 0
  fi

  # Fallback for steps without id (e.g. docker login, built-in setup steps).
  local generic_failure
  generic_failure=$(cat <<EOF
Job failed without producing JUnit test failures. This typically indicates an infrastructure failure in a step without an id (e.g. docker login, setup step, artifact download).
Check workflow logs: ${workflow_run_url}
EOF
  )

  save_junit_failure "$job_name" "error" "$generic_failure"
  gh_log debug "Created generic JUnit failure record for job: $job_name"
  return 0
}

# Uploads the test metrics CSV to GCS for BigQuery ingestion.
save_test_metrics() {
  if [[ "$#" -ne 3 ]]; then
    gh_log error "missing args. usage: save_test_metrics <CSV file> <bucket> <subdir>"
    exit 1
  fi
  local csv="$1"
  local bucket="$2"
  local subdir="$3"
  local to="${bucket}/${subdir}"
  gh_log debug "Saving Big Query test records from ${csv} to ${to}"
  gcloud storage cp "${csv}" "${to}/"
}

main() {
  local subcommand="${1:-}"
  check_not_empty subcommand
  shift
  case "$subcommand" in
    capture_job_failure_as_junit | save_test_metrics)
      "$subcommand" "$@"
      ;;
    *)
      gh_log error "unknown subcommand: ${subcommand}"
      exit 1
      ;;
  esac
}

main "$@"
