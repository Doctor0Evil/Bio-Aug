#!/usr/bin/env bash
set -euo pipefail

echo "Installing pre-commit hooks (pre-commit must be installed locally)";
pre-commit install || true

echo "Done. Run 'pre-commit run --all-files' to test rules.";
