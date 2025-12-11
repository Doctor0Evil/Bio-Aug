# BioAug Biomech Augmentation Reference Pack

This folder contains a public reference ALN profile package for biomechanical augmentation safety-focused research and development.

Files:
- `AU.BioAug.BiomechCore.v1.aln` — core safety invariants for limb interface and sensor fusion
- `AU.BioAug.BiomechICU.v1.aln` — ICU overlay and fail-safe invariants for ICU settings
- `AU.BioAug.BiomechGuards.v1.aln` — ALN guard bindings to runtime guard functions
- `biomech_reference_manifest.json` — manifest describing the profiles and intended uses
- `generate_guard.sh` — helper script to generate Rust guard module from ALN using `aln` CLI

Usage:
1. Build `aln-cli` and `aln-guard-codegen` in the workspace with `cargo build`.
2. Generate guard module using `./tools/find_aln.sh` or with `./target/release/aln`:
   ```bash
   ALN_BIN=$(./tools/find_aln.sh)
   "$ALN_BIN" GuardCodegen aln-reference/biomech-augmentation/AU.BioAug.BiomechGuards.v1.aln --module bioaug_biomech_guards --out generated/biomech/bioaug_biomech_guards.rs
   ```
3. For CI: workflow `bioaug_biomech_reference.yml` regenerates, builds and tests the guard crate and signs the artifact with dev keys.

Citation identifiers (use in papers):
- `AU.BioAug.BiomechCore.v1`
- `AU.BioAug.BiomechICU.v1`
- `AU.BioAug.BiomechGuards.v1`

This pack is intended for public reference, research, and preclinical testing. Not an approved medical product.
