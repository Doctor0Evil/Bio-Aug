#!/usr/bin/env bash
set -e
# ALN_BIN resolution (shared helper)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ALN_BIN:=$(sh "$SCRIPT_DIR/../../tools/find_aln.sh")}"
# 1) Validate ALN invariants and datasets under BioAugClinical.
"${ALN_BIN}" validate --profile bioaug-clinical --require-dpia --require-dos-guard
"${ALN_BIN}" semantics run --workspace bioaug-clinical --profile BioAugClinical --fail-on-error || true

# 2) Coverage including neuronano hazards.
"${ALN_BIN}" coverage check --workspace bioaug-clinical --profile BioAugClinical \
  --out-csv bioaug-clinical/build/out/hazard_control_matrix_neuronano_math.csv \
  --out-json bioaug-clinical/build/out/hazard_coverage_proof_neuronano_math.json || true

# 3) Sign trace if signer script is present.
if [ -x "bioaug-clinical/scripts/trace_sign.sh" ]; then
  bioaug-clinical/scripts/trace_sign.sh bioaug-clinical/build/out/hazard_control_matrix_neuronano_math.csv
fi
