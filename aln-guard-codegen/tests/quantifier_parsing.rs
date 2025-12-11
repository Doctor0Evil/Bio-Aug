use aln_guard_codegen::extract_invariants_from_source;

#[test]
fn extracts_quantifier_invariants() {
    let content = std::fs::read_to_string("bioaug-clinical/specs/NanoNeuro-MathInvariants.v1.aln").expect("read neuro specs");
    let invs = extract_invariants_from_source(&content);
    assert!(invs.len() >= 5, "expected >=5 invariants, got {}", invs.len());
    let has_binds = invs.iter().any(|i| !i.binds.is_empty());
    assert!(has_binds, "expected at least one invariant to have quantifier binds");
}
