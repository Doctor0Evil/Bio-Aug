-- File: db/schema/neuro_ar_lab_v1_0_0.sql

CREATE TABLE lab_tenant (
    tenant_id          UUID PRIMARY KEY,
    name               VARCHAR(255) NOT NULL,
    iso13485_scope     VARCHAR(255) NOT NULL,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE subject (
    subject_id         UUID PRIMARY KEY,
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    pseudonym_code     VARCHAR(64) NOT NULL UNIQUE,
    year_of_birth      INT,
    sex_at_birth       VARCHAR(16),
    notes              VARCHAR(1024),
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE device_family (
    family_code        VARCHAR(64) PRIMARY KEY,
    class              VARCHAR(32) NOT NULL,          -- BODY_TRACKING/BIOSENSING/IMAGING/HYBRID
    description        VARCHAR(512) NOT NULL,
    iso13485_relevant  BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO device_family (family_code, class, description)
VALUES
('MOCAP_OPTICAL', 'BODY_TRACKING',
 'Optical motion capture arrays for gait and movement AR labs.'),
('IMU_BODY', 'BODY_TRACKING',
 'Wearable IMUs for body tracking and AR rehabilitation.'),
('MULTIPLEX_BIOSENSE', 'BIOSENSING',
 'Multiplex biosensing platforms for non‑sleep physiological monitoring.');

CREATE TABLE device_asset (
    device_id          UUID PRIMARY KEY,
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    family_code        VARCHAR(64) NOT NULL REFERENCES device_family(family_code),
    manufacturer_model VARCHAR(128),
    serial_number      VARCHAR(128),
    location_label     VARCHAR(128),
    active             BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE calibration_profile (
    profile_id         UUID PRIMARY KEY,
    family_code        VARCHAR(64) NOT NULL REFERENCES device_family(family_code),
    profile_name       VARCHAR(128) NOT NULL,
    target_rms_mm      NUMERIC(6,3),
    max_rms_mm         NUMERIC(6,3),
    target_bias_pct    NUMERIC(5,2),
    max_bias_pct       NUMERIC(5,2),
    target_cv_pct      NUMERIC(5,2),
    max_cv_pct         NUMERIC(5,2),
    max_interval_days  INT NOT NULL,
    notes              VARCHAR(1024)
);

CREATE TABLE calibration_record (
    cal_id             UUID PRIMARY KEY,
    device_id          UUID NOT NULL REFERENCES device_asset(device_id),
    profile_id         UUID NOT NULL REFERENCES calibration_profile(profile_id),
    performed_on       TIMESTAMP NOT NULL,
    performed_by_role  VARCHAR(64) NOT NULL,
    passed             BOOLEAN NOT NULL,
    rms_error_mm       NUMERIC(6,3),
    bias_pct           NUMERIC(5,2),
    cv_pct             NUMERIC(5,2),
    action_taken       VARCHAR(512),
    audit_user         VARCHAR(128) NOT NULL,
    audit_timestamp    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE facility_context (
    facility_id        UUID PRIMARY KEY,
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    type               VARCHAR(16) NOT NULL,          -- HOSPITAL/LAB/REHAB
    description        VARCHAR(512),
    requires_ded_room  BOOLEAN NOT NULL DEFAULT FALSE,
    requires_phantom   BOOLEAN NOT NULL DEFAULT FALSE,
    min_staff_trained  INT NOT NULL DEFAULT 1
);

-- Explicitly non‑sleep study types: gait, posture, neuro‑rehab, cognitive AR tasks.
CREATE TABLE study (
    study_id           UUID PRIMARY KEY,
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    study_code         VARCHAR(64) NOT NULL UNIQUE,
    title              VARCHAR(255) NOT NULL,
    study_type         VARCHAR(32) NOT NULL,   -- GAIT/POSTURE/COGNITIVE_AR/BIOSENSE/OTHER
    rem_sleep_allowed  BOOLEAN NOT NULL DEFAULT FALSE,
    irb_protocol_id    VARCHAR(128),
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (rem_sleep_allowed = FALSE)
);

CREATE TABLE ar_session (
    session_id         UUID PRIMARY KEY,
    study_id           UUID NOT NULL REFERENCES study(study_id),
    subject_id         UUID NOT NULL REFERENCES subject(subject_id),
    facility_id        UUID NOT NULL REFERENCES facility_context(facility_id),
    started_at         TIMESTAMP NOT NULL,
    ended_at           TIMESTAMP,
    purpose            VARCHAR(64) NOT NULL,  -- GAIT_TRAINING, BALANCE_TASK, COGNITIVE_AR, BIOSENSE_FEEDBACK
    rem_flag           BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (rem_flag = FALSE)
);

CREATE TABLE ar_session_device (
    session_id         UUID NOT NULL REFERENCES ar_session(session_id),
    device_id          UUID NOT NULL REFERENCES device_asset(device_id),
    role               VARCHAR(64) NOT NULL,  -- PRIMARY_TRACKER, SECONDARY_SENSOR, DISPLAY_HMD, BIOSENSE_INPUT
    PRIMARY KEY (session_id, device_id)
);

CREATE TABLE biosense_measurement (
    measurement_id     UUID PRIMARY KEY,
    session_id         UUID NOT NULL REFERENCES ar_session(session_id),
    device_id          UUID NOT NULL REFERENCES device_asset(device_id),
    analyte_code       VARCHAR(64) NOT NULL,
    value              NUMERIC(12,4) NOT NULL,
    unit               VARCHAR(32) NOT NULL,
    timestamp          TIMESTAMP NOT NULL,
    quality_flag       VARCHAR(32) NOT NULL,  -- OK/OUT_OF_RANGE/CAL_WARNING
    CHECK (analyte_code NOT ILIKE '%MELATONIN%')
);

CREATE TABLE motion_capture_sample (
    sample_id          BIGSERIAL PRIMARY KEY,
    session_id         UUID NOT NULL REFERENCES ar_session(session_id),
    device_id          UUID NOT NULL REFERENCES device_asset(device_id),
    frame_index        BIGINT NOT NULL,
    timestamp          TIMESTAMP NOT NULL,
    rms_fit_error_mm   NUMERIC(6,3),
    quality_flag       VARCHAR(32) NOT NULL
);

-- Security / audit for electronic records.[web:12][web:15]
CREATE TABLE audit_event (
    audit_id           BIGSERIAL PRIMARY KEY,
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    actor_id           VARCHAR(128) NOT NULL,
    action             VARCHAR(64) NOT NULL,
    entity_type        VARCHAR(64) NOT NULL,
    entity_id          VARCHAR(64) NOT NULL,
    event_time         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details            VARCHAR(2048)
);

-- Hard block any future attempt to label a study or session as REM-related
-- at the database level (defense in depth).
CREATE OR REPLACE FUNCTION prevent_rem_labels()
RETURNS trigger AS $$
BEGIN
    IF NEW.study_type ILIKE '%REM%' THEN
        RAISE EXCEPTION 'REM-related study types are prohibited in this database.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_study_no_rem
BEFORE INSERT OR UPDATE ON study
FOR EACH ROW EXECUTE FUNCTION prevent_rem_labels();
