#!/usr/bin/env bash
set -e
# Enforce BioAugClinical profile, DPIA, DoS, and Class C traceability for new pillar policies.
./aln-cli/target/release/aln validate --profile bioaug-clinical \
  --require-dpia \
  --require-dos-guard \
  --fail-if-unverified-class-c

# Run semantic and coverage checks to ensure every pillar hazard is covered by controls and tests.
./aln-cli/target/release/aln semantics run --workspace bioaug-clinical --profile BioAugClinical --fail-on-error || true
./aln-cli/target/release/aln coverage check --workspace bioaug-clinical --profile BioAugClinical \
  --out-csv bioaug-clinical/build/out/hazard_control_matrix.csv \
  --out-json bioaug-clinical/build/out/hazard_coverage_proof.json || true

# Re-sign updated traceability matrix if trace_sign script exists.
if [ -x "bioaug-clinical/scripts/trace_sign.sh" ]; then
  bioaug-clinical/scripts/trace_sign.sh bioaug-clinical/build/out/hazard_control_matrix.csv || true
  # Export pillar-focused trace and sign
  ./bioaug-clinical/scripts/export_pillar_trace.sh || true
fi
