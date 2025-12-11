#![no_std]

pub fn guard_hybrid_reliability(r_ai: f32, r_human: f32, r_target: f32) -> Result<(), &'static str> {
    let r_hybrid = 1.0f32 - (1.0f32 - r_ai) * (1.0f32 - r_human);
    if r_hybrid < r_target { return Err("hybrid_reliability_below_target"); }
    Ok(())
}
