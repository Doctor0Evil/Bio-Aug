# Regulatory Mapping for BioAugClinical Pillars

This document maps the hazard IDs in `bioaug-clinical/policies/*.aln` to relevant standards (IEC 62304, ISO 14971, ISO 10993, IEC 60601 series) and legal/regulatory expectations for clinical neuromodulation and neuro-infrastructure.

| Hazard ID | Standard Mapping | Notes |
|-----------|------------------|-------|
| HAZ-NANO-STIM-002 | ISO 14971; IEC 62304: Class C; ISO 10993 | Nanotransducer energy/temp, biocompatibility, chronic stability |
| HAZ-NANOBMI-001 | ISO 14971; IEC 62304: Class C; ISO 10993 | Flexible BMI materials, chronic implant stability, FBR |
| HAZ-NEUROMORPHIC-002 | IEC 62304: Class C; cybersecurity (IEC 62443)| Latency/power/throughput bounds, neuromorphic attack surface |
| HAZ-CITY-NEURO-GOV-001 | GDPR; ISO 27001; Local Public Safety Standards | Data governance, privacy, municipal obligations |
| HAZ-NEURORIGHTS-001 | Local legal standards (Chile, EU frameworks) | Protected mental privacy and autonomy |

For device-level regulatory pathways (human trials), ensure the system is tested per: FDA IDE/PMA or EU MDR with ISO 13485 QMS, and follow local medical device classification flows.
