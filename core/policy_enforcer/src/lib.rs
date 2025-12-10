#![no_std]

extern crate alloc;
use alloc::string::String;
use alloc::vec::Vec;
use core::result::Result;

/// Decision returned to kernel when checking whether an actuation request is allowed.
pub enum Decision {
    Allow,
    Deny(&'static str),
}

/// Actuation parameters to be evaluated against channel policy.
pub struct ActuationParams {
    pub amplitude_mA: f32,
    pub pulse_width_us: u32,
    pub frequency_hz: f32,
}

/// Simple channel-level policy.
pub struct ChannelPolicy {
    pub name: &'static str,
    pub allowed: bool,
    pub max_amplitude_mA: f32,
    pub max_pw_us: u32,
    pub max_freq_hz: f32,
    pub hitl_required: bool,
}

/// Bundle metadata that the kernel receives after verification.
pub struct BundleMetadata {
    pub id: String,
    pub version: String,
    pub channels: Vec<ChannelPolicy>,
    pub signed_by_clinical: bool,
    pub signed_by_security: bool,
}

/// Simple trait representing an HSM / secure element verification capability.
/// In a production runtime, this trait should be implemented by platform-specific
/// bindings into an HSM or secure element API.
pub trait HsmVerifier {
    /// Verify the `data_hash` using the provided `signature`.
    fn verify(&self, data_hash: &[u8], signature: &[u8]) -> bool;
}

/// Policy Enforcer used by kernel to evaluate whether actuation is permitted.
pub struct PolicyEnforcer {
    pub bundle: BundleMetadata,
}

impl PolicyEnforcer {
    pub fn new(bundle: BundleMetadata) -> Self {
        PolicyEnforcer { bundle }
    }

    /// Verifies the signature coverage. This is a simplified check — a real
    /// implementation queries HSM-backed verification and verifies signatures
    /// are valid for issuer keys, revocation status, etc.
    pub fn verify_bundle_signature(&self, _hsm: &dyn HsmVerifier, _sig_clin: &[u8], _sig_sec: &[u8]) -> bool {
        // Verified in the HAL/HSM layer for kernel. Stub: return true only if both flags
        // are set on the in-memory metadata.
        self.bundle.signed_by_clinical && self.bundle.signed_by_security
    }

    /// Evaluate whether actuation is allowed for the given channel and params.
    /// `hitl_signed` indicates the presence of an explicit clinician + patient approval.
    pub fn can_actuate(&self, channel: &str, params: &ActuationParams, hitl_signed: bool) -> Decision {
        for ch in self.bundle.channels.iter() {
            if ch.name == channel {
                if !ch.allowed {
                    return Decision::Deny("channel not allowed");
                }

                if params.amplitude_mA > ch.max_amplitude_mA { return Decision::Deny("amplitude exceeds limit"); }
                if params.pulse_width_us > ch.max_pw_us { return Decision::Deny("pulse width exceeds limit"); }
                if params.frequency_hz > ch.max_freq_hz { return Decision::Deny("frequency exceeds limit"); }
                if ch.hitl_required && !hitl_signed { return Decision::Deny("HITL required but missing"); }
                return Decision::Allow;
            }
        }
        Decision::Deny("unknown channel")
    }
}

// Optional trivial unit test area for non-kernel builds (std) — will be ignored in no_std targets.
#[cfg(test)]
mod tests {
    use super::*;

    struct DummyHsm;
    impl HsmVerifier for DummyHsm {
        fn verify(&self, _data_hash: &[u8], _signature: &[u8]) -> bool { true }
    }

    #[test]
    fn allow_simple_channel() {
        let ch = ChannelPolicy { name: "vagal_stim_channel", allowed: true, max_amplitude_mA: 1.5, max_pw_us: 250, max_freq_hz: 25.0, hitl_required: true };
        let bundle = BundleMetadata { id: String::from("1"), version: String::from("0.1"), channels: vec![ch], signed_by_clinical: true, signed_by_security: true };
        let enforcer = PolicyEnforcer::new(bundle);
        let params = ActuationParams { amplitude_mA: 1.0, pulse_width_us: 200, frequency_hz: 10.0 };
        let decision = enforcer.can_actuate("vagal_stim_channel", &params, true);
        match decision { Decision::Allow => (), _ => panic!("should have allowed") };
    }
}
