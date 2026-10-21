function out=screen32_amc(seeds,maxFE,D,funcs,tag)
%SCREEN32_AMC  5-arm factorial P1: archive credit x adaptive move control.
if nargin<1 || isempty(seeds), seeds=3176:3185; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='amc_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
armA=base; armA.enacOn=1; armA.enacMode='identity'; armA.amcOn=0; armA.amcWindow=10; armA.amcSuccessThresh=0.2; armA.amcExpand=1.10; armA.amcShrink=0.90; armA.amcGammaMax=2.0; armA.amcGammaMin=1.0;
armB=base; armB.enacOn=1; armB.enacMode='enac';     armB.amcOn=0; armB.amcWindow=10; armB.amcSuccessThresh=0.2; armB.amcExpand=1.10; armB.amcShrink=0.90; armB.amcGammaMax=2.0; armB.amcGammaMin=1.0;
armC=armA; armC.amcOn=1;
armD=armB; armD.amcOn=1;

algs  ={'SGWO_AMC','SGWO_AMC','SGWO_AMC','SGWO_AMC','SGWO'};
labels={'A-Identity','B-ENAC','C-Identity-AMC','D-ENAC-AMC','E-V1'};
states=cell(1,5); states{1}=armA; states{2}=armB; states{3}=armC; states{4}=armD;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
