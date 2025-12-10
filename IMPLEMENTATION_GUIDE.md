# Implementation Guide — Bio‑Aug

This guide provides concrete, implementation-driven steps for ALN policy development, policy bundle creation, signature verification and an example enforcement stub suitable for safe, no_std runtime kernels.

The artifacts in this guide are example, minimal implementations meant to accelerate integration with real systems and to demonstrate typical CI gating, signing, and simulation requirements. They are not production-ready — real deployments must use hardware security modules (HSMs), full CI, and verified kernel builds.

---

## Example ALN: BCI Anti‑Nausea Profile

File: `aln_specs/samples/bci_anti_nausea.aln`

```aln
object BCI.VagalComfortLoop.AntiNauseaProfile
  role "Vagal stimulation profile for anti-nausea rescue and preventive modes"
  constraints
    - read_mode_only true
    - physician_programmable_only true
    - HITL_override_required true
  stimulation_bounds
./scripts/verify_policy_bundle.sh policy_bundles/sample_bci_antinausia.yaml

# Sign a bundle using dev key (or HSM)
tools/signer-rs/target/release/signer-rs sign --input policy_bundles/sample_bci_antinausia.yaml --profile CLINICAL_POLICY --keyref dev/dev_pkcs8.key --output policy_bundles/sample_bci_antinausia.signed.yaml

# Verify the signed bundle
tools/signer-rs/target/release/signer-rs verify --input policy_bundles/sample_bci_antinausia.signed.yaml --keyref ci/keys/bgc_root.pub --expect-profile CLINICAL_POLICY

Note: The `signer-rs` CLI now appends or merges multiple signatures into a single `.sig.json` sidecar for ALN files and into a `signatures` top-level field for YAML bundles. Use `--force` to overwrite an existing signature for the same profile if necessary.

## Sim runner
# Build and run the sim harness
cd sim/runner
cargo build --release
cd -
sim/runner/target/release/sim-runner sim/scenarios/policy_bypass_attempt.json --policies policy_bundles

# Signing & CI helpers

To generate dev keys and sign policy ALN files for CI testing:

```bash
./bioaug-clinical/scripts/gen_dev_keys.sh bioaug-clinical/ci/dev
./bioaug-clinical/scripts/sign_all_policies.sh
```

## ALN parsing, validation and codegen
cd aln-cli && cargo build --release
./aln-cli/target/release/aln parse aln-examples/AU.BioMesh.NetEnvelope.v1.aln
./aln-cli/target/release/aln validate aln-examples/AU.BioMesh.NetEnvelope.v1.aln --profile bioaug-clinical
# Codegen (placeholder)
cd aln-cli && ./target/release/aln codegen rust --in aln-examples/AU.BioMesh.NetEnvelope.v1.aln --out generated
    pulse_width_us_range 50-250
    frequency_hz_range 5-25
  actuators
    - vagal_stim_channel
  policies
    - require ETHCORE.system.audit.enabled true
    - require CLINICAL_POLICY.signature present
    - require SECURITY_POLICY.signature present
  safety
    - log_all_sessions true
    - if nausea_score >= 7 then mode = "rescue" and require double_signature true
end
```

This profile shows an ALN snippet for an anti-nausea practice: read-only default, safety limits, HITL override requirement and signature checks.

---

## Sample Policy Bundle YAML format

File: `policy_bundles/sample_bci_antinausia.yaml`

```yaml
bundle_id: bgp-bci-anti-nausea-2025-0001
version: 0.1.0
aln_hash: >
  5ac6e1b0d9a809f1b7b0f... # SHA-256 of ALN file
issuer: did:example:clinic-001
issued_at: '2025-12-10T12:34:56Z'
metadata:
  description: "Anti‑nausea BCI VagalComfortLoop profile (rescue/preventive)"
signatures:
  - type: CLINICAL_POLICY
    signer: did:example:clinician-1
    sig: BEARER_BASE64_SIGNATURE_EXAMPLE
  - type: SECURITY_POLICY
    signer: did:example:security-1
    sig: BEARER_BASE64_SIGNATURE_EXAMPLE
deployment_targets:
  - mode: Mode.ClinicProcedure
    target: clinic-backend-1
  - mode: Mode.ResearchSandbox
    target: research-sandbox-1
```

