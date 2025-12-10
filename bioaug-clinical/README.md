# BioAugClinical Workspace

This workspace contains the ALN policy definitions, Rust `no_std` guard crates and CI wiring for the BioAugClinical profile (IEC 62304 Class C, ISO 14971).

Key features:
- Class C enforcement with DPIA and DoS guard checks
- Multi-signature sidecar support for ALN files
- Rust `no_std` guard stubs with property-based tests (proptest)
- Nanoneuromodulation and neuromorphic dataset & envelope policies (wireless stim, TiS2/Pt, magnetoelectric, compute & dataset provenance)
	- New neuromorphic ALN dataset specs added: `specs/NanoNeuro.NeuromorphicClinical.v1.aln` and `specs/NanoNeuro.NeuromorphicUrban.v1.aln`.
- City-scale neuro-infrastructure policies (stability, privacy, neuro-rights)
 - Pillar specs: `specs/BioAugClinical-Pillars-NanoNeuro-SmartCity-NeuroRights.md` and `specs/xAI.NanoNeuroIntegration.*.aln` include governance, modalities, and documented invariants
- Placeholder WCET/Memory/WASM analytic checks in CI
- Zero-trust validation hooks
- Scripts to generate dev sign keys, sign policies, and verify signatures

ALN Linting & Docs Gate
----------------------
We provide a portable linter wrapper at `tools/aln_portable_lint.sh` which locates the `aln` binary in common locations and runs `aln lint` across `specs/` and `policies/`. The linter supports an `--auto-build` mode that attempts to build `aln` via `aln-cli` if it's not found on PATH. The `ci/aln_and_docs_gate.sh` combines ALN linting with the gold-standard docs presence check to provide a single gate that the CI runs in the main and `release/*` workflows.

Release & Branch Protection
---------------------------
For gold-class release branches (release/*), the project provides a dedicated workflow `BioAugClinical-ClassC-Neuronano-Release` that runs tightened neuronano/cyberneuro checks and packages a Class C release bundle (WASM + SBOM + signed TAR). To enforce non-bypassable checks, configure the repository branch protection rules to require this workflow to pass before merging release branches.

Quick start (dev):

1) Build signer & tools
```powershell
cd tools/signer-rs
cargo build --release
cd ../..
cd aln-cli; cargo build --release
```

2) Create dev keys, sign policies, and run the strict validator
```powershell
./bioaug-clinical/scripts/gen_dev_keys.sh bioaug-clinical/ci/dev
./bioaug-clinical/scripts/sign_all_policies.sh
./bioaug-clinical/scripts/validate_aln_strict.sh
```

3) Run CI-like checks locally
```powershell
./bioaug-clinical/scripts/aln_coverage_and_sign.sh
./bioaug-clinical/scripts/rust_classc_checks.sh
./bioaug-clinical/scripts/wcet_mem_check.sh
./bioaug-clinical/scripts/run_proptests.sh
./bioaug-clinical/scripts/validate_pillars.sh
./bioaug-clinical/scripts/validate_nanoneuro_core.sh
./bioaug-clinical/scripts/prereq_check.sh
./bioaug-clinical/scripts/certify_core_nanoneuro.sh
./bioaug-clinical/scripts/wasm_build_stub.sh
Finishing-Touch Gold-Standard Pipeline
-------------------------------------
For a single, end-to-end pass that builds the ALN toolchain, runs the ALN lint & docs gate, executes neuronano math checks and strict guards, and packages a signed Class C artefact bundle, run the finishing-touch script:

```bash
./bioaug-clinical/scripts/run_finishing_touch_pipeline.sh
```

Note: The finishing-touch script will attempt to build `aln` and `signer-rs` from source when their directories exist; the CI already includes `cargo build` steps on `ubuntu-latest` so this is safe to run in CI.
```

Notes:
- This workspace is intentionally conservative and includes placeholders for security & formal analyzers. To move towards production, integrate SoftHSM for CI HSM emulation, add a full ALN AST and grammar, and integrate formal WCET & memory analyzers.

TODO: See `HSM_TODO.md`, `AST_TODO.md`, and `FORMAL_TODO.md` for next steps.
For nanoneuro integration: see `specs/xAI.NanoNeuroIntegration.Core.v1.aln` and `specs/xAI.NanoNeuroIntegration.Neuromorphic.v1.aln` for dataset schemas, and `policies/nano.safety_metrics_guard.aln` for safety metric policies.
