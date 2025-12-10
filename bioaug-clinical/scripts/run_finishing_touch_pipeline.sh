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
./bioaug-clinical/tools/aln_portable_lint.sh --auto-build
./bioaug-clinical/ci/docs_presence_check.sh

# 3) Run neuronano mathematical fidelity checks (invariants, coverage, trace signing).
./bioaug-clinical/scripts/run_neuronano_fidelity_checks.sh

# 4) Run strict guard tests (proptests) for canonical neuronano math/env guards.
./bioaug-clinical/scripts/run_neuronano_guard_tests_strict.sh

# 5) Package Class C neuronano release (WASM + ALN specs + hazard matrices + SBOM stubs + signatures).
./bioaug-clinical/scripts/package_classc_release.sh

# 6) Optional verification of produced tarball (if verify script exists).
if [ -x "bioaug-clinical/scripts/verify_classc_release.sh" ]; then
  ./bioaug-clinical/scripts/verify_classc_release.sh
fi
