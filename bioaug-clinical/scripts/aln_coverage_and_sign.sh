#!/usr/bin/env bash
set -euo pipefail

ALN="bioaug-clinical/policies/ai.chat.dos_guard.aln"
OUT_CSV="bioaug-clinical/build/out/hazard_control_matrix.csv"
OUT_PROOF="bioaug-clinical/build/out/hazard_coverage_proof.json"
mkdir -p $(dirname "$OUT_CSV")
./aln-cli/target/release/aln check-coverage "$ALN" --out-csv "$OUT_CSV" --out-proof "$OUT_PROOF"
./bioaug-clinical/scripts/trace_sign.sh "$OUT_CSV"

echo "Coverage and sign complete" 
