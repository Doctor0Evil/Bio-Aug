# ALN Language Specification (Bio‑Aug)

This document summarizes the ALN language grammar, semantics, and core Bio‑Aug profiles for interoperability, safety, and governance.

## Goals
- Provide a formally specified grammar (EBNF/PEG) for ALN.
- Implement a Rust-based parser and AST (aln-syntax crate).
- Provide semantic checking and Bio‑Aug-specific rules in aln-check.
- Provide code generation backends to Rust/WASM/Config via aln-codegen.
- Provide a CLI and LSP integration for IDE/editor tooling.

## Grammar format
- The repo contains `aln-syntax/aln.pest`, a PEG grammar for parsing ALN.
- The grammar includes top-level declarations and minimal rules for block parsing.

## AST, Semantic checks
- The `aln-syntax` crate provides a parser and a minimal AST (see `src/ast.rs`).
- The `aln-check` crate contains a validation library with Bio‑Aug check-profiles (bioaug-clinical, bioaug-research).

## Code Generator targets
- Rust backend: generate typed structs, policy-check functions, and guard constructors.
- WASM backend: compile selected policies/guards as WASM contracts, suitable for ledger enforcement.
- Config backend: emit K8s CRDs and SDN ACLs for `no internet → actuator` policies.

## Toolchain
- `aln-cli` — CLI for parse, validate, codegen and formatting.
- `aln-lsp` — TODO: LSP server for IDE integration.

## Examples & Stdlib
- Standard library (aln-stdlib) contains Bio‑Aug core typedefs and policies.
- Example ALN files under `aln-examples/` include `AU.BioMesh.NetEnvelope.v1.aln`.

## Versioning
- ALN-CORE x.y for language core releases.
- ALN-BIOAUG x.y for Bio‑Aug standard pack releases.
- Project spec tags: `AU.*.vN`.

## Signing & Provenance
- Use `tools/signer-rs` to sign canonical ALN (aln fmt output) and verify signatures.
- CI enforces that ALN core and high-impact ALN specs are validated, signed, and present in the public policy registry before merge.

## BioAugClinical profile (Regulatory alignment)

- BioAugClinical validation targets **IEC 62304 Class C** safety level for ALN artifacts that can influence actuation or invasive sensing. Such artifacts must include:
	- `traceability` blocks linking policies/guards to `hazard_id`, `iso14971_clause`, `iec62304_class`, and `rationale`.
	- Signed ALN sidecar signatures for CLINICAL_POLICY and SECURITY_POLICY using HSM-backed keys.
	- Simulation proof artifacts that demonstrate the policy's mitigation of the hazard.

These constraints are enforced in CI and through `aln-cli validate --profile bioaug-clinical`.
Note: `aln-cli` will try to call the repository-local signer CLI at `tools/signer-rs/target/release/signer-rs` to verify sidecar signatures using the CI-root public key `ci/keys/bgc_root.pub`. In CI, the `scripts/verify_aln_signatures.sh` script validates both CLINICAL_POLICY and SECURITY_POLICY signatures.

Sidecar signing behavior: the `signer-rs` tool appends signatures into a multi-record sidecar JSON (`.sig.json`) under the `signatures` array. Each signature entry includes `profile`, `signer`, `hash`, `signature`, and a `timestamp`. To overwrite a prior signature for the same profile, use `--force` when signing.

Example traceability block required for any actuation/implant/invasive policy:

```aln
policy emergency_stop {
	// ... guard/conditions here
	traceability {
		hazard_id: "HAZ-001";
		iso14971_clause: "5.2.1";
		iec62304_class: "C";
		rationale: "Stop actuator if perfusion levels exceed safe bounds";
	}
}
```

---

For the full design, consult the `aln-syntax`, `aln-check`, `aln-codegen`, and `aln-cli` crates in this repository and review the CI workflow for automated validation and codegen.
