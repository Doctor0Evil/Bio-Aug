use nanoswarm_write_api::domain::models::NanoswarmWrite;
use nanoswarm_edge_adapter::SimulatedWriter;

#[test]
fn simulated_writer_receives_payload() {
    let w = SimulatedWriter::new();

    let write = NanoswarmWrite {
        time_ms: 1,
        user_session_id: "u-1".into(),
        device_id: "d-1".into(),
        nanoswarm_node_id: "n-1".into(),
        write_target: "session_note".into(),
        write_scope: "edge".into(),
        write_type: "append".into(),
        payload_class: "json".into(),
        payload_len: 10,
        signed: true,
        integrity_ok: true,
        consent_ok: true,
        safety_budget_tokens: 1,
    };

    let payload: &[u8] = b"{"hello": true}";
    let ack = w.write(&write, payload).expect("writer should accept");
    assert!(ack.success);
}
