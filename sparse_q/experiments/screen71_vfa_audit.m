function out=screen71_vfa_audit(seeds,maxFE,D,funcs,tag)
%SCREEN71_VFA_AUDIT  Passive shadow audit of the two-layer archive premise (behaviour = frozen).
if nargin<1 || isempty(seeds), seeds=3414:3418; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='vfa_audit'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'vfaMode','shadow','vfaCap',8, ...
    'vfaSepFrac',0.02,'vfaQualQ',0.25,'vfaSlots',4);
opt=struct(); opt.states={st}; opt.labels={'VFA-Audit'};
out=run_batch_sq(tag,{'SGWO_VFA'},funcs,seeds,D,maxFE,opt);
end
