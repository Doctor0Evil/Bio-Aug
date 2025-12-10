#![no_std]
// NOTE: This file is a reference no_std implementation used for local development and
// to document the expected runtime guard signature. The canonical runtime implementation
// lives in `bioaug-clinical/rust/neuronano-guards` and should be used by production builds.

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
    if x.s_value < env.s_lower || x.s_value > env.s_upper {
        return Err(EnvError::SOutOfRange);
    }
    if x.s_squared_dt >= env.e_damage {
        return Err(EnvError::EnergyExceeded);
    }
    if x.delta_t > env.delta_t_safe {
        return Err(EnvError::DeltaTExceeded);
    }
    if x.ssi < env.ssi_min {
        return Err(EnvError::SSIBelowMin);
    }
    Ok(())
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HybridError {
    ReliabilityBelowTarget,
}

pub fn check_hybrid_reliability(r_ai: f32, r_human: f32, r_target: f32) -> Result<(), HybridError> {
    let one = 1.0f32;
    let r_hybrid = one - (one - r_ai) * (one - r_human);
    if r_hybrid < r_target {
        return Err(HybridError::ReliabilityBelowTarget);
    }
    Ok(())
}
