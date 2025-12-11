CREATE TABLE ai_asset (
    id                      UUID            PRIMARY KEY,
    name                    VARCHAR(256)    NOT NULL,
    provider                VARCHAR(256)    NOT NULL,
    modality                VARCHAR(32)     NOT NULL CHECK (modality IN
                                ('text','vision','audio','multimodal','control','biosignal')),
    interface_profile       VARCHAR(32)     NOT NULL CHECK (interface_profile IN
                                ('cli','rest','grpc','on_device','embedded_fpga','neurolink')),
    license_class           VARCHAR(32)     NOT NULL CHECK (license_class IN
                                ('permissive','copyleft','proprietary','clinical_restricted')),
    safety_level            VARCHAR(32)     NOT NULL CHECK (safety_level IN
                                ('experimental','research','clinical_pilot','clinical_production')),
    version_tag             VARCHAR(128)    NOT NULL,
    aln_schema_uri          VARCHAR(512)    NOT NULL,
    github_repo_uri         VARCHAR(512)    NOT NULL,
    documentation_uri       VARCHAR(512)    NOT NULL,
    device_profile          VARCHAR(128)    NOT NULL,
    ops_threshold_tops      NUMERIC(10,3)   NOT NULL CHECK (ops_threshold_tops >= 0),
    latency_budget_ms       NUMERIC(10,3)   NOT NULL CHECK (latency_budget_ms > 0),
    max_power_watts         NUMERIC(10,3)   NOT NULL CHECK (max_power_watts >= 0),
    hexa_fingerprint        CHAR(64)        NOT NULL,
    loinc_code              VARCHAR(32),
    snomed_ct_code          VARCHAR(32),
    created_at_utc          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at_utc          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    is_clinically_validated BOOLEAN         NOT NULL DEFAULT FALSE,
    is_public_discoverable  BOOLEAN         NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_ai_asset_modality
    ON ai_asset (modality);

CREATE INDEX idx_ai_asset_safety_level
    ON ai_asset (safety_level);

CREATE INDEX idx_ai_asset_device_profile
    ON ai_asset (device_profile);

CREATE INDEX idx_ai_asset_public_discoverable
    ON ai_asset (is_public_discoverable);

CREATE UNIQUE INDEX idx_ai_asset_fingerprint
    ON ai_asset (hexa_fingerprint);
