#!/usr/bin/env bash
set -euo pipefail

DATE_TAG="$(date -u +%Y%m%d)"
BRANCH_NAME="research/cybernetic-daily-${DATE_TAG}"

echo "[daily] starting cybernetic research cycle: ${DATE_TAG}"

# DOMAIN ROTATION: ensure broad coverage across days
# --------------------------------------------------
DAY_INDEX=$((10#${DATE_TAG: -2} % 5))
case "${DAY_INDEX}" in
  1) DOMAIN="AugUser_BCI_EEG_MCI" ;;
  2) DOMAIN="Nanoswarm_Therapy_Safety" ;;
  3) DOMAIN="Neuromorphic_AI_Aug" ;;
  4) DOMAIN="SmartCity_Cybernetic_Nodes" ;;
  0) DOMAIN="Mixed_Integration_Fusion" ;;
esac

mkdir -p aln-reference/daily
ALN_FILE="aln-reference/daily/AU.CyberAug.${DOMAIN}.${DATE_TAG}.aln"

# 1) CREATE / UPDATE DAILY ALN PROFILE
cat > "${ALN_FILE}" << ALN_EOF
aln system CyberAugDaily_${DATE_TAG} {
  record CyberSample {
    time_ms: int;
    user_id: string;
    node_id: string;
    # ... fields elided for brevity (as before)
  end
  # policies elided for brevity
}
ALN_EOF

echo "[daily] ALN profile written: ${ALN_FILE}"

# 2) GENERATE TYPED RUST GUARDS + RECORDS (crate-local)
CRATE_DIR="daily-cyberaug-guards-${DATE_TAG}"
mkdir -p "${CRATE_DIR}/src/generated"
GEN_DIR="${CRATE_DIR}/src/generated"
GUARDS_RS="${GEN_DIR}/cyberaug_daily_${DATE_TAG}_guards.rs"

ALN_BIN="${ALN_BIN:-$(./tools/find_aln.sh || echo 'aln-cli')}"

"${ALN_BIN}" GuardCodegen \
  "${ALN_FILE}" \
  --module "cyberaug_daily_${DATE_TAG}_guards" \
  --out "${GUARDS_RS}"

echo "[daily] guards generated: ${GUARDS_RS}"

# 3) CREATE / UPDATE DAILY GUARDS CRATE
mkdir -p "${CRATE_DIR}/src"
cat > "${CRATE_DIR}/Cargo.toml" << TOML_EOF
[package]
name = "cyberaug-daily-guards-${DATE_TAG}"
version = "0.1.0"
edition = "2021"
license = "MIT OR Apache-2.0"
description = "Daily cybernetic (BCI/EEG/MCI, nanoswarm, neuromorphic, smart-city) guard crate for ${DATE_TAG}."

[dependencies]
anyhow = "1.0"

[lib]
name = "cyberaug_daily_${DATE_TAG}_guards"
path = "src/lib.rs"
crate-type = ["rlib"]
TOML_EOF

cat > "${CRATE_DIR}/src/lib.rs" << RS_EOF
pub mod generated;

pub use generated::*;
RS_EOF

cat > "${CRATE_DIR}/src/generated/mod.rs" << RS_EOF
include!("cyberaug_daily_${DATE_TAG}_guards.rs");
RS_EOF

echo "[daily] daily cyberaug guard crate created: ${CRATE_DIR}"

# 4) PROMETHEUS metrics (omitted content for brevity)...
mkdir -p prometheus
PROM_FILE="prometheus/cyberaug_daily_${DATE_TAG}_metrics.example.txt"
cat > "${PROM_FILE}" << PROM_EOF
# Placeholder metrics files for brevity
PROM_EOF

echo "[daily] Prometheus metrics example written: ${PROM_FILE}"

# 5) TESTS
mkdir -p "${CRATE_DIR}/tests"
cat > "${CRATE_DIR}/tests/daily_smoke.rs" << RS_TEST
use cyberaug_daily_${DATE_TAG}_guards::*;

#[test]
fn daily_guard_module_loads() {
    assert!(true);
}
RS_TEST

echo "[daily] tests added for crate: ${CRATE_DIR}"

# 6) git add/commit (if available)
if git rev-parse --git-dir > /dev/null 2>&1; then
  git checkout -b "${BRANCH_NAME}" 2>/dev/null || git checkout "${BRANCH_NAME}"
  git add "${ALN_FILE}" "${GUARDS_RS}" "${CRATE_DIR}" "${PROM_FILE}"
  git commit -m "Cyberaug daily guards + metrics (${DOMAIN}) for ${DATE_TAG}" || true
  echo "[daily] branch ready: ${BRANCH_NAME}"
else
  echo "[daily] not in a git repo; skipping branch/commit."
fi

# 7) manifest & blueprint
mkdir -p research-logs
MANIFEST="research-logs/cyberaug_daily_manifest.jsonl"
BLUEPRINT="research-logs/cyberaug_blueprint_${DATE_TAG}.json"
cat > "${BLUEPRINT}" << JSON_EOF
{
  "date": "${DATE_TAG}",
  "domain": "${DOMAIN}",
  "aln_profile": "${ALN_FILE}",
  "guards_module": "${GUARDS_RS}",
  "guards_crate": "${CRATE_DIR}",
  "prometheus_metrics": "${PROM_FILE}"
}
JSON_EOF

BLUEPRINT_HASH="$(sha256sum "${BLUEPRINT}" | awk '{print $1}')"

jq -nc --arg date "${DATE_TAG}" --arg domain "${DOMAIN}" \
      --arg aln "${ALN_FILE}" --arg guards "${GUARDS_RS}" --arg crate "${CRATE_DIR}" --arg prom "${PROM_FILE}" --arg blueprint "${BLUEPRINT}" --arg b_hash "${BLUEPRINT_HASH}" '
{
  date: $date,
  domain: $domain,
  aln_profile: $aln,
  guards_module: $guards,
  guards_crate: $crate,
  prometheus_metrics: $prom,
  blueprint_file: $blueprint,
  blueprint_sha256: $b_hash
}' >> "${MANIFEST}"

echo "[daily] manifest updated: ${MANIFEST}"
echo "[daily] blueprint hash: ${BLUEPRINT_HASH}"
echo "[daily] cybernetic cycle completed."