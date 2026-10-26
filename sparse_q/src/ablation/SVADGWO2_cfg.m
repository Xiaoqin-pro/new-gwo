function [Best,T,info]=SVADGWO2_cfg(f,state,seed,varargin)
%SVADGWO2_CFG  Configurable entry point for screening / slot experiments.
%   Only for development screens; the proposed algorithm is SVADGWO2.m.
%   Usage: SVADGWO2_cfg(f,state,seed,'screening','arc','nG2',25,'nE',25)
o=struct();
for k=1:2:numel(varargin)
    o.(varargin{k})=varargin{k+1};
end
if ~isfield(o,'useE'), o.useE=1; end
if ~isfield(o,'useDiff'), o.useDiff=1; end
if ~isfield(o,'diffFiller'), o.diffFiller='gwo'; end
[Best,T,info]=SVADGWO2_core(f,state,50,seed,'diff',0,o);
info.Config=o;
end
