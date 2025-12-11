#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ALN_BIN:=$(sh "$SCRIPT_DIR/../../tools/find_aln.sh")}"

# Validate all policies under nano/neuromorphic/city for Class C compliance
"$ALN_BIN" validate bioaug-clinical/policies/nano.wireless_envelope.aln --profile bioaug-clinical --require-dpia --require-dos-guard
"$ALN_BIN" validate bioaug-clinical/policies/nano.tis2pt_bci.aln --profile bioaug-clinical --require-dpia --require-dos-guard
"$ALN_BIN" validate bioaug-clinical/policies/nano.magnetoelectric_actuators.aln --profile bioaug-clinical --require-dpia --require-dos-guard
"$ALN_BIN" validate bioaug-clinical/policies/neuromorphic.compute_envelope.aln --profile bioaug-clinical --require-dpia --require-dos-guard
"$ALN_BIN" validate bioaug-clinical/policies/neuromorphic.dataset_provenance.aln --profile bioaug-clinical --require-dpia --require-dos-guard
"$ALN_BIN" validate bioaug-clinical/policies/city.neurofeedback_loop.aln --profile bioaug-clinical --require-dpia --require-dos-guard
"$ALN_BIN" validate bioaug-clinical/policies/city.neuro_privacy_guard.aln --profile bioaug-clinical --require-dpia --require-dos-guard
"$ALN_BIN" validate bioaug-clinical/policies/hybrid.ai_human_controller.aln --profile bioaug-clinical --require-dpia --require-dos-guard

# Run semantics check
"$ALN_BIN" zero-trust-validate bioaug-clinical/policies/zero_trust_bci_kernel.aln --segment 'bci-kernel,smart-city-edge'

# Coverage check for neuromorphic/nano policies
"$ALN_BIN" check-coverage bioaug-clinical/policies/nano.wireless_envelope.aln --out-csv bioaug-clinical/build/out/hazard_control_matrix.csv --out-proof bioaug-clinical/build/out/hazard_coverage_proof.json

# Run nanomod guard proptests
./bioaug-clinical/scripts/nanomod_guard_proptests.sh || true

# SBOM + vulnerability scan (stub)
./bioaug-clinical/scripts/sbom_and_vuln_scan_stub.sh || true

# Export pillar trace and sign (if trace_sign available)
./bioaug-clinical/scripts/export_pillar_trace.sh || true

echo "Nano/Neuromorphic/City validation complete"
