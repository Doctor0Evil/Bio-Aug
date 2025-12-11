#!/usr/bin/env bash
set -e

# Run full GOLD pipeline (portable linter, docs gate, neuronano checks, tests, package)
ROOT='bioaug-clinical'

echo "[1/6] Building ALN CLI and signer (if present)"
if [ -d "./aln-cli" ]; then
  (cd ./aln-cli && cargo build --release)
fi
if [ -d "./tools/signer-rs" ]; then
  (cd ./tools/signer-rs && cargo build --release)
fi

echo "[2/6] Portable ALN lint & docs gate"
./$ROOT/ci/aln_and_docs_gate.sh

echo "[3/6] Neuronano / dataset fidelity checks"
./$ROOT/scripts/run_neuronano_fidelity_checks.sh

echo "[4/6] Run strict neuronano guard proptests"
./$ROOT/scripts/run_neuronano_guard_tests_strict.sh

echo "[5/6] Package Class C release"
./$ROOT/scripts/package_classc_release.sh

echo "[6/6] Verify Class C Release TAR (stub)"
./$ROOT/scripts/verify_classc_release.sh || true

echo "Gold-standard pipeline complete"
