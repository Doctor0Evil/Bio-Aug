#!/usr/bin/env bash
set -euo pipefail
OUTDIR=${1:-bioaug-clinical/ci/dev}
mkdir -p "$OUTDIR"
TOOLS_SIGNER=tools/signer-rs/target/release/signer-rs
if [[ ! -f "$TOOLS_SIGNER" ]]; then
  echo "signer binary not found, building...";
  (cd tools/signer-rs && cargo build --release)
fi
echo "Generating dev key bundle at $OUTDIR/dev_keys.tar.gz"
"$TOOLS_SIGNER" generate-dev-keys --output "$OUTDIR/dev_keys.tar.gz"
tar -xzf "$OUTDIR/dev_keys.tar.gz" -C "$OUTDIR"
echo "Generated dev keys: $OUTDIR/dev_pkcs8.key, $OUTDIR/dev_pub.key"
exit 0

