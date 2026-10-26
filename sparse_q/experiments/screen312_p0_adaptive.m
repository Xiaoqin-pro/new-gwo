function out=screen312_p0_adaptive(seeds,maxFE,D,funcs,tag)
%SCREEN312_P0_ADAPTIVE  P0 for yield-based adaptive slot allocation: 29 fn x 6 seeds.
%   A0  fixed 50/12/38, random screening     (the old hand-set ratio)
%   A1  adaptive slots, random screening     (ratios emerge from source yield)
%   A2  adaptive slots, beta=1.0             (gentler allocation)
%   A3  adaptive slots, beta=4.0             (sharper allocation)
if nargin<1 || isempty(seeds), seeds=4821:4826; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_adaptive_v2'; end
st={ struct('screening','rand','adaptSlots',0,'nG2',12,'nE',38), ...
     struct('screening','rand','adaptSlots',1,'allocBeta',2.0), ...
     struct('screening','rand','adaptSlots',1,'allocBeta',1.0), ...
     struct('screening','rand','adaptSlots',1,'allocBeta',4.0) };
labels={'A0-fixed-12/38','A1-adapt-b2','A2-adapt-b1','A3-adapt-b4'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,4),funcs(:),seeds(:),D,maxFE,opt);
end
