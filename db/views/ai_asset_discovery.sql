CREATE OR REPLACE VIEW ai_asset_clinical_production AS
SELECT *
FROM ai_asset
WHERE safety_level = 'clinical_production'
  AND is_clinically_validated = TRUE;

CREATE OR REPLACE VIEW ai_asset_neuro_nanoswarm_public AS
SELECT *
FROM ai_asset
WHERE device_profile = 'neuro_nanoswarm_v1'
  AND is_public_discoverable = TRUE;
