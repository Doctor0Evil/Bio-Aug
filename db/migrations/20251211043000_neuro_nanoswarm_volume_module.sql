-- =====================================================================
-- neuro_nanoswarm volume orchestration module
-- - Encodes policy ceilings, device-class virtualization, and
--   frequency ranges for BCI/EEG/neuromorphic stacks.
-- - Embeds hex fingerprints so higher layers can bind to virtual devices.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) Core device profiles (virtualized counterparts + hex patterns)
-- ---------------------------------------------------------------------
CREATE TABLE device_profile (
    id                          UUID            PRIMARY KEY,
    device_profile              VARCHAR(64)     NOT NULL UNIQUE,
    class                       VARCHAR(32)     NOT NULL CHECK (class IN (
                                        'BCI',
                                        'EEG',
                                        'NEUROMORPHIC',
                                        'BIOMECH')),
    description                 VARCHAR(512)    NOT NULL,
    min_ops_tops                NUMERIC(10,3)   NOT NULL CHECK (min_ops_tops >= 0),
    max_ops_tops                NUMERIC(10,3)   NOT NULL CHECK (max_ops_tops >= min_ops_tops),
    freq_low_hz                 NUMERIC(10,3)   NOT NULL CHECK (freq_low_hz >= 0),
    freq_high_hz                NUMERIC(10,3)   NOT NULL CHECK (freq_high_hz >= freq_low_hz),
    hexa_fingerprint_256        CHAR(64)        NOT NULL,
    created_at_utc              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

INSERT INTO device_profile (
    id, device_profile, class, description,
    min_ops_tops, max_ops_tops, freq_low_hz, freq_high_hz, hexa_fingerprint_256
) VALUES
    -- Motor-imagery BCI / MCI stack (EEG 4–40 Hz, µV scale)
    ('ffffffff-ffff-4fff-8fff-fffffffffff1',
     'bci_motor_imagery_v1',
     'BCI',
     'Motor-imagery BCI stack for MI/ERP paradigms (EEG frontal/parietal montage, µV range).',
     10.000, 150.000,
     4.000, 40.000,
     'B4E2D7A1C9F0837AD1E4B6C3F9A2D5E1B7C8D9F0A3E6B1C4D7F2A9E0C5B8D3F6'),

    -- Clinical EEG stack (0.5–100 Hz)
    ('ffffffff-ffff-4fff-8fff-fffffffffff2',
     'eeg_clinical_32ch_v1',
     'EEG',
     'Clinical 32-channel EEG stack (delta–gamma coverage, 0.5–100 Hz) for monitoring and diagnostics.',
     5.000, 80.000,
     0.500, 100.000,
     '9F1C0A7D2B6E53C8D4F8A1E2B7C9D0F3A5E6B1C4D7F2A9E0C5B8D3F6B4E2D7A1'),

    -- Neuromorphic spike-based device (200 Hz–20 kHz event rate)
    ('ffffffff-ffff-4fff-8fff-fffffffffff3',
     'neuromorphic_spike_array_v1',
     'NEUROMORPHIC',
     'Event-based neuromorphic spike array with per-core spike rates 200 Hz–20 kHz.',
     1000.000, 20000.000,
     200.000, 20000.000,
     'A3E6B1C4D7F2A9E0C5B8D3F6B4E2D7A1C9F0837AD1E4B6C3F9A2D5E1B7C8D9F0'),

    -- Biomechanical infusion/exoskeleton controller (0–10 Hz torque/flow)
    ('ffffffff-ffff-4fff-8fff-fffffffffff4',
     'biomech_infusion_exo_v1',
     'BIOMECH',
     'Biomechanical controller for infusion and exoskeleton torque envelopes (0–10 Hz actuation).',
     2.000, 50.000,
     0.000, 10.000,
     'C5B8D3F6B4E2D7A1C9F0837AD1E4B6C3F9A2D5E1B7C8D9F0A3E6B1C4D7F2A9E0');

-- ---------------------------------------------------------------------
-- 2) Volume policy registry (mirrors DefaultVolumePolicy semantics)
-- ---------------------------------------------------------------------
CREATE TABLE volume_policy (
    id                          UUID            PRIMARY KEY,
    name                        VARCHAR(128)    NOT NULL UNIQUE,
    device_profile              VARCHAR(64)     NOT NULL REFERENCES device_profile(device_profile),
    max_allowed_ml              NUMERIC(10,3)   NOT NULL CHECK (max_allowed_ml >= 0),
    qpu_cycle_budget_ns         BIGINT          NOT NULL CHECK (qpu_cycle_budget_ns > 0),
    compliance_tag              VARCHAR(64)     NOT NULL,
    hexa_policy_fingerprint_128 CHAR(32)        NOT NULL,
    created_at_utc              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

INSERT INTO volume_policy (
    id, name, device_profile, max_allowed_ml, qpu_cycle_budget_ns,
    compliance_tag, hexa_policy_fingerprint_128
) VALUES
    -- Policy mirroring neuro_nanoswarm DefaultVolumePolicy for infusion matrices
    ('dddddddd-dddd-4ddd-8ddd-ddddddddddd4',
     'neuro_nanoswarm_infusion_v1',
     'biomech_infusion_exo_v1',
     1000.000,
     250,
     'GMP-CLASS-A',
     '3F9A2D5E1B7C8D9F0A3E6B1C4D7F2A9');

-- ---------------------------------------------------------------------
-- 3) Patient volume matrix table (target of transactional inserts)
-- ---------------------------------------------------------------------
CREATE TABLE patient_volume_matrix (
    id                          UUID            PRIMARY KEY,
    patient_id                  UUID            NOT NULL,
    max_volume_ml               NUMERIC(10,3)   NOT NULL CHECK (max_volume_ml >= 0),
    compliance_tag              VARCHAR(64)     NOT NULL,
    qpu_cycle_budget_ns         BIGINT          NOT NULL CHECK (qpu_cycle_budget_ns > 0),
    policy_id                   UUID            NOT NULL REFERENCES volume_policy(id),
    device_profile              VARCHAR(64)     NOT NULL REFERENCES device_profile(device_profile),
    created_at_utc              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_patient_volume_matrix_patient
    ON patient_volume_matrix (patient_id);

CREATE INDEX idx_patient_volume_matrix_volume
    ON patient_volume_matrix (patient_id, max_volume_ml);

-- ---------------------------------------------------------------------
-- 4) Virtualized high-tech bindings: per-row device + frequency bands
-- ---------------------------------------------------------------------
CREATE TABLE patient_volume_device_binding (
    id                          UUID            PRIMARY KEY,
    patient_volume_matrix_id    UUID            NOT NULL REFERENCES patient_volume_matrix(id) ON DELETE CASCADE,
    device_profile              VARCHAR(64)     NOT NULL REFERENCES device_profile(device_profile),
    freq_band_low_hz            NUMERIC(10,3)   NOT NULL CHECK (freq_band_low_hz >= 0),
    freq_band_high_hz           NUMERIC(10,3)   NOT NULL CHECK (freq_band_high_hz >= freq_band_low_hz),
    hexa_binding_fingerprint_128 CHAR(32)       NOT NULL,
    created_at_utc              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Example bindings:
--  - EEG clinical band 0.5–40 Hz
--  - BCI MI band 8–30 Hz (µ rhythm focused)
--  - Neuromorphic spike envelope 500–5000 Hz
INSERT INTO patient_volume_device_binding (
    id, patient_volume_matrix_id, device_profile,
    freq_band_low_hz, freq_band_high_hz, hexa_binding_fingerprint_128
)
SELECT
    gen_random_uuid(),
    pvm.id,
    'eeg_clinical_32ch_v1',
    0.500,
    40.000,
    '1E4B6C3F9A2D5E1B7C8D9F0A3E6B1C4'
FROM patient_volume_matrix AS pvm
WHERE pvm.device_profile = 'biomech_infusion_exo_v1';

INSERT INTO patient_volume_device_binding (
    id, patient_volume_matrix_id, device_profile,
    freq_band_low_hz, freq_band_high_hz, hexa_binding_fingerprint_128
)
SELECT
    gen_random_uuid(),
    pvm.id,
    'bci_motor_imagery_v1',
    8.000,
    30.000,
    'D7F2A9E0C5B8D3F6B4E2D7A1C9F0837'
FROM patient_volume_matrix AS pvm
WHERE pvm.device_profile = 'biomech_infusion_exo_v1';

INSERT INTO patient_volume_device_binding (
    id, patient_volume_matrix_id, device_profile,
    freq_band_low_hz, freq_band_high_hz, hexa_binding_fingerprint_128
)
SELECT
    gen_random_uuid(),
    pvm.id,
    'neuromorphic_spike_array_v1',
    500.000,
    5000.000,
    'A9E0C5B8D3F6B4E2D7A1C9F0837AD1E'
FROM patient_volume_matrix AS pvm
WHERE pvm.device_profile = 'biomech_infusion_exo_v1';

-- ---------------------------------------------------------------------
-- 5) Helper view: audit-ready joined representation
-- ---------------------------------------------------------------------
CREATE VIEW v_patient_volume_matrix_audit AS
SELECT
    pvm.id                          AS volume_row_id,
    pvm.patient_id,
    pvm.max_volume_ml,
    pvm.compliance_tag,
    pvm.qpu_cycle_budget_ns,
    pvm.created_at_utc,
    dp.device_profile,
    dp.class                         AS device_class,
    dp.freq_low_hz                  AS device_freq_low_hz,
    dp.freq_high_hz                 AS device_freq_high_hz,
    dp.hexa_fingerprint_256         AS device_hex_fingerprint,
    vp.name                         AS policy_name,
    vp.max_allowed_ml               AS policy_max_allowed_ml,
    vp.hexa_policy_fingerprint_128  AS policy_hex_fingerprint
FROM patient_volume_matrix pvm
JOIN volume_policy vp
  ON pvm.policy_id = vp.id
JOIN device_profile dp
  ON pvm.device_profile = dp.device_profile;

-- ---------------------------------------------------------------------
-- 6) DOWN migration
-- ---------------------------------------------------------------------
-- To reverse this module, drop dependent objects in reverse order.
-- (Adjust for your migration tool if it uses separate *.down.sql files.)
--
-- DROP VIEW  IF EXISTS v_patient_volume_matrix_audit;
-- DROP TABLE IF EXISTS patient_volume_device_binding;
-- DROP TABLE IF EXISTS patient_volume_matrix;
-- DROP TABLE IF EXISTS volume_policy;
-- DROP TABLE IF EXISTS device_profile;
