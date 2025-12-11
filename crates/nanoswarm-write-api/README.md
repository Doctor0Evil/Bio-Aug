# Nanoswarm Write API (crates/nanoswarm-write-api)

This crate provides a minimal scaffolding for a Nanoswarm write API used by
BioAug research projects. It includes:

- ALN-backed domain models (in `domain::models`) — currently a simple `NanoswarmWrite` struct
- Guard scaffolding (in `domain::guards`) — default implementations that the
  `aln-guard-codegen` will replace or augment
- Minimal service code in `service::router` and `service::executor`
- Simple in-memory `TestWriter` implementation used by tests (simulates nanoswarm writes)

How to build & test

```bash
cd crates/nanoswarm-write-api
cargo test
```

Notes

- When the generator `aln-guard-codegen` generates a typed guard module, it will be placeable in `src/generated` and included by `domain::guards`.
- The current module provides fallback guard implementations so the crate compiles even if the generated code is absent.
