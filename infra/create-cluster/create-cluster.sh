#!/usr/bin/env bash
#
# Creates a cluster on infra.
#

set -euxo pipefail

FLAVOR="$1"
NAME="$2"
LIFESPAN="$3"
WAIT="$4"
NO_SLACK="$5"
ENDPOINT="$6"
INSECURE="$7"

if [ "$#" -gt 7 ]; then
    ARGS="$8"
else
    ARGS=""
fi

check_not_empty \
    FLAVOR NAME LIFESPAN WAIT \
    INFRA_TOKEN

ALLOWED_NAMES="^[a-z][a-z0-9-]{1,26}[a-z0-9]$"
CNAME="${NAME//./-}"

if ! [[ "${CNAME}" =~ ${ALLOWED_NAMES} ]]; then
    gh_log error "The cluster name must comply to the regular expression: \"${ALLOWED_NAMES}"\"
    exit 1
fi

function infractl_call() {
    local options=("--endpoint $ENDPOINT")
    if [ "$INSECURE" = "true" ]; then
        options+=("--insecure")
        gh_log notice "Using an insecure connection when connecting to infra endpoint $ENDPOINT."
    fi
    infractl "${options[@]}" $@
}

function cluster_info() {
    infractl_call 2>/dev/null get "$1" --json
}

function cluster_status() {
    cluster_info "$1" | jq -r '.Status'
}

function cluster_destroying() {
    [ "$(cluster_status "$1")" = "DESTROYING" ]
}

function infra_status_summary() {
    gh_summary <<EOF
*$2*
Infra status for '$1':
\`\`\`
$(cluster_info "$1")
\`\`\`

EOF
}

case $(cluster_status "$CNAME") in
"")
    gh_summary "Cluster $CNAME doesn't exist."
    ;;
FAILED)
    # Existing cluster is in failed state, i.e. not active.
    # Don't print the status.
    ;;
CREATING)
    # Don't wait for the cluster being created, as another workflow could be
    # waiting for it.
    # TODO: use concurrency tweak to allow only single workflow running at once.
    infra_status_summary "$CNAME" "Cluster is being created by another workflow"
    exit 0
    ;;
READY)
    # Cluster exists already.
    infra_status_summary "$CNAME" "Cluster already exists"
    exit 0
    ;;
DESTROYING)
    # Cluster is being destroyed.
    infra_status_summary "$CNAME" "Cluster is being destroyed"
    while cluster_destroying "$CNAME"; do
        gh_log notice "Waiting 30s for the cluster '$CNAME' to be destroyed"
        sleep 30
    done
    ;;
FINISHED)
    # Cluster has already been destroyed. Create it again.
    gh_log notice "Cluster \`$CNAME\` has been destroyed already."
    infra_status_summary "$CNAME" "Cluster has been destroyed already"
    ;;
*)
    infra_status_summary "$CNAME" "Unknown status"
    ;;
esac

# Creating a cluster
echo "Will attempt to create the cluster."

OPTIONS=()
if [ "$WAIT" = "true" ]; then
    OPTIONS+=("--wait")
    gh_log warning "The job will wait for the cluster creation to finish."
fi

if [ "$NO_SLACK" = "true" ]; then
    OPTIONS+=("--no-slack")
    gh_log notice "Skipping sending Slack messages for cluster \`$CNAME\`."
fi

IFS=',' read -ra args <<<"$ARGS"
for arg in "${args[@]}"; do
    OPTIONS+=("--arg")
    OPTIONS+=("$arg")
done

infractl_call create "$FLAVOR" "$CNAME" \
    --lifespan "$LIFESPAN" \
    "${OPTIONS[@]}"

infra_status_summary "$CNAME" "Cluster creation has been requested"
