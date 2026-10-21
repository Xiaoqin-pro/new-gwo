function out=screen34_ecps(seeds,maxFE,D,funcs,tag)
%SCREEN34_ECPS  4-arm P1: standard GWO aggregation vs evaluation-credited proposal selection.
if nargin<1 || isempty(seeds), seeds=3196:3205; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='ecps_p1'; end

base=struct('mode','sparse','K',10,'nG2',0,'nE',50,'screenPolicy','random');
armA=base; armA.ecpsMode='none'; armA.ecpsWindow=1000; armA.ecpsSeedOffset=777777;
armB=base; armB.ecpsMode='ecps'; armB.ecpsWindow=1000; armB.ecpsSeedOffset=777777;
armC=base; armC.ecpsMode='random'; armC.ecpsWindow=1000; armC.ecpsSeedOffset=777777;

algs  ={'SGWO_ECPS','SGWO_ECPS','SGWO_ECPS','SGWO'};
labels={'A-TwoRoute','B-ECPS','C-RandomProposal','D-V1'};
states=cell(1,4); states{1}=armA; states{2}=armB; states{3}=armC;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
