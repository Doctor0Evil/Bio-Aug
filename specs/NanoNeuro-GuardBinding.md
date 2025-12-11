# NanoNeuro Guard Binding (Canonical)

- Canonical runtime guards for neuromod invariants live in the `neuronano-guards` crate:
  - `bioaug-clinical/rust/neuronano-guards` (no_std)
- `bioaug-guards` crate re-exports the canonical checks for compatibility with other runtime modules.
- ALN policies declare binding intent for Class C-level certification. Codegen or runtime config MUST map NanoNeuro.MathInvariants records to the `EnvMath` & `SampleMath` structs feeding the canonical `check_neuromod_math` function.

## Requirements
- Re-export guard APIs (neuro math + envelope checks) in `bioaug-guards`.
- Add `proptest` coverage inside `neuronano-guards` for logic and edge cases.
- Document how ALN records map to Rust structs and ensure structural compatibility.
