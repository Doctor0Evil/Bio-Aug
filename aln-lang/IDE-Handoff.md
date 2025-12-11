# ALN Toolchain IDE Handoff

This document explains the ALN toolchain architecture and steps for an IDE team to implement a full-featured language ecosystem (parser, checker, codegen, LSP, integration with CI and HSM signing).

## Overview
The repository provides scaffolding for a formal ALN grammar, a parser, a semantic checker (bio‑aug rule profiles), code generation backends, and a CLI. The IDE team should deliver:

- A complete grammar (Pest/LALRPOP or Chumsky) with high coverage for ALN constructs.
- A robust AST with spans and types for IDE features.
- A comprehensive `aln-check` implemented as a library that runs domain-specific safety checks.
- Code generation backends that compile ALN specs into Rust code and WASM contracts.
- An LSP server that integrates with the `aln-cli` and provides diagnostics, formatting, and go‑to definition.
- Integration with the `tools/signer-rs` for ALN signing and verification.

## Priorities & Workflow
1. Stabilize grammar and AST: Complete `aln-syntax/aln.pest` to cover all ALN constructs used across Biomech and Digest pipeline specs.
2. Expand `aln-check` with Name resolution and Bio‑Aug safety rules:
   - `no_internet_to_actuators`
   - `read_only_sense_mesh`
   - `policy` well-formedness
3. Build codegen outputs (Rust first): transform ALN decls and policy blocks into typed Rust code with policy-checking stubs.
4. LSP work (editor experience): syntax highlighting, diagnostics, and go-to; implement `aln-lsp` server.
5. Integrate codegen outputs and validation into CI, enabling codegen tests (compile and run minimal policy-checks).

## Tasks for IDE Team
- Create `aln-syntax` grammar unit tests for every ALN example (include the BioMesh spec and Digest Pipeline specs).
- Implement round-trip pretty-printing and `aln fmt` functionality in `aln-cli`.
- Integrate `aln-check` into `aln-cli` with support for different validation profiles.
- Implement `aln-lsp` with full LSP features, package as a VS Code extension and ensure that the extension uses `aln-cli` for diagnostics.
- Implement editor snippets and sample templates for Bio‑Aug policies and macros.

## Tests and CI
- The CI job `aln-tooling` must run parse/validate/codegen on `aln-examples/` and ensure the generated Rust code compiles.
- For `aln-check` add golden tests (annotated ALN files and expected diagnostics) and property tests.

## Security and Signing
- Integrate `tools/signer-rs` to sign canonicalized ALN; build `aln hash` to compute canonical digest and `signer-rs` for signature operations.
- Add `aln-cli` commands `aln sign` and `aln verify` that delegate to signing CLI or directly call HSM APIs.

## Deliverables
- Completed grammar `aln-syntax/aln.pest` and EBNF `aln-syntax/aln.ebnf`.
- Parser library with robust AST (`aln-syntax/src/ast.rs`).
- `aln-check` rules and profiles with tests.
- `aln-codegen` rust backend for policy/stub generation and example WASM stubs.
- `aln-cli` with parse/validate/codegen/hash commands, used in CI.
- `aln-lsp` server and VS Code extension with syntax/diagnostics/goto functionality.

## Notes & Constraints
- Follow the no‑Python rule for kernel or device-adjacent tools — server-side and dev tooling may utilize other languages (Rust/Go/TS) but keep production kernel code in Rust.
- Preserve ALN invariants and guard checks in codegen to ensure compile-time enforcement when possible.
- Code must be documented and signed where relevant; include `aln hash` and `aln sign` as part of the release process.

---

This handoff should provide the IDE and language team with a pragmatic path to making ALN a robust, production-ready domain-specific language for Bio‑Aug integrations and tooling.