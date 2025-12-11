# ALN Guard Codegen

This crate provides a code generator that converts ALN `policy` declarations into a Rust module with placeholder guard functions.

Usage (via `aln` CLI):

```
# Build the CLI
cargo build -p aln-cli --release

# Generate guard module from ALN file
./target/release/aln GuardCodegen path/to/policy.aln --module bioaug_guards --out generated/bioaug_guards.rs
```

The generated module contains `pub fn check_<policy_name>() -> bool` placeholders; replace `false` with real checks or wire into the runtime guard library.
