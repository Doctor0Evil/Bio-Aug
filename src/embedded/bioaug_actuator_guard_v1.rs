#![no_std]

pub fn guard_actuator(input_ok: bool) -> Result<(), &'static str> {
    if !input_ok { return Err("safe_off"); }
    Ok(())
}
