#![no_std]

pub type Energy = f32;

#[derive(Clone, Copy, Debug)]
pub struct NeuromodEnvelope {
    pub min_freq_hz: f32,
    pub max_freq_hz: f32,
    pub max_intensity: f32,
    pub max_pulse_width_ms: f32,
    pub max_session_energy: Energy,
}

#[derive(Clone, Copy, Debug)]
pub struct StimRequest {
    pub freq_hz: f32,
    pub intensity: f32,
    pub pulse_width_ms: f32,
    pub duty_cycle: f32,
    pub pulses: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GuardError {
    FrequencyOutOfRange,
    IntensityTooHigh,
    PulseWidthTooLong,
    DutyCycleOutOfRange,
    SessionEnergyExceeded,
}

pub fn check_stim(
    env: &NeuromodEnvelope,
    req: &StimRequest,
    session_energy_so_far: Energy,
) -> Result<(), GuardError> {
    if req.freq_hz < env.min_freq_hz || req.freq_hz > env.max_freq_hz {
        return Err(GuardError::FrequencyOutOfRange);
    }
    if req.intensity > env.max_intensity {
        return Err(GuardError::IntensityTooHigh);
    }
    if req.pulse_width_ms > env.max_pulse_width_ms {
        return Err(GuardError::PulseWidthTooLong);
    }
    if req.duty_cycle < 0.0 || req.duty_cycle > 1.0 {
        return Err(GuardError::DutyCycleOutOfRange);
    }
    let incremental_energy =
        req.intensity * req.pulse_width_ms * (req.pulses as f32) * req.freq_hz;
    if session_energy_so_far + incremental_energy > env.max_session_energy {
        return Err(GuardError::SessionEnergyExceeded);
    }
    Ok(())
}
