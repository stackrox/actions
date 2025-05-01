#!/usr/bin/bash
set -eou pipefail

input_dir=$1
configmap_name=$2
configmap_namespace=$3

DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1091
source "${DIR}"/configmap-utils.sh

print_configmap_header "$configmap_name" "$configmap_namespace"

mapfile -t files < <(ls "${input_dir}"/*.y*ml)

for file in "${files[@]}"; do
  filename=$(basename "$file")
  add_file_to_configmap "$file" "$filename"
done
