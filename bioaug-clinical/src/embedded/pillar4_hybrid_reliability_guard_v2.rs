#![no_std]
pub fn guard_hybrid_reliability(r_ai: f32, r_human: f32, r_target: f32) -> Result<(), &'static str> {
    let one = 1.0f32;
    let r_hybrid = one - (one - r_ai) * (one - r_human);
    if r_hybrid < r_target {
        return Err("hybrid_reliability_below_target");
    }
    Ok(())
}
