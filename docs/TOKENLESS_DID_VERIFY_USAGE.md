# Tokenless DID Verification

- Generate: `scripts/run_finishing_touch_with_did.sh`
- Verify: `scripts/verify_tokenless_did.sh <artifact> <artifact.did.json>`
- CI: `scripts/run_finishing_touch_with_did_and_verify.sh` wired into release workflow.

Notes:
- The DID verifier performs a content-hash comparison (sha256) and checks the `id` field in the DID doc matches `did:bioaug:sha256:<hash>`.
- For production, the DID doc should be populated with actual `publicKeyJwk` values from a trusted signer or HSM.
