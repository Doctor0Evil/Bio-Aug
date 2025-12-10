# Contributing to Bio‑Aug

Welcome — thank you for taking part in the Bio‑Aug research and reference repository. This document defines a policy-first contribution workflow focused on safety, rights, and regulatory compliance.

## Contributor Roles

- Core Maintainer
  - Responsibilities: stewarding the repository, merging approved policy bundles, verifying formal proofs and critical CI gates.
  - Privileges: create and sign framework-level policy bundles; assign reviewers; manage governance tasks.
- Clinical Reviewer
  - Responsibilities: review any changes affecting clinical behavior, actuation, or patient-facing decisions.
  - Privileges: vote on clinical policy approvals; request simulation and clinical proof.
- Security Reviewer
  - Responsibilities: ensure the security aspects (network, firmware, telemetry) comply with the repository’s lifecycle policies (IEC 62304, ISO 14971, NIST, etc.).
  - Privileges: vote on security policy approvals; request additional threat modeling.
- External Contributor
  - Responsibilities: provide code, policies, ALN files, supporting simulations, and run CI tests.
  - Privileges: propose changes through PRs following the workflow below.

## Required Artifacts for ALN Policy Changes

Any change that modifies an ALN policy (ALN file), ALN semantics, or references to device actuation must include these artifacts in the PR:

1. Updated ALN spec file(s) under `aln_specs/` with clear, inline comments for mapping to runtime enforcement modules.
2. Threat/Risk Notes: a short section referencing at least the following standards and guidance as applicable:
   - IEC 62304 (software lifecycle + security), ISO 14971 (risk management), ISO 10993 (biocompatibility)
   - Current medical cybersecurity guidance for the relevant jurisdictions (e.g., FDA postmarket cybersecurity guidance, MDCG, TGA, PMDA)
3. Simulation Test Plan proof: A documented, reproducible simulation plan with deterministic seeds and scenarios that validate the changes in a twin environment. Sandbox and clinical profiles must be included (Unreal/Unity/Godot compatible inputs or instructions).
4. Signed Policy Bundle (see `GOVERNANCE.md` for signature and signing process): a compiled policy bundle in `policy_bundles/` along with the signed metadata.

## Mandatory Rules (CI-enforced)

- No Python in any safety kernel or device‑adjacent path. The CI pipeline will reject changes that add `.py` files into `core/`, `bci/`, `kernel/`, `drivers/`, or other device-adjacent paths.
- All device and telemetry work should use IEEE 11073 and HL7 FHIR mappings where applicable; provide clear mapping docs in the PR and a `mapping.md` where appropriate.
- Simulation-first before enabling actuation: Any policy change that relaxes a safety constraint or expands the actuation domain must pass the simulation acceptance criteria in `CI` (see `IMPLEMENTATION_GUIDE.md`).

## Contribution Workflow

1. Fork the repo.
2. Create a feature branch for your work (format: `feat/<short>-description`).
3. Add ALN + Rust/Go runtime changes in your branch.
4. Add supporting docs: threat/risk notes, simulation plan, test scenarios, sample payloads, and a compiled policy bundle in `policy_bundles/`.
5. Submit a PR with a concise description of changes and links to simulation artifacts and the `policy_bundles/` signed metadata.
6. The PR must be reviewed by two reviewers:
   - At least one technical reviewer (Core Maintainer or Developer).
   - At least one Clinical or Security Reviewer, depending on the change.
7. The PR must pass CI gates (format, linting, code tests, ALN policy verification, no-Python checks, bundle-signature verification, simulation acceptance tests).
  - Run `aln-cli validate <file>` for any changed ALN files.
  - For ALN files that affect actuation or implants, the PR must additionally:
    - include `traceability` metadata blocks on any policy/guard that affects actuation (hazard_id, iec62304_class, rationale),
    - add ALN sidecar signatures (`.sig.json`) verifying CLINICAL_POLICY and SECURITY_POLICY sign-offs,
    - provide simulation proofs and CI scenario pass artifacts linked in the PR.
8. On approval, add signed policy bundle(s) attached to the PR. Core Maintainers can merge into `main` after signatures and the two-reviewer approvals are present.

Signing policy bundles: Use the `tools/signer-rs` CLI to sign bundles before attaching them to PRs.
Example:
```
tools/signer-rs/target/release/signer-rs sign --input policy_bundles/<file>.yaml --profile CLINICAL_POLICY --keyref hsm://slot:1 --output policy_bundles/<file>.signed.yaml
```
CI verifies signatures using the public key in `ci/keys/`.

ALN validation: Any changes to `aln_specs/` must pass ALN invariant checks. Use `scripts/validate_aln_mesh.sh` to ensure that networked mesh semantics are preserved (no ip-stack, hop-count == 1, remote_exec_cap == 0, required guard flags in place). This check runs automatically in CI and via pre-commit hooks.

## Security and Confidentiality

- Do not share confidential clinical or patient data in PRs.
- All telemetry examples should be de-identified or simulated.
- Any data that cannot be released must be replaced by a reproducible simulator seed and a description of the deterministic inputs used for verification.

## How to Report Security or Safety Issues

- Use the repository’s security policy (see `SECURITY.md`, or create an issue marked `security` if none exists).
- For urgent safety vulnerabilities affecting early prototypes or demos, contact the Security Reviewer(s) and a Core Maintainer directly using the governance channel (see `GOVERNANCE.md`).

---

Contributors help us improve safety and patient rights — thank you for participating respectfully and responsibly.
