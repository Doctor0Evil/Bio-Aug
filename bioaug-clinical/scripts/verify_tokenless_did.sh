#!/usr/bin/env bash
set -e

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <artifact-path> <did-doc-path>" >&2
  exit 1
fi

ARTIFACT="$1"
DID_DOC="$2"

if [ ! -f "$ARTIFACT" ]; then
  echo "ERROR: artifact not found: $ARTIFACT" >&2
  exit 1
fi
if [ ! -f "$DID_DOC" ]; then
  echo "ERROR: DID document not found: $DID_DOC" >&2
  exit 1
fi

ALG='sha256'
HASH=$(openssl dgst -$ALG -r "$ARTIFACT" | awk '{print $1}')

# Extract id field from DID doc (simple grep/awk JSON parsing; assumes minimal format).
DID_ID=$(grep '"id"' "$DID_DOC" | head -n1 | sed 's/[",]//g' | awk '{print $2}')
EXPECTED="did:bioaug:$ALG:$HASH"

if [ "$DID_ID" != "$EXPECTED" ]; then
  echo "DID mismatch" >&2
  echo "   expected: $EXPECTED" >&2
  echo "   found:    $DID_ID" >&2
  exit 1
fi

echo "DID verified: $DID_ID"
