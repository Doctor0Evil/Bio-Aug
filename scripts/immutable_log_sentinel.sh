#!/usr/bin/env bash
set -euo pipefail

OUT_CSV=${1:-build/out/forensics_traceability.csv}
OUT_JSON=${2:-build/out/forensics_traceability_signed.json}
ALN_FILE=${3:-policies/forensics.immutable_logs.aln}

echo "Exporting trace for forensic policies from $ALN_FILE"
mkdir -p $(dirname "$OUT_CSV")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ALN_BIN:=$(sh "$SCRIPT_DIR/../tools/find_aln.sh")}"
"$ALN_BIN" trace-export "$ALN_FILE" --out "$OUT_CSV"
echo "Signing trace CSV -> $OUT_JSON"
./scripts/trace_sign.sh "$OUT_CSV" "$OUT_JSON" clinical-class-c
echo "Forensics trace export & sign done: $OUT_JSON"
exit 0
