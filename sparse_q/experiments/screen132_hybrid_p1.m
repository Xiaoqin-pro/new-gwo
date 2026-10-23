function out=screen132_hybrid_p1(seeds,maxFE,D,funcs,tag)
%SCREEN132_HYBRID_P1  GWO->LSHADE P1.
if nargin<1 || isempty(seeds), seeds=3774:3783; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='hybrid_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common;
armB=common; armB.hybFrac=0.50;
algs={'SGWO_STEER3','SGWO_HYBRID'};
labels={'A-Frozen','B-Hybrid'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
