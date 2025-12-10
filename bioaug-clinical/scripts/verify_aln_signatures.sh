#!/usr/bin/env bash
set -euo pipefail
KEYREF_DEV="bioaug-clinical/ci/dev/dev_pub.key"
KEYREF_CI="ci/keys/bgc_root.pub"
TOOLS_SIGNER="tools/signer-rs/target/release/signer-rs"
ERROR=0
if [[ ! -f "$TOOLS_SIGNER" ]]; then
  echo "building signer..."; (cd tools/signer-rs && cargo build --release)
fi
if [[ ! -f "$KEYREF" ]]; then
  echo "Dev public key not found, generating dev keys..."; ./bioaug-clinical/scripts/gen_dev_keys.sh bioaug-clinical/ci/dev
fi
for f in bioaug-clinical/policies/*.aln; do
  content=$(tr '[:upper:]' '[:lower:]' < "$f")
  if echo "$content" | grep -q "actuat\|implant\|invasive\|ai\|agent\|critical_service"; then
    echo "Verifying signatures for $f";
    if ! "$TOOLS_SIGNER" verify --input "$f" --keyref "$KEYREF_DEV" --expect-profile CLINICAL_POLICY ; then
      # fallback to CI keyref if present
      if [[ -f "$KEYREF_CI" ]]; then
        if ! "$TOOLS_SIGNER" verify --input "$f" --keyref "$KEYREF_CI" --expect-profile CLINICAL_POLICY ; then
          echo "CLINICAL_POLICY verify failed for $f"; ERROR=1; continue
        fi
      else
        echo "CLINICAL_POLICY verify failed for $f (dev & ci verification failed)"; ERROR=1; continue
      fi
    fi
      echo "CLINICAL_POLICY verify failed for $f"; ERROR=1; continue
    fi
    if ! "$TOOLS_SIGNER" verify --input "$f" --keyref "$KEYREF_DEV" --expect-profile SECURITY_POLICY ; then
      if [[ -f "$KEYREF_CI" ]]; then
        if ! "$TOOLS_SIGNER" verify --input "$f" --keyref "$KEYREF_CI" --expect-profile SECURITY_POLICY ; then
          echo "SECURITY_POLICY verify failed for $f"; ERROR=1; continue
        fi
      else
        echo "SECURITY_POLICY verify failed for $f (dev & ci verification failed)"; ERROR=1; continue
      fi
    fi
      echo "SECURITY_POLICY verify failed for $f"; ERROR=1; continue
    fi
    echo "Verified: $f";
  fi
done
if [[ "$ERROR" -eq 1 ]]; then
  echo "ALN signature verification failed"; exit 2
fi
echo "All ALN signature checks passed"
#!/usr/bin/env bash
set -euo pipefail
PROFILE="bioaug-clinical"
if [[ "$#" -gt 0 ]]; then
echo "args: $@"
fi
# Simple placeholder: ensure all .aln files in policies/contain dpia true for class C and have sidecar
FAIL=0
for f in bioaug-clinical/policies/*.aln; do
  content=$(cat "$f")
  # check dpia true
  if ! echo "$content" | grep -q "dpia\s*=\s*true"; then
    echo "Missing dpia in $f"; FAIL=1;
  fi
  # sidecar check: file.sig.json exists
  if [[ -f "${f%.aln}.sig.json" ]]; then
    echo "Found sidecar for $f";
  else
    echo "Missing sidecar for $f"; FAIL=1;
  fi
done
if [[ $FAIL -ne 0 ]]; then
  echo "Signature checks failed"; exit 2
fi

echo "Signature checks passed"
