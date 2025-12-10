#![no_std]
pub struct NanoStimParams {
    pub s_value: i32,
    pub l_bound: i32,
    pub u_bound: i32,
    pub energy_integral: u32,
    pub max_energy: u32,
}

pub fn guard_nano_stim(p: &NanoStimParams) -> Result<(), &'static str> {
    if p.s_value < p.l_bound || p.s_value > p.u_bound {
        return Err("nano_stim_envelope_violation");
    }
    if p.energy_integral > p.max_energy {
        return Err("nano_stim_energy_violation");
    }
    Ok(())
}
