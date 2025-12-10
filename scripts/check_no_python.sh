#!/usr/bin/env bash
# Exit on errors
set -euo pipefail

# Paths to protect
PROTECTED_PATHS=("core" "bci" "kernel" "drivers")

# Base branch to compare to (CI will pass ref; default to origin/main)
BASE_REF=${1:-origin/main}

# Get changed files (or staged files if run locally)
CHANGED=$(git diff --name-only "${BASE_REF}"...HEAD || true)

for f in ${CHANGED}; do
  for p in "${PROTECTED_PATHS[@]}"; do
    if [[ "$f" == $p/* ]] && [[ "$f" == *.py ]]; then
      echo "ERROR: Python file $f is not allowed in protected path $p"; exit 1
    fi
  done
done

echo "No Python in kernel/device paths detected."; exit 0
