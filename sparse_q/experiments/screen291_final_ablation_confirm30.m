function out=screen291_final_ablation_confirm30(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='final_ablation_confirm30'; end
fin=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','diffa','g2F',1.0,'g2Fend',0.3,'g2FendFrac',0.7,'g2Pool','pool','g2Anchor','any');
a=fin;                          % A: 最终结构
b=fin; b.g2Mode='shell';        % B: 无差分
c=fin; c.ablateE=1;             % C: 无 E
d=fin; d.succSteer=0;           % D: 无 STEER
algs=repmat({'SGWO_STEER3'},1,4);
labels={'A-Final','B-NoDiff','C-NoE','D-NoSteer'};
opt=struct('states',{ {a,b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
