function out=screen253_localtriad_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4263:4264; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='localtriad_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
b=base; b.leaderTopo='featknn'; b.knnK=20; b.leaderBlend=1;
c=base; c.leaderTopo='featknnall'; c.knnK=10; c.leaderBlend=1;
d=base; d.leaderTopo='featknnall'; d.knnK=20; d.leaderBlend=1;
e=base; e.leaderTopo='featknnall'; e.knnK=30; e.leaderBlend=1;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Global','B-GlobalAlphaLocalBD','C-LocalAll10','D-LocalAll20','E-LocalAll30'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
