#!/usr/bin/env bash
#
# Starts a secured cluster
#
# When running locally you need to have a kubeconfig file and set the following environment variables
#
# export SECURED_CLUSTER_NAME=<secured cluster name>
# export TAG=<tag>
# export KUBECONFIG=/tmp/${SECURED_CLUSTER_NAME}/kubeconfig
# export CENTRAL_IP=<cluster ip> # Get this from when central is created
# export ROX_ADMIN_PASSWORD=<rox admin password> # Get this from when central is created
# export STACKROX_DIR=/home/jvirtane/go/src/github.com/stackrox/stackrox

set -euox pipefail

pushd "$STACKROX_DIR"

export CLUSTER_API_ENDPOINT=https://"${CENTRAL_IP}":443
export API_ENDPOINT="${CENTRAL_IP}":443
export MAIN_IMAGE_TAG=$TAG
export CLUSTER=secured-cluster

"${STACKROX_DIR}"/deploy/k8s/sensor.sh

kubectl -n stackrox create secret generic access-rhacs --from-literal="username=${ROX_ADMIN_USERNAME}" --from-literal="password=${ROX_ADMIN_PASSWORD}" --from-literal="central_url=https://${CENTRAL_IP}":443
