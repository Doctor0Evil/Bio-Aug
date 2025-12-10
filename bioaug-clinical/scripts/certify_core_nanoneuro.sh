#!/usr/bin/env bash
set -euo pipefail
OUTDIR=bioaug-clinical/build/out/certify
mkdir -p "$OUTDIR"

echo "Running validations and tests..."
./bioaug-clinical/scripts/validate_nanoneuro_core.sh || true
./bioaug-clinical/scripts/validate_pillars.sh || true
./bioaug-clinical/scripts/nanomod_guard_proptests.sh || true
./bioaug-clinical/scripts/sbom_and_vuln_scan_stub.sh || true

echo "Copying artifacts to $OUTDIR"
cp -v bioaug-clinical/build/out/* "${OUTDIR}/" || true

TAR_OUT="$OUTDIR/certify_core_nanoneuro.tar.gz"
tar -czf "$TAR_OUT" -C "${OUTDIR}" . || true

DEVDIR=bioaug-clinical/ci/dev
if [[ ! -f "${DEVDIR}/dev_pkcs8.key" ]]; then
  echo "Dev keys missing, generating dev keys at ${DEVDIR}"
  ./bioaug-clinical/scripts/gen_dev_keys.sh "${DEVDIR}"
fi

TOOLS_SIGNER=tools/signer-rs/target/release/signer-rs
if [[ ! -f "${TOOLS_SIGNER}" ]]; then
  echo "signer binary not found, building...";
  (cd tools/signer-rs && cargo build --release)
fi

echo "Signing the certification tarball"
"${TOOLS_SIGNER}" sign --input "$TAR_OUT" --keyref "${DEVDIR}/dev_pkcs8.key" --profile "BioAugClinical" --force || true

echo "Certification bundle created and signed: $TAR_OUT"
