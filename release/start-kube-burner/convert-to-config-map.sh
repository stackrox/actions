#!/usr/bin/bash
set -eou pipefail

input_file=$1
configmap_name=$2
configmap_namespace=$3
filename=${4:-}

DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1091
source "${DIR}"/configmap-utils.sh

print_configmap_header "$configmap_name" "$configmap_namespace"

if [[ -z ${filename:-} ]]; then
  filename=$(basename "$input_file")
fi

add_file_to_configmap "$input_file" "$filename"
