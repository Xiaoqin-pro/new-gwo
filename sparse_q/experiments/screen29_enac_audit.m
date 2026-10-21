function out=screen29_enac_audit(seeds,maxFE,D,funcs,tag)
%SCREEN29_ENAC_AUDIT  Passive P0 audit for archive-credit identity/exposure.
if nargin<1 || isempty(seeds), seeds=3161:3165; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[7 10 13 16 18 22 24 30]; end
if nargin<5 || isempty(tag), tag='enac_audit'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
aud=base; aud.auditOn=1;
opt=struct(); opt.states={aud}; opt.labels={'V1-Audit'};
out=run_batch_sq(tag,{'SGWO_ENAC_AUDIT'},funcs,seeds,D,maxFE,opt);
end
