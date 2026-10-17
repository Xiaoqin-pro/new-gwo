function root=setup_project()
%SETUP_PROJECT  Add the NEW_GWO_2026 code and the CEC2017 harness to the path.
%   The CEC2017 MEX opens "input_data/..." relative to the CURRENT directory,
%   so experiments must cd into data/cec2017 before evaluating. See
%   experiments/runner_cec.m for the enforced pattern.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'));
addpath(fullfile(root,'experiments'));
addpath(fullfile(root,'data','cec2017'));
addpath(fullfile(root,'+overnight'));
end
