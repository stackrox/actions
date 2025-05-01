#!/usr/bin/env bash

DIR="$(cd "$(dirname "$0")" && pwd)"

KUBE_BURNER_CONFIG_DIR_BASE="$(dirname "$KUBE_BURNER_CONFIG_DIR")"

# TODO(ROX-28948): When all versions using the cluster-density directory
# are out of support, remove it from here
if [ ! -d "$KUBE_BURNER_CONFIG_DIR" ]; then
  KUBE_BURNER_CONFIG_DIR="${KUBE_BURNER_CONFIG_DIR_BASE}/cluster-density"
fi

dockerconfigjson="$(kubectl -n stackrox get secret stackrox -o yaml | grep dockerconfigjson | head -1 | awk '{print $2}')"
secret_template="${KUBE_BURNER_CONFIG_DIR_BASE}/secret_template.yml"
secret_file="${KUBE_BURNER_CONFIG_DIR}/secret.yml"

gh_log notice "Patching $secret_template"
sed "s|__DOCKERCONFIGJSON__|$dockerconfigjson|" "$secret_template" > "$secret_file" 

kubectl create ns kube-burner

kubectl create configmap --from-file="$KUBE_BURNER_CONFIG_DIR" kube-burner-config -n kube-burner

temp_metrics_file="${DIR}"/metrics.yml
cp "${KUBE_BURNER_METRICS_FILE}" "$temp_metrics_file"
kubectl create configmap --from-file="$temp_metrics_file" kube-burner-metrics-config -n kube-burner

kubectl create configmap --from-file="$KUBE_BURNER_METRICS_FILE" kube-burner-metrics-config -n kube-burner

kubectl create -f "${DIR}"/service-account.yaml
kubectl create -f "${DIR}"/cluster-role-binding.yaml

uuid="${INFRA_NAME}-$(date +%s)"
gh_log notice "Setting uuid to $uuid"

kubectl create secret generic kube-burner-secret \
    --from-literal=ELASTICSEARCH_URL="$ELASTICSEARCH_URL" \
    --from-literal=UUID="$uuid" \
    --from-literal=METRICS_COLLECTION_TIME="$METRICS_COLLECTION_TIME" \
    --from-literal=METRICS_TIME_STEP="5m" \
    --namespace=kube-burner

kubectl create -f "${DIR}"/kube-burner.yaml
