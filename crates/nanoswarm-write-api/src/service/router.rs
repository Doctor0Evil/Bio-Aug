use crate::domain::models::NanoswarmWrite;
use crate::domain::guards;
use crate::service::executor::NanoswarmWriter;
use anyhow::Result;

// A very small CLI-friendly entry used by unit tests. In production this
// would be an HTTP/gRPC endpoint that deserializes the request body and
// applies guards + executor.

pub fn handle_write<W: NanoswarmWriter>(writer: &W, req: &NanoswarmWrite, payload: &[u8]) -> Result<String> {
    // Run invariants
    guards::all_invariants_pass(req).map_err(|e| anyhow::anyhow!(e))?;

    // Call the writer
    let ack = writer.write(req, payload)?;

    Ok(ack.request_id)
}
