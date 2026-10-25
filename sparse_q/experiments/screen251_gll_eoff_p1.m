function out=screen251_gll_eoff_p1(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4251:4260; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='gll_eoff_p1'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',1,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
d=base; d.leaderTopo='featknn'; d.knnK=20; d.leaderBlend=1; d.topoEvery=50;
algs={'SGWO_STEER3','SGWO_STEER3'};
labels={'C-Global-Eoff','D-GLL20-Eoff'};
opt=struct('states',{ {base,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
