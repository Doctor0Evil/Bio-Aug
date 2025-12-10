#!/usr/bin/env bash
set -e
# Run proptests/unit tests for neuronano_math_guards via bioaug-guards crate if wired.
if [ -d "bioaug-clinical/rust/bioaug-guards" ]; then
  cd bioaug-clinical/rust/bioaug-guards
  cargo test --tests -- --test-threads=1
fi
