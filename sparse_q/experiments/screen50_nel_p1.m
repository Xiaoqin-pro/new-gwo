function out=screen50_nel_p1(seeds,maxFE,D,funcs,tag)
%SCREEN50_NEL_P1  Three-arm NEL pilot: A standard fillers, B NEL, C random exemplar.
if nargin<1 || isempty(seeds), seeds=3301:3305; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='nel_p1'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'nelNeighbors',10,'nelPc',0.5,'nelPert',0.1,'nelSeedOffset',555555);
armA=base; armA.nelMode='none';
armB=base; armB.nelMode='on';
armC=base; armC.nelMode='random';
algs={'SGWOAB','SGWO_NEL','SGWO_NEL'}; labels={'A-FrozenFill','B-NEL','C-RandomExemplar'};
states={armA,armB,armC};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
