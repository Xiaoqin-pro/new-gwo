function out=screen227_covsteer_dev3(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4181:4182; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='covsteer_dev3'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
b=base; b.steerMode='cov'; b.covSteerSource='wolves'; b.covSteerBlend=0.50;
c=base; c.steerMode='cov'; c.covSteerSource='wolves'; c.covSteerBlend=0.75;
d=base; d.steerMode='cov'; d.covSteerSource='wolves'; d.covSteerBlend=1.00;
e=base; e.succSteer=0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-RandomSTEER','B-CovBeta0.5','C-CovBeta0.75','D-CovBeta1.0','E-NoSTEER'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
