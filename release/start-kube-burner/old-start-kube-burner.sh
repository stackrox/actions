#!/usr/bin/env bash
#
# Starts kube-burner which generates load for collector and scanner
#
# When running locally first have a kubeconfig file and set the following environment variables
#
# export KUBECONFIG=<kubeconfig file>
# export KUBE_BURNER_CONFIG_DIR=<kube_burner_config_dir>

set -euo pipefail

gh_log notice "Deploying benchmark operator"
make -C "$BENCHMARK_OPERATOR_DIR" deploy

# TODO(ROX-28948): When all versions using the cluster-density directory
# are out of support, remove it here
kube_burner_load_dir="${KUBE_BURNER_CONFIG_DIR}/berserker-load"
if [ ! -d "$kube_burner_load_dir" ]; then
  kube_burner_load_dir="${KUBE_BURNER_CONFIG_DIR}/cluster-density"
fi

node_name="$(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}')"
kube_burner_cr="$KUBE_BURNER_CONFIG_DIR"/kube-burner-cr.yml
kube_burner_cr_gen="$KUBE_BURNER_CONFIG_DIR"/kube-burner-cr-gen.yml

gh_log notice "Patching $kube_burner_cr"
sed "s|__NODE_NAME__|$node_name|" "$kube_burner_cr" > "$kube_burner_cr_gen"

dockerconfigjson="$(kubectl -n stackrox get secret stackrox -o yaml | grep dockerconfigjson | head -1 | awk '{print $2}')"
secret_template="${KUBE_BURNER_CONFIG_DIR}/secret_template.yml"
secret_file="${kube_burner_load_dir}/secret.yml"

gh_log notice "Patching $secret_template"
sed "s|__DOCKERCONFIGJSON__|$dockerconfigjson|" "$secret_template" > "$secret_file"

kubectl create configmap --from-file="$kube_burner_load_dir" kube-burner-config -n benchmark-operator

kubectl create -f "$kube_burner_cr_gen"
