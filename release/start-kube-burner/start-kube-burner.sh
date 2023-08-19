#!/usr/bin/env bash
#
# Starts kube-burner which generates load for collector and scanner
#
# When running locally first have a kubeconfig file and set the following environment variables
#
# export KUBECONFIG=<kubeconfig file>
# export STACKROX_DIR=<stackrox directory>

set -euo pipefail

make -C "$BENCHMARK_OPERATOR_DIR" deploy

node_name="$(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}')"
kube_burner_cr="$KUBE_BURNER_CONFIG_DIR"/kube-burner-cr.yml
kube_burner_cr_gen="$KUBE_BURNER_CONFIG_DIR"/kube-burner-cr-gen.yml
sed "s|__NODE_NAME__|$node_name|" "$kube_burner_cr" > "$kube_burner_cr_gen"

dockerconfigjson="$(kubectl -n stackrox get secret stackrox -o yaml | grep dockerconfigjson | head -1 | awk '{print $2}')"
secret_template="$KUBE_BURNER_CONFIG_DIR"/secret_template.yml
secret_file="$KUBE_BURNER_CONFIG_DIR"/cluster-density/secret.yml
sed "s|__DOCKERCONFIGJSON__|$dockerconfigjson|" "$secret_template" > "$secret_file" 

kubectl create configmap --from-file="$KUBE_BURNER_CONFIG_DIR/cluster-density" kube-burner-config -n benchmark-operator

kubectl create -f "$kube_burner_cr_gen"
