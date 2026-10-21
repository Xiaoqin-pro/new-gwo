function out=screen33_cala(seeds,maxFE,D,funcs,tag)
%SCREEN33_CALA  4-arm P1: two-route G1+E with CALA and RandomLeader control.
if nargin<1 || isempty(seeds), seeds=3186:3195; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='cala_p1'; end

base=struct('mode','sparse','K',10,'nG2',0,'nE',50,'screenPolicy','random');
armA=base; armA.calaMode='none'; armA.calaEps=1e-12; armA.calaSeedOffset=666666;
armB=base; armB.calaMode='cala'; armB.calaEps=1e-12; armB.calaSeedOffset=666666;
armC=base; armC.calaMode='random'; armC.calaEps=1e-12; armC.calaSeedOffset=666666;

algs  ={'SGWO_CALA','SGWO_CALA','SGWO_CALA','SGWO'};
labels={'A-TwoRoute','B-CALA','C-RandomLeader','D-V1'};
states=cell(1,4); states{1}=armA; states{2}=armB; states{3}=armC;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
