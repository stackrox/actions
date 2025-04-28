#!/usr/bin/env bash

DIR="$(cd "$(dirname "$0")" && pwd)"

# TODO(ROX-28948): When all versions using the cluster-density directory
# are out of support, remove it here
#kube_burner_load_dir="${KUBE_BURNER_CONFIG_DIR}/berserker-load"
#if [ ! -d "$kube_burner_load_dir" ]; then
#  kube_burner_load_dir="${KUBE_BURNER_CONFIG_DIR}/cluster-density"
#fi

KUBE_BURNER_CONFIG_DIR_BASE="$(dirname "$KUBE_BURNER_CONFIG_DIR")"

dockerconfigjson="$(kubectl -n stackrox get secret stackrox -o yaml | grep dockerconfigjson | head -1 | awk '{print $2}')"
secret_template="${KUBE_BURNER_CONFIG_DIR_BASE}/secret_template.yml"
secret_file="${KUBE_BURNER_CONFIG_DIR}/secret.yml"

#gh_log notice "Patching $secret_template"
sed "s|__DOCKERCONFIGJSON__|$dockerconfigjson|" "$secret_template" > "$secret_file" 

kube_burner_config_map="${KUBE_BURNER_CONFIG_DIR_BASE}/kube-burner-config.yml"
"${DIR}"/combine-configs.sh "$KUBE_BURNER_CONFIG_DIR" kube-burner-config kube-burner > "$kube_burner_config_map"

kubectl create ns kube-burner

kubectl create -f "${DIR}"/service-account.yaml
kubectl create -f "${DIR}"/cluster-role-binding.yaml
kubectl create -f "$kube_burner_config_map"
kubectl create -f "${DIR}"/metrics-full-config.yml

kubectl create secret generic kube-burner-secret \
    --from-literal=ELASTICSEARCH_URL=$ELASTICSEARCH_URL \
    --from-literal=TEST_NAME=$INFRA_NAME \
    --namespace=kube-burner

kubectl create -f "${DIR}"/kube-burner.yaml
