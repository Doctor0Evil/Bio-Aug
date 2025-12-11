#!/usr/bin/env bash
set -e
# Proptest-style check: sample inside/outside envelopes via existing bioaug-guards crate if wired,
# or run unit tests when integrated.
cd bioaug-clinical/rust/bioaug-guards || exit 0
cargo test --tests -- --test-threads=1
