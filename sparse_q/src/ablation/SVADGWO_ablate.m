function [Best,T,info]=SVADGWO_ablate(f,state,variant,N,seed)
%SVADGWO_ABLATE  Ablation harness for SVAD-GWO.  Not part of the proposed algorithm.
%   variant:
%     'full'    - complete SVAD-GWO (identical to SVADGWO.m)
%     'nodiff'  - differential slots replaced by alpha-centred shells
%     'noe'     - archive slots replaced by standard GWO moves
%     'nosteer' - no directional perturbation on leader-guided wolves
%     'gwo'     - plain sparse GWO (no differential, no archive, no steer)

switch lower(variant)
    case 'full',    g='diff'; e=0; p=0.5;
    case 'nodiff',  g='shell'; e=0; p=0.5;
    case 'noe',     g='diff'; e=1; p=0.5;
    case 'nosteer', g='diff'; e=0; p=0.0;
    case 'gwo',     g='shell'; e=1; p=0.0;
    otherwise, error('SVADGWO_ablate: unknown variant %s',variant);
end
[Best,T,info]=SVADGWO_core(f,state,N,seed,g,e,p);
info.Variant=variant;
end
