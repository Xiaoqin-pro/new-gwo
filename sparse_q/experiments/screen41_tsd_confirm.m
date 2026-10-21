function out=screen41_tsd_confirm(seeds,maxFE,D,funcs,tag)
%SCREEN41_TSD_CONFIRM  New B/C arms; A-G1E is reused from ablcore A2-G1E.
%   A  = ablcore_20261017_062209 / A2-G1E (29 funcs, seeds 3071:3100, 100k FE)
%   B  = VGA single-state strict acceptance
%   C  = TSD base (P/Z decoupling)
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='tsd_confirm_bc'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0);
armB=base; armB.vgaMode='verified'; armB.vgaSeedOffset=999999;
armC=base; armC.tsdMode='base';

algs  ={'SGWO_VGA','SGWO_TSD'};
labels={'B-VGA','C-TSDbase'};
states=cell(1,2); states{1}=armB; states{2}=armC;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
