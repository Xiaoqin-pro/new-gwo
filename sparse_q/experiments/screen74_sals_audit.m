function out=screen74_sals_audit(seeds,maxFE,D,funcs,tag)
%SCREEN74_SALS_AUDIT  Passive audit of post-selection coefficient sampling (behaviour = frozen).
if nargin<1 || isempty(seeds), seeds=3434:3438; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='sals_audit'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'salsMode','audit','salsSeedOffset',555111);
opt=struct(); opt.states={st}; opt.labels={'SALS-Audit'};
out=run_batch_sq(tag,{'SGWO_SALS'},funcs,seeds,D,maxFE,opt);
end
