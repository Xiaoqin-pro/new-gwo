function out=screen223_cass_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4170:4174; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cass_p0'; end
algs={'CMAES','CMA_DE','CMA_DE','CMA_DE','jSO'};
labels={'A-CMA','B-CASS5','C-CASS5-NoCov','D-CASS10','E-jSO'};
b=struct('cmaMixMode','random','cmaMixFraction',0.05,'cmaScoutCovUpdate',true);
c=struct('cmaMixMode','random','cmaMixFraction',0.05,'cmaScoutCovUpdate',false);
d=struct('cmaMixMode','random','cmaMixFraction',0.10,'cmaScoutCovUpdate',true);
opt=struct('states',{ {struct(),b,c,d,struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
