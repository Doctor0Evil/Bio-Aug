% aln_syntax_package_model.m
% Mathematical consistency and dependency model for the provided Cargo.toml
% All quantities are modeled as discrete variables or boolean flags.

%% 1. Basic package metadata as symbolic variables
syms v_major v_minor v_patch integer
syms year integer

% Version 0.1.0 encoded as integers [web:7]
v_major = 0;
v_minor = 1;
v_patch = 0;

% Edition 2021 encoded as a year integer [web:7]
year = 2021;

% License set size (MIT, Apache-2.0) [web:7]
L = 2;   % number of dual-licensing options

%% 2. Dependency set and version encoding
% Let each dependency d_i be mapped to a semantic-version triple
% d1 = pest, d2 = pest_derive, d3 = serde, d4 = anyhow  [web:7][web:4][web:5]

% pest = 2.6.x  -> encode as (2,6,0) base constraint
Dpest    = [2, 6, 0];
% pest_derive = 2.6.x -> same major/minor constraint
Dpestdrv = [2, 6, 0];
% serde = 1.0.x       -> (1,0,0)
Dserde   = [1, 0, 0];
% anyhow = 1.0.x      -> (1,0,0)
Danyhow  = [1, 0, 0];

% Represent required minimal version vector for each dependency as rows
D_min = [
    Dpest;
    Dpestdrv;
    Dserde;
    Danyhow
];

% Number of dependencies
n_dep = size(D_min,1);

%% 3. Feature flags as boolean variables
% default = ["std"], std = [], no_std = []  [web:7]
syms F_default F_std F_no_std

% Enforce that "default" implies "std"
% F_default, F_std, F_no_std ∈ {0,1}
assumeAlso(F_default >= 0 & F_default <= 1);
assumeAlso(F_std     >= 0 & F_std     <= 1);
assumeAlso(F_no_std  >= 0 & F_no_std  <= 1);

% Logical constraint: default -> std
% Implemented as inequality: F_default ≤ F_std
constraint_default_implies_std = F_default <= F_std;

% Mutually-exclusive future invariant: std and no_std should not be active together
constraint_mutual_exclusion    = F_std + F_no_std <= 1;

%% 4. Reproducible build constraint model
% Let B be the build reproducibility score in [0,1].
% We model it as a function of:
%  - P: publish flag (1 if true)
%  - W: workspace isolation clarity (1 if clearly specified)
%  - V: version pinning vector consistency (1 if all minimal versions set)
syms B P W V

assumeAlso(P >= 0 & P <= 1);
assumeAlso(W >= 0 & W <= 1);
assumeAlso(V >= 0 & V <= 1);

% In this manifest:
%  - publish = true -> P = 1
%  - workspace clarity is stated -> W = 1
%  - all dependencies specify at least a major version -> V = 1  [web:7]
P = 1;
W = 1;
V = 1;

% Define a simple linear reproducibility index:
% B = (P + W + V) / 3
B = (P + W + V)/3;

%% 5. Library crate-type constraint
% crate-type = ["rlib"] ⇒ no cdylib/staticlib constraints  [web:7]
% Encode crate-type as a one-hot vector:
%   C = [c_rlib, c_cdylib, c_staticlib]
C = [1, 0, 0];  % only rlib active

% Constraint: exactly one crate-type is active
constraint_one_crate_type = sum(C) == 1;

%% 6. Summary of constraints as a system
% Collect all inequality/equality constraints into a set S.
S = [
    constraint_default_implies_std;
    constraint_mutual_exclusion;
    constraint_one_crate_type
];

% Display the structured model
disp('Version triple (v_major, v_minor, v_patch):');
disp([v_major, v_minor, v_patch]);

disp('Dependency minimal version matrix D_min: [major minor patch]');
disp(D_min);

disp('Feature-flag constraints (must all hold):');
disp(S);

disp('Reproducible-build index B (1 = ideal):');
disp(B);
