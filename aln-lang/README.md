# ALN Toolchain (Bio‑Aug)

This workspace contains the ALN language toolchain for Bio‑Aug. It includes:

- `aln-syntax`: grammar and parser (pest) and a minimal AST.
- `aln-check`: semantic checker and Bio‑Aug rule profiles.
- `aln-codegen`: code generation backends for Rust, WASM, and config.
- `aln-cli`: CLI to parse, validate, format, hash and codegen ALN files.
- `aln-stdlib`: Bio‑Aug standard ALN packs.
- `aln-examples`: example ALN files (BioMesh, Digest Pipeline).

## Getting started (developer)

1. Install Rust toolchain (stable).
2. Build the workspace:

```bash
cd aln-syntax
cargo build --release
cd ../aln-cli
cargo build --release
```

3. Parse/validate an example:

```bash
aln-cli/target/release/aln parse aln-examples/AU.BioMesh.NetEnvelope.v1.aln
aln-cli/target/release/aln validate aln-examples/AU.BioMesh.NetEnvelope.v1.aln --profile bioaug-clinical
```

4. Use codegen to generate Rust stubs (placeholder):

```bash
mkdir -p aln-cli/generated
aln-cli/target/release/aln codegen aln-examples/AU.BioMesh.NetEnvelope.v1.aln --target rust --out aln-cli/generated
```

## Next steps
- Expand `aln-syntax` grammar to fully cover ALN (policy, guard, mapping, macros, block structures, annotations).
- Add full AST builder and round-trip printing.
- Implement semantic checks and Bio‑Aug rule presets in `aln-check`.
- Implement backends in `aln-codegen` for Rust and WASM.
- Implement LSP server for ALN and integrate with VS Code.
- Implement signature checks for ALN sources using `tools/signer-rs`.

---

This workspace provides the skeleton of the ALN toolchain; it is intentionally minimal for initial bootstrapping and CI integration. Contribute by enhancing grammar coverage, adding tests, and improving codegen mapping fidelity.
