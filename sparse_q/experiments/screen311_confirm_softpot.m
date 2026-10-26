function out=screen311_confirm_softpot(seeds,maxFE,D,funcs,tag)
%SCREEN311_CONFIRM_SOFTPOT  Confirmation of the soft potential rule on fresh seeds.
%   C0  uniform random
%   C1  softpot gA=0.5 gR=0.5   P0 winner
%   C2  softpot gA=0.5 gR=0.25  weaker novelty
%   C3  softpot gA=0.75 gR=0.5  between P0 winners
if nargin<1 || isempty(seeds), seeds=4811:4816; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='confirm_softpot'; end
st={ struct('screening','rand'), ...
     struct('screening','softpot','gammaA',0.5,'gammaR',0.5), ...
     struct('screening','softpot','gammaA',0.5,'gammaR',0.25), ...
     struct('screening','softpot','gammaA',0.75,'gammaR',0.5) };
labels={'C0-rand','C1-s05r05','C2-s05r025','C3-s075r05'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,4),funcs(:),seeds(:),D,maxFE,opt);
end
