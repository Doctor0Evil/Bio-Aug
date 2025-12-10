# HSM/PKCS#11 Integration (TODO)

- Implement SoftHSM support for CI with the following steps:
 - Implement SoftHSM support for CI with the following steps:
  - Use `gnutls`/`SoftHSM` container or action to provide a PKCS#11 provider in CI.
  - Update `tools/signer-rs` to support `--keyref hsm://<slot>/<label>` and use `cryptoki` crate or `pkcs11` for signing and verification in HSM.
  - Add an optional `--trust-root` configuration to verification to check proofs against a chain-of-custody resolver.

- Tests & gating:
  - Provide an integration test harness that signs policies using SoftHSM and verifies them using the public key exported from SoftHSM.
  - Ensure HSM operations are used in production and simulators only use dev keys.

- Docs & governance:
  - Document key generation, rotation, and emergency key rollover steps.
  - Provide a secure path for signing in a production environment (HSM-backed) with audit trail.
 - Concrete plan:
   1. Add a job to the `bioaug_clinical_ci.yml` which spins up `softHSM` (container or action) and initializes a token+slot.
   2. Add `cryptoki`/`tokio-pkcs11` to `tools/signer-rs` as an optional feature flag to use HSM signing.
   3. Test the signing flow in CI: the job should generate a CSR, load keys to SoftHSM, sign a sample ALN, export public key and verify signature using verifier code path.
   4. Add gating: require signature from `production` HSM slot for merging branch `main` into `release/production`.
