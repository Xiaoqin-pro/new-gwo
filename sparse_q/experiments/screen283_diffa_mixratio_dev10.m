function out=screen283_diffa_mixratio_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4414:4423; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_mixratio_dev10'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','mix','g2F',1.0,'g2Fend',0.3,'g2Pool','pool','g2Anchor','any');
a=base;                              % A: shell6/diff6 (当前 mix 默认)
b=base; b.g2MixDiff=0;               % B: shell0/diff12 (=全差分 Fdecay)
c=base; c.g2MixDiff=3;               % C: shell3/diff9
d=base; d.g2MixDiff=9;               % D: shell9/diff3
e=base; e.g2MixDiff=12;              % E: shell12/diff0 (=纯 α壳 Fdecay)
f=base; f.g2Mode='diffa'; f.g2MixDiff=nan; f.g2F=1.0; f.g2Fend=nan;  % F: 全差分 F=1.0 (最强 confirm30 参考)
algs=repmat({'SGWO_STEER3'},1,6);
labels={'A-S6D6','B-S0D12','C-S3D9','D-S9D3','E-S12D0','F-DiffA-F10'};
opt=struct('states',{ {a,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
