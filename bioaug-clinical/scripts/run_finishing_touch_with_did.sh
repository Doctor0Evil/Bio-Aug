#!/usr/bin/env bash
set -e

OUT_DIR="bioaug-clinical/build/out"
ROOT='bioaug-clinical'

# 1) Build ALN CLI and signer if sources exist (ensures tools for lint/sign).
if [ -d "aln-cli" ]; then
  (cd aln-cli && cargo build --release)
fi
if [ -d "tools/signer-rs" ]; then
  (cd tools/signer-rs && cargo build --release)
fi

# 2) ALN + docs gates (auto-build linter).
./$ROOT/tools/aln_portable_lint.sh --auto-build
./$ROOT/ci/docs_presence_check.sh

# 3) Neuronano fidelity + strict guards.
./$ROOT/scripts/run_neuronano_fidelity_checks.sh
./$ROOT/scripts/run_neuronano_guard_tests_strict.sh

# 4) Package Class C release (WASM + specs + matrices + SBOM meta).
./$ROOT/scripts/package_classc_release.sh

# 5) Optional verify step.
if [ -x "$ROOT/scripts/verify_classc_release.sh" ]; then
  $ROOT/scripts/verify_classc_release.sh
fi

# 6) Generate tokenless DID for the Class C tarball (alternative to GitHub secrets).
TARBALL="$OUT_DIR/bioaug_classc_neuronano_release.tar.gz"
if [ -f "$TARBALL" ]; then
  ./bioaug-clinical/scripts/gen_tokenless_did.sh "$TARBALL"
fi
