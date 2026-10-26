function out=screen310_p0_softpot(seeds,maxFE,D,funcs,tag)
%SCREEN310_P0_SOFTPOT  P0 for soft potential-weighted screening: 29 fn x 6 seeds.
%   P0  uniform random (baseline)
%   P1  softpot gA=0.5 gR=0.5   mild tilt toward alpha + novelty
%   P2  softpot gA=1.0 gR=0.5   default tilt
%   P3  softpot gA=1.0 gR=1.0   stronger novelty
%   P4  softpot gA=0.3 gR=0.3   very mild tilt (near-random control)
if nargin<1 || isempty(seeds), seeds=4801:4806; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_softpot'; end
st={ struct('screening','rand'), ...
     struct('screening','softpot','gammaA',0.5,'gammaR',0.5), ...
     struct('screening','softpot','gammaA',1.0,'gammaR',0.5), ...
     struct('screening','softpot','gammaA',1.0,'gammaR',1.0), ...
     struct('screening','softpot','gammaA',0.3,'gammaR',0.3) };
labels={'P0-rand','P1-s05r05','P2-s10r05','P3-s10r10','P4-s03r03'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
