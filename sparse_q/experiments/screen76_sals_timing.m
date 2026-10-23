function out=screen76_sals_timing(seeds,maxFE,D,funcs,tag)
%SCREEN76_SALS_TIMING  Same-batch runtime comparison of the frozen final algorithm against the SALS
%   active arms (post-selection IID / stratified) and the passive audit arm.
%   TIMING ONLY: seeds are reused from the frozen 29x30 block on purpose -- no performance claim is
%   made from this batch, it only quantifies the mechanism's wall-clock overhead after the
%   runtime optimisation of SGWO_SALS (see tests/test_sals_opt_equivalence.m).
if nargin<1 || isempty(seeds), seeds=3071:3073; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 14]; end
if nargin<5 || isempty(tag), tag='sals_timing'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'salsSeedOffset',555111);
armA=common; armA.salsMode='none';
armB=common; armB.salsMode='iid';
armC=common; armC.salsMode='lhs';
armD=common; armD.salsMode='audit';
algs=repmat({'SGWO_SALS'},1,4);
labels={'A-Frozen-Final','B-PostIID','C-SALS','D-Audit'};
opt=struct(); opt.states={armA,armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
