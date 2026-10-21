function out=screen30_enac(seeds,maxFE,D,funcs,tag)
%SCREEN30_ENAC  Pre-registered ENAC P1 with identity-only control.
if nargin<1 || isempty(seeds), seeds=3151:3160; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[7 10 13 16 18 22 24 30]; end
if nargin<5 || isempty(tag), tag='enac_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
idc=base; idc.enacOn=1; idc.enacMode='identity'; idc.enacA=1; idc.enacB=1;
ena=idc; ena.enacMode='enac';

algs  ={'SGWO','SGWO_ENAC','SGWO_ENAC'};
labels={'V1-Frozen','Identity-Credit','ENAC'};
states=cell(1,3); states{2}=idc; states{3}=ena;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
