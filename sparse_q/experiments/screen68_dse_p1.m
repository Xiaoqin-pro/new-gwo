function out=screen68_dse_p1(seeds,maxFE,D,funcs,tag)
%SCREEN68_DSE_P1  Three new arms (DSE alone / STEER+DSE-cauchy / STEER+DSE-gauss).
if nargin<1 || isempty(seeds), seeds=3071:3080; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='dse_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'dseRho',0.05,'dseTauFrac',0.02,'dseTauMin',500,'dseCapFrac',0.05);
armC=common; armC.dseMode='cauchy'; armC.succSteer=0;
armD=common; armD.dseMode='cauchy'; armD.succSteer=0.5; armD.steerLambda=0.5; armD.sdirSource='random';
armE=common; armE.dseMode='gauss';  armE.succSteer=0.5; armE.steerLambda=0.5; armE.sdirSource='random';
algs=repmat({'SGWO_DSE'},1,3);
labels={'C-DSE-Cauchy','D-STEER-DSE-Cauchy','E-STEER-DSE-Gauss'};
opt=struct(); opt.states={armC,armD,armE}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
