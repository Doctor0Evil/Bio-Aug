#!/usr/bin/env bash
set -e
# Validate core and neuromorphic datasets + safety metric policies under BioAugClinical.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ALN_BIN:=$(sh "$SCRIPT_DIR/../../tools/find_aln.sh")}"

"$ALN_BIN" validate --profile bioaug-clinical --require-dpia --require-dos-guard
"$ALN_BIN" semantics run --workspace bioaug-clinical --profile BioAugClinical --fail-on-error || true

# Check coverage including new nanotransducer hazards.
"$ALN_BIN" coverage check --workspace bioaug-clinical --profile BioAugClinical \
  --out-csv bioaug-clinical/build/out/hazard_control_matrix_core_nanoneuro.csv \
  --out-json bioaug-clinical/build/out/hazard_coverage_proof_core_nanoneuro.json || true

# Export and sign trace if available.
if [ -x "bioaug-clinical/scripts/trace_sign.sh" ]; then
  bioaug-clinical/scripts/trace_sign.sh bioaug-clinical/build/out/hazard_control_matrix_core_nanoneuro.csv
fi
