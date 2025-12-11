use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NanoswarmWrite {
    pub time_ms: i64,
    pub user_session_id: String,
    pub device_id: String,
    pub nanoswarm_node_id: String,
    pub write_target: String,
    pub write_scope: String,
    pub write_type: String,
    pub payload_class: String,
    pub payload_len: i64,
    pub signed: bool,
    pub integrity_ok: bool,
    pub consent_ok: bool,
    pub safety_budget_tokens: i64,
}
