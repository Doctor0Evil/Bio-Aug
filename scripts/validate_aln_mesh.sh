#!/usr/bin/env bash
# Validate ALN mesh invariants in the AU.BioMesh.NetEnvelope.v1.aln file(s).
set -euo pipefail

ALN_DIR="aln_specs"
FAIL=0
for f in "$ALN_DIR"/*.aln; do
  echo "Validating $f"
  # Use aln-cli to validate entirely if available
  if [[ -x "aln-cli/target/release/aln" ]]; then
    aln-cli/target/release/aln validate "$f" --profile bioaug-clinical || { echo "aln-cli validation failed for $f"; FAIL=1; }
  fi
  # Check for required invariants
  if ! grep -q "invariant inv.NO_REMOTE_EXEC" "$f"; then
    echo "ERROR: missing invariant NO_REMOTE_EXEC in $f"; FAIL=1
  fi
  if ! grep -q "invariant inv.NO_INBOUND_WRITE" "$f"; then
    echo "ERROR: missing invariant NO_INBOUND_WRITE in $f"; FAIL=1
  fi
  if ! grep -q "invariant inv.OFFLINE_ONLY" "$f"; then
    echo "ERROR: missing invariant OFFLINE_ONLY in $f"; FAIL=1
  fi

  # For each instance of Interface, ensure has_ip_stack == 0u8
  # We'll try to extract interface blocks by name
  grep -n "instance AU.BioMesh.Iface." "$f" | cut -d: -f1 | while read -r line; do
    # get the block starting from line to next '}' or 'end' - assume ALN uses '}' or 'end'
    block=$(sed -n "$line, $((line+60))p" "$f")
    if ! echo "$block" | grep -q "has_ip_stack\s*=\s*0u8"; then
      echo "ERROR: Interface in $f (starting line $line) missing has_ip_stack == 0u8"; FAIL=1
    fi
    if ! echo "$block" | grep -q "FLAG_NO_RF_TX"; then
      echo "ERROR: Interface in $f missing FLAG_NO_RF_TX"; FAIL=1
    fi
    if ! echo "$block" | grep -q "FLAG_HARD_AIRGAP"; then
      echo "ERROR: Interface in $f missing FLAG_HARD_AIRGAP"; FAIL=1
    fi
    if ! echo "$block" | grep -q "FLAG_READ_ONLY_CTRL"; then
      echo "ERROR: Interface in $f missing FLAG_READ_ONLY_CTRL"; FAIL=1
    fi
  done

  # Check link invariants
  grep -n "instance AU.BioMesh.Link." "$f" | cut -d: -f1 | while read -r line; do
    block=$(sed -n "$line, $((line+40))p" "$f")
    if ! echo "$block" | grep -q "hop_count_max\s*=\s*1u8"; then
      echo "ERROR: Link in $f (starting line $line) missing hop_count_max == 1u8"; FAIL=1
    fi
    if ! echo "$block" | grep -q "remote_exec_cap\s*=\s*0u8"; then
      echo "ERROR: Link in $f missing remote_exec_cap == 0u8"; FAIL=1
    fi
    if ! echo "$block" | grep -q "LFLAG_NO_REMOTE_EXEC"; then
      echo "ERROR: Link in $f missing LFLAG_NO_REMOTE_EXEC"; FAIL=1
    fi
  done

  # Basic numeric checks for bandwidth
  bw_values=$(grep -E "bw_kbps_max\s*=\s*[0-9]+u32" "$f" | grep -oE "[0-9]+")
  for v in $bw_values; do
    if [ "$v" -gt 256 ]; then
      echo "ERROR: bw_kbps_max $v exceeds 256 in $f"; FAIL=1
    fi
  done

done

if [ "$FAIL" -ne 0 ]; then
  echo "ALN mesh validation failed"; exit 2
fi

echo "ALN mesh validation passed"; exit 0
