function out=screen54_pcss_p1(seeds,maxFE,D,funcs,tag)
%SCREEN54_PCSS_P1  Active PCSS P1: frozen baseline, active surrogate-guided
%   screening, and the matched random control (same 2+8 selection structure).
if nargin<1 || isempty(seeds), seeds=3327:3336; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='pcss_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'pcssK',5,'pcssCap',256,'pcssGuide',2);
a=common; a.pcssMode='none';      % A: frozen G1+E
b=common; b.pcssMode='active';    % B: 2 surrogate-guided + 8 random
c=common; c.pcssMode='control';   % C: 2 random "guided" + 8 random (matched)
algs={'SGWO_PCSS','SGWO_PCSS','SGWO_PCSS'};
labels={'A-FrozenG1E','B-PCSS-Active','C-PCSS-Control'};
opt=struct(); opt.states={a,b,c}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
