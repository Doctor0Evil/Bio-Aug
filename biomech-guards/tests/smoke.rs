use bioaug_biomech_guards::bioaug_biomech_guards;
use bioaug_biomech_guards::GuardContext;
use bioaug_biomech_guards::NeuromodSample;
use bioaug_biomech_guards::NeuromodEnvInvariant;

#[test]
fn smoke_guard_compiles() {
    // Try calling placeholder functions (should compile & return bool)
    let ctx = GuardContext { torque_nm: 10.0, current_amp: 0.1, pressure_kpa: 10.0, link_ok: true, neuromod_samples: Vec::new(), neuromod_envs: Vec::new() };
    let _ = bioaug_biomech_guards::torque_within_envelope(&ctx);
    let _ = bioaug_biomech_guards::current_within_envelope(&ctx);
    // Ensure we can build record instances and add to ctx
    let sample = NeuromodSample { env_id: "env0".to_string(), s_value: 10.0, s_squared_dt: 100.0, delta_t: 1.0, ssi: 0.5 };
    let env = NeuromodEnvInvariant { id: "env0".to_string(), s_lower: 5.0, s_upper: 15.0, e_damage: 200.0, delta_t_safe: 2.0, ssi_min: 0.1 };
    let ctx2 = GuardContext { torque_nm: 0.0, current_amp: 0.0, pressure_kpa: 0.0, link_ok: true, neuromod_samples: vec![sample], neuromod_envs: vec![env] };
    let _ = bioaug_biomech_guards::torque_within_envelope(&ctx2);
}
