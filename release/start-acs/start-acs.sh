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
# 
# export GITHUB_OUTPUT=delete-log-github-output.txt
# export GITHUB_STEP_SUMMARY=delete-log-start-acs.txt

set -euox pipefail

pushd "$STACKROX_DIR"

# shellcheck source=/dev/null
source "${STACKROX_DIR}"/deploy/common/deploy.sh

"${STACKROX_DIR}"/deploy/k8s/central.sh
kubectl -n stackrox port-forward deploy/central 8000:8443 > /dev/null 2>&1 &
sleep 20

"${STACKROX_DIR}"/deploy/k8s/sensor.sh

kubectl -n stackrox set env deploy/sensor MUTEX_WATCHDOG_TIMEOUT_SECS=0 ROX_FAKE_KUBERNETES_WORKLOAD=long-running ROX_FAKE_WORKLOAD_STORAGE=/var/cache/stackrox/pebble.db
kubectl -n stackrox patch deploy/sensor -p '{"spec":{"template":{"spec":{"containers":[{"name":"sensor","resources":{"requests":{"memory":"3Gi","cpu":"2"},"limits":{"memory":"12Gi","cpu":"4"}}}]}}}}'

kubectl -n stackrox set env deploy/central MUTEX_WATCHDOG_TIMEOUT_SECS=0
kubectl -n stackrox patch deploy/central -p '{"spec":{"template":{"spec":{"containers":[{"name":"central","resources":{"requests":{"memory":"3Gi","cpu":"2"},"limits":{"memory":"12Gi","cpu":"4"}}}]}}}}'

CENTRAL_IP=$(kubectl -n stackrox get svc/central-loadbalancer -o json | jq -r '.status.loadBalancer.ingress[0] | .ip // .hostname')

API_ENDPOINT="${CENTRAL_IP}":443
wait_for_central "${API_ENDPOINT}"

ROX_ADMIN_PASSWORD=$(cat "${STACKROX_DIR}"/deploy/k8s/central-deploy/password)
# TODO Mask $ROX_ADMIN_PASSWORD
#echo "::add-mask::$ROX_ADMIN_PASSWORD"
kubectl -n stackrox create secret generic access-rhacs --from-literal="username=${ROX_ADMIN_USERNAME}" --from-literal="password=${ROX_ADMIN_PASSWORD}" --from-literal="central_url=https://${CENTRAL_IP}"
echo "rox_password=${ROX_ADMIN_PASSWORD}" >> "$GITHUB_OUTPUT"
echo "central-ip=${CENTRAL_IP}" >> "$GITHUB_OUTPUT"
ls $GITHUB_OUTPUT
echo ""
cat $GITHUB_OUTPUT

printf "Long-running GKE cluster %s has been patched.\nAccess it by running \`./scripts/release-tools/setup-central-access.sh %s\` from your local machine." "${NAME//./-}" "${NAME//./-}" >> "$GITHUB_STEP_SUMMARY"
