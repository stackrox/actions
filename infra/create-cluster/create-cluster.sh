#!/usr/bin/env bash
#
# Creates a cluster on infra.
#

set -euo pipefail

FLAVOR="$1"
NAME="$2"
LIFESPAN="$3"
WAIT="$4"

if [ "$#" -gt 4 ]; then
    ARGS="$5"
else
    ARGS=""
fi

check_not_empty \
    FLAVOR NAME LIFESPAN WAIT \
    INFRA_TOKEN

CNAME="${NAME//./-}"

function cluster_info() {
    local check_out=""
    local tries=5
    local count=0
    until check_out="$(infractl 2>/dev/null get "$1" --json -e infra.stackrox.com)"; do
        exit=$?
        if [[ "${check_out}" =~ NotFound ]]; then
            # A missing cluster
            echo "${check_out}"
            return "${exit}"
        else
            # Other errors can be temporary networking issues and retried
            wait=$((2 ** count))
            count=$((count + 1))
            if [[ $count -lt $tries ]]; then
                sleep "${wait}"
            else
                # Reached the end of retries
                echo "${check_out}"
                return "${exit}"
            fi
        fi
    done
    echo "${check_out}"
    return 0
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

IFS=',' read -ra args <<<"$ARGS"
for arg in "${args[@]}"; do
    OPTIONS+=("--arg")
    OPTIONS+=("$arg")
done

retry 5 true infractl create "$FLAVOR" "$CNAME" \
    --lifespan "$LIFESPAN" \
    -e infra.stackrox.com \
    "${OPTIONS[@]}"

infra_status_summary "$CNAME" "Cluster creation has been requested"
