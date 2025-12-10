#![no_std]

extern crate alloc;

pub use nanomod_env_guard::{NeuromodEnvelope, StimRequest, check_stim};

pub mod math {
    #[derive(Clone, Copy)]
    pub struct EnvMath {
        pub s_lower: f32,
        pub s_upper: f32,
        pub e_damage: f32,
        pub delta_t_safe: f32,
        pub ssi_min: f32,
    }

    #[derive(Clone, Copy)]
    pub struct SampleMath {
        pub s_value: f32,
        pub s_squared_dt: f32,
        pub delta_t: f32,
        pub ssi: f32,
    }

    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum EnvError {
        SOutOfRange,
        EnergyExceeded,
        DeltaTExceeded,
        SSIBelowMin,
    }

    pub fn check_neuromod_math(env: &EnvMath, x: &SampleMath) -> Result<(), EnvError> {
        if x.s_value < env.s_lower || x.s_value > env.s_upper { return Err(EnvError::SOutOfRange); }
        if x.s_squared_dt >= env.e_damage { return Err(EnvError::EnergyExceeded); }
        if x.delta_t > env.delta_t_safe { return Err(EnvError::DeltaTExceeded); }
        if x.ssi < env.ssi_min { return Err(EnvError::SSIBelowMin); }
        Ok(())
    }

    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum HybridError {
        ReliabilityBelowTarget,
    }

    pub fn check_hybrid_reliability(r_ai: f32, r_human: f32, r_target: f32) -> Result<(), HybridError> {
        let one = 1.0f32;
        let r_hybrid = one - (one - r_ai) * (one - r_human);
        if r_hybrid < r_target { return Err(HybridError::ReliabilityBelowTarget); }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::math::*;
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn test_check_neuromod_math(s_value in -100.0f32..100.0f32, s_squared_dt in 0.0f32..10000.0f32, delta_t in 0.0f32..1000.0f32, ssi in 0.0f32..10.0f32,
                                   s_lower in -100.0f32..0.0f32, s_upper in 0.0f32..100.0f32, e_damage in 0.0f32..10000.0f32, delta_t_safe in 0.0f32..1000.0f32, ssi_min in 0.0f32..10.0f32) {
            let (s_lower, s_upper) = if s_lower <= s_upper { (s_lower, s_upper) } else { (s_upper, s_lower) };
            let env = EnvMath { s_lower, s_upper, e_damage, delta_t_safe, ssi_min };
            let samp = SampleMath { s_value, s_squared_dt, delta_t, ssi };
            let _ = check_neuromod_math(&env, &samp);
            if s_value >= s_lower && s_value <= s_upper && s_squared_dt < e_damage && delta_t <= delta_t_safe && ssi >= ssi_min {
                prop_assert_eq!(check_neuromod_math(&env, &samp).unwrap(), ());
            }
        }

        #[test]
        fn test_check_hybrid_reliability(r_ai in 0.0f32..1.0f32, r_human in 0.0f32..1.0f32, r_target in 0.0f32..1.0f32) {
            let _ = check_hybrid_reliability(r_ai, r_human, r_target);
            let r_hybrid = 1.0f32 - (1.0f32 - r_ai) * (1.0f32 - r_human);
            if r_hybrid >= r_target { prop_assert_eq!(check_hybrid_reliability(r_ai, r_human, r_target).unwrap(), ()); }
        }
    }
}
