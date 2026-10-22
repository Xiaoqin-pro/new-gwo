function out=screen67_dse_audit(seeds,maxFE,D,funcs,tag)
%SCREEN67_DSE_AUDIT  Passive audit of the DSE dual-stagnation premise (behaviour = frozen).
if nargin<1 || isempty(seeds), seeds=3399:3403; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='dse_audit'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','dsaudit','stjTauFrac',0.02,'stjTauMin',500);
opt=struct(); opt.states={st}; opt.labels={'DSE-AUDIT'};
out=run_batch_sq(tag,{'SGWO_STEER'},funcs,seeds,D,maxFE,opt);
end
