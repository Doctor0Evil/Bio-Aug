#!/usr/bin/env bash
set -euo pipefail

KEYREF="ci/keys/bgc_root.pub"
FAIL=0
REQUIRE_CLINICAL=0
REQUIRE_SECURITY=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --require-clinical) REQUIRE_CLINICAL=1; shift;;
    --require-security) REQUIRE_SECURITY=1; shift;;
    --profile) PROFILE="$2"; shift 2;;
    --fail-on-missing) FAIL_ON_MISSING=1; shift;;
    *) shift;;
  esac
done

# Search ALN files in specified directories
DIRS=("aln-examples" "aln-stdlib" "aln_specs")
for d in "${DIRS[@]}"; do
  for f in ${d}/*.aln; do
    if [[ -f "$f" ]]; then
      echo "Checking $f for actuation traces";
      content=$(cat "$f" | tr '[:upper:]' '[:lower:]')
      if echo "$content" | grep -q "actuat\|implant\|invasive\|ai\|agent"; then
        echo "ALN file $f mentions actuate; require signature sidecar and verification";
        sigfile="${f%.aln}.sig.json"
        if [[ ! -f "$sigfile" ]]; then
          echo "Missing signature sidecar $sigfile for $f"; FAIL=1; continue
        fi
        # Verify both clinical and security profiles
        if [[ "$REQUIRE_CLINICAL" -eq 1 ]]; then
          if ! tools/signer-rs/target/release/signer-rs verify --input "$f" --keyref "$KEYREF" --expect-profile CLINICAL_POLICY ; then
            echo "Clinical signature verification failed for $f"; FAIL=1; continue
          fi
        fi
        if [[ "$REQUIRE_SECURITY" -eq 1 ]]; then
          if ! tools/signer-rs/target/release/signer-rs verify --input "$f" --keyref "$KEYREF" --expect-profile SECURITY_POLICY ; then
            echo "Security signature verification failed for $f"; FAIL=1; continue
          fi
        fi
        echo "Signatures OK for $f";
      fi
    fi
  done
done

if [[ "$FAIL" -ne 0 ]]; then
  echo "ALN signature verification failed"; exit 2
fi

echo "All ALN signature checks passed"; exit 0
