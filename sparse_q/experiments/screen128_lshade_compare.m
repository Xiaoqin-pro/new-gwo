function out=screen128_lshade_compare(seeds,maxFE,D,funcs)
%SCREEN128_LSHADE_COMPARE  Small L-SHADE vs current final comparison.
if nargin<1 || isempty(seeds), seeds=3739:3743; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
algs={'LSHADE','SGWO_STEER3'};
labels={'L-SHADE','Current-G1E-Steer'};
opt=struct('states',{ {struct(),common} },'labels',{labels});
out=run_batch_sq('lshade_compare',algs,funcs(:),seeds(:),D,maxFE,opt);
end
