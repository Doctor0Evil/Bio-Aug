#!/usr/bin/env bash
set -euo pipefail

ROOT=${1:-src/embedded}
OUT_JSON=${2:-build/out/rust_classc_checks.json}
mkdir -p $(dirname "$OUT_JSON")

issues=0
for f in $(find "$ROOT" -name "*.rs" -type f); do
  if grep -q "panic!\(" "$f"; then
    echo "Found panic!() in $f"; issues=$((issues+1));
  fi
  if ! grep -q "#!\[no_std\]" "$f"; then
    echo "Missing #![no_std] in $f"; issues=$((issues+1));
  fi
done

if [[ $issues -gt 0 ]]; then
  cat <<EOF > $OUT_JSON
{"status":"fail","issues":$issues}
EOF
  echo "Rust Class C checks failed: $issues issues"; exit 2
else
  cat <<EOF > $OUT_JSON
{"status":"ok","issues":0}
EOF
  echo "Rust Class C checks passed"; exit 0
fi
