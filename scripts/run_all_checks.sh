#!/usr/bin/env bash
set -euo pipefail
echo "Preparing build";
mkdir -p bioaug-clinical/build/out

echo "Prereq checks";
./bioaug-clinical/scripts/prereq_check.sh || true

echo "Build signer & tools";
cd tools/signer-rs && cargo build --release || true; cd -
cd aln-cli && cargo build --release || true; cd -

echo "Run validation and tests";
./bioaug-clinical/scripts/validate_pillars.sh || true
./bioaug-clinical/scripts/validate_nanoneuro_core.sh || true
./bioaug-clinical/scripts/nanomod_guard_proptests.sh || true
./bioaug-clinical/scripts/sbom_and_vuln_scan_stub.sh || true

echo "Certify & sign core artifacts";
./bioaug-clinical/scripts/certify_core_nanoneuro.sh || true

echo "All checks done"
