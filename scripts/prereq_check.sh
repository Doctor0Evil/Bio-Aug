#!/usr/bin/env bash
set -euo pipefail
echo "Checking for required tools: cargo, aln-cli, signer-rs"
if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo not found; please install Rust & cargo to run Rust tests"
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ALN_BIN:=$(sh "$SCRIPT_DIR/../../tools/find_aln.sh")}"
if [ ! -x "$ALN_BIN" ]; then
  echo "aln-cli binary not found; you'll need to build it: cd aln-cli && cargo build --release"
fi
if [[ ! -f "tools/signer-rs/target/release/signer-rs" ]]; then
  echo "signer binary not found; build it: cd tools/signer-rs && cargo build --release"
fi
echo "Prereq check complete"
