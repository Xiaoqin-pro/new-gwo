function out=screen72_dlh_audit(seeds,maxFE,D,funcs,tag)
%SCREEN72_DLH_AUDIT  Passive geometry audit of Sparse-DLH (behaviour = frozen G1+E+STEER).
if nargin<1 || isempty(seeds), seeds=3419:3423; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='dlh_audit'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'dlhMode','audit','dlhSeedOffset',777777,'dlhDegFrac',0.005);
opt=struct(); opt.states={st}; opt.labels={'DLH-Audit'};
out=run_batch_sq(tag,{'SGWO_DLH'},funcs,seeds,D,maxFE,opt);
end
