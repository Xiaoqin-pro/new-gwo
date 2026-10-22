function out=screen51_ref_p1(seeds,maxFE,D,funcs,tag)
%SCREEN51_REF_P1  Three-arm REF pilot: A standard fillers, B REF, C uniform immigrants.
if nargin<1 || isempty(seeds), seeds=3306:3315; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='ref_p1'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'refSeedOffset',666666);
armA=base; armA.refMode='none';
armB=base; armB.refMode='ref';
armC=base; armC.refMode='uniform';
algs={'SGWOAB','SGWO_REF','SGWO_REF'}; labels={'A-FrozenFill','B-REF','C-UniformImmigrant'};
states={armA,armB,armC};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
