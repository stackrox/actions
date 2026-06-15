#!/usr/bin/env bash
# Queries BigQuery for per-job CPU performance and generates ranking files.
# Only creates per-job files where the ranking meaningfully differs from _default.
#
# Usage: bash generate-rankings.sh [--dry-run]
#
# Requires: bq CLI authenticated to acs-san-stackroxci project.

set -euo pipefail

RANKINGS_DIR="${BASH_SOURCE[0]%/*}/rankings"
BAND_PCT=5        # CPUs within this % of each other are in the same band
BQ_TABLE="acs-san-stackroxci.ci_metrics.stackrox_jobs"

# Use the last full calendar month for stable averages (not a rolling window)
month_start=$(date -u -v-1m +%Y-%m-01 2>/dev/null || date -u -d "last month" +%Y-%m-01)
month_end=$(date -u +%Y-%m-01)
TIME_FILTER="started_at >= '${month_start}' AND started_at < '${month_end}'"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Jobs that have speedracer enabled. Only these get per-job ranking files.
SPEEDRACER_JOBS="pre-build-go-binaries build-and-push-main build-and-push-operator build-and-push-scanner go go-postgres"

# CPU ID extraction — must match action.yaml's sed
cpu_id_sql="CASE
    WHEN build LIKE '%EPYC 7763%' THEN 'EPYC-7763'
    WHEN build LIKE '%EPYC 9V74%' THEN 'EPYC-9V74'
    WHEN build LIKE '%EPYC 9V45%' THEN 'EPYC-9V45'
    WHEN build LIKE '%8370C%' THEN 'Xeon-8370C'
    WHEN build LIKE '%8573C%' THEN 'Xeon-8573C'
    WHEN build LIKE '%6973P%' THEN 'Xeon-6973P'
    WHEN build LIKE '%Neoverse%' THEN 'Neoverse-N2'
    ELSE build
  END"

# ── 1. Query BQ ────────────────────────────────────────────────────────────

echo "Querying BigQuery (${month_start} to ${month_end})..."

