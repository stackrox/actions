#!/usr/bin/env bash
#
# Wait for an image to appear on Quay.io
#
set -euo pipefail

NAME_TAG="${1-}"
QUAY_TOKEN="${2-}"

# Seconds:
INTERVAL="${3-30}"
TIME_LIMIT="${4-2400}"

check_not_empty \
    NAME_TAG

IFS=: read -r NAME TAG <<<"$NAME_TAG"

check_not_empty \
    NAME \
    TAG \
    INTERVAL \
    TIME_LIMIT

find_tag() {
    URL="https://quay.io/api/v1/repository/$1/tag?specificTag=$2"
    CURL_PARAMS+=( "--silent" "--show-error" "--fail" "--location" "$URL" )
    if [ -n "$QUAY_TOKEN" ]; then
        >&2 echo "Connecting to Quay with token"
        CURL_PARAMS+=( "-H" "Authorization: Bearer $QUAY_TOKEN" )
    else
        >&2 echo "Connecting to Quay without token"
    fi
    curl "${CURL_PARAMS[@]}" | jq -r ".tags[0].name"
}

# bash built-in variable
SECONDS=0

FOUND_TAG=""
while [ "$SECONDS" -le "$TIME_LIMIT" ]; do
    FOUND_TAG=$(find_tag "$NAME" "$TAG")
    if [ "$FOUND_TAG" = "$TAG" ]; then
        echo "Image '$NAME:$TAG' has been found on Quay.io."
        exit 0
    fi
    if [ "$INTERVAL" -eq 0 ]; then
        break
    fi
    echo "Waiting $INTERVAL more seconds for $NAME:$TAG..."
    sleep "$INTERVAL"
done

gh_log error "Image '$NAME:$TAG' has not been found on Quay.io within the time limit."
exit 1
