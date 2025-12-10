#!/usr/bin/env bash
set -e

OUT_DIR="bioaug-clinical/build/out"

# 1) Run full finishing-touch + DID generation (ensures lint auto-build as used by finishing touch).
./bioaug-clinical/scripts/run_finishing_touch_with_did.sh

# 2) Verify DID <-> artifact consistency if artefact and DID doc exist.
TARBALL="$OUT_DIR/bioaug_classc_neuronano_release.tar.gz"
DID_DOC="$TARBALL.did.json"

if [ -f "$TARBALL" ] && [ -f "$DID_DOC" ]; then
  ./bioaug-clinical/scripts/verify_tokenless_did.sh "$TARBALL" "$DID_DOC"
fi
