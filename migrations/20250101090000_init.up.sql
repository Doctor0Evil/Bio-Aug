CREATE TABLE patient_volume_matrix (
    id                  UUID            PRIMARY KEY,
    patient_id          UUID            NOT NULL,
    max_volume_ml       NUMERIC(10,3)   NOT NULL CHECK (max_volume_ml >= 0),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_patient_volume_matrix_patient_id
    ON patient_volume_matrix (patient_id);
