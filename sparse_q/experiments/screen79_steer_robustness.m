function out=screen79_steer_robustness(seeds,maxFE,D,funcs,tag)
%SCREEN79_STEER_ROBUSTNESS  Fresh-seed, confirm-scale replication of the STEER effect (A vs D).
%   A = frozen final (G1-STEER on), D = frozen G1+E (G1-STEER off); both via SGWO_ESTEER (bitwise
%   verified against SGWO_STEER3 in both configs by tests/test_esteer_contract.m).
%   Pre-registration: sparse_q/docs/71_STEER_ROBUSTNESS_PREREG.md
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='steer_robust'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'esteerMode','none');
armA=common; armA.steerMode='perwolf'; armA.sdirSource='random'; armA.succSteer=0.5; armA.steerLambda=0.5;
armD=common; armD.steerMode='none'; armD.sdirSource='random'; armD.succSteer=0.0; armD.steerLambda=0.5;
algs=repmat({'SGWO_ESTEER'},1,2);
labels={'A-Final-SteerOn','D-FrozenG1E-SteerOff'};
opt=struct(); opt.states={armA,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
