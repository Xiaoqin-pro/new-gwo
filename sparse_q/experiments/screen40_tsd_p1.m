function out=screen40_tsd_p1(seeds,maxFE,D,funcs,tag)
%SCREEN40_TSD_P1  Four-arm TSD P1: frozen, VGA, TSD-base, TSD-full.
if nargin<1 || isempty(seeds), seeds=3261:3270; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='tsd_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0);
armA=base;
armB=base; armB.vgaMode='verified'; armB.vgaSeedOffset=999999;
armC=base; armC.tsdMode='base';
armD=base; armD.tsdMode='full';

algs  ={'SGWOAB','SGWO_VGA','SGWO_TSD','SGWO_TSD'};
labels={'A-Frozen','B-VGA','C-TSDbase','D-TSDfull'};
states=cell(1,4); states{1}=armA; states{2}=armB; states{3}=armC; states{4}=armD;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
