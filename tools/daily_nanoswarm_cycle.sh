#!/usr/bin/env bash
set -euo pipefail

DATE_TAG="$(date -u +%Y%m%d)"
BRANCH_NAME="research/nanoswarm-${DATE_TAG}"

echo "[nanoswarm] starting nanoswarm daily cycle: ${DATE_TAG}"

mkdir -p aln-reference/nanoswarm
ALN_FILE="aln-reference/nanoswarm/AU.BioAug.NanoswarmWrite.v1.${DATE_TAG}.aln"
cp aln-reference/nanoswarm/AU.BioAug.NanoswarmWrite.v1.aln "${ALN_FILE}"

# Generate guards into the crate's src/generated dir
CRATE_DIR="crates/nanoswarm-write-api"
GEN_DIR="${CRATE_DIR}/src/generated"
mkdir -p "${GEN_DIR}"
GUARDS_RS="${GEN_DIR}/nanoswarm_write_${DATE_TAG}_guards.rs"

ALN_BIN="${ALN_BIN:-$(./tools/find_aln.sh || echo 'aln-cli')}"

"${ALN_BIN}" GuardCodegen \
  "${ALN_FILE}" \
  --module "nanoswarm_write_${DATE_TAG}_guards" \
  --out "${GUARDS_RS}"

# Wire a generated mod.rs so the crate includes generated code
cat > "${GEN_DIR}/mod.rs" << RS_EOF
include!("nanoswarm_write_${DATE_TAG}_guards.rs");
RS_EOF

# Update crate lib to include generated
cat > "${CRATE_DIR}/src/lib.rs" << RS_EOF
pub mod domain;
pub mod service;
pub mod telemetry;

pub use domain::models::NanoswarmWrite;
pub use domain::guards as guards;
RS_EOF

# Run local build/test (if tools/cargo exists on this machine)
if command -v cargo >/dev/null 2>&1; then
  (cd "${CRATE_DIR}" && cargo test)
fi

echo "[nanoswarm] cycle complete"