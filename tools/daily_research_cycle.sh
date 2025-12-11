#!/usr/bin/env bash
set -euo pipefail

DATE_TAG="$(date -u +%Y%m%d)"
BRANCH_NAME="research/daily-${DATE_TAG}"

echo "[daily] starting daily research cycle: ${DATE_TAG}"

# 1) CREATE / UPDATE A DAILY ALN PROFILE
# --------------------------------------
# Example: new biomech + BCI profile variant for this day.
mkdir -p aln-reference/daily
ALN_FILE="aln-reference/daily/AU.BioAug.DailyBiomechBCI.${DATE_TAG}.aln"

cat > "${ALN_FILE}" << ALN_EOF
aln system BioAugDaily_${DATE_TAG} {
  record NeuromodSample {
    time_ms: int;
    torque_nm: float;
    current_amp: float;
    eeg_alpha: float;
    eeg_beta: float;
    link_ok: bool;
  end

  policy BiomechLimits {
    invariant torque_safe:
      forall s in NeuromodSample where s.link_ok => s.torque_nm < 45.0;

    invariant current_safe:
      forall s in NeuromodSample where s.link_ok => s.current_amp < 2.0;
  end

  policy BCIStability {
    invariant eeg_band_ratio_safe:
      forall s in NeuromodSample where s.link_ok =>
        (s.eeg_beta / (s.eeg_alpha + 0.0001)) < 2.5;
  end
end
ALN_EOF

echo "[daily] ALN profile written: ${ALN_FILE}"

# 2) GENERATE TYPED RUST GUARDS + RECORDS (crate-local)
# ----------------------------------------------------
CRATE_DIR="daily-guards-${DATE_TAG}"
mkdir -p "${CRATE_DIR}/src/generated"
GEN_DIR="${CRATE_DIR}/src/generated"
GUARDS_RS="${GEN_DIR}/bioaug_daily_${DATE_TAG}_guards.rs"

ALN_BIN="${ALN_BIN:-$(./tools/find_aln.sh || echo 'aln-cli')}"

"${ALN_BIN}" GuardCodegen \
  "${ALN_FILE}" \
  --module "bioaug_daily_${DATE_TAG}_guards" \
  --out "${GUARDS_RS}"

echo "[daily] guards generated: ${GUARDS_RS}"

# 3) CREATE / UPDATE A DAILY GUARDS CRATE (lib.rs + generated/mod.rs)
# ------------------------------------------------------------------
mkdir -p "${CRATE_DIR}/src"
cat > "${CRATE_DIR}/Cargo.toml" << TOML_EOF
[package]
name = "bioaug-daily-guards-${DATE_TAG}"
version = "0.1.0"
edition = "2021"
license = "MIT OR Apache-2.0"
description = "Daily biomech/BCI guard crate generated from ALN for ${DATE_TAG}."

[dependencies]
anyhow = "1.0"

[lib]
name = "bioaug_daily_${DATE_TAG}_guards"
path = "src/lib.rs"
crate-type = ["rlib"]
TOML_EOF

cat > "${CRATE_DIR}/src/lib.rs" << RS_EOF
pub mod generated;

pub use generated::*;
RS_EOF

cat > "${CRATE_DIR}/src/generated/mod.rs" << RS_EOF
include!("bioaug_daily_${DATE_TAG}_guards.rs");
RS_EOF

echo "[daily] daily guard crate created: ${CRATE_DIR}"

# 4) DEFINE A PROMETHEUS NODE METRICS FILE
# ----------------------------------------
PROM_FILE="prometheus/daily_${DATE_TAG}_metrics.example.txt"
mkdir -p prometheus

cat > "${PROM_FILE}" << PROM_EOF
# HELP bioaug_guard_violation_total Total number of guard violations (daily profile).
# TYPE bioaug_guard_violation_total counter
bioaug_guard_violation_total{profile="daily_${DATE_TAG}"} 0

# HELP bioaug_neuromod_samples_total Number of neuromod samples seen.
# TYPE bioaug_neuromod_samples_total counter
bioaug_neuromod_samples_total{profile="daily_${DATE_TAG}"} 0

# HELP bioaug_eeg_ratio_last Last observed EEG beta/alpha ratio.
# TYPE bioaug_eeg_ratio_last gauge
bioaug_eeg_ratio_last{profile="daily_${DATE_TAG}"} 0.0
PROM_EOF

echo "[daily] Prometheus metrics example written: ${PROM_FILE}"

# 5) ADD / UPDATE TESTS FOR THE DAILY CRATE
# -----------------------------------------
mkdir -p "${CRATE_DIR}/tests"
cat > "${CRATE_DIR}/tests/daily_smoke.rs" << RS_TEST
use bioaug_daily_${DATE_TAG}_guards::*;

#[test]
fn daily_guard_module_loads() {
    // TODO: call real generated guard functions once wired.
    assert!(true);
}
RS_TEST

echo "[daily] tests added for crate: ${CRATE_DIR}"

# 6) GIT WORKFLOW: NEW BRANCH + COMMIT (FOR YOUR DEV MACHINE)
# -----------------------------------------------------------
if git rev-parse --git-dir > /dev/null 2>&1; then
  git checkout -b "${BRANCH_NAME}" 2>/dev/null || git checkout "${BRANCH_NAME}"
  git add "${ALN_FILE}" "${GUARDS_RS}" "${CRATE_DIR}" "${PROM_FILE}"
  git commit -m "Daily biomech/BCI guards and Prometheus metrics for ${DATE_TAG}" || true
  echo "[daily] branch ready: ${BRANCH_NAME}"
else
  echo "[daily] not in a git repo; skipping branch/commit."
fi

# 7) DAILY MANIFEST UPDATE (MACHINE-READABLE LOG)
# -----------------------------------------------
mkdir -p research-logs
MANIFEST="research-logs/daily_manifest.jsonl"

jq -nc --arg date "${DATE_TAG}" --arg aln "${ALN_FILE}" --arg guards "${GUARDS_RS}" --arg crate "${CRATE_DIR}" --arg prom "${PROM_FILE}" '
{
  date: $date,
  aln_profile: $aln,
  guards_module: $guards,
  guards_crate: $crate,
  prometheus_metrics: $prom
}' >> "${MANIFEST}"

echo "[daily] manifest updated: ${MANIFEST}"
echo "[daily] cycle completed."