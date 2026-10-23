function out=screen80_mse_p0(seeds,maxFE,D,funcs,tag)
%SCREEN80_MSE_P0  Passive audit of the multi-scale elite shell (MSE).  Pre-registration: docs/72.
if nargin<1 || isempty(seeds), seeds=3489:3493; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='mse_p0'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'mseMode','audit','mseSeedOffset',777777);
algs={'SGWO_MSE'}; labels={'MSE-Audit'};
opt=struct(); opt.states={st}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
