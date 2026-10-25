function out=screen211_cma_de_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4141:4145; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_de_p0'; end
algs={'CMAES','CMA_DE','CMA_DE','CMA_DE','jSO'};
labels={'A-CMA','B-DE5','C-PermutedDE5','D-Random5','E-jSO'};
b=struct('cmaMixMode','always','cmaMixFraction',0.05,'cmaMixScale',0.35,'cmaMixStepCap',1.0);
c=struct('cmaMixMode','permuted','cmaMixFraction',0.05,'cmaMixScale',0.35,'cmaMixStepCap',1.0);
d=struct('cmaMixMode','random','cmaMixFraction',0.05);
opt=struct('states',{ {struct(),b,c,d,struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
