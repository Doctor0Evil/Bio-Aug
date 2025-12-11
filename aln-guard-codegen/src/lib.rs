use anyhow::Result;
mod expr_codegen;
mod record_codegen;
use anyhow::Result;
use aln_syntax::{parse_aln, parse_records};
use expr_codegen::{invariants_to_module, invariant_to_fn};
use record_codegen::records_to_rust;
use pest::iterators::Pairs;
use aln_syntax::Rule;

pub use expr_codegen::{expr_to_rust, invariant_to_fn, invariants_to_module};

/// Stub: extract invariants from parsed ALN document.
/// For now, this returns an empty list; next step is to walk the
/// ALN AST and fill real invariants, but keep the signature stable.
pub fn extract_invariants_from_source(src: &str) -> Vec<aln_syntax::Invariant> {
    match aln_syntax::parse_invariants(src) {
        Ok(invs) => invs,
        Err(_) => Vec::new(),
    }
}

pub fn extract_records_from_source(src: &str) -> Vec<aln_syntax::Record> {
    match parse_records(src) {
        Ok(recs) => recs,
        Err(_) => Vec::new(),
    }
}

/// High-level codegen entry: ALN → Rust module string.
pub fn generate_guards(source: &str, module_name: &str) -> Result<String> {
    // Minimal parse of ALN source to ensure validity.
    let _pairs = parse_aln(source)?;
    let invariants = extract_invariants_from_source(source);
    let records = extract_records_from_source(source);
    let mut module = invariants_to_module(module_name, &invariants, &records);
    // no external GuardContext import needed; generated module includes `GuardContext`.
    Ok(module)
}
    // Deduplicate ids while preserving order
