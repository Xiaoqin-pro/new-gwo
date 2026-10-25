function out=screen242_kbudget20_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4227:4228; end
if nargin<2 || isempty(maxFE), maxFE=20000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='kbudget20_dev'; end
base=struct('mode','sparse','K',10,'kSchedule','fixed','kEnd',50,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
b=base; b.K=25;
c=base; c.K=50;
d=base; d.kSchedule='up'; d.K=10; d.kEnd=50;
e=base; e.kSchedule='down'; e.K=10; e.kEnd=50;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-K10','B-K25','C-K50','D-Up10to50','E-Down50to10'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
