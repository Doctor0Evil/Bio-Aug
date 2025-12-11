# Bio‑Aug Security Policy

This document defines the scope, reporting process, and expectations for responsible disclosure of security vulnerabilities related to the Bio‑Aug project.

## Scope

In‑scope items include but are not limited to:

- Code paths for the safety kernel, device drivers, and any hardware-adjacent Rust or Go modules that could affect actuation or sensor readings.
- ALN policy compilation and enforcement logic that can change device behavior.
- Policy bundle signing and verification mechanisms, including HSM integrations.
- Telemetry forwarding and EHR integration code that may leak or corrupt telemetry.
- Any middleware that has access to kernel-level policy decisions or actuation requests.

Out-of-scope:

- Forks and third-party customizations not using the main upstream policy bundles.
- Content-only documentation mistakes that are purely stylistic and do not impact security.

## Security Contact

To report a security vulnerability, please contact us via:

security-contact: security@bioaug-foundation.org
PGP public key: https://keys.openpgp.org/vks/v1/by-fingerprint/ABCDEF1234567890

If you prefer to use an encrypted channel for sensitive details, please encrypt information using our PGP key and send it to the same email address (PGP public key will be published in this repo as `SECURITY_PGP_KEY.asc`).

## Reporting Process

1. Send an initial email to `security@bioaug-foundation.org` with a concise subject line and a short description of the vulnerability, including reproduction steps and impacted components.
2. Include a sanitized, non‑patient dataset or deterministic simulation harness seed that allows us to reproduce the issue.
3. If you suspect immediate patient harm or an actively exploited vulnerability, mark the email `URGENT` and call the designated security number in the governance directory (see `GOVERNANCE.md`).

## Response Timeline

- Acknowledgement within **3 business days**.
- Initial triage and assignment within **7 business days**.
- Coordinated disclosure or mitigation timeline depends on severity (e.g., **critical** severity aims for 30‑90 days coordinated disclosure).

## Vulnerability Categories & Severity

We use a simplified severity model for triage:

- Critical: RCE or immediate physical harm, bypass of HITL, silent actuator triggers.
- High: Sensitive telemetry leakage or policy-bundle forgery enabling policy change.
- Medium: DoS or degraded operation that impacts safety observability.
- Low: Minor information leakage or non-security documentation issues.

## Disclosure Guidelines

- Do not publicly disclose the vulnerability until the maintainers have provided coordinated disclosure details.
- We will work with the reporter to set an appropriate disclosure timeline and possibly coordinate with affected vendors and regulators.

## Rewards and Recognition

We currently do not operate a formal bug bounty program. We will acknowledge and credit reporters who follow the responsible disclosure process, subject to safe and lawful practices.

---

This policy will be reviewed periodically and improved based on real-world incidents and governance decisions.