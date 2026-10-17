classdef EvalProbe < handle
%EVALPROBE  Uniform evaluation-interface probe: true-FE audit + novelty archive.
%   Every algorithm in NEW_GWO_2026 is instrumented identically through this
%   probe:
%     * counts TRUE objective evaluations independently of the algorithm;
%     * maintains a bounded reservoir archive (uniform sample over all
%       evaluated positions, capacity A) - an unbiased sample of the
%       evaluated set, so nearest-neighbour distances to it approximate
%       nearest-neighbour distances to everything evaluated;
%     * records the novelty (normalised nearest-neighbour distance to
%       previously evaluated positions) of every `stride`-th evaluation
%       (pre-registered rule: fe divisible by stride). Novelty is always
%       measured BEFORE the evaluated point enters the archive.
%   Novelty is normalised by the search-space diagonal, so it is
%   dimension- and scale-free.
%
%   RNG: reservoir replacement draws from its own RandStream (`seed+51`
%   convention), so instrumentation never perturbs any algorithm stream.
%
%   Usage (runner):
%     probe=EvalProbe(lb,ub,budget,seed,5,200);
%     fprobe=@(x)probe.evaluate(fraw,x);
%     ... algorithm calls fprobe ...
%     probe.noveltyOf(x) / probe.noveltyOfMany(X)   % same archive for modules
properties
    D; budget; stride; A; diag;
    Arch; nArch=0; fe=0;
    an;            % cached squared norms of archive rows
    aux;
    novFe=zeros(0,1); novVal=zeros(0,1);
    nDistanceOps=0;
end
methods
    function obj=EvalProbe(lb,ub,budget,seed,stride,A)
        obj.D=numel(lb);
        obj.budget=budget; obj.stride=stride; obj.A=min(A,budget);
        obj.Arch=zeros(obj.A,obj.D); obj.an=zeros(obj.A,1);
        obj.diag=norm(ub-lb);
        obj.aux=RandStream('mt19937ar','Seed',seed+51);
    end
    function [v,nov]=evaluate(obj,f,x)
        obj.fe=obj.fe+1;
        nov=NaN;
        if mod(obj.fe,obj.stride)==0
            nov=obj.noveltyOf(x);
            obj.novFe(end+1,1)=obj.fe;
            obj.novVal(end+1,1)=nov;
        end
        v=f(x);
        if obj.fe<=obj.A
            obj.nArch=obj.fe;
            obj.Arch(obj.fe,:)=x; obj.an(obj.fe)=sum(x.^2);
        else
            j=randi(obj.aux,obj.fe);
            if j<=obj.A
                obj.Arch(j,:)=x; obj.an(j)=sum(x.^2);
            end
        end
    end
    function d=noveltyOf(obj,x)
        d=obj.noveltyOfMany(x);
    end
    function dd=noveltyOfMany(obj,X)
        % X: n-by-D；返回每行对档案（此前已评位置的无偏采样）的最小归一化距离
        n=size(X,1);
        if obj.nArch==0
            dd=ones(n,1); return
        end
        a=obj.Arch(1:obj.nArch,:); anv=obj.an(1:obj.nArch);
        d2=sum(X.^2,2)+anv'-2*(X*a');
        dd=sqrt(max(d2,0))/obj.diag;
        dd=min(dd,[],2);
        obj.nDistanceOps=obj.nDistanceOps+obj.nArch*n;
    end
end
end
