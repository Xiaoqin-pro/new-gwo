function out=screen233_qtopo_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4193:4194; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='qtopo_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
b=base; b.leaderTopo='knn'; b.knnK=10; b.leaderBlend=1.0;
c=base; c.topoPolicy='random';
d=base; d.topoPolicy='q'; d.topoActions=[0 5 10 20]; d.topoAlpha=0.1; d.topoGamma=0.9; d.topoEpsStart=0.30; d.topoEpsEnd=0.05;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Global','B-FixedKNN10','C-RandomTopo','D-QTopo'};
opt=struct('states',{ {base,b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
