#![no_std]

pub fn guard_channel(x: i32, l: i32, u: i32) -> Result<(), &'static str> {
    if x < l || x > u { return Err("envelope_violation"); }
    Ok(())
}
