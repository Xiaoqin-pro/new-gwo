function out=screen246_featknn_dev3(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4237:4238; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='featknn_dev3'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
b=base; b.leaderTopo='featknn'; b.knnK=20; b.leaderBlend=1; b.topoEvery=10;
c=base; c.leaderTopo='featknn'; c.knnK=20; c.leaderBlend=0.8; c.topoEvery=10;
d=base; d.leaderTopo='featknnrand'; d.knnK=20; d.leaderBlend=0.8; d.topoEvery=10;
e=base; e.leaderTopo='knn'; e.knnK=10; e.leaderBlend=1;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Global','B-FeatKNN20','C-FeatKNN20-Blend0.8','D-FeatRand20-Blend0.8','E-EuclidKNN10'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
