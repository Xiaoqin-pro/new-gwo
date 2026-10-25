function out=screen235_qtopo_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4200:4204; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='qtopo_p0'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
q=base; q.topoPolicy='q'; q.topoActions=[0 5 10 20]; q.topoAlpha=0.1; q.topoGamma=0.9; q.topoEpsStart=0.30; q.topoEpsEnd=0.05; q.topoEpsDecay=0.995; q.topoInitPrior=0;
r=base; r.topoPolicy='random'; r.topoActions=[0 5 10 20];
d=base; d.leaderTopo='knn'; d.knnK=10; d.leaderBlend=1.0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Global','B-QTopo','C-RandomTopo','D-FixedKNN10'};
opt=struct('states',{ {base,q,r,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
