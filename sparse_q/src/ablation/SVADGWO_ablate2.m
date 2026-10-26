function [Best,T,info]=SVADGWO_ablate2(f,state,variant,N,seed)
%SVADGWO_ABLATE2  Strict factorial ablation harness for SVAD-GWO.
%   Not part of the proposed algorithm.  Every arm keeps the sparse evaluation
%   discipline fixed: N=50 leader-guided wolves, 12 differential-budget slots,
%   38 archive-budget slots, M=100 candidates, K=10 real evaluations per
%   generation, 100k FE.  Only the mechanism under test changes.
%
%   FACTORIAL CORE (2x2, E x DiffA)
%     'base'      useE=0, useDiff=0   sparse GWO baseline
%     'eonly'     useE=1, useDiff=0   archive on, differential off
%     'diffonly'  useE=0, useDiff=1   differential on (wolves only), no archive
%     'full'      useE=1, useDiff=1   the proposed algorithm
%
%   AUXILIARY (one component removed from full)
%     'nosteer'   STEER off, RNG draw schedule unchanged
%     'fixeddiff' F(t) fixed at 1.0 (no late contraction)
%
%   PATH DECOMPOSITION (supplementary, E as three levels)
%     'noeslots'  archive exists and feeds DiffA, but the 38 E slots are fillers
%     'noeref'    E slots on, but DiffA draws only from the wolves
%
%   Filler policy is pre-registered and identical in every arm that needs one:
%   the 12 differential slots are filled by alpha-centred shells and the 38
%   archive slots by standard GWO moves on fixed wolf indices (j-1 mod N)+1.
%   No arm gains extra candidates, extra evaluations or a looser acceptance rule.
o=struct();
switch lower(variant)
    case 'full',      o.useE=1; o.useDiff=1;
    case 'base',      o.useE=0; o.useDiff=0;
    case 'eonly',     o.useE=1; o.useDiff=0;
    case 'diffonly',  o.useE=0; o.useDiff=1;
    case 'nosteer',   o.useE=1; o.useDiff=1; o.pSteerOn=0;
    case 'fixeddiff', o.useE=1; o.useDiff=1; o.fixedF=1.0;
    case 'noeslots',  o.useE=1; o.useDiff=1; o.eSlots=0;
    case 'noeref',    o.useE=1; o.useDiff=1; o.diffPool='wolves';
    % --- uniform-filler variants: the 12 differential-budget slots are filled
    % with plain GWO moves instead of alpha shells, so switching DiffA off means
    % "replace DiffA by ordinary GWO", not "replace it by a local operator".
    case 'baseg',     o.useE=0; o.useDiff=0; o.diffFiller='gwo';
    case 'eonlyg',    o.useE=1; o.useDiff=0; o.diffFiller='gwo';
    otherwise, error('SVADGWO_ablate2: unknown variant %s',variant);
end
if ~isfield(o,'diffFiller'), o.diffFiller='shell'; end
p=1.0; if isfield(o,'pSteerOn'), p=o.pSteerOn; end
e=0;  if isfield(o,'eSlots') && o.eSlots==0, e=1; end
[Best,T,info]=SVADGWO_core(f,state,N,seed,'diff',e,p,o);
info.Variant=variant;
end
