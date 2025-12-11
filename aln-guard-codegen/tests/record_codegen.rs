use aln_guard_codegen::generate_guards;

#[test]
fn generates_structs_and_guardctx_from_records() {
    let src = r#"
        aln dataset NanoNeuro.MathInvariants.v1

        record NeuromodSample {
            env_id: string
            s_value: f32
            s_squared_dt: f32
            delta_t: f32
            ssi: f32
        }

        record NeuromodEnvInvariant {
            id: string
            s_lower: f32
            s_upper: f32
            e_damage: f32
            delta_t_safe: f32
            ssi_min: f32
        }

        policy NeuromodChecks {
            forall x in NeuromodSample, env in NeuromodEnvInvariant where x.env_id == env.id:
                assert x.s_value >= env.s_lower && x.s_value <= env.s_upper;
        end
    "#;
    let code = generate_guards(src, "test_guards").expect("codegen failed");
    assert!(code.contains("pub struct NeuromodSample"));
    assert!(code.contains("pub struct NeuromodEnvInvariant"));
    assert!(code.contains("pub struct GuardContext"));
    assert!(code.contains("pub fn check_"));
}
