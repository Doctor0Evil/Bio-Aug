#!/usr/bin/env bash
set -e
# Run proptests/unit tests for neuronano_math_guards via bioaug-guards crate if wired.
if [ -d "bioaug-clinical/rust/bioaug-guards" ]; then
  cd bioaug-clinical/rust/bioaug-guards
  cargo test --tests -- --test-threads=1
fi

# If generated guard module exists, run neuronano-guards tests with generated_checks feature
if [ -f "bioaug-clinical/rust/guard_gen/neuronano_guards.rs" ] && [ -d "bioaug-clinical/rust/neuronano-guards" ]; then
  cd bioaug-clinical/rust/neuronano-guards
  cargo test --features generated_checks -- --test-threads=1 || true
fi
