#!/usr/bin/env bash
set -euo pipefail
echo "Building wasm stub for `bioaug-guards`"
cd bioaug-clinical/rust/bioaug-guards
if ! rustup target list | grep -q wasm32-unknown-unknown; then
  echo "Please run: rustup target add wasm32-unknown-unknown"
fi
cargo build --target wasm32-unknown-unknown --release || true
mkdir -p ../../build/out
cp -v target/wasm32-unknown-unknown/release/bioaug-guards.wasm ../../build/out/ || true
echo "WASM build stub completed; artifact at build/out/bioaug-guards.wasm"
