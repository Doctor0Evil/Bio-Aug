#![no_std]
extern crate alloc;

#[cfg(test)]
extern crate std;

pub use neuronano_guards::math::{check_neuromod_math, check_hybrid_reliability};

pub fn guard_channel(x: i32, l: i32, u: i32) -> Result<(), &'static str> {
    if x < l || x > u { return Err("envelope_violation"); }
    Ok(())
}

pub fn guard_stim_envelope(s: i32, l: i32, u: i32) -> Result<(), &'static str> {
    if s < l || s > u { return Err("stim_envelope_violation"); }
    Ok(())
}

pub fn guard_hybrid_reliability(r_ai: f32, r_human: f32, r_target: f32) -> Result<(), &'static str> {
    match check_hybrid_reliability(r_ai, r_human, r_target) {
        Ok(()) => Ok(()),
        Err(_) => Err("hybrid_reliability_below_target"),
    }
}

pub fn guard_neuromod_math(s_value: f32, s_squared_dt: f32, delta_t: f32, ssi: f32,
                          s_lower: f32, s_upper: f32, e_damage: f32, delta_t_safe: f32, ssi_min: f32) -> Result<(), &'static str> {
    let env = neuronano_guards::math::EnvMath { s_lower, s_upper, e_damage, delta_t_safe, ssi_min };
    let samp = neuronano_guards::math::SampleMath { s_value, s_squared_dt, delta_t, ssi };
    match check_neuromod_math(&env, &samp) {
        Ok(()) => Ok(()),
        Err(e) => match e {
            neuronano_guards::math::EnvError::SOutOfRange => Err("s_out_of_range"),
            neuronano_guards::math::EnvError::EnergyExceeded => Err("energy_exceeded"),
            neuronano_guards::math::EnvError::DeltaTExceeded => Err("delta_t_exceeded"),
            neuronano_guards::math::EnvError::SSIBelowMin => Err("ssi_below_min"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use nanomod_env_guard::{NeuromodEnvelope, StimRequest, check_stim};
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn test_guard_channel(x in -100..100i32, l in -100..100i32, u in -100..100i32) {
            // Normalize l <= u
            let (l, u) = if l <= u { (l, u) } else { (u, l) };
            let _res = guard_channel(x, l, u);
            // Property: if x in [l,u] then Ok
            if x >= l && x <= u {
                prop_assert_eq!(guard_channel(x, l, u).unwrap(), ());
            }
        }
        #[test]
        fn test_guard_stim_envelope(s in -1000..1000i32, l in -1000..0i32, u in 0..1000i32) {
            let (l, u) = if l <= u { (l, u) } else { (u, l) };
            let _ = guard_stim_envelope(s, l, u);
            if s >= l && s <= u { prop_assert_eq!(guard_stim_envelope(s, l, u).unwrap(), ()); }
        }
        #[test]
        fn test_hybrid_reliability(r_ai in 0.0f32..1.0f32, r_human in 0.0f32..1.0f32, r_target in 0.0f32..1.0f32) {
            let _ = guard_hybrid_reliability(r_ai, r_human, r_target);
            let r_hybrid = 1.0f32 - (1.0f32 - r_ai) * (1.0f32 - r_human);
            if r_hybrid >= r_target { prop_assert_eq!(guard_hybrid_reliability(r_ai, r_human, r_target).unwrap(), ()); }
        }
        #[test]
        fn test_guard_neuromod_math(s_value in -100.0f32..100.0f32, s_squared_dt in 0.0f32..10000.0f32, delta_t in 0.0f32..1000.0f32, ssi in 0.0f32..10.0f32,
                                   s_lower in -100.0f32..0.0f32, s_upper in 0.0f32..100.0f32, e_damage in 0.0f32..10000.0f32, delta_t_safe in 0.0f32..1000.0f32, ssi_min in 0.0f32..10.0f32) {
            let (s_lower, s_upper) = if s_lower <= s_upper { (s_lower, s_upper) } else { (s_upper, s_lower) };
            let _ = check_neuromod_math(&neuronano_guards::math::EnvMath { s_lower, s_upper, e_damage, delta_t_safe, ssi_min }, &neuronano_guards::math::SampleMath { s_value, s_squared_dt, delta_t, ssi });
            if s_value >= s_lower && s_value <= s_upper && s_squared_dt < e_damage && delta_t <= delta_t_safe && ssi >= ssi_min { prop_assert_eq!(guard_neuromod_math(s_value, s_squared_dt, delta_t, ssi, s_lower, s_upper, e_damage, delta_t_safe, ssi_min).unwrap(), ()); }
        }
        #[test]
        fn test_nanomod_stim_envelope(freq in 1.0f32..200.0f32, intensity in 0.0f32..20.0f32, pulse_width in 0.1f32..100.0f32, max_freq in 1.0f32..200.0f32, max_int in 0.0f32..20.0f32, max_pw in 0.1f32..100.0f32) {
            // Simple property: if stimulus params are within envelope, guard should not error.
            let min_freq = 1.0f32;
            let env = NeuromodEnvelope { min_freq_hz: min_freq, max_freq_hz: max_freq, max_intensity: max_int, max_pulse_width_ms: max_pw, max_session_energy: 1000.0f32 };
            let req = StimRequest { freq_hz: freq, intensity, pulse_width_ms: pulse_width, duty_cycle: 0.5f32, pulses: 1 };
            let _ = check_stim(&env, &req, 0.0f32);
            if (freq >= min_freq && freq <= max_freq) && (intensity <= max_int) && (pulse_width <= max_pw) {
                prop_assert!(check_stim(&env, &req, 0.0f32).is_ok());
            }
        }
    }
}
