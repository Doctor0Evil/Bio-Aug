#!/usr/bin/env bash
set -e
# Combined gate: ALN lint + docs presence for gold-standard readiness.

./bioaug-clinical/tools/aln_portable_lint.sh --auto-build
./bioaug-clinical/ci/docs_presence_check.sh
