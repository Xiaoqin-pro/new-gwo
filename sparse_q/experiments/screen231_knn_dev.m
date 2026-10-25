function out=screen231_knn_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4189:4190; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='knn_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
b=base; b.leaderTopo='knn'; b.knnK=5;
c=base; c.leaderTopo='knn'; c.knnK=10;
d=base; d.leaderTopo='knn'; d.knnK=20;
e=base; e.leaderTopo='knnrand'; e.knnK=10;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Global','B-KNN5','C-KNN10','D-KNN20','E-KNNRand10'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
