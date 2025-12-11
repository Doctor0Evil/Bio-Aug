use nanoswarm_write_api::domain::models::NanoswarmWrite;
use nanoswarm_write_api::service::executor::TestWriter;
use nanoswarm_write_api::service::router::handle_write;

#[test]
fn nanoswarm_write_flow_smoke() {
    let write = NanoswarmWrite {
        time_ms: 1,
        user_session_id: "user-1".into(),
        device_id: "dev-1".into(),
        nanoswarm_node_id: "node-1".into(),
        write_target: "session_note".into(),
        write_scope: "edge".into(),
        write_type: "append".into(),
        payload_class: "json".into(),
        payload_len: 32,
        signed: true,
        integrity_ok: true,
        consent_ok: true,
        safety_budget_tokens: 10,
    };

    let writer = TestWriter::new();
    let payload = br#"{"note":"hello"}"#;

    let req_id = handle_write(&writer, &write, payload).expect("write should succeed");

    assert!(req_id.starts_with("req-"));
}
