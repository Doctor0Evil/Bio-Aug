use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FieldClass { NeuralData, SensorData }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AccessAction { Read, Write }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AccessRole { PoliceMedic, Doctor, Admin }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccessContext {
    pub role: AccessRole,
    pub jurisdiction: String,
    pub case_id: Option<String>,
    pub emergency_flag: bool,
    pub consent_present: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccessDecision { pub allowed: bool, pub reason: String }

pub fn evaluate_access(_field: FieldClass, ctx: &AccessContext, action: AccessAction) -> AccessDecision {
    // Minimal logic: Admins can do everything; PoliceMedic can write during emergency; consent needed otherwise.
    match ctx.role {
        AccessRole::Admin => AccessDecision { allowed: true, reason: "admin".into() },
        AccessRole::PoliceMedic => {
            if ctx.emergency_flag { AccessDecision{ allowed: true, reason: "emergency".into() } } else { AccessDecision{ allowed: ctx.consent_present, reason: if ctx.consent_present { "consent".into() } else { "no-consent".into() } } }
        }
        AccessRole::Doctor => {
            if action == AccessAction::Read { AccessDecision{ allowed: true, reason: "read".into() } } else { AccessDecision{ allowed: ctx.consent_present, reason: if ctx.consent_present { "consent".into() } else { "no-consent".into() } } }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn basic_access_admin() {
        let ctx = AccessContext { role: AccessRole::Admin, jurisdiction: "demo".into(), case_id: None, emergency_flag: false, consent_present: false };
        let dec = evaluate_access(FieldClass::NeuralData, &ctx, AccessAction::Write);
        assert!(dec.allowed);
    }
}
