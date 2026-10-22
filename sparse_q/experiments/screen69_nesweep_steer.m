function out=screen69_nesweep_steer(seeds,maxFE,D,funcs,tag)
%SCREEN69_NESWEEP_STEER  Slot-composition sweep of nE with the confirmed STEER enabled.
if nargin<1 || isempty(seeds), seeds=3404:3413; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='nesweep_steer'; end
nEList=[0 10 19 28 38 48 50];
nArm=numel(nEList);
algs=repmat({'SGWO_STEER'},1,nArm); labels=cell(1,nArm); states=cell(1,nArm);
for k=1:nArm
    nE=nEList(k);
    st=struct('mode','sparse','K',10,'nG2',50-nE,'nE',nE,'screenPolicy','random', ...
        'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
        'succSteer',0.5,'steerLambda',0.5);
    states{k}=st;
    labels{k}=sprintf('NE%02d-STEER',nE);
end
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
