# aln-syntax

This crate contains the ALN grammar and parser for the Bio‑Aug project.

- Grammar: `aln.pest` (PEG) and `aln.ebnf` (sketch EBNF).
- Parser: `pest`-based parser implemented in `src/lib.rs`.
- AST: `src/ast.rs` minimal types; extend for full ALN AST.

To run tests and build:

```bash
cd aln-syntax
cargo build --release
cargo test
```

Add additional AST types and comprehensive tests (round-trip tests, golden files) as you extend the grammar.
