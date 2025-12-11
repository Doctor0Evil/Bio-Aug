use proptest::prelude::*;
use bioaug_biomech_guards::bioaug_biomech_guards;
use bioaug_biomech_guards::GuardContext;

proptest! {
    #[test]
    fn torque_guard_matches_expected(torque in -200.0f64..200.0f64, link_ok in any::<bool>()) {
        let ctx = GuardContext { torque_nm: torque as f64, current_amp: 0.0, pressure_kpa: 0.0, link_ok, neuromod_samples: Vec::new(), neuromod_envs: Vec::new() };
        let res = bioaug_biomech_guards::torque_within_envelope(&ctx);
        let expected = (ctx.link_ok) && (ctx.torque_nm < 50.0);
        prop_assert_eq!(res, expected);
    }
}

proptest! {
    #[test]
    fn current_guard_matches_expected(current in -10.0f64..10.0f64) {
        let ctx = GuardContext { torque_nm: 0.0, current_amp: current as f64, pressure_kpa: 0.0, link_ok: true, neuromod_samples: Vec::new(), neuromod_envs: Vec::new() };
        let res = bioaug_biomech_guards::current_within_envelope(&ctx);
        let expected = (ctx.current_amp < 5.0);
        prop_assert_eq!(res, expected);
    }
}

proptest! {
    #[test]
    fn pressure_guard_matches_expected(pressure in -10.0f64..200.0f64) {
        let ctx = GuardContext { torque_nm: 0.0, current_amp: 0.0, pressure_kpa: pressure as f64, link_ok: true, neuromod_samples: Vec::new(), neuromod_envs: Vec::new() };
        let res = bioaug_biomech_guards::interface_pressure_within_band(&ctx);
        let expected = (ctx.pressure_kpa < 40.0);
        prop_assert_eq!(res, expected);
    }
}
