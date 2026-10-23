function out=screen129_ghs_late_p0(seeds,maxFE,D,funcs,tag)
%SCREEN129_GHS_LATE_P0  Late SHADE phase P0.
if nargin<1 || isempty(seeds), seeds=3754:3758; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='ghs_late_p0'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.hybMode='off';
armB=common; armB.hybMode='shade'; armB.hybN=50; armB.hybStartFrac=0.5;
algs=repmat({'SGWO_GHS'},1,2);
labels={'A-GHS-Off','B-GHS-Late'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