The `signatures` field must include HSM-backed signatures per `GOVERNANCE.md`.

---

## Rust Enforcement Stub (no_std compatible)

File: `core/policy_enforcer/src/lib.rs`

This stub demonstrates a `no_std`-compatible Rust policy enforcer that verifies an HSM signature and evaluates actuation decisions.

```rust
#![no_std]
#![allow(unused)]

extern crate alloc;
use alloc::string::String;
use alloc::vec::Vec;
use core::result::Result;

pub enum Decision {
    Allow,
    Deny(&'static str),
}

pub struct ActuationParams {
    pub amplitude_mA: f32,
    pub pulse_width_us: u32,
    pub frequency_hz: f32,
}

pub struct ChannelPolicy {
    pub name: &'static str,
    pub allowed: bool,
    pub max_amplitude_mA: f32,
    pub max_pw_us: u32,
    pub max_freq_hz: f32,
    pub hitl_required: bool,

    `aln-cli` provides additional commands: `check-coverage`, `trace-export`, `trace-sign`, `zero-trust-validate`, and `validate` accepts `--require-dpia`, `--require-dos-guard`, `--fail-if-unverified-class-c`.
}

pub struct BundleMetadata {
    pub id: String,
    pub version: String,
    pub channels: Vec<ChannelPolicy>,
    pub signed_by_clinical: bool,
    pub signed_by_security: bool,
}

pub trait HsmVerifier {
    fn verify(&self, data_hash: &[u8], signature: &[u8]) -> bool;
}

pub struct PolicyEnforcer {
    bundle: BundleMetadata,
}

impl PolicyEnforcer {
    pub fn new(bundle: BundleMetadata) -> Self {
        PolicyEnforcer { bundle }
    }

    pub fn verify_bundle_signature(&self, _hsm: &dyn HsmVerifier, _sig_clin: &[u8], _sig_sec: &[u8]) -> bool {
        // In a production implementation, this calls into HSM APIs.
        // This stub will return true if both signatures are non-empty and flags present.
        self.bundle.signed_by_clinical && self.bundle.signed_by_security
    }

    pub fn can_actuate(&self, channel: &str, params: &ActuationParams, hitl_signed: bool) -> Decision {
        for ch in self.bundle.channels.iter() {
            if ch.name == channel {
                if !ch.allowed {
                    return Decision::Deny("channel not allowed");
                }

                if params.amplitude_mA > ch.max_amplitude_mA { return Decision::Deny("amplitude exceeds limit"); }
                if params.pulse_width_us > ch.max_pw_us { return Decision::Deny("pulse width exceeds limit"); }
                if params.frequency_hz > ch.max_freq_hz { return Decision::Deny("frequency exceeds limit"); }
                if ch.hitl_required && !hitl_signed { return Decision::Deny("HITL required but missing"); }
                return Decision::Allow;
            }
        }
        Decision::Deny("unknown channel")
    }
}
```

Notes:
- The real implementation would use a hardware-backed HSM API for signature verification and will probably live in a `no_std`-kernel context with a custom allocator.
- Policy parsing and loading should happen off-kernel where possible. Bundles can be parsed in a secure service and only the minimal verification data marshalled to the kernel.

---

## Example telemetry forwarding service (non-kernel, standard environment)

File: `services/telemetry_forwarder/main.go`

This is a minimal, illustrative service that receives device metrics in IEEE 11073-like structure and posts FHIR Observation resources. The kernel forwards telemetry only — conversion to FHIR and network posting must occur off-kernel.

