#!/usr/bin/env bash
set -euo pipefail
cat << 'OUT'
Build modes:
  1) Community-safe:
       cargo build --workspace --release --features "community-default"
  2) Clinical / LE (restricted, approval required):
       cargo build --workspace --release --features "clinical-le"
OUT
