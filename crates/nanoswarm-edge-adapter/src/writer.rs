use anyhow::Result;
use nanoswarm_write_api::domain::models::NanoswarmWrite;

#[derive(Debug, Clone)]
pub struct Ack {
    pub request_id: String,
    pub nanoswarm_node_id: String,
    pub success: bool,
}

pub trait NanoswarmWriter: Send + Sync {
    fn write(&self, ctx: &NanoswarmWrite, payload: &[u8]) -> Result<Ack>;
}

#[derive(Default)]
pub struct SimulatedWriter {
    pub writes: std::sync::Mutex<Vec<(String, Vec<u8>)>>,
}

impl SimulatedWriter {
    pub fn new() -> Self {
        Self { writes: std::sync::Mutex::new(Vec::new()) }
    }
}

impl NanoswarmWriter for SimulatedWriter {
    fn write(&self, ctx: &NanoswarmWrite, payload: &[u8]) -> Result<Ack> {
        let rid = format!("req-{}-{}", ctx.user_session_id, ctx.time_ms);
        self.writes.lock().unwrap().push((rid.clone(), payload.to_vec()));
        Ok(Ack { request_id: rid, nanoswarm_node_id: ctx.nanoswarm_node_id.clone(), success: true })
    }
}
