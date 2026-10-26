function [Best,T,info]=SVADGWO2_ablate(f,state,variant,N,seed)
%SVADGWO2_ABLATE  Ablation harness for the final SVAD-GWO (no pool, quota 4/3/3).
%   Not part of the proposed algorithm.  Design principle: the ablation replaces
%   GENERATORS, never the EVALUATION BUDGET.  Every arm spends exactly K=10 real
%   evaluations per generation and generates exactly 10 candidates; when a
%   mechanism is removed its quota is handed to the leader-guided GWO generator,
%   so no arm gains or loses evaluation budget.
%
%     'full'      G1 4 + DiffA 3 + E 3        the proposed algorithm
%     'base'      G1 10                        sparse GWO, no DiffA, no archive
%     'eonly'     G1 7 + E 3                   archive only
%     'diffonly'  G1 7 + DiffA 3               differential only (wolves pool)
%
%   Acceptance rules, archive maintenance and the leader update are identical in
%   every arm; only the provenance of the 10 candidates changes.
o=struct('M',10,'K',10,'adaptSlots',0,'adaptK',0,'screening','rand');
switch lower(variant)
    case 'full',      o.nG2=3; o.nE=3; o.useE=1; o.useDiff=1;
    case 'base',      o.nG2=0; o.nE=0; o.useE=0; o.useDiff=0;
    case 'eonly',     o.nG2=0; o.nE=3; o.useE=1; o.useDiff=0;
    case 'diffonly',  o.nG2=3; o.nE=0; o.useE=0; o.useDiff=1;
    case 'fixeddiff', o.nG2=3; o.nE=3; o.useE=1; o.useDiff=1; o.fixedF=1.0;
    otherwise, error('SVADGWO2_ablate: unknown variant %s',variant);
end
o.diffFiller='gwo';
[Best,T,info]=SVADGWO2_core(f,state,N,seed,'diff',0,o);
info.Variant=variant;
end
