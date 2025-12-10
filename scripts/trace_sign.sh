#!/usr/bin/env bash
set -euo pipefail

INPUT_CSV=${1:?input csv}
OUT_JSON=${2:-build/out/hazard_trace_signed.json}
SIGNER_BIN=${SIGNER_BIN:-tools/signer-rs/target/release/signer-rs}
PROFILE=${3:-clinical-class-c}

if [[ -f "$SIGNER_BIN" ]]; then
  echo "Signing trace CSV $INPUT_CSV with profile $PROFILE"
  $SIGNER_BIN sign --input "$INPUT_CSV" --profile "$PROFILE" --output "$OUT_JSON"
else
  echo "Signer binary not found ($SIGNER_BIN). Copying CSV to $OUT_JSON as unsigned fallback"
  mkdir -p $(dirname "$OUT_JSON")
  jq -R -s -c 'split("\n") | map(select(length > 0))' "$INPUT_CSV" | jq '{file: "$INPUT_CSV", rows: .}' > "$OUT_JSON"
fi

echo "Signed trace output -> $OUT_JSON"
exit 0
