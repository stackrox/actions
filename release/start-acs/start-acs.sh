#!/usr/bin/env bash
#
# Start ACS central and secured cluster and patch it so that it can be used for the long running cluster
#
# When running locally there should be a kubeconfig created.
# When running locally there are some environment variables that should be set
#
# export NAME=<cluster name>
# export KUBECONFIG=/tmp/${NAME}/kubeconfig
#
# export ROX_IMAGE_FLAVOR=RHACS_BRANDING
# export MAIN_IMAGE_TAG=<tag>
# export API_ENDPOINT=localhost:8000
# export STORAGE=pvc # Backing storage
# export STORAGE_CLASS=faster # Runs on an SSD type
# export STORAGE_SIZE=100 # 100G
# export MONITORING_SUPPORT=true # Runs monitoring
# export LOAD_BALANCER=lb
# export ROX_ADMIN_USERNAME=admin
# export STACKROX_DIR=<stackrox dir>
# export PAGERDUTY_INTEGRATION_KEY=<PagerDuty release engineering integration key>
#
# export GITHUB_OUTPUT=delete-log-github-output.txt
# export GITHUB_STEP_SUMMARY=delete-log-start-acs.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if kubectl -n stackrox get deploy/central; then
  gh_log error "Central is already running. It means that you are trying to deploy ACS to a cluster where it is already deployed. This can happen if you try to create a long-running cluster for a release candicate when the such a cluster already exists. Try looking for another workflow that created the cluster."
  exit 1
fi

gh_log notice "Deploying ACS with roxie..."
roxie_envrc="$(mktemp)"
roxie deploy \
    --verbose \
    --tag "$MAIN_IMAGE_TAG" \
    --config "${SCRIPT_DIR}/roxie-config.yaml" \
    --envrc "$roxie_envrc" \
    --early-readiness

# shellcheck source=/dev/null
source "$roxie_envrc"
rm -f "$roxie_envrc"
CENTRAL_IP="${API_ENDPOINT%:*}"
gh_log notice "CENTRAL_IP=$CENTRAL_IP"

if [[ "${MONITORING_SUPPORT:-}" == "true" ]]; then
    gh_log notice "Deploying monitoring stack..."
    monitoring_values="$(mktemp)"
    envsubst < "${STACKROX_DIR}/deploy/charts/monitoring/values.yaml" > "$monitoring_values"
    helm dependency update "${STACKROX_DIR}/deploy/charts/monitoring"
    helm upgrade -n stackrox --install stackrox-monitoring \
        "${STACKROX_DIR}/deploy/charts/monitoring" \
        --values "$monitoring_values" \
        --set persistence.type=pvc \
        --set exposure.type=none
    rm -f "$monitoring_values"
fi

# Don't mask the password: masked values are not passed to the runner.
gh_output rox-password "$ROX_ADMIN_PASSWORD"
gh_output central-ip "$CENTRAL_IP"
gh_output ca-cert "$(base64 -w0 < "$ROX_CA_CERT_FILE")"

gh_log notice "Creating access-rhacs secret with the username and the password..."
kubectl -n stackrox create secret generic access-rhacs \
    --from-literal="username=${ROX_ADMIN_USERNAME}" \
    --from-literal="password=${ROX_ADMIN_PASSWORD}" \
    --from-literal="central_url=https://${CENTRAL_IP}"

gh_summary <<EOSUMMARY
Long-running GKE cluster ${NAME//./-} has been patched.
Access it by running:
\`\`\`
./scripts/release-tools/setup-central-access.sh ${NAME//./-}
\`\`\`
from your local machine.
EOSUMMARY
