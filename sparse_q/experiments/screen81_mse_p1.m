function out=screen81_mse_p1(seeds,maxFE,D,funcs,tag)
%SCREEN81_MSE_P1  Three-arm MSE experiment: A frozen / B multi-scale mix / C matched-RMS single scale.
%   Pre-registration: sparse_q/docs/73_MSE_P1_PREREG.md
if nargin<1 || isempty(seeds), seeds=3494:3503; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='mse_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'mseSeedOffset',777777);
armA=common; armA.mseMode='none';
armB=common; armB.mseMode='mix';
armC=common; armC.mseMode='ctrl';
algs=repmat({'SGWO_MSE'},1,3);
labels={'A-Frozen','B-Mix','C-CtrlRMS'};
opt=struct(); opt.states={armA,armB,armC}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
