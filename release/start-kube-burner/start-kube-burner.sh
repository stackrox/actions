#!/usr/bin/env bash
#
# Starts kube-burner which generates load for collector and scanner
#
# When running locally first have a kubeconfig file and set the following environment variables
#
# export KUBECONFIG=<kubeconfig file>
# export STACKROX_DIR=<stackrox directory>

set -euox pipefail

make -C "$BENCHMARK_OPERATOR_DIR" deploy

kube_burner_config_dir="$STACKROX_DIR"/scripts/release-tools/kube-burner-configs

kubectl create configmap --from-file="$kube_burner_config_dir/cluster-density" kube-burner-config -n benchmark-operator

node_name="$(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}')"
kube_burner_cr="$kube_burner_config_dir"/kube-burner-cr.yml
kube_burner_cr_gen="$kube_burner_config_dir"/kube-burner-cr-gen.yml
sed "s|__NODE_NAME__|$node_name|" "$kube_burner_cr" > "$kube_burner_cr_gen"

dockerconfigjson="$(kubectl -n stackrox get secret stackrox -o yaml | grep dockerconfigjson | head -1 | awk '{print $2}')"
secret_template="$kube_burner_config_dir"/secret_template.yml
secret_file="$kube_burner_config_dir"/cluster-density/secret.yml
sed "s|__DOCKERCONFIGJSON__|$dockerconfigjson|" "$secret_template" > "$secret_file" 

kubectl create -f "$kube_burner_cr_gen"
