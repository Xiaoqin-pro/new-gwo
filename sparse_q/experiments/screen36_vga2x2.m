function out=screen36_vga2x2(seeds,maxFE,D,funcs,tag)
%SCREEN36_VGA2X2  G2-off/on x standard/verified G1 parent acceptance.
if nargin<1 || isempty(seeds), seeds=3216:3225; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='vga_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
armA=base; armA.ablateG2=1; armA.ablateE=0;
armB=base; armB.ablateG2=1; armB.ablateE=0; armB.vgaMode='verified'; armB.vgaSeedOffset=999999;
armC=base; armC.ablateG2=0; armC.ablateE=0;
armD=base; armD.ablateG2=0; armD.ablateE=0; armD.vgaMode='verified'; armD.vgaSeedOffset=999999;
armR=base; armR.ablateG2=1; armR.ablateE=0; armR.vgaMode='random'; armR.vgaSeedOffset=999999;

algs  ={'SGWOAB','SGWO_VGA','SGWOAB','SGWO_VGA','SGWO_VGA'};
labels={'A-Std-G2off','B-VGA-G2off','C-Std-G2on','D-VGA-G2on','R-RandomAccept-G2off'};
states=cell(1,5); states{1}=armA; states{2}=armB; states{3}=armC; states{4}=armD; states{5}=armR;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
