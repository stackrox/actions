#!/usr/bin/env bash
set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"${STACKROX_DIR}/deploy/k8s/sensor.sh"
kubectl -n stackrox create secret generic access-rhacs \
  --from-literal="username=${ROX_ADMIN_USERNAME}" \
  --from-literal="password=${ROX_ADMIN_PASSWORD}" \
  --from-literal="central_url=${CLUSTER_API_ENDPOINT}"

# Create the collector-config ConfigMap in order to enable external IPs
kubectl create -f "${SCRIPT_DIR}/collector-config.yaml"

echo "Deploying Monitoring..."
monitoring_values_file="${COMMON_DIR}/../charts/monitoring/values.yaml"

helm_args=(
  --set persistence.type="${STORAGE}"
  --set exposure.type="${MONITORING_LOAD_BALANCER}"
  --set resources.requests.memory="8Gi"
  --set resources.limits.memory="8Gi"
  --set-json 'metricRelabelConfigs=[{"source_labels":["container"],"regex":"berserker","action":"drop"},{"source_labels":["namespace"],"regex":"berserker-.*","action":"drop"}]'
)

helm dependency update "${COMMON_DIR}/../charts/monitoring"
envsubst < "$monitoring_values_file" > "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml"
helm upgrade -n stackrox --install --create-namespace stackrox-monitoring "${COMMON_DIR}/../charts/monitoring" --values "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml" "${helm_args[@]}"
rm "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml"
