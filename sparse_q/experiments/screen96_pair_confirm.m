function out=screen96_pair_confirm(seeds,maxFE,D,funcs,tag,resume)
%SCREEN96_PAIR_CONFIRM  Quality-aware elite pairing vs shuffled-rank control (frozen arm reused). docs/89
%   Optional sixth argument resume=<batch dir> enables RFC-style continuation.
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='pair_confirm'; end
if nargin<6, resume=''; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armB=common; armB.pairMode='quality';
armC=common; armC.pairMode='shuffled';
algs=repmat({'SGWO_PAIR'},1,2);
labels={'B-PAIR-Quality','C-PAIR-Shuffled'};
opt=struct(); opt.states={armB,armC}; opt.labels=labels;
if ~isempty(resume), opt.resume=char(resume); end
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
