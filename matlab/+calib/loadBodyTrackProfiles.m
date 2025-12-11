function profiles = loadBodyTrackProfiles()
%LOADBODYTRACKPROFILES In-memory calibration profiles derived from ALN spec.
%
% Profiles cover medical-grade gait, posture, balance, and rehab AR work.
% REM sleep and non-clinical entertainment use cases are explicitly excluded.

profiles = struct( ...
    'id',              {}, ...
    'familyCode',      {}, ...
    'description',     {}, ...
    'minMarkers',      {}, ...
    'maxMarkers',      {}, ...
    'requiresSweep',   {}, ...
    'requiresStance',  {}, ...
    'targetRmsMm',     {}, ...
    'maxRmsMm',        {}, ...
    'minDurSec',       {}, ...
    'maxDurSec',       {} );

% -------------------------------------------------------------------------
% Profile 1: Optical gait and posture AR lab (baseline)
% -------------------------------------------------------------------------
profiles(1).id             = '44444444-4444-4444-8444-444444444444';
profiles(1).familyCode     = 'MOCAP_OPTICAL';
profiles(1).description    = [ ...
    'Optical volume calibration for gait and posture AR labs; ' ...
    'sub-millimetre target for calibration wand and static reference.' ...
    ];
profiles(1).minMarkers     = 8;      % minimum marker count for stable 3D solution
profiles(1).maxMarkers     = 64;     % upper bound for clinical lab rigs
profiles(1).requiresSweep  = true;   % volume sweep with wand/grid
profiles(1).requiresStance = true;   % quiet stance capture for origin/orientation
profiles(1).targetRmsMm    = 0.5;    % target RMS reprojection error
profiles(1).maxRmsMm       = 2.0;    % hard ceiling for acceptable calibration
profiles(1).minDurSec      = 30.0;   % minimum time to cover volume
profiles(1).maxDurSec      = 600.0;  % upper bound to prevent excessive exposure

% -------------------------------------------------------------------------
% Profile 2: IMU-based anatomical calibration for rehab AR
% -------------------------------------------------------------------------
profiles(2).id             = '55555555-5555-4555-8555-555555555555';
profiles(2).familyCode     = 'IMU_BODY';
profiles(2).description    = [ ...
    'IMU anatomical calibration for AR rehabilitation sessions; ' ...
    'uses quiet stance plus standard movement tests (e.g. hip/knee flexion).' ...
    ];
profiles(2).minMarkers     = 4;      % minimum IMUs (e.g. pelvis and legs)
profiles(2).maxMarkers     = 32;     % allows full-body IMU arrays
profiles(2).requiresSweep  = false;  % no full volume sweep needed
profiles(2).requiresStance = true;   % neutral stance used as anatomical baseline
profiles(2).targetRmsMm    = 5.0;    % looser spatial tolerance than optical
profiles(2).maxRmsMm       = 10.0;   % ceiling for clinically acceptable error
profiles(2).minDurSec      = 60.0;   % short IMU calibration block
profiles(2).maxDurSec      = 900.0;  % upper bound for extended rehab setups

% -------------------------------------------------------------------------
% Profile 3: Balance platform with reduced marker set (falls clinic)
% -------------------------------------------------------------------------
profiles(3).id             = '66666666-6666-4666-8666-666666666666';
profiles(3).familyCode     = 'MOCAP_OPTICAL_BALANCE';
profiles(3).description    = [ ...
    'Optical calibration for balance and falls clinics; ' ...
    'focus on trunk and lower-limb segments over force platform.' ...
    ];
profiles(3).minMarkers     = 6;      % trunk + bilateral lower limb minimum
profiles(3).maxMarkers     = 24;     % limited by clinic footprint
profiles(3).requiresSweep  = true;   % small-volume sweep above force plates
profiles(3).requiresStance = true;   % quiet stance for baseline COM/COG
profiles(3).targetRmsMm    = 1.0;    % slightly relaxed vs full gait volume
profiles(3).maxRmsMm       = 3.0;    % still within sub-centimetre scale
profiles(3).minDurSec      = 20.0;   % compact calibration window
profiles(3).maxDurSec      = 300.0;  % limit to 5 minutes for throughput

% -------------------------------------------------------------------------
% Profile 4: Upper-limb AR rehab (optical + IMU hybrid)
% -------------------------------------------------------------------------
profiles(4).id             = '77777777-7777-4777-8777-777777777777';
profiles(4).familyCode     = 'HYBRID_UPPERLIMB';
profiles(4).description    = [ ...
    'Hybrid optical/IMU calibration for upper-limb AR rehabilitation; ' ...
    'prioritizes shoulder and elbow joint centers for repetitive tasks.' ...
    ];
profiles(4).minMarkers     = 6;      % bilateral upper limb segments
profiles(4).maxMarkers     = 20;     % enough for scapula + arm segments
profiles(4).requiresSweep  = false;  % local workspace around treatment chair
profiles(4).requiresStance = false;  % seated neutral pose instead of stance
profiles(4).targetRmsMm    = 2.0;    % moderate tolerance around upper limb
profiles(4).maxRmsMm       = 5.0;    % ceiling before recalibration required
profiles(4).minDurSec      = 45.0;   % minimal seated calibration routine
profiles(4).maxDurSec      = 600.0;  % up to 10 minutes including patient prep

% -------------------------------------------------------------------------
% Profile 5: Pediatric gait AR assessment (shorter sessions)
% -------------------------------------------------------------------------
profiles(5).id             = '88888888-8888-4888-8888-888888888888';
profiles(5).familyCode     = 'MOCAP_OPTICAL_PEDIATRIC';
profiles(5).description    = [ ...
    'Optical gait calibration profile adapted for pediatric AR assessment; ' ...
    'shorter sessions and slightly relaxed RMS thresholds.' ...
    ];
profiles(5).minMarkers     = 10;     % trunk + limbs with redundancy
profiles(5).maxMarkers     = 40;     % fewer markers than adult full-body rigs
profiles(5).requiresSweep  = true;   % volume sweep, but smaller capture area
profiles(5).requiresStance = true;   % quiet stance where tolerated
profiles(5).targetRmsMm    = 1.0;    % balanced between precision and practicality
profiles(5).maxRmsMm       = 3.5;    % softening tolerance for pediatric motion
profiles(5).minDurSec      = 20.0;   % keep calibration short for children
profiles(5).maxDurSec      = 420.0;  % capped at 7 minutes total

end
