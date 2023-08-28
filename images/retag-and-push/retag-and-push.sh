#!/usr/bin/env bash
set -eou pipefail

src_image=$1
dst_image=$2

docker tag "$src_image" "$dst_image"
docker push "$dst_image"
