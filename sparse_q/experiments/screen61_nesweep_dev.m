function out=screen61_nesweep_dev(seeds,maxFE,D,funcs,tag)
%SCREEN61_NESWEEP_DEV  Slot-composition dev sweep: E vs standard GWO filler slots.
if nargin<1 || isempty(seeds), seeds=3369:3378; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='nesweep_dev'; end
nEList=[0 10 19 28 38 48 50];
nArm=numel(nEList);
algs=repmat({'SGWOAB'},1,nArm); labels=cell(1,nArm); states=cell(1,nArm);
for k=1:nArm
    nE=nEList(k);
    st=struct('mode','sparse','K',10,'nG2',50-nE,'nE',nE,'screenPolicy','random', ...
        'ablateG2',1,'ablateE',0);
    states{k}=st;
    labels{k}=sprintf('E%02d',nE);
end
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
