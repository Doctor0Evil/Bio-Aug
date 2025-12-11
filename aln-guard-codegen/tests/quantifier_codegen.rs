use aln_guard_codegen::generate_guards;

#[test]
fn emits_loops_for_forall_invariants() {
    let src = r#"
        aln system Test {
            policy NeuromodChecks {
                forall x in NeuromodSample, env in NeuromodEnvInvariant where x.env_id == env.id:
                    assert x.s_value >= env.s_lower && x.s_value <= env.s_upper;
            end
        end
    "#;
    let code = generate_guards(src, "test_guards").expect("codegen failed");
    assert!(code.contains("for x in &ctx.neuromod_samples"));
    assert!(code.contains("for env in &ctx.neuromod_envs"));
    assert!(code.contains("if !(x.s_value >= env.s_lower && x.s_value <= env.s_upper)"));
    // Should also provide a typed single-item function wrapper (typed args)
    assert!(code.contains("_single("));
    assert!(code.contains("NeuromodSample") && code.contains("NeuromodEnvInvariant"));
    assert!(code.contains("pub struct GuardContext") && code.contains("pub struct NeuromodSample"));
}
