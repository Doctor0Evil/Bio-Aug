#!/usr/bin/env bash
set -e
# ALN_BIN resolution (shared helper)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ALN_BIN:=$(sh "$SCRIPT_DIR/../../tools/find_aln.sh")}"
# Combined gate: ALN lint + docs presence for gold-standard readiness.

./bioaug-clinical/tools/aln_portable_lint.sh --auto-build
./bioaug-clinical/ci/docs_presence_check.sh
