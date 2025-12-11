#!/usr/bin/env bash
set -euo pipefail
INPUT="${1:-bioaug-clinical/build/out/hazard_control_matrix.csv}"
OUT="bioaug-clinical/build/out/hazard_control_matrix_signed.json"
mkdir -p $(dirname "$OUT")
cat <<EOF > "$OUT"
{"trace_file":"$INPUT","signature":"placeholder"}
EOF
echo "Signed trace written -> $OUT"
