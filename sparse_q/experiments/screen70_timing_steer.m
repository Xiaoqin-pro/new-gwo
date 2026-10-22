function out=screen70_timing_steer(seeds,maxFE,D,funcs,tag)
%SCREEN70_TIMING_STEER  Same-batch runtime comparison: frozen vs STEER, original vs optimised impl.
if nargin<1 || isempty(seeds), seeds=3986:3990; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 13 30]; end
if nargin<5 || isempty(tag), tag='timing_steer'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','steerLambda',0.5);
armA=common; armA.succSteer=0;    % frozen, original implem
armB=common; armB.succSteer=0.5;  % STEER, original implem
armC=common; armC.succSteer=0;    % frozen, optimised implem
armD=common; armD.succSteer=0.5;  % STEER, optimised implem
algs={'SGWO_STEER','SGWO_STEER','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Frozen-Orig','B-Steer-Orig','C-Frozen-Opt','D-Steer-Opt'};
opt=struct(); opt.states={armA,armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
