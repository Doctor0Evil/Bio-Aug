#![no_std]

pub fn guard_stim_envelope(s: i32, l: i32, u: i32) -> Result<(), &'static str> {
    if s < l || s > u { return Err("stim_envelope_violation"); }
    Ok(())
}
