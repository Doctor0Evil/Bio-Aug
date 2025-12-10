#!/usr/bin/env bash
set -e

aln trace export \
  --workspace "bioaug-clinical" \
  --profile BioAugClinical \
  --filter 'hazard_id~HAZ-NANO|HAZ-NANO-MATH|HAZ-NEURORIGHTS' \
  --out-csv "bioaug-clinical/build/out/hazard_control_matrix_neuronano_math_snapshot.csv" \
  --out-graph "bioaug-clinical/build/out/hazard_trace_neuronano_math_snapshot.graphml" || true

if [ -x "bioaug-clinical/scripts/trace_sign.sh" ]; then
  "bioaug-clinical/scripts/trace_sign.sh" "bioaug-clinical/build/out/hazard_control_matrix_neuronano_math_snapshot.csv"
fi
