function out=screen226_covsteer_dev2(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4179:4180; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='covsteer_dev2'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
b=base; b.steerMode='cov'; b.covSteerSource='wolves';
c=base; c.steerMode='cov'; c.covSteerSource='shuffled';
d=base; d.steerMode='cov'; d.covSteerSource='wolves_random';
e=base; e.succSteer=0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-RandomSTEER','B-CovWolves','C-CovShuffled','D-CovRandomWolves','E-NoSTEER'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
