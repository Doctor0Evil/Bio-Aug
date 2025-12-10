#!/usr/bin/env bash
# Simple policy bundle verification script (placeholder).
# Usage: ./scripts/verify_policy_bundle.sh <bundle_yaml>
set -euo pipefail

BUNDLE=${1:-}
if [[ -z "${BUNDLE}" ]]; then
  echo "Usage: $0 <bundle_yaml>"; exit 2
fi

if [[ ! -f "${BUNDLE}" ]]; then
  echo "Bundle file not found: ${BUNDLE}"; exit 2
fi

# Check signatures present and required fields
# If signer CLI exists, prefer it for signature verification
if [[ -x "tools/signer-rs/target/release/signer-rs" ]]; then
  tools/signer-rs/target/release/signer-rs verify --input "${BUNDLE}" --keyref ci/keys/bgc_root.pub --expect-profile CLINICAL_POLICY || { echo "signature verification failed for ${BUNDLE}"; exit 1; }
  tools/signer-rs/target/release/signer-rs verify --input "${BUNDLE}" --keyref ci/keys/bgc_root.pub --expect-profile SECURITY_POLICY || { echo "security signature verification failed for ${BUNDLE}"; exit 1; }
  echo "Bundle ${BUNDLE} verified by signer CLI.";
  exit 0
fi

if ! grep -q "signatures:" "${BUNDLE}"; then
  echo "Missing signatures block in ${BUNDLE}"; exit 1
fi
if ! grep -q "aln_hash:" "${BUNDLE}"; then
  echo "Missing aln_hash in ${BUNDLE}"; exit 1
fi

# Optionally verify the ALN hash if ALN file is available in the bundle metadata
ALN_HASH=$(yq e '.aln_hash' ${BUNDLE} 2>/dev/null || true)
if [[ -n "${ALN_HASH}" ]] && [[ "${ALN_HASH}" != "null" ]]; then
  echo "Bundle indicates aln_hash: ${ALN_HASH}"
  # Nothing else here; HSM/PKI verification must be performed by a platform-specific tool.
fi

echo "Bundle ${BUNDLE} basic verification succeeded (signature presence and fields)."
exit 0
