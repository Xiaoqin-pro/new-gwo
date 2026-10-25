function out=screen228_qdleader_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4183:4184; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='qdleader_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderMode','global');
b=base; b.leaderMode='qd';
c=base; c.leaderMode='qdhalf'; c.qdShare=0.5;
d=base; d.leaderMode='qdrand';
e=base; e.succSteer=0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-GlobalLeaders','B-QDAll','C-QDHalf','D-QDRandom','E-NoSTEER'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
