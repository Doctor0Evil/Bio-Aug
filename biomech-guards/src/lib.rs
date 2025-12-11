// The generated file will be placed in `generated/bioaug_biomech_guards.rs` within this crate.
// It should be created by CI (aln GuardCodegen) and included here.
pub mod generated {
    include!("generated/bioaug_biomech_guards.rs");
}

pub use generated::bioaug_biomech_guards;

// Re-export record types and GuardContext for convenience
pub use bioaug_biomech_guards::{GuardContext, NeuromodSample, NeuromodEnvInvariant};
