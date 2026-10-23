function out=screen83_km_protocol(seeds,maxFE,D,funcs,tag)
%SCREEN83_KM_PROTOCOL  Evaluation-batch granularity sweep: M=100 with K in {10,15,20}, fixed 100k FE.
%   Pre-registration: sparse_q/docs/76_KM_PROTOCOL_PREREG.md
if nargin<1 || isempty(seeds), seeds=3539:3548; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='km_protocol'; end
common=struct('mode','sparse','nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'mseMode','none');
armA=common; armA.K=10;
armB=common; armB.K=15;
armC=common; armC.K=20;
algs=repmat({'SGWO_MSE'},1,3);
labels={'A-K10','B-K15','C-K20'};
opt=struct(); opt.states={armA,armB,armC}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
