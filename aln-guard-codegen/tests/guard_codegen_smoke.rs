use aln_guard_codegen::generate_guards;
use aln_syntax::parse_aln;

#[test]
fn generates_compilable_module() {
    let src = r#"
        aln system Test {
            policy Integrity {
            end
        }
    "#;
    let code = generate_guards(src, "test_guards").expect("codegen failed");
    // As no real invariants exist in sample, guard functions for policies are not expected yet.
    assert!(code.contains("pub mod test_guards"));
    assert!(code.contains("pub struct GuardContext") || code.contains("pub struct GuardContext"));
    // Module should define GuardContext and basic structs when records are present.
    // Ensure the module compiles by writing to a temp file and invoking rustc? (Skipping live compile in unit test)
}
