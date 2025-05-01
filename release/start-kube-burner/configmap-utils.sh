#!/usr/bin/bash
set -eou pipefail

print_configmap_header() {
  configmap_name=$1
  configmap_namespace=$2

  echo "apiVersion: v1"
  echo "kind: ConfigMap"
  echo "metadata:"
  echo "  name: ${configmap_name}"
  echo "  namespace: ${configmap_namespace}"
  echo "data:"
}

add_file_to_configmap() {
  file=$1
  filename=$2

  first_line="$(head -1 "$file")"
  echo "  ${filename}: |"
  if [ "$first_line" != "---" ]; then
    echo "    ---"
  fi
  sed 's|^|    |' "$file"
}
