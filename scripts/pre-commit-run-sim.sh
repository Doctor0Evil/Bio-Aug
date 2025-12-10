#!/usr/bin/env bash
set -euo pipefail
# Run a minimal sim scenario for changed policy bundles

for f in $(git diff --name-only origin/main...HEAD | grep -E '^policy_bundles/.*\.yaml' || true); do
  echo "Changed policy bundle: $f";
  # Build sim runner if not present
  if [[ ! -x "sim/runner/target/release/sim-runner" ]]; then
    (cd sim/runner && cargo build --release)
  fi
  # Run the sim runner for one small scenario to sanity-check guard
  sim/runner/target/release/sim-runner sim/scenarios/policy_bypass_attempt.json --policies policy_bundles || exit 1
done

echo "Pre-commit sim check passed."; exit 0
