#!/usr/bin/env bash
set -euo pipefail
mkdir -p bioaug-clinical/build/out
cat <<EOF > bioaug-clinical/build/out/wcet_memory.json
{"wcet":"bounded_placeholder","memory":"bounded_placeholder"}
EOF
echo "wcet/memory stub written to bioaug-clinical/build/out/wcet_memory.json"
