function out=screen26_sfac(seeds,maxFE,D,funcs,tag)
%SCREEN26_SFAC  Pre-registered P1 for success-failure adaptive archive credit.
if nargin<1 || isempty(seeds), seeds=3121:3130; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[7 10 13 14 16 18 22 24]; end
if nargin<5 || isempty(tag), tag='sfac_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
sfac=base; sfac.sfacOn=1; sfac.sfacUniform=0; sfac.sfacDecay=1; sfac.sfacFloor=0;

algs  ={'SGWO','SGWO_SFAC'};
labels={'V1-Frozen','V1-SFAC'};
states=cell(1,2); states{2}=sfac;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
