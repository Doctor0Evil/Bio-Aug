#!/usr/bin/env bash
set -e
# Stub SBOM + vuln scan for Rust; replace with cargo audit / SBOM generator in production.
echo '{"sbom":"stub","vuln_scan":"stub"}' > bioaug-clinical/build/out/sbom_vuln_scan.json
