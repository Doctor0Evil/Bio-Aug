#![no_std]
pub struct NeuroBackendParams {
    pub synops_per_sec: u64,
    pub max_synops_per_sec: u64,
    pub latency_ms: u32,
    pub max_latency_ms: u32,
    pub power_w: u32,
    pub max_power_w: u32,
}

pub fn guard_neuromorphic_backend(p: &NeuroBackendParams) -> Result<(), &'static str> {
    if p.synops_per_sec > p.max_synops_per_sec {
        return Err("synops_rate_exceeded");
    }
    if p.latency_ms > p.max_latency_ms {
        return Err("latency_exceeded");
    }
    if p.power_w > p.max_power_w {
        return Err("power_budget_exceeded");
    }
    Ok(())
}
