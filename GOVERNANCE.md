# Bio‑Aug Governance

This document defines the governance model for Bio‑Aug policy bundles, signing procedures, and the Bio‑Aug Governance Council (BGC).

## Bio‑Aug Governance Council (BGC)

The BGC is the project’s policy and audit authority. Minimum required roles:

- Clinician Lead (MD/PhD) — reviews & signs clinical policy bundles.
- Regulatory/Ethics Lead — reviews conformance to jurisdictional guidance and ethics considerations.
- Security Lead — reviews security, telemetry, and networked behavior.
- Core Maintainer — oversees repository integrity, signature trust chain, and operations.

Additional stakeholder delegates can be appointed from patient advocates, device manufacturers, and independent auditors.

## Policy Bundle Lifecycle

Policy bundles are versioned, signed configurations that include ALN specs and supporting artifacts. Lifecycle states:

- DRAFT: Development stage in the PR — not signed nor accepted.
- REVIEW: Submitted for formal review by BGC; automated CI gating is required.
- APPROVED: Signed by required signers (see signing matrix); publishable to the public policy registry.
- DEPRECATED: A previously approved bundle that is no longer recommended. A replacement must be identified.
- REVOKED: A previously signed bundle that has been invalidated due to safety or legal issues; requires full audit and revocation reason.

All bundles should contain a `metadata.yaml` including:

```
version: 1.0.0
bundle_id: bgp-0001
aln_hash: <sha256>
issuer: <organization-or-operator-did>
issued_at: 2025-12-10T00:00:00Z
signatures:
  - type: CLINICAL_POLICY
    signer: did:example:clinician1
    sig: <base64sig>
  - type: SECURITY_POLICY
    signer: did:example:security1
    sig: <base64sig>
```

## HSM-Backed Keys

HSM-backed keys ensure strong, auditable policy authority. Keys and their roles:

- BGC_ROOT
  - Used for framework-level rules. (Top-level trust anchor, rarely rotated, multi-party storage recommended.)

- CLINICAL_POLICY
  - Used for clinical actuation policies, BCI profile bindings, and digital twin changes affecting clinical safety.

- SECURITY_POLICY
  - Used for security-sensitive policies (networking, telemetry, update paths).

Key management guidance:
- Keys should be created, stored and operated by hardware security modules (HSMs) or secure elements (YubiHSM, AWS CloudHSM, Azure Key Vault HSM, or similar) under governance control.
- Keys must be rotated on schedule or on compromise; policy bundles signed with a revoked key should be marked as REVOKED.

## Signing Requirements

- Every high-impact ALN change — defined as any change to implants, actuators, tokenization logic, or direct HITL actuation rules — MUST be signed by both CLINICAL_POLICY and SECURITY_POLICY keys.
- For non-high-impact ALN changes (e.g., telemetry-only changes, visualization-only additions), a CLINICAL or SECURITY signature may be sufficient depending on the nature of the change; the default gating requires at least one of the signing keys.

## Public Policy Registry

- A publicly viewable registry of approved bundles should be published and maintained with a cryptographic hash for each bundle, its version, signatures, and revocation status.
- This registry provides auditors and regulators a single source of truth for the widely-deployed policy bundles.

## Decision Processes

- Normal Changes: The BGC indicates a review period. A quorum (at least 3 of the 4 minimum roles) is required, and a majority vote is sufficient for approval.
- Emergency Lockdown: If a severe safety or security event occurs, any two of the following (Clinician, Security, Regulator delegate) can trigger the global failsafe mode:
  - Read‑only mode for data streams.
  - Disable actuation.
  - Increase audit sampling and export forensic logs.

All governance actions should be recorded with transparent rationale, linked to PRs and simulation evidence.

## Branch Protection & CI Gating (Repository Settings)

- Protected branches: `main`, `release/*`.
- Required status checks:
  - CI: `lint`, `no-python-kernel`, `policy-bundle-verify`, `simulation-smoke` (if present).
  - All status checks must pass for merges into protected branches.
- Required approvals:
  - Two approvers required for any PR touching `aln/`, `core/`, `bci/`, `policy_bundles/`, `kernel/`, `drivers/` — at least one must be a Core Maintainer, and one must be a Clinical Reviewer or Security Reviewer depending on the change.
- Merge protection:
  - No force-pushes or deletion on protected branches.
  - Enforce linear history via `rebase` or `squash and merge` only.

These rules should be enforced via repo settings and automation upfront. The BGC may add exceptions for hotfixes that simultaneously require emergency lockdown procedures (see Emergency Lockdown above).

## Audits & Forensics

- All trusting decisions, signature metadata, and artifact proofs are preserved in an append-only ledger or immutable datastore (e.g., a ledger or Merkle-backed store) so reviewers, regulators, and auditors can verify the integrity of decisions.

## Appeals & Revocation

- Parties may appeal for re-evaluation of a revoked or deprecated bundle through the BGC Appeals board. Revocations must specify technical and clinical rationale for revocation.

---

## Contact Points

- `governance@bio-aug.org` — BGC secretariat (example address; for real systems use governance channels defined in the repository).
- `security@bio-aug.org` — Security issues and incident reports.
- `clinical@bio-aug.org` — Clinical review and medical oversight issues.

Security contact for responsible disclosure is stored in the `SECURITY_CONTACT` file and the PGP public key is available as `SECURITY_PGP_KEY.asc`. For urgent incidents, the BGC should follow the emergency lockdown procedure and notify the security contact.

---

This governance document is a minimum viable governance plan for the repository and should be adapted as the project scales and as working groups define further committee and subcommittee structures.
