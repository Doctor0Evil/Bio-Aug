#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALN_BIN="${ALN_BIN:-$(sh "$SCRIPT_DIR/../../tools/find_aln.sh" 2>/dev/null || true)}"
if [ -z "$ALN_BIN" ]; then
	ALN_BIN='./target/release/aln'
	if [ ! -x "$ALN_BIN" ]; then ALN_BIN='./aln-cli/target/release/aln'; fi
	if [ ! -x "$ALN_BIN" ]; then ALN_BIN='aln'; fi
fi

mkdir -p ../../../generated/biomech
"$ALN_BIN" GuardCodegen "$SCRIPT_DIR/AU.BioAug.BiomechGuards.v1.aln" --module bioaug_biomech_guards --out ../../../generated/biomech/bioaug_biomech_guards.rs

# Copy into biomech-guards crate for dev convenience
mkdir -p ../../../biomech-guards/generated
cp ../../../generated/biomech/bioaug_biomech_guards.rs ../../../biomech-guards/generated/bioaug_biomech_guards.rs || true

echo "Generated guard module: ../../../generated/biomech/bioaug_biomech_guards.rs"
