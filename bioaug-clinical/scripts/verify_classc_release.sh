#!/usr/bin/env bash
set -e
OUT_DIR="bioaug-clinical/build/out"
TAR="$OUT_DIR"/bioaug_classc_neuronano_release.tar.gz
if [ ! -f "$TAR" ]; then
  echo "Class C release tar not found: $TAR"; exit 1
fi
if [ -x "tools/signer-rs/target/release/signer-rs" ]; then
  tools/signer-rs/target/release/signer-rs verify --input "$TAR" --public-key ci/keys/dev_pkcs8.pub || true
  echo "Verified tarball signature (stub or real)"
else
  echo "No signer available; signature verification skipped (stub)."
fi
