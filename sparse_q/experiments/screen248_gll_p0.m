function out=screen248_gll_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4241:4245; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='gll_p0'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
b=base; b.leaderTopo='featknn'; b.knnK=20; b.leaderBlend=1; b.topoEvery=50;
c=base; c.leaderTopo='knn'; c.knnK=10; c.leaderBlend=1;
d=base; d.leaderTopo='featknnrand'; d.knnK=20; d.leaderBlend=1; d.topoEvery=50;
e=base; e.leaderTopo='featknn'; e.knnK=20; e.leaderBlend=0.8; e.topoEvery=50;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Global','B-GLL20','C-EuclidKNN10','D-RandLocal20','E-GLL20-Blend0.8'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
