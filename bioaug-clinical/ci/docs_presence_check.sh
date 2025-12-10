#!/usr/bin/env bash
set -e
# Ensure key clinical / governance / research docs exist for gold-standard status.
required_files=(
  guides/CLINICAL_PLAYBOOK_EPILEPSY.md
  guides/CLINICAL_PLAYBOOK_DEPRESSION.md
  guides/CLINICAL_PLAYBOOK_PAIN.md
  guides/CONSENT_TEMPLATE_CLINICAL.md
  guides/CONSENT_TEMPLATE_URBAN_BCI.md
  guides/DATA_COLLECTION_SOP_LABS.md
  guides/DATA_COLLECTION_SOP_HOME.md
  guides/NEUROMORPHIC_DATASET_TEMPLATE_V1.md
  guides/NEUROMORPHIC_DATASET_TEMPLATE_V2.md
  guides/SMARTCITY_NEURO_GOVERNANCE_SOP.md
  guides/RISK_REGISTER_TEMPLATE_IEC62304.md
  guides/VALIDATION_PLAN_TEMPLATE_CLASSC.md
  guides/RELEASE_CHECKLIST_CLASSC.md
  guides/INCIDENT_RESPONSE_RUNBOOK_NEUROMOD.md
  guides/POSTMARKET_SURVEILLANCE_PLAN_NEURONANO.md
)
for f in "${required_files[@]}"; do
  if [ ! -f "bioaug-clinical/$f" ]; then
    echo "MISSING: $f" >&2
    exit 1
  fi
done

echo "All required docs present: gold-standard docs checklist passed"
