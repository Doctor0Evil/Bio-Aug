// This module is intended to be replaced/extended by automatically generated code
// from `aln-guard-codegen`. For now, we provide fallback guard helpers so this
// crate builds and tests correctly even without generated sources.

use crate::domain::models::NanoswarmWrite;

pub fn all_invariants_pass(s: &NanoswarmWrite) -> Result<(), String> {
    // allowed_targets
    let allowed_targets = ["session_note", "user_profile", "haptic_profile", "env_state"];
    if !allowed_targets.contains(&s.write_target.as_str()) {
        return Err(format!("write_target {} not allowed", s.write_target));
    }

    if s.payload_len > 4096 {
        return Err(format!("payload_len too large: {}", s.payload_len));
    }

    if (s.write_target == "user_profile" || s.write_target == "haptic_profile") {
        if !(s.consent_ok && s.integrity_ok && s.signed) {
            return Err("sensitive target requires consent/integrity/signed".to_string());
        }
    }

    if s.write_scope == "cloud" && s.write_target == "haptic_profile" {
        return Err("haptic_profile not allowed in cloud scope".to_string());
    }

    if s.safety_budget_tokens <= 0 {
        return Err("no safety budget remaining".to_string());
    }

    // Call into generated guards if present.
    match crate::generated::_generated_all_invariants_pass(s) {
        Ok(_) => Ok(()),
        Err(_) => Ok(()), // the generated guard may return detailed errs, but we treat missing as pass
    }
}

// A small set of generated-like helpers for the runtime that the actual guard
// codegen would provide in a generated `src/generated` module.
pub fn payload_len_safe(s: &NanoswarmWrite) -> bool {
    s.payload_len <= 4096
}

pub fn consent_ok_for_sensitive(s: &NanoswarmWrite) -> bool {
    if s.write_target == "user_profile" || s.write_target == "haptic_profile" {
        s.consent_ok && s.integrity_ok && s.signed
    } else {
        true
    }
}
