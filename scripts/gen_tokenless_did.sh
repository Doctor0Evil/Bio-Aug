#!/usr/bin/env bash
set -e
# Tokenless DID generator:
# - No GitHub secrets, no tokens; uses local dev key material and content hashes.
# - DID format: did:bioaug:<ALG>:<CONTENT_HASH>
# - Designed for staging/non-production and HSM-backed production when wired.

ALG='sha256'

# Input: path to artefact (e.g., class C tarball or ALN bundle)
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <artifact-path>" >&2
  exit 1
fi

ARTIFACT="$1"
if [ ! -f "$ARTIFACT" ]; then
  echo "ERROR: Artifact not found: $ARTIFACT" >&2
  exit 1
fi

# Compute content hash (hex).
HASH=$(openssl dgst -$ALG -r "$ARTIFACT" | awk '{print $1}')
DID="did:bioaug:$ALG:$HASH"

# Try to extract public key JWK from signer-rs if available
PUBKEY_X='REPLACE_WITH_PUBKEY_BASE64URL'
# Look for typical dev pubkey locations or an explicit env var SIGNER_PUBKEY
PUBKEY_PATH="${SIGNER_PUBKEY:-}"
if [ -z "${PUBKEY_PATH}" ] && [ -f "bioaug-clinical/ci/dev/dev_pub.key" ]; then
  PUBKEY_PATH="bioaug-clinical/ci/dev/dev_pub.key"
fi
if [ -z "${PUBKEY_PATH}" ] && [ -f "ci/keys/dev_pub.key" ]; then
  PUBKEY_PATH="ci/keys/dev_pub.key"
fi
if [ -n "${PUBKEY_PATH}" ] && [ -x "tools/signer-rs/target/release/signer-rs" ]; then
  echo "Using signer-rs to export JWK from $PUBKEY_PATH"
  JWK_OUT="$(tools/signer-rs/target/release/signer-rs export-jwk "$PUBKEY_PATH" 2>/dev/null || true)"
  if [ -n "${JWK_OUT}" ]; then
    X_VAL=$(echo "${JWK_OUT}" | tr -d ' \n' | sed 's/.*"x":"//;s/".*//') || true
    if [ -n "${X_VAL}" ]; then
      PUBKEY_X="${X_VAL}"
    fi
  fi
fi

# Emit DID document (minimal, JSON).
DOC_PATH="bioaug-clinical/build/out/$(basename "$ARTIFACT").did.json"
mkdir -p "$(dirname "$DOC_PATH")"
cat > "$DOC_PATH" <<JSON
{
  "id": "$DID",
  "verificationMethod": [
    {
      "id": "$DID#key-1",
      "type": "Ed25519VerificationKey2020",
      "controller": "$DID",
      "publicKeyJwk": {
        "kty": "OKP",
        "crv": "Ed25519",
        "x": "$PUBKEY_X"
      }
    }
  ],
  "assertionMethod": ["$DID#key-1"]
}
JSON

echo "DID generated: $DID"
echo "DID document: $DOC_PATH"
