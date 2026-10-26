function out=screen307_p0_screening(seeds,maxFE,D,funcs,tag)
%SCREEN307_P0_SCREENING  P0 screening-rule screen: 29 functions x 6 fresh seeds.
%   Arms (all with the frozen v2 structure: G1 GWO, G2 DiffA, E archive; no STEER;
%   uniform GWO filler; M=100, K=10, 50/12/38 slots):
%     S0  uniform random          (current baseline)
%     S1  maximin coreset, alpha-anchored          (fps)
%     S2  maximin coreset, random anchor           (fpsr, control for the anchor)
%     S3  source-guaranteed maximin coreset        (core, our proposal)
if nargin<1 || isempty(seeds), seeds=4801:4806; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_screening'; end
scr={'rand','fps','fpsr','core'};
labels={'S0-rand','S1-fps','S2-fpsr','S3-core'};
st=cell(1,numel(scr));
for k=1:numel(scr), st{k}=struct('screening',scr{k}); end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,numel(scr)),funcs(:),seeds(:),D,maxFE,opt);
end
