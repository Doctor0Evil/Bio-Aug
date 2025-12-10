# ALN Portable Linter (No Package Manager Required)

  - Existing `aln` binary in `./aln-cli/target/release/aln`, `./aln`, or in `PATH`.
 - Note: The linter supports `--auto-build` which builds `aln` from `aln-cli` when no `aln` binary is found.
 - `./bioaug-clinical/tools/aln_portable_lint.sh --auto-build`
  - Wired into `bioaug-clinical/.github/workflows/bioaug_clinical_ci.yml` via `ci/aln_and_docs_gate.sh`.

Notes & Troubleshooting
