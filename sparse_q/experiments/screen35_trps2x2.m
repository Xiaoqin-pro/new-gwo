function out=screen35_trps2x2(seeds,maxFE,D,funcs,tag)
%SCREEN35_TRPS2X2  G2-off/on x standard/trust-region proposal selection.
if nargin<1 || isempty(seeds), seeds=3206:3215; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='trps_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
armA=base; armA.ablateG2=1; armA.ablateE=0;
armB=base; armB.ablateG2=1; armB.ablateE=0; armB.trpsMode='trps'; ...
    armB.trpsWindow=1000; armB.trpsSeedOffset=888888;
armC=base; armC.ablateG2=0; armC.ablateE=0;
armD=base; armD.ablateG2=0; armD.ablateE=0; armD.trpsMode='trps'; ...
    armD.trpsWindow=1000; armD.trpsSeedOffset=888888;
armR=base; armR.ablateG2=1; armR.ablateE=0; armR.trpsMode='random'; ...
    armR.trpsWindow=1000; armR.trpsSeedOffset=888888;

algs  ={'SGWOAB','SGWO_TRPS','SGWOAB','SGWO_TRPS','SGWO_TRPS'};
labels={'A-Std-G2off','B-TRPS-G2off','C-Std-G2on','D-TRPS-G2on','R-RandomTR-G2off'};
states=cell(1,5); states{1}=armA; states{2}=armB; states{3}=armC; states{4}=armD; states{5}=armR;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
