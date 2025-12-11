#!/usr/bin/env bash
set -euo pipefail

ALN="bioaug-clinical/policies/ai.chat.dos_guard.aln"
OUT_CSV="bioaug-clinical/build/out/hazard_control_matrix.csv"
OUT_PROOF="bioaug-clinical/build/out/hazard_coverage_proof.json"
mkdir -p $(dirname "$OUT_CSV")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ALN_BIN:=$(sh "$SCRIPT_DIR/../../tools/find_aln.sh")}"
"$ALN_BIN" check-coverage "$ALN" --out-csv "$OUT_CSV" --out-proof "$OUT_PROOF"
./scripts/trace_sign.sh "$OUT_CSV"

echo "Coverage and sign complete" 
