# Branch Protection: release/*

To ensure that Neuronano / Cyberneuro Class C release branches are non-bypassable, set the repository's branch protection rules in GitHub to require the `BioAugClinical-ClassC-Neuronano-Release` workflow check to pass before merging, and to block force pushes.

Example settings (GitHub UI):
- Protect matching branches: release/*
- Require status checks to pass before merging: enable and add `BioAugClinical-ClassC-Neuronano-Release`
- Require branches to be up-to-date with the base branch before merging: enabled
- Restrict who can push: optionally restrict to administrators/maintainers
- Require signed commits: optional for additional security

Updating these settings via cli or automation is out-of-scope for the ALN/Rust-only constraints, but is recommended for production use.
