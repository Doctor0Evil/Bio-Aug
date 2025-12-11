#!/usr/bin/env bash
set -euo pipefail

CRATE=${1:-bioaug-guards}
echo "Running property-based tests for crate: $CRATE (placeholder)"
cargo test -p $CRATE --features 'bioaug_class_c,no_std' -- --test-threads=1 || { echo "Property tests failed or not present for $CRATE"; exit 2; }
echo "Property tests run (check results for failures)."
exit 0
