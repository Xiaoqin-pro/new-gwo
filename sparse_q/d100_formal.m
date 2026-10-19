function out=d100_formal()
%D100_FORMAL  D=100 formal batch for the seven-algorithm main table.
%
%   Protocol (frozen in docs/17_D100_PREREG.md BEFORE this batch):
%     CEC2017, 29 functions (F1,F3:F30), D=100, 100k true FE, seeds 3001:3030,
%     N=50 for all arms, shared initial pool per (function,seed), exactly 4
%     local workers, atomic per-job storage, resume-safe.
%
%   Reuse rule: the archived batch fd100_20261016_232205 contributes ONLY its
%   290 S-star rows (seeds 3001:3010) after 290/290 bitwise reproduction.
%   This runner therefore generates 5,800 NEW jobs:
%       VAST-GWO : 29 fn x seeds 3011:3030          =  580
%       GWO      : 29 fn x seeds 3001:3030          =  870
%       IGWO     : 29 fn x seeds 3001:3030          =  870
%       HAGWO    : 29 fn x seeds 3001:3030          =  870
%       PSO      : 29 fn x seeds 3001:3030          =  870
%       CLPSO    : 29 fn x seeds 3001:3030          =  870
%       AOGWO    : 29 fn x seeds 3001:3030          =  870
%
%   Output directory is FIXED: sparse_q/results/d100_formal_20261018
%   Re-running this function resumes (never overwrites valid records).

sq=fileparts(mfilename('fullpath')); root=fileparts(sq);
addpath(fullfile(root,'src'),fullfile(root,'data','cec2017'),fullfile(sq,'src'), ...
        fullfile(sq,'experiments'),root);

D=100; funcs=[1 3:30]; maxFE=100000; N=50;
outDir=fullfile(sq,'results','d100_formal_20261018');
if ~exist(outDir,'dir'), mkdir(outDir); end

base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
sStar=base; sStar.K=10; sStar.screenPolicy='random';

% ---- canonical job list (deterministic order; must stay identical on resume) ----
spec={ 'SGWO','VAST-GWO',3011:3030; ...
       'GWO','GWO',3001:3030; ...
       'IGWO','IGWO',3001:3030; ...
       'HAGWO','HAGWO',3001:3030; ...
       'PSO','PSO',3001:3030; ...
       'CLPSO','CLPSO',3001:3030; ...
       'AOGWO','AOGWO',3001:3030 };
jobs=struct('algorithm',{},'label',{},'fid',{},'D',{},'seed',{}, ...
            'maxFE',{},'N',{},'state',{},'useProbe',{});
k=0;
for a=1:size(spec,1)
    algn=spec{a,1}; lab=spec{a,2}; seeds=spec{a,3};
    for fi=1:numel(funcs)
        for si=1:numel(seeds)
            k=k+1;
            st=struct(); if strcmp(algn,'SGWO'), st=sStar; end
            jobs(k)=struct('algorithm',algn,'label',lab,'fid',funcs(fi), ...
                'D',D,'seed',seeds(si),'maxFE',maxFE,'N',N,'state',st,'useProbe',true);
        end
    end
end
assert(k==5800,'job count %d ~= 5800',k);

% ---- provenance (code hashes frozen in docs/17) ----
H=struct();
H.SGWO=fileSha256(fullfile(sq,'src','SGWO.m'));
H.runner_sgwo=fileSha256(fullfile(sq,'experiments','runner_sgwo.m'));
H.GWO=fileSha256(fullfile(root,'src','GWO.m'));
H.IGWO=fileSha256('D:\111\Desktop\噜噜\狼群\src\IGWO.m');
H.HAGWO=fileSha256(fullfile(sq,'src','HAGWO_CEC.m'));
H.PSO=fileSha256(fullfile(sq,'src','PSO_CEC.m'));
H.CLPSO=fileSha256(fullfile(sq,'src','CLPSO_CEC.m'));
H.AOGWO=fileSha256(fullfile(sq,'src','AOGWO_CEC.m'));
H.EvalProbe=fileSha256(fullfile(root,'src','EvalProbe.m'));
H.cec_mex=fileSha256(fullfile(root,'data','cec2017','cec17_func.mexw64'));
prov=struct('tag','d100_formal','D',D,'maxFE',maxFE,'N',N, ...
    'funcs',funcs,'seedsAll',3001:3030,'seedsNewVAST',3011:3030, ...
    'algs',{{'SGWO','GWO','IGWO','HAGWO','PSO','CLPSO','AOGWO'}}, ...
    'labels',{{'VAST-GWO','GWO','IGWO','HAGWO','PSO','CLPSO','AOGWO'}}, ...
    'initSeedRule','261013000 + fid*10000 + seed', ...
    'searchSeedRule','seed + 1000000', ...
    'initialPoolRule','-100 + 200*rand(50,D) after rng(initSeed,''twister'')', ...
    'hashes',H,'matlab',version,'stamp',datestr(now,31));
save(fullfile(outDir,'provenance.mat'),'prov');

fprintf('[d100_formal] %d jobs -> %s\n',numel(jobs),outDir);
summary=overnight.runBatch4(jobs,@runner_sgwo,outDir);
disp(summary);
collect_sq(outDir);
out=struct('outDir',outDir,'summary',summary);
end
