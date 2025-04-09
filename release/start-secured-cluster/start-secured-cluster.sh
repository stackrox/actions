#!/usr/bin/env bash
set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create the collector-config ConfigMap in order to enable external IPs
kubectl create -f "${SCRIPT_DIR}/collector-config.yaml"

"${STACKROX_DIR}/deploy/k8s/sensor.sh"
kubectl -n stackrox create secret generic access-rhacs \
  --from-literal="username=${ROX_ADMIN_USERNAME}" \
  --from-literal="password=${ROX_ADMIN_PASSWORD}" \
  --from-literal="central_url=${CLUSTER_API_ENDPOINT}"

echo "Deploying Monitoring..."
helm_args=(
  --set persistence.type="${STORAGE}"
  --set exposure.type="${MONITORING_LOAD_BALANCER}"
)

helm dependency update "${COMMON_DIR}/../charts/monitoring"
envsubst < "${COMMON_DIR}/../charts/monitoring/values.yaml" > "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml"
helm upgrade -n stackrox --install --create-namespace stackrox-monitoring "${COMMON_DIR}/../charts/monitoring" --values "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml" "${helm_args[@]}"
rm "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml"
echo "Deployed Monitoring..."
