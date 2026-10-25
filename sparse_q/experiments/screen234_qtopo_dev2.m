function out=screen234_qtopo_dev2(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4195:4196; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='qtopo_dev2'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'leaderTopo','global');
q0=struct('topoPolicy','q','topoActions',[0 5 10 20]);
b=base; b=mergeStruct(b,q0); b.topoEpsStart=0.30; b.topoEpsEnd=0.05; b.topoEpsDecay=0.995; b.topoInitPrior=0;
c=base; c=mergeStruct(c,q0); c.topoEpsStart=0.10; c.topoEpsEnd=0.02; c.topoEpsDecay=0.98; c.topoInitPrior=0;
d=base; d=mergeStruct(d,q0); d.topoEpsStart=0.30; d.topoEpsEnd=0.05; d.topoEpsDecay=0.995; d.topoInitPrior=0.10;
e=base; e=mergeStruct(e,q0); e.topoEpsStart=0.10; e.topoEpsEnd=0.02; e.topoEpsDecay=0.98; e.topoInitPrior=0.10;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Global','B-QCurrent','C-QConservative','D-QPrior','E-QPriorConservative'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
function s=mergeStruct(a,b)
s=a; fn=fieldnames(b); for i=1:numel(fn), s.(fn{i})=b.(fn{i}); end
end
