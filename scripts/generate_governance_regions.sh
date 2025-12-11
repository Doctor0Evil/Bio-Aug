#!/usr/bin/env bash
set -euo pipefail

OUT=${1:-build/out/governance_regions.toml}
mkdir -p $(dirname "$OUT")
cat <<EOF > "$OUT"
[regions]
enabled = ["US","EU","UK","JP","CH"]

[adapts]
consent = true
logging = true
encryption = true
data_residency = true
EOF

echo "Governance config written -> $OUT"
exit 0
