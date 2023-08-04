#!/usr/bin/env bash
#
# Creates clusters
#
# Local wet run:
#
#   DRY_RUN=false test/local-env.sh release/create-clusters <version> "true" "true" "true"
#
set -euo pipefail

VERSION="$1"
SHALL_CREATE_GKE="$2"
SHALL_CREATE_OS="$3"
SHALL_CREATE_LONG="$4"

check_not_empty \
    VERSION \
    SHALL_CREATE_GKE \
    SHALL_CREATE_OS \
    SHALL_CREATE_LONG \
    QUAY_TOKEN \
    DRY_RUN


../wait-for-image/wait-for-image.sh "rhacs-eng/main:${VERSION}" "$QUAY_TOKEN"
../wait-for-image/wait-for-image.sh "rhacs-eng/scanner:${VERSION}" "$QUAY_TOKEN"
../wait-for-image/wait-for-image.sh "rhacs-eng/scanner-db:${VERSION}" "$QUAY_TOKEN"
../wait-for-image/wait-for-image.sh "rhacs-eng/collector:${VERSION}" "$QUAY_TOKEN"

echo "All images are available"

../../infra/create-cluster/create-cluster.sh \
  "qa-demo" \
  "qa-k8s-${VERSION}" \
  "48h" \
  "true" \
  "main-image=quay.io/rhacs-eng/main:${VERSION},central-db-image=quay.io/rhacs-eng/central-db:${VERSION}"

## TODO: notify Slack

../../infra/create-cluster/create-cluster.sh \
  "openshift-4-demo" \
  "openshift-4-demo-${VERSION}" \
  "48h" \
  "true" \
  "central-services-helm-chart-version=${VERSION},secured-cluster-services-helm-chart-version=${VERSION}"

## TODO: notify Slack

../../infra/create-cluster/create-cluster.sh \
  "gke-default" \
  "gke-long-running-${VERSION}" \
  "168h" \
  "true" \
  "nodes=5,machine-type=e2-standard-8"

## TODO: Patch long-running
## TODO: notify Slack
## TODO: Start fake workload

## TODO: Notify slack about potential failures in cluster creation
