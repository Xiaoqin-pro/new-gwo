function out=screen94_null_control(seeds,maxFE,D,funcs,tag)
%SCREEN94_NULL_CONTROL  Four random-stream offsets of the SAME frozen algorithm (docs/87).
if nargin<1 || isempty(seeds), seeds=3071:3080; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='null_control'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
arm1=common; arm1.nullOffset=900001;
arm2=common; arm2.nullOffset=900002;
arm3=common; arm3.nullOffset=900003;
arm4=common; arm4.nullOffset=900004;
algs=repmat({'SGWO_NULL'},1,4);
labels={'N1-Off900001','N2-Off900002','N3-Off900003','N4-Off900004'};
opt=struct(); opt.states={arm1,arm2,arm3,arm4}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
