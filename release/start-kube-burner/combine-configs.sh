#!/usr/bin/bash
set -eou pipefail

input_dir=$1
configmap_name=$2
configmap_namespace=$3

echo "apiVersion: v1"
echo "kind: ConfigMap"
echo "metadata:"
echo "  name: ${configmap_name}"
echo "  namespace: ${configmap_namespace}"
echo "data:"

mapfile -t files < <(ls "${input_dir}"/*.y*ml)

for file in "${files[@]}"; do
	filename=$(basename "$file")
	first_line="$(head -1 "$file")"
	echo "  ${filename}: |"
	if [ "$first_line" != "---" ]; then
		echo "    ---"
	fi
	sed 's|^|    |' "$file"
done
