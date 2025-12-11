#!/usr/bin/env bash
set -e

ROOT='bioaug-clinical'

# 1) Build ALN CLI and signer (if sources exist) to guarantee tools for linting and signing.
if [ -d "aln-cli" ]; then
  (cd aln-cli && cargo build --release)
fi
if [ -d "tools/signer-rs" ]; then
  (cd tools/signer-rs && cargo build --release)
fi

# 2) Run ALN portable linter + docs gate (gold-standard documentation + spec sanity).
:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ALN_BIN:=$(sh "$SCRIPT_DIR/../../tools/find_aln.sh")}"
./bioaug-clinical/tools/aln_portable_lint.sh --auto-build
./bioaug-clinical/ci/docs_presence_check.sh

# 3) Run neuronano mathematical fidelity checks (invariants, coverage, trace signing).
./bioaug-clinical/scripts/run_neuronano_fidelity_checks.sh

# 4) Run strict guard tests (proptests) for canonical neuronano math/env guards.
./bioaug-clinical/scripts/run_neuronano_guard_tests_strict.sh

# 5) Package Class C neuronano release (WASM + ALN specs + hazard matrices + SBOM stubs + signatures).
# 4a) Guard codegen: generate Rust guard module from math invariants to wire into runtime guards
mkdir -p bioaug-clinical/rust/guard_gen
GUARD_OUT="bioaug-clinical/rust/guard_gen/neuronano_guards.rs"
if [ -f "bioaug-clinical/specs/NanoNeuro-MathInvariants.v1.aln" ]; then
  "$ALN_BIN" GuardCodegen bioaug-clinical/specs/NanoNeuro-MathInvariants.v1.aln --module neuronano_guards --out "$GUARD_OUT" || true
fi
./bioaug-clinical/scripts/package_classc_release.sh

# 6) Optional verification of produced tarball (if verify script exists).
if [ -x "bioaug-clinical/scripts/verify_classc_release.sh" ]; then
  ./bioaug-clinical/scripts/verify_classc_release.sh
fi
