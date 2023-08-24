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

pushd "$STACKROX_DIR"

# shellcheck source=/dev/null
source "${STACKROX_DIR}"/deploy/common/deploy.sh

gh_log notice "Deploying central..."
"${STACKROX_DIR}"/deploy/k8s/central.sh

gh_log notice "Forwarding central port..."
kubectl -n stackrox port-forward deploy/central 8000:8443 > /dev/null 2>&1 &
sleep 20

gh_log notice "Deploying sensor..."
"${STACKROX_DIR}"/deploy/k8s/sensor.sh

PATCH=$(cat <<EOPATCH
{ "spec": { "template":
    { "spec": { "containers": [
        { "name": "sensor",
            "env": [
                { "name": "MUTEX_WATCHDOG_TIMEOUT_SECS", "value": "0" },
                { "name": "ROX_FAKE_KUBERNETES_WORKLOAD", "value": "long-running" },
                { "name": "ROX_FAKE_WORKLOAD_STORAGE", "value": "/var/cache/stackrox/pebble.db" }
            ],
            "resources": {
                "requests": { "memory": "3Gi", "cpu": "2" },
                "limits": { "memory": "12Gi", "cpu": "4" }
            }
        }
    ] } }
} }
EOPATCH
)
gh_log notice "Patching sensor deployment..."
kubectl -n stackrox patch deploy/sensor -p "$PATCH"

PATCH=$(cat <<EOPATCH
{ "spec": { "template":
    { "spec": { "containers": [
        { "name": "central",
            "env": [
                { "name": "MUTEX_WATCHDOG_TIMEOUT_SECS", "value": "0" }
            ],
            "resources": {
                "requests": { "memory": "3Gi", "cpu": "2" },
                "limits": { "memory": "12Gi", "cpu": "4" }
            }
        }
    ] } }
} }
EOPATCH
)
gh_log notice "Patching central deployment..."
kubectl -n stackrox patch deploy/central -p "$PATCH"

CENTRAL_IP=$(kubectl -n stackrox get svc/central-loadbalancer -o json | jq -r '.status.loadBalancer.ingress[0] | .ip // .hostname')
gh_log notice "CENTRAL_IP=$CENTRAL_IP"

API_ENDPOINT="${CENTRAL_IP}:443"
wait_for_central "${API_ENDPOINT}"

ROX_ADMIN_PASSWORD=$(cat "${STACKROX_DIR}"/deploy/k8s/central-deploy/password)

popd

# Don't mask the password: masked values are not passed to the runner.
gh_output rox-password "$ROX_ADMIN_PASSWORD"
gh_output central-ip "$CENTRAL_IP"

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
