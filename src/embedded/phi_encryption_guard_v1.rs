#![no_std]

pub fn guard_throughput(r_enc: u64, r_data: u64, k: u64) -> Result<(), &'static str> {
    if k < 5 { return Err("k_too_small"); }
    if r_enc < k.saturating_mul(r_data) { return Err("enc_insufficient"); }
    Ok(())
}
