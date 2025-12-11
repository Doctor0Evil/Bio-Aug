#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALN_BIN="${ALN_BIN:-$(sh "$SCRIPT_DIR/../tools/find_aln.sh" 2>/dev/null || true)}"
if [ -z "$ALN_BIN" ]; then
  ALN_BIN='./target/release/aln'
  if [ ! -x "$ALN_BIN" ]; then ALN_BIN='./aln-cli/target/release/aln'; fi
  if [ ! -x "$ALN_BIN" ]; then ALN_BIN='aln'; fi
fi
echo "[regenerate] biomech guards..."
(cd "aln-reference/biomech-augmentation" && ./generate_guard.sh)
echo "[regenerate] anti-riot guards (if present)..."
if [ -f "aln-reference/anti-riot/AU.BioAug.AntiRiot.v1.aln" ]; then
  mkdir -p generated/anti_riot
  "$ALN_BIN" GuardCodegen aln-reference/anti-riot/AU.BioAug.AntiRiot.v1.aln --module bioaug_anti_riot_guards --out generated/anti_riot/bioaug_anti_riot_guards.rs
fi
echo "[regenerate] done."
#!/usr/bin/env bash
set -euo pipefail

ALN_BIN="${ALN_BIN:-$(./tools/find_aln.sh)}"

echo "[regenerate] biomech guards..."
(
  cd aln-reference/biomech-augmentation
  ./generate_guard.sh
)

echo "[regenerate] anti-riot guards (if present)..."
if [ -f "aln-reference/anti-riot/AU.BioAug.AntiRiot.v1.aln" ]; then
  "$ALN_BIN" GuardCodegen \
    aln-reference/anti-riot/AU.BioAug.AntiRiot.v1.aln \
    --module bioaug_anti_riot_guards \
    --out generated/anti_riot/bioaug_anti_riot_guards.rs
fi

echo "[regenerate] done."
