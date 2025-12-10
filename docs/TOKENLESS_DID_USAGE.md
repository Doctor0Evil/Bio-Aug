# Tokenless DID for Bio-Aug Class C Artefacts

- Purpose: avoid GitHub secrets for basic artefact identity; use content-addressed IDs (sha256) and local key material.
- DID format: `did:bioaug:<ALG>:<CONTENT_HASH>`
- Scripts:
  - `scripts/gen_tokenless_did.sh <artifact-path>`
  - `scripts/run_finishing_touch_with_did.sh`  (runs full pipeline + DID generation)
- Notes:
  - Public key placeholder in DID document must be replaced with real Ed25519 JWK when keys are provisioned.
  - For HSM-backed production, `signer-rs` should output the verification key, which can populate the DID document automatically.
  - This approach provides content-addressed binding independent of GitHub tokens; for production, integrate HSM-based key management and signer with hardware-backed keys.
