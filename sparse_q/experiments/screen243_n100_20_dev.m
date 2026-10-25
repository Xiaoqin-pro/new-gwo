function out=screen243_n100_20_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4231:4232; end
if nargin<2 || isempty(maxFE), maxFE=20000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='n100_20_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
b=base;
c=base; c.nG2=12; c.nE=88;
d=base; d.nG2=12; d.nE=88; d.K=20;
algs={'SGWO_STEER3','SGWO100','SGWO100','SGWO100'};
labels={'A-N50M100K10','B-N100M150K10','C-N100M200K10','D-N100M200K20'};
opt=struct('states',{ {base,b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
