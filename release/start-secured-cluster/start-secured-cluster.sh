#!/usr/bin/env bash
set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Extract version from MAIN_IMAGE_TAG (e.g., "4.11.0-rc.2" -> "4.11")
version_major_minor=$(echo "${MAIN_IMAGE_TAG}" | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')
version_major=$(echo "${version_major_minor}" | cut -d. -f1)
version_minor=$(echo "${version_major_minor}" | cut -d. -f2)

is_4_11_plus=false
if [[ "$version_major" -gt 4 ]] || [[ "$version_major" -eq 4 && "$version_minor" -ge 11 ]]; then
  gh_log notice "Using ACS 4.11+ secured cluster setup (version: ${version_major_minor})"
  is_4_11_plus=true
else
  gh_log notice "Using ACS pre-4.11 secured cluster setup (version: ${version_major_minor})"
fi

gh_log notice "Deploying secured cluster with roxie..."
roxie deploy secured-cluster \
    --verbose \
    --tag "$MAIN_IMAGE_TAG" \
    --config "${SCRIPT_DIR}/roxie-config.yaml" \
    --set "securedCluster.spec.centralEndpoint=${CENTRAL_IP}:443" \
    --set "securedCluster.spec.clusterName=${CLUSTER}" \
    --early-readiness

kubectl -n stackrox create secret generic access-rhacs \
    --from-literal="username=${ROX_ADMIN_USERNAME}" \
    --from-literal="password=${ROX_ADMIN_PASSWORD}" \
    --from-literal="central_url=${CLUSTER_API_ENDPOINT}"

kubectl create -f "${SCRIPT_DIR}/collector-config.yaml"

if [[ "${MONITORING_SUPPORT:-}" == "true" ]]; then
    gh_log notice "Deploying monitoring stack..."
    monitoring_values="$(mktemp)"
    monitoring_chart="${STACKROX_DIR}/deploy/charts/monitoring"

    helm_args=(
        --set persistence.type=pvc
        --set exposure.type=none
        --set resources.requests.memory="8Gi"
        --set resources.limits.memory="8Gi"
    )

    if [[ "$is_4_11_plus" == true ]]; then
        helm_args+=(
            --set-json 'cadvisorMetricRelabelConfigs=[{"source_labels":["container"],"regex":"berserker","action":"drop"},{"source_labels":["namespace"],"regex":"berserker-.*","action":"drop"}]'
        )
    fi

    envsubst < "${monitoring_chart}/values.yaml" > "$monitoring_values"
    helm dependency update "$monitoring_chart"
    helm upgrade -n stackrox --install --create-namespace stackrox-monitoring \
        "$monitoring_chart" --values "$monitoring_values" "${helm_args[@]}"
    rm -f "$monitoring_values"

    if [[ "$is_4_11_plus" == false ]]; then
        kubectl apply -f "${SCRIPT_DIR}/prometheus.yaml"
    fi
fi
