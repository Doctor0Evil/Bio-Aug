#!/usr/bin/env bash
set -euo pipefail
ROOT=bioaug-clinical
DEVDIR="$ROOT/ci/dev"
mkdir -p "$DEVDIR"
TOOLS_SIGNER=tools/signer-rs/target/release/signer-rs
if [[ ! -f "$TOOLS_SIGNER" ]]; then
  echo "signer binary not found, building...";
  (cd tools/signer-rs && cargo build --release)
fi
if [[ ! -f "$DEVDIR/dev_pkcs8.key" ]]; then
  echo "Generating dev keys...";
  ./bioaug-clinical/scripts/gen_dev_keys.sh "$DEVDIR"
fi
for f in $ROOT/policies/*.aln; do
  echo "Signing $f with clinical profile";
  "$TOOLS_SIGNER" sign --input "$f" --keyref "$DEVDIR/dev_pkcs8.key" --profile CLINICAL_POLICY --force
  echo "Signing $f with security profile";
  "$TOOLS_SIGNER" sign --input "$f" --keyref "$DEVDIR/dev_pkcs8.key" --profile SECURITY_POLICY --force
done
echo "All policies signed with CLINICAL_POLICY and SECURITY_POLICY"
exit 0
exit 0
