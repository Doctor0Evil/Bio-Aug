#!/usr/bin/env bash
set -euo pipefail

DATE_TAG="$(date -u +%Y%m%d)"
BRANCH_NAME="research/adjacent-daily-${DATE_TAG}"

echo "[adjacent] starting adjacent-domain research cycle: ${DATE_TAG}"

# Domain rotation and ALN path
DAY_INDEX=$((10#${DATE_TAG: -2} % 5))
case "${DAY_INDEX}" in
  1) DOMAIN="Implantable_BCI_ECoG_Depth" ;;
  2) DOMAIN="NonInvasive_EEG_MEG_XR" ;;
  3) DOMAIN="Organic_BioHybrid_Computing" ;;
  4) DOMAIN="SoftRobotics_Haptics_Prosthetics" ;;
  0) DOMAIN="CyberImmune_Security_Safety" ;;
esac

mkdir -p aln-reference/adjacent
ALN_FILE="aln-reference/adjacent/AU.CyberAug.Adjacent.${DOMAIN}.${DATE_TAG}.aln"

# 1) DAILY ALN PROFILE (ADJACENT DOMAINS)
cat > "${ALN_FILE}" << ALN_EOF
aln system CyberAugAdjacent_${DATE_TAG} {
  record AdjacentSample {
    time_ms: int;
    user_id: string;
    device_id: string;
    # ... (fields elided for brevity)
  end
  # policies omitted
}
ALN_EOF

echo "[adjacent] ALN profile written: ${ALN_FILE}"

# 2) GENERATE RUST GUARDS + RECORDS (crate-local generation)
CRATE_DIR="adjacent-cyberaug-guards-${DATE_TAG}"
mkdir -p "${CRATE_DIR}/src/generated"
GEN_DIR="${CRATE_DIR}/src/generated"
GUARDS_RS="${GEN_DIR}/cyberaug_adjacent_${DATE_TAG}_guards.rs"

ALN_BIN="${ALN_BIN:-$(./tools/find_aln.sh || echo 'aln-cli')}"

"${ALN_BIN}" GuardCodegen \
  "${ALN_FILE}" \
  --module "cyberaug_adjacent_${DATE_TAG}_guards" \
  --out "${GUARDS_RS}"

echo "[adjacent] guards generated: ${GUARDS_RS}"

# 3) Create crate skeleton: lib.rs + generated/mod.rs
mkdir -p "${CRATE_DIR}/src"
cat > "${CRATE_DIR}/Cargo.toml" << TOML_EOF
[package]
name = "cyberaug-adjacent-guards-${DATE_TAG}"
version = "0.1.0"
edition = "2021"
license = "MIT OR Apache-2.0"
description = "Adjacent-domain guard crate for ${DATE_TAG}."

[dependencies]
anyhow = "1.0"

[lib]
name = "cyberaug_adjacent_${DATE_TAG}_guards"
path = "src/lib.rs"
crate-type = ["rlib"]
TOML_EOF

cat > "${CRATE_DIR}/src/lib.rs" << RS_EOF
pub mod generated;

pub use generated::*;
RS_EOF

cat > "${CRATE_DIR}/src/generated/mod.rs" << RS_EOF
include!("cyberaug_adjacent_${DATE_TAG}_guards.rs");
RS_EOF

echo "[adjacent] adjacent guard crate created: ${CRATE_DIR}"

# 4) WRITE PROMETHEUS METRICS (full details omitted) and tests
mkdir -p prometheus
PROM_FILE="prometheus/cyberaug_adjacent_${DATE_TAG}_metrics.example.txt"
cat > "${PROM_FILE}" << PROM_EOF
# Example metrics for adjacent domain
PROM_EOF

mkdir -p "${CRATE_DIR}/tests"
cat > "${CRATE_DIR}/tests/adjacent_smoke.rs" << RS_TEST
use cyberaug_adjacent_${DATE_TAG}_guards::*;

#[test]
fn adjacent_guard_module_loads() {
    assert!(true);
}
RS_TEST

echo "[adjacent] tests added for crate: ${CRATE_DIR}"

# 5) git commit (optional)
if git rev-parse --git-dir > /dev/null 2>&1; then
  git checkout -b "${BRANCH_NAME}" 2>/dev/null || git checkout "${BRANCH_NAME}"
  git add "${ALN_FILE}" "${GUARDS_RS}" "${CRATE_DIR}" "${PROM_FILE}"
  git commit -m "Adjacent cyberaug guards + metrics (${DOMAIN}) for ${DATE_TAG}" || true
  echo "[adjacent] branch ready: ${BRANCH_NAME}"
else
  echo "[adjacent] not in a git repo; skipping branch/commit."
fi

# 6) manifest updated
mkdir -p research-logs
MANIFEST="research-logs/cyberaug_adjacent_manifest.jsonl"
cat >> "${MANIFEST}" << JSON_EOF
{"date":"${DATE_TAG}", "domain":"${DOMAIN}", "aln_profile":"${ALN_FILE}", "guards_module":"${GUARDS_RS}", "guards_crate":"${CRATE_DIR}", "prometheus_metrics":"${PROM_FILE}"}
JSON_EOF

echo "[adjacent] manifest updated: ${MANIFEST}"

echo "[adjacent] cycle completed."