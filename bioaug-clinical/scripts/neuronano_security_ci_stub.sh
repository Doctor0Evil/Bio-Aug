#!/usr/bin/env bash
set -e
# Future: replace with cargo-audit + SBOM generator + HSM signing; currently stub metadata.
echo '{"sbom":"stub","vuln_scan":"stub","signing":"stub","domain":"neuronano_cyberneuro"}' > bioaug-clinical/build/out/neuronano_security_ci_meta.json
