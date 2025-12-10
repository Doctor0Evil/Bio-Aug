#!/usr/bin/env bash
set -euo pipefail

./bioaug-clinical/scripts/gen_dev_keys.sh bioaug-clinical/ci/dev
./bioaug-clinical/scripts/sign_all_policies.sh
./bioaug-clinical/scripts/validate_aln_strict.sh
./bioaug-clinical/scripts/aln_coverage_and_sign.sh
./bioaug-clinical/scripts/run_proptests.sh
./bioaug-clinical/scripts/rust_classc_checks.sh
./bioaug-clinical/scripts/wcet_mem_check.sh
./bioaug-clinical/scripts/verify_aln_signatures.sh
./bioaug-clinical/scripts/validate_nano_neuro_city.sh

echo "CI local verify completed"