bq_data=$(bq query --use_legacy_sql=false --format=csv --max_rows=5000 "
SELECT
  name AS job_name,
  ${cpu_id_sql} AS cpu_id,
  COUNT(*) AS n,
  ROUND(AVG(TIMESTAMP_DIFF(stopped_at, started_at, SECOND)), 1) AS avg_sec
FROM \`${BQ_TABLE}\`
WHERE build IS NOT NULL AND build != '' AND build NOT LIKE 'ubuntu%'
  AND ${TIME_FILTER}
  AND stopped_at IS NOT NULL AND outcome = 'success' AND ci_system = 'gha'
GROUP BY job_name, cpu_id
HAVING COUNT(*) > 20
ORDER BY job_name, avg_sec DESC
" 2>&1 | tail -n +2)  # skip header

# ── 2. Generate _default (overall ranking) ──────────────────────────────────

echo "Generating _default ranking..."

default_data=$(bq query --use_legacy_sql=false --format=csv --max_rows=100 "
SELECT
  ${cpu_id_sql} AS cpu_id,
  ROUND(AVG(TIMESTAMP_DIFF(stopped_at, started_at, SECOND)), 1) AS avg_sec
FROM \`${BQ_TABLE}\`
WHERE build IS NOT NULL AND build != '' AND build NOT LIKE 'ubuntu%'
  AND ${TIME_FILTER}
  AND stopped_at IS NOT NULL AND outcome = 'success' AND ci_system = 'gha'
GROUP BY cpu_id
HAVING COUNT(*) > 20
ORDER BY avg_sec DESC
" 2>&1 | tail -n +2)

default_order=$(echo "$default_data" | cut -d, -f1)
echo "$default_order" > "${RANKINGS_DIR}/_default"
echo "  _default: $(echo "$default_order" | tr '\n' ' ')"

# ── 3. For each job, check if its ranking differs from _default ─────────────

jobs="$SPEEDRACER_JOBS"

changed=0
unchanged=0
removed=0

for job in $jobs; do
  # Extract this job's data: cpu_id,avg_sec (already sorted slowest-first)
  job_data=$(echo "$bq_data" | awk -F, -v j="$job" '$1 == j {print $2","$4}')
  job_order=$(echo "$job_data" | cut -d, -f1)

  # Check if strict order matches _default (considering only shared CPUs)
  # Filter _default to only CPUs present in this job's data
  shared_default=$(echo "$default_order" | while read -r cpu; do
    if echo "$job_order" | grep -qxF "$cpu"; then echo "$cpu"; fi
  done)

  if [[ "$job_order" == "$shared_default" ]]; then
    # Strict order matches — no file needed
    if [[ -f "$RANKINGS_DIR/$job" ]]; then
      echo "  $job: matches _default (removing)"
      $DRY_RUN || rm "$RANKINGS_DIR/$job"
      removed=$((removed + 1))
    fi
    unchanged=$((unchanged + 1))
    continue
  fi

  # Order differs — check if differences are within noise band
  needs_own_file=false
  job_cpus=()
  job_secs=()
  while IFS=, read -r cpu sec; do
    job_cpus+=("$cpu")
    job_secs+=("$sec")
  done <<< "$job_data"

  # For each pair of CPUs that are swapped relative to _default,
  # check if they're within BAND_PCT of each other
  for ((i=0; i<${#job_cpus[@]}; i++)); do
    for ((j=i+1; j<${#job_cpus[@]}; j++)); do
      cpu_i="${job_cpus[$i]}"
      cpu_j="${job_cpus[$j]}"
      sec_i="${job_secs[$i]}"
      sec_j="${job_secs[$j]}"

      # Find their positions in _default
      pos_i=$(echo "$shared_default" | grep -nxF "$cpu_i" | cut -d: -f1 || true)
      pos_j=$(echo "$shared_default" | grep -nxF "$cpu_j" | cut -d: -f1 || true)

      # If either CPU isn't in _default, can't compare — keep the job file
      if [[ -z "$pos_i" || -z "$pos_j" ]]; then
        needs_own_file=true
        break 2
      fi

      # i is ranked slower (higher in list) than j in the job data.
      # If _default has them in the opposite order (pos_i > pos_j means
      # _default thinks i is faster), they're swapped.
      if [[ "$pos_i" -gt "$pos_j" ]]; then
        # Swapped — is the gap significant?
        pct_gap=$(awk "BEGIN {printf \"%.1f\", ($sec_i - $sec_j) / $sec_j * 100}")
        if awk "BEGIN {exit ($pct_gap > $BAND_PCT) ? 0 : 1}"; then
          needs_own_file=true
          break 2
        fi
      fi
    done
  done

  if $needs_own_file; then
    echo "  $job: differs from _default → $(echo "$job_order" | tr '\n' ' ')"
    if ! $DRY_RUN; then
      echo "$job_order" > "$RANKINGS_DIR/$job"
    fi
    changed=$((changed + 1))
  else
    echo "  $job: within ${BAND_PCT}% noise of _default (removing)"
    if [[ -f "$RANKINGS_DIR/$job" ]] && ! $DRY_RUN; then
      rm "$RANKINGS_DIR/$job"
    fi
    removed=$((removed + 1))
    unchanged=$((unchanged + 1))
  fi
done

# Remove ranking files for jobs not in SPEEDRACER_JOBS
for f in "$RANKINGS_DIR"/*; do
  name=$(basename "$f")
  [[ "$name" == "_default" ]] && continue
  if ! echo "$SPEEDRACER_JOBS" | tr ' ' '\n' | grep -qxF "$name"; then
    echo "  $name: not a speedracer job (removing)"
    $DRY_RUN || rm "$f"
    removed=$((removed + 1))
  fi
done

echo ""
echo "Summary: ${changed} job-specific files written, ${unchanged} match _default, ${removed} removed"
echo ""
echo "Final ranking files:"
for f in "$RANKINGS_DIR"/*; do
  echo "  $(basename "$f"): $(tr '\n' ' ' < "$f")"
done