```go
package main

import (
    "bytes"
    "encoding/json"
    "log"
    "net/http"
)

type Metric struct {
    DeviceID string  `json:"device_id"`
    Code     string  `json:"code"`
    Value    float64 `json:"value"`
    Unit     string  `json:"unit"`
    Time     string  `json:"time"`
}

func main() {
    // Example: convert a received Metric to a FHIR Observation and POST.
    metric := Metric{DeviceID: "dev-001", Code: "8480-6", Value: 98.6, Unit: "degF", Time: "2025-12-10T12:00:00Z"}
    fhirObs := map[string]interface{}{
        "resourceType": "Observation",
        "status": "final",
        "code": map[string]interface{}{ "coding": []map[string]interface{}{{"system": "http://loinc.org", "code": metric.Code}}},
        "valueQuantity": map[string]interface{}{"value": metric.Value, "unit": metric.Unit},
        "effectiveDateTime": metric.Time,
    }
    body, _ := json.Marshal(fhirObs)
    resp, err := http.Post("https://fhir.example.org/Observation", "application/json", bytes.NewReader(body))
    if err != nil { log.Fatalf("post fhir failed: %v", err) }
    defer resp.Body.Close()
    log.Printf("fhir response: %v", resp.Status)
}
```

This service demonstrates the separation between kernel policy enforcement and networked telemetry publication.

---

## CI Checks (Examples)

A sample GitHub Actions pipeline is included in `.github/workflows/ci.yml` (see the repo skeleton). The pipeline should include the following checks:

- `lint`: run `rustfmt`, `clippy`, `gofmt`, `golangci-lint`.
- `no-python-kernel`: run a check script to reject any `.py` files in kernel and device-adjacent paths.
- `policy-bundle-verify`: verify policy bundle signatures (shell wrapper that calls a bundle verification tool or HSM-based signature check).
 - `signatures`: verify ALN `.sig.json` sidecars and YAML bundle signatures for CLINICAL_POLICY and SECURITY_POLICY using `scripts/verify_aln_signatures.sh`.
- `simulate`: run simulation scenarios and/or run test harness that validates that no new actuation path is present.

Example script for rejecting Python in kernel paths:

```sh
# scripts/check_no_python.sh
for f in $(git diff --name-only origin/main...HEAD); do
  if [[ ${f} == core/* || ${f} == bci/* || ${f} == kernel/* || ${f} == drivers/* ]]; then
    if [[ ${f} == *.py ]]; then
      echo "Python files are not allowed in kernel/device-adjacent paths: $f"; exit 1
    fi
  fi
done
```

Add this as an early CI step. For security-critical projects, run this check both locally in pre-commit and in CI.

### DPIA / DoS / Zero-Trust CI gating
We provide an example CI workflow `.github/workflows/bioaug_clinical_dpia_dos.yml` that enforces `aln validate --profile bioaug-clinical --require-dpia --require-dos-guard` and signature checks. The pipeline runs `zero-trust` validation and enforces that all Class C policies have required traceability and `dpia: true` entries.


---

## Simulation Proof Requirements

PRs that alter ALN policies with potential affect on actuation MUST provide simulation proof artifacts. The acceptance criteria are:

1. Deterministic scenarios and seed.
2. Test results, logs, and a diff or summary listing. Example scenarios to include:
   - Healthy baseline digestion
   - High-risk profile (IBS-like, or post-op) with nausea risk index > 0.7
   - Network fault/reconnect simulation validating failsafe behavior
   - Alert storm & rate-limited telemetry scenario validating that notifications are deduplicated and not causing actuation
3. The simulation harness must link back to the ALN changes and policy bundle used to configure the twin.

---

## Example Commands for PR Authors

```bash
# Run static checks locally
./scripts/check_no_python.sh
cargo fmt --all
cargo clippy --all
gofmt -w ./services

golangci-lint run

# Verify policy bundle (example, replace with HSM tool)
./scripts/verify_policy_bundle.sh policy_bundles/sample_bci_antinausia.yaml

# Run basic simulation tests (placeholder, depends on your simengine)
./simulator/run --scenario healthy --policy policy_bundles/sample_bci_antinausia.yaml
./simulator/run --scenario high_load --policy policy_bundles/sample_bci_antinausia.yaml
```

---

## Summary

This guide provides a minimal, example pipeline for implementing ALN policy bundles with governance-backed signing, a `no_std` policy enforcer, and CI checks that ensure simulation evidence and signature verification are present for safety-critical changes. Adopt and adapt these examples for your specific CI environment, HSMs, and simulation toolchains.

If you’d like, I can generate the sample files referenced in this document (ALN sample, policy bundle YAML, Rust stub, Go telemetry forwarder, CI config) in the repository for an immediate starting point.
