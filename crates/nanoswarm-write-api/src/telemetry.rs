// Minimal telemetry scaffolding for Prometheus metrics. The production code
// should register counters/gauges and export on a metrics endpoint.

use std::sync::atomic::{AtomicU64, Ordering};

pub static NANOSWARM_WRITE_REQUESTS_TOTAL: AtomicU64 = AtomicU64::new(0);
pub static NANOSWARM_WRITE_REJECTS_TOTAL: AtomicU64 = AtomicU64::new(0);
pub static NANOSWARM_WRITE_SUCCESS_TOTAL: AtomicU64 = AtomicU64::new(0);

pub fn inc_write_request() {
    NANOSWARM_WRITE_REQUESTS_TOTAL.fetch_add(1, Ordering::Relaxed);
}

pub fn inc_write_reject() {
    NANOSWARM_WRITE_REJECTS_TOTAL.fetch_add(1, Ordering::Relaxed);
}

pub fn inc_write_success() {
    NANOSWARM_WRITE_SUCCESS_TOTAL.fetch_add(1, Ordering::Relaxed);
}
