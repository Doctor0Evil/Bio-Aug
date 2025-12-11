use anyhow::Result;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

bitflags::bitflags! {
    /// Capability flags for modules in the augmentation stack.
    #[derive(Serialize, Deserialize)]
    pub struct Capability: u32 {
        const READ_ONLY_BCI    = 0b00000001;
        const THERAPEUTIC_WRITE = 0b00000010;
        const ECONOMY_MAPPER   = 0b00000100;
        const LEDGER_ADMIN     = 0b00001000;
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ConsentMode { None, Clinical, EmergencyOverride }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConsentState {
    pub subject_id: String,
    pub mode: ConsentMode,
    pub last_updated: DateTime<Utc>,
    pub signature: String,
}

impl ConsentState {
    pub fn is_active_for_high_risk(&self) -> bool { matches!(self.mode, ConsentMode::Clinical | ConsentMode::EmergencyOverride) }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SafetyBudget { pub max_energy_joule: u64, pub used_energy_joule: u64, pub max_neuromod_pulses: u64, pub used_neuromod_pulses: u64 }

impl SafetyBudget { pub fn can_spend(&self, delta_energy: u64, delta_pulses: u64) -> bool { self.used_energy_joule.saturating_add(delta_energy) <= self.max_energy_joule && self.used_neuromod_pulses.saturating_add(delta_pulses) <= self.max_neuromod_pulses } }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RadEnvelope { pub max_sar_mw_per_kg: u32, pub max_duty_cycle_pct: u8 }

impl RadEnvelope { pub fn within_limits(&self, sar_mw_per_kg: u32, duty_cycle_pct: u8) -> bool { sar_mw_per_kg <= self.max_sar_mw_per_kg && duty_cycle_pct <= self.max_duty_cycle_pct } }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum EnergyReason { ForensicReward, ResearchReward, UptimeReward, AdminAdjust }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnergyEvent { pub id: String, pub subject_id: String, pub delta_auet: i64, pub delta_csp: i64, pub reason: EnergyReason, pub timestamp: DateTime<Utc>, pub prev_hash: String, pub hash: String }

impl EnergyEvent {
    pub fn compute_hash(&self) -> String {
        let encoded = serde_json::to_vec(self).expect("EnergyEvent should serialize deterministically"); let mut hasher = Sha256::new(); hasher.update(encoded); hex::encode(hasher.finalize())
    }
    pub fn with_hash(mut self) -> Self { self.hash = self.compute_hash(); self }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlueprintConstants { pub c_e: f64, pub c_s: f64, pub max_auet_supply: u64, pub max_csp_supply: u64, pub base_daily_auet: u64, pub alpha_daily_auet: u64 }

impl BlueprintConstants { pub fn daily_cap(&self, current_auet: u64) -> u64 { self.base_daily_auet.saturating_add(self.alpha_daily_auet.saturating_mul(current_auet)) } }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Blueprint { pub version: String, pub constants: BlueprintConstants, pub created_at: DateTime<Utc> }

impl Blueprint { pub fn hash(&self) -> String { let encoded = serde_json::to_vec(self).expect("Blueprint should serialize deterministically"); let mut hasher = Sha256::new(); hasher.update(encoded); hex::encode(hasher.finalize()) } }

pub struct CoercionGuard<'a> { pub blueprint: &'a BlueprintConstants, pub consent: &'a ConsentState, pub safety_budget: &'a SafetyBudget, pub rad_envelope: &'a RadEnvelope, pub current_auet: u64 }

pub struct WriteInRequest { pub subject_id: String, pub energy_cost: u64, pub neuromod_pulses: u64, pub sar_mw_per_kg: u32, pub duty_cycle_pct: u8 }

pub struct WriteInDecision { pub allowed: bool, pub reason: &'static str }

impl<'a> CoercionGuard<'a> {
    pub fn evaluate(&self, req: &WriteInRequest) -> WriteInDecision {
        if self.consent.subject_id != req.subject_id { return WriteInDecision { allowed: false, reason: "subject-mismatch" }; }
        if !self.consent.is_active_for_high_risk() { return WriteInDecision { allowed: false, reason: "insufficient-consent" }; }
        if !self.safety_budget.can_spend(req.energy_cost, req.neuromod_pulses) { return WriteInDecision { allowed: false, reason: "safety-budget-exhausted" }; }
        if !self.rad_envelope.within_limits(req.sar_mw_per_kg, req.duty_cycle_pct) { return WriteInDecision { allowed: false, reason: "rad-envelope-violation" }; }
        let cap = self.blueprint.daily_cap(self.current_auet);
        if req.energy_cost > cap { return WriteInDecision { allowed: false, reason: "exceeds-daily-energy-cap" }; }
        WriteInDecision { allowed: true, reason: "ok" }
    }
}

pub fn validate_admin_adjust(event: &EnergyEvent, constants: &BlueprintConstants) -> bool { if !matches!(event.reason, EnergyReason::AdminAdjust) { return false;} if event.delta_auet > 0 || event.delta_csp > 0 { return false; } let total = event.delta_auet.abs() as u64 .saturating_add(event.delta_csp.abs() as u64); total <= constants.max_auet_supply.saturating_div(1000)
}

pub fn deny_broadcast_write_in(target_count: usize) -> bool { target_count == 1 }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_coercion_guard_denies_on_mismatch() {
        let constants = BlueprintConstants { c_e: 1.0, c_s: 2.0, max_auet_supply: 1000, max_csp_supply: 1000, base_daily_auet: 100, alpha_daily_auet: 0 };
        let blueprint = Blueprint { version: "0.1".into(), constants: constants.clone(), created_at: chrono::Utc::now() };
        let consent = ConsentState { subject_id: "sub1".into(), mode: ConsentMode::Clinical, last_updated: chrono::Utc::now(), signature: "sig".into() };
        let budget = SafetyBudget { max_energy_joule: 1000, used_energy_joule: 0, max_neuromod_pulses: 1000, used_neuromod_pulses: 0 };
        let rad = RadEnvelope { max_sar_mw_per_kg: 10, max_duty_cycle_pct: 50 };
        let guard = CoercionGuard { blueprint: &blueprint.constants, consent: &consent, safety_budget: &budget, rad_envelope: &rad, current_auet: 0 };
        let req = WriteInRequest { subject_id: "other".into(), energy_cost: 10, neuromod_pulses: 1, sar_mw_per_kg: 1, duty_cycle_pct: 1 };
        let dec = guard.evaluate(&req);
        assert!(!dec.allowed && dec.reason == "subject-mismatch");
    }
}
