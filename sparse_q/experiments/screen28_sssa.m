function out=screen28_sssa(seeds,maxFE,D,funcs,tag)
%SCREEN28_SSSA  Pre-registered P1 for source-specific success-scale adaptation.
if nargin<1 || isempty(seeds), seeds=3141:3150; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[7 10 13 16 18 22 24 30]; end
if nargin<5 || isempty(tag), tag='sssa_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
sssa=base; sssa.sssaOn=1; sssa.sssaSwap=0;
sssa.sssaCap=25; sssa.sssaMin=5; sssa.sssaInitFrac=0.05; sssa.sssaFloorFrac=0.01;
swap=sssa; swap.sssaSwap=1;

algs  ={'SGWO','SGWO_SSSA','SGWO_SSSA'};
labels={'V1-Frozen','SSSA','SSSA-Swap'};
states=cell(1,3); states{2}=sssa; states{3}=swap;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
