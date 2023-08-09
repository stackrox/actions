#!/usr/bin/env bash
#
# Wait for an image to appear on Quay.io
#
set -euo pipefail

NAME_TAG="$1"
TOKEN="${2-}"

# Seconds:
INTERVAL="${3-30}"
TIME_LIMIT="${4-2400}"

IFS=: read -r NAME TAG <<<"$NAME_TAG"

check_not_empty \
    NAME \
    TAG \
    INTERVAL \
    TIME_LIMIT

find_tag() {
    URL="https://quay.io/api/v1/repository/$1/tag?specificTag=$2"
    {
        if [ -z "$TOKEN" ]; then
            gh_log notice "Connecting to Quay without token"
            curl --silent --show-error --fail --location "$URL"
        else
            gh_log notice "Connecting to Quay with token"
            curl --silent --show-error --fail --location "$URL" \
                -H "Authorization: Bearer $TOKEN"
        fi
    } | jq -r ".tags[0].name"
}

# bash built-in variable
SECONDS=0

FOUND_TAG=""
while [ "$SECONDS" -le "$TIME_LIMIT" ]; do
    FOUND_TAG=$(find_tag "$NAME" "$TAG")
    if [ "$FOUND_TAG" = "$TAG" ]; then
        gh_log notice "Image '$NAME:$TAG' has been found on Quay.io."
        exit 0
    fi
    if [ "$INTERVAL" -eq 0 ]; then
        break
    fi
    echo "Waiting $INTERVAL more seconds for $NAME:$TAG..."
    sleep "$INTERVAL"
done

gh_log error "Image '$NAME:$TAG' has not been found on Quay.io."
exit 1
