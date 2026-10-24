function out=screen286_final_ablation_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4444:4453; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='final_ablation_p0'; end
% 最终结构：G1(STEER) + G2(diffa F1 pool) + E(38)
fin=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','diffa','g2F',1.0,'g2Pool','pool','g2Anchor','any');
% A: 完整最终算法
a=fin;
% B: 去掉差分（G2 用 shell 填回）
b=fin; b.g2Mode='shell';
% C: 去掉 E（E 槽位用标准 GWO 候选填补）
c=fin; c.ablateE=1;
% D: 去掉 STEER
d=fin; d.succSteer=0;
% E: GWO-only（去掉差分+E+STEER，G2 槽位用标准 GWO 填补）
e=fin; e.g2Mode='shell'; e.ablateE=1; e.succSteer=0;
algs=repmat({'SGWO_STEER3'},1,5);
labels={'A-Final','B-NoDiff','C-NoE','D-NoSteer','E-GWOonly'};
opt=struct('states',{ {a,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
