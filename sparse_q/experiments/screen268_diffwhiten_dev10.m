function out=screen268_diffwhiten_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4319:4328; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 5 6 7 8 9 10 11 13 14 18 20 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffwhiten_dev10'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5);
a=base;
b=base; b.opFixed=2; b.opDiffMode='nowarc';      % 普通差分（参考，已知旋转灾难）
c=base; c.opFixed=2; c.opDiffMode='whiten';      % 白化差分（修复旋转）
d=base; d.opFixed=2; d.opDiffMode='shuffle';     % 打乱对照（方向信息对照）
algs=repmat({'SGWO_STEER3'},1,4);
labels={'A-Standard','B-DiffPlain','C-DiffWhiten','D-DiffShuffle'};
opt=struct('states',{ {a,b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
