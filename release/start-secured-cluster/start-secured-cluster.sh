#!/usr/bin/env bash
set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Extract version from MAIN_IMAGE_TAG (e.g., "4.11.0-rc.2" -> "4.11")
version_major_minor=$(echo "${MAIN_IMAGE_TAG}" | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')

# Parse major and minor version numbers
version_major=$(echo "${version_major_minor}" | cut -d. -f1)
version_minor=$(echo "${version_major_minor}" | cut -d. -f2)

# Determine if version is 4.11 or later (compare as integers, not floats)
is_4_11_plus=false
if [[ "$version_major" -gt 4 ]] || [[ "$version_major" -eq 4 && "$version_minor" -ge 11 ]]; then
  echo "Using ACS 4.11+ secured cluster setup (version: ${version_major_minor})"
  is_4_11_plus=true
else
  echo "Using ACS pre-4.11 secured cluster setup (version: ${version_major_minor})"
fi

"${STACKROX_DIR}/deploy/k8s/sensor.sh"
kubectl -n stackrox create secret generic access-rhacs \
  --from-literal="username=${ROX_ADMIN_USERNAME}" \
  --from-literal="password=${ROX_ADMIN_PASSWORD}" \
  --from-literal="central_url=${CLUSTER_API_ENDPOINT}"

# Create the collector-config ConfigMap in order to enable external IPs
kubectl create -f "${SCRIPT_DIR}/collector-config.yaml"

echo "Deploying Monitoring..."
monitoring_values_file="${COMMON_DIR}/../charts/monitoring/values.yaml"

# Build base helm arguments
helm_args=(
  --set persistence.type="${STORAGE}"
  --set exposure.type="${MONITORING_LOAD_BALANCER}"
)

# Handle memory configuration based on version
if [[ "$is_4_11_plus" == false ]]; then
  # Pre-4.11: Use yq to modify values file
  yq -i '.resources.requests.memory = "8Gi"' "$monitoring_values_file"
  yq -i '.resources.limits.memory = "8Gi"' "$monitoring_values_file"
else
  # 4.11+: Add memory settings and metric relabel configs to helm args
  helm_args+=(
    --set resources.requests.memory="8Gi"
    --set resources.limits.memory="8Gi"
    --set-json 'cadvisorMetricRelabelConfigs=[{"source_labels":["container"],"regex":"berserker","action":"drop"},{"source_labels":["namespace"],"regex":"berserker-.*","action":"drop"}]'
  )
fi

helm dependency update "${COMMON_DIR}/../charts/monitoring"
envsubst < "$monitoring_values_file" > "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml"
helm upgrade -n stackrox --install --create-namespace stackrox-monitoring "${COMMON_DIR}/../charts/monitoring" --values "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml" "${helm_args[@]}"
rm "${COMMON_DIR}/../charts/monitoring/values_substituted.yaml"

# Pre-4.11 only: Replace prometheus ConfigMap
if [[ "$is_4_11_plus" == false ]]; then
  kubectl -n stackrox delete configmap prometheus
  kubectl create -f "${SCRIPT_DIR}"/prometheus.yaml
fi
