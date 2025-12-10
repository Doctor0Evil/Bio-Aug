# BioAugClinical Next Steps & TODOs

This file captures immediate next steps to take this workspace from staged to production-readiness.

High priority:
- Implement SoftHSM/PKCS#11 support in `tools/signer-rs` and add SoftHSM to the CI pipeline for key management and verification.
- Implement a robust ALN grammar and AST (see `AST_TODO.md`) and use the AST for stricter `aln-check` validation.
- Replace WCET/memory/wasm verification placeholders with real analyzers that produce machine-readable proofs.

Medium priority:
- Add LSP/VSCode support and pre-commit hooks for ALN grammar checks, codegen validation, and signature detection.
- Expand `aln-codegen` backends to produce real no_std Rust & WASM that compile to `rlib` with property-based tests.
- Add a `bioaug-clinical/certify` script to assemble proofs, traces, and signatures into a release artifact.

Low priority:
- Add more robust test coverage for `aln-check` semantic checks and compliance rules (e.g. IEC 62304 violations).

Security & Governance anchors:
- Ensure all production CI uses HSM-backed signing and never stores private keys in repo.
- Maintain a `ci/keys` root for public keys and a `ci/dev` folder for ephemeral dev keys used only in CI tests.

Documentation:
- Add a `BIOAUGCLINICAL_README.md` summarizing the profile requirements, runtime expectations, and CI gates.

