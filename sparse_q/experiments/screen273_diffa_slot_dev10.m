function out=screen273_diffa_slot_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4359:4368; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_slot_dev10'; end
% A: 冻结（G1 标准 + G2 shell + E）
a=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
% B: G2 纯差分槽位（参考，已知 F1 退化）
b=a; b.g2Mode='diff'; b.g2Pool='pool';
% C: G2 toward-alpha 差分槽位（新，F1 收益 + 安全门）
c=a; c.g2Mode='diffa'; c.g2Pool='pool';
% D: G2 toward-alpha 差分槽位 F=1.0（更激进）
d=a; d.g2Mode='diffa'; d.g2Pool='pool'; d.g2F=1.0;
algs=repmat({'SGWO_STEER3'},1,4);
labels={'A-Frozen','B-DiffSlot','C-DiffASlot','D-DiffASlot-F10'};
opt=struct('states',{ {a,b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
