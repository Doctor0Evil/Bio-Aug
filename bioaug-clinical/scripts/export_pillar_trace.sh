#!/usr/bin/env bash
set -e
mkdir -p bioaug-clinical/build/out
aln trace export \
  --workspace bioaug-clinical \
  --profile BioAugClinical \
  --filter 'hazard_id~HAZ-NANO|HAZ-NANOBMI|HAZ-NEUROMORPHIC|HAZ-CITY-NEURO-GOV|HAZ-NEURORIGHTS' \
  --out-csv bioaug-clinical/build/out/hazard_control_matrix_pillars.csv \
  --out-graph bioaug-clinical/build/out/hazard_trace_pillars.graphml || true

if [ -x "bioaug-clinical/scripts/trace_sign.sh" ]; then
  bioaug-clinical/scripts/trace_sign.sh bioaug-clinical/build/out/hazard_control_matrix_pillars.csv || true
fi
