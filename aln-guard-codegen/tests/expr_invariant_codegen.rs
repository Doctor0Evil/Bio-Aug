use aln_guard_codegen::generate_guards;

#[test]
fn generates_invariant_guard() {
    let src = r#"
        aln system Example {
            policy Safety {
                invariant inv.TorqueBound: torque < 50
            end
        end
    "#;
    let code = generate_guards(src, "test_guards").expect("codegen failed");
    assert!(code.contains("pub fn check_inv_TorqueBound("));
    // Should include typed param name which is torque_nm
    assert!(code.contains("torque_nm: f64"));
    assert!(code.contains("ctx.torque_nm < 50") || code.contains("torque_nm < 50"));
}
