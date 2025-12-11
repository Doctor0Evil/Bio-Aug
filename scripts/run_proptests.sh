#!/usr/bin/env bash
set -euo pipefail
cd bioaug-clinical/rust/bioaug-guards
cargo test --features "" -- --test-threads=1
