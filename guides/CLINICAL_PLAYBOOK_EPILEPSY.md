# Bio-Aug Epilepsy Neuromodulation Playbook (Clinician-Facing)

- Scope: TiS2/Pt-like multifunctional nanotransducer protocols for seizure suppression; structured around safe S-value envelopes, ΔT_max <= ~1–2 °C, and energy/session limits from nanoneuromodulation literature. [web:18][web:25]
- Inputs: ALN NanoNeuro.Datasets.v2 (Stimulus, Session, SafetyOutcome), neuronano-guards compiled binaries, signed Class C artefacts.
- Workflow (high-level):
  1. Select subject + ConsentRecord (clinical scope, non-revoked).
  2. Choose protocol with validated NanoStimEnvelope and NeuromodEnvInvariant profile.
  3. Configure device within envelope (freq, intensity, duty cycle, session duration).
  4. Monitor continuous ΔT and SafetyOutcome metrics (delta_t_max, energy_session, efficacy_score).
  5. Record and sign session data into ALN dataset for audit, training, and postmarket surveillance.
