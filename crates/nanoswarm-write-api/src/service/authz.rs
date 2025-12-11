// Placeholder authz module. In production this module would validate
// tokens, session metadata, and query governance/roles to determine allowed
// operations. For tests we expose a tiny helper.

use crate::domain::models::NanoswarmWrite;

pub fn authorized_for_write(_req: &NanoswarmWrite) -> bool {
    // Simplified: allow all writes in tests.
    true
}
