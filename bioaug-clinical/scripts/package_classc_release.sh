#!/usr/bin/env bash
set -e

OUT_DIR="bioaug-clinical/build/out"
PKG_DIR="bioaug-clinical/build/out/classc_release"
mkdir -p "$PKG_DIR"

# 1) Run all neuronano/cyberneuro checks (math + guards + policies).
./bioaug-clinical/scripts/run_neuronano_fidelity_checks.sh
./bioaug-clinical/scripts/run_neuronano_guard_tests_strict.sh

# 2) Produce WASM artifact (stubbed by existing wasm_build_stub.sh if present).
if [ -x "bioaug-clinical/scripts/wasm_build_stub.sh" ]; then
  ./bioaug-clinical/scripts/wasm_build_stub.sh
fi

# 3) SBOM + vuln/meta (stub; replace with real tools).
if [ -x "bioaug-clinical/scripts/sbom_and_vuln_scan_stub.sh" ]; then
  ./bioaug-clinical/scripts/sbom_and_vuln_scan_stub.sh
fi
if [ -x "bioaug-clinical/scripts/neuronano_security_ci_stub.sh" ]; then
  ./bioaug-clinical/scripts/neuronano_security_ci_stub.sh
fi

# 4) Collect artefacts (ALN specs, hazard matrices, proofs, WASM, security meta).
cp -f bioaug-clinical/specs/*.aln "$PKG_DIR"/ 2>/dev/null || true
cp -f "$OUT_DIR"/hazard_control_matrix_*".csv" "$PKG_DIR"/ 2>/dev/null || true
cp -f "$OUT_DIR"/hazard_coverage_proof_*.json "$PKG_DIR"/ 2>/dev/null || true
cp -f "$OUT_DIR"/*.wasm "$PKG_DIR"/ 2>/dev/null || true
cp -f "$OUT_DIR"/*security*.json "$PKG_DIR"/ 2>/dev/null || true
cp -f "$OUT_DIR"/sbom_vuln_scan.json "$PKG_DIR"/ 2>/dev/null || true

# 5) Tarball the release bundle.
tar -czf "$OUT_DIR"/bioaug_classc_neuronano_release.tar.gz -C "$PKG_DIR" .

# 6) Sign tarball if signer is present (dev key/HSM stub).
if [ -x "tools/signer-rs/target/release/signer-rs" ]; then
  tools/signer-rs/target/release/signer-rs sign \
    --input "$OUT_DIR"/bioaug_classc_neuronano_release.tar.gz \
    --keyref ci/keys/dev_pkcs8.key \
    --profile CLASSC_RELEASE
fi
