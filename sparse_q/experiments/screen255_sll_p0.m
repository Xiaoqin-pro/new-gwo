function out=screen255_sll_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4271:4275; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='sll_p0'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
b=base; b.leaderTopo='featknnrandall'; b.knnK=10; b.leaderBlend=1;
c=base; c.leaderTopo='featknnrandall'; c.knnK=20; c.leaderBlend=1;
d=base; d.leaderTopo='knnall'; d.knnK=10; d.leaderBlend=1;
e=base; e.leaderTopo='featknnall'; e.knnK=10; e.leaderBlend=1; e.topoEvery=50;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Global','B-SLL10','C-SLL20','D-EuclidAll10','E-GraphAll10'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
