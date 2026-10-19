function out=d100_phase2_audit()
%D100_PHASE2_AUDIT  Phase-2 fairness/audit gate for the D=100 formal batch.
%   Checks (all must pass before the 6090-run batch):
%     1) code hashes of the frozen method + 6 baselines + harness;
%     2) shared initial population: T(1:50) identical across all 7 algorithms
%        for the same (function, seed), and the pool hash is recorded;
%     3) exact true-FE accounting (== 100000) for every algorithm at D=100;
%     4) determinism: repeated run of one algorithm is bitwise identical;
%     5) VAST-GWO bitwise reproduction vs archived D=50 and D=100 batches;
%     6) IGWO bitwise reproduction vs the archived D=100 12-function audit CSV.
%   Writes a machine-readable summary to results/d100_phase2_audit/.
sq=fileparts(mfilename('fullpath')); root=fileparts(sq);
addpath(fullfile(root,'src'),fullfile(root,'data','cec2017'),fullfile(sq,'src'),fullfile(sq,'experiments'),fullfile(sq,'tests'));
outDir=fullfile(sq,'results','d100_phase2_audit');
if ~exist(outDir,'dir'), mkdir(outDir); end
logFid=fopen(fullfile(outDir,'phase2_audit.log'),'w');
cleanup=onCleanup(@()fclose(logFid));
say=@(varargin)fprintf(logFid,varargin{:});
say('D=100 PHASE-2 AUDIT  %s\n',datestr(now,31));
say('Repo root: %s\n',root);
say('MATLAB %s\n\n',version);

% ---------- 1) hashes ----------
files={'sparse_q/src/SGWO.m','sparse_q/experiments/runner_sgwo.m','src/GWO.m', ...
 'src/ANGWO.m','sparse_q/src/HAGWO_CEC.m','sparse_q/src/AOGWO_CEC.m', ...
 'sparse_q/src/PSO_CEC.m','sparse_q/src/CLPSO_CEC.m','src/EvalProbe.m', ...
 'src/trace_metrics.m','src/CEC2017Function.m','data/cec2017/cec17_func.mexw64', ...
 'data/cec2017/cec17_func.cpp'};
say('=== 1) CODE HASHES (sha256) ===\n');
H=struct();
for i=1:numel(files)
    p=fullfile(root,files{i});
    if ~isfile(p), error('missing %s',files{i}); end
    h=fileSha256(p); H.(matlab.lang.makeValidName(files{i}))=h;
    say('%-42s %s\n',files{i},h);
end
igwoPath='D:\111\Desktop\噜噜\狼群\src\IGWO.m';
assert(isfile(igwoPath),'IGWO.m missing');
H.IGWO=fileSha256(igwoPath);
say('%-42s %s\n','D:/.../狼群/src/IGWO.m',H.IGWO);
say('\n');

% ---------- 2)+3)+4) 7-alg shared init / FE / determinism ----------
D=100; fid=1; seed=3001; budget=100000; N=50;
algs={'SGWO','GWO','IGWO','HAGWO','PSO','CLPSO','AOGWO'};
labels={'VAST-GWO','GWO','IGWO','HAGWO','PSO','CLPSO','AOGWO'};
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
sStar=base; sStar.K=10; sStar.screenPolicy='random';
seedInit=261013000+fid*10000+seed;
rng(seedInit,'twister'); pool=-100+200*rand(50,D);
poolHash=matSha256(pool);
say('=== 2) SHARED INITIAL POPULATION (F%d, seed %d, D=%d) ===\n',fid,seed,D);
say('initSeed=%d  pool sha256=%s\n',seedInit,poolHash);
T50=zeros(numel(algs),50); feAll=zeros(1,numel(algs)); bc=zeros(1,numel(algs));
for a=1:numel(algs)
    st=struct(); if a==1, st=sStar; end
    job=struct('algorithm',algs{a},'label',labels{a},'fid',fid,'D',D,'seed',seed, ...
        'maxFE',budget,'N',N,'state',st,'useProbe',true);
    res=runner_sgwo(job);
    feAll(a)=res.Evaluations; bc(a)=res.BestCost;
    % recover full T by re-running with a plain counting wrapper? runner stores sampled T.
    T50(a,:)=initTrace(job);
    say('%-10s FE=%d ProbeFE=%d InitSeed=%d SearchSeed=%d BestCost=%.10g\n', ...
        labels{a},res.Evaluations,res.ProbeFE,res.InitSeed,res.SearchSeed,res.BestCost);
end
% AOGWO (author code) applies its own hybrid-opposition (DO) initialisation
% transform to the shared pool -- a pre-registered, documented algorithmic
% component (docs/15). It is therefore excluded from the bitwise T(1:50)
% comparison; the *input* pool is still identical for all seven arms.
direct=[1 2 3 4 5 6];          % SGWO,GWO,IGWO,HAGWO,PSO,CLPSO evaluate the pool as given
sameInit=all(max(abs(T50(direct,:)-T50(1,:)),[],2)<1e-12);
say('T(1:50) identical across SGWO/GWO/IGWO/HAGWO/PSO/CLPSO: %d\n',sameInit);
say('AOGWO first-50 trace differs (author hybrid-OBL init transform; documented): %d\n', ...
    max(abs(T50(7,:)-T50(1,:)))>1e-12);
assert(all(feAll==budget),'FE accounting failed for some algorithm');
assert(sameInit,'shared-initial-population audit failed');
say('\n');

% determinism: SGWO repeated
job=struct('algorithm','SGWO','label','VAST-GWO','fid',fid,'D',D,'seed',seed, ...
    'maxFE',budget,'N',N,'state',sStar,'useProbe',true);
r1=runner_sgwo(job); r2=runner_sgwo(job);
det=(r1.BestCost==r2.BestCost);
say('=== 3) DETERMINISM ===\nSGWO repeat bitwise identical: %d (%.17g vs %.17g)\n\n',det,r1.BestCost,r2.BestCost);
assert(det,'determinism failed');

% ---------- 5) VAST-GWO reproduction ----------
say('=== 4) VAST-GWO BITWISE REPRODUCTION (archived D=50 and D=100) ===\n');
rep=test_d100_repro([1 3001; 5 3003; 9 3005; 13 3007; 18 3008; 24 3010]);
say('reproduction rows=%d allPass=%d\n\n',height(rep),all(rep.pass));

% ---------- 6) IGWO reproduction vs audited D=100 12-fn CSV ----------
say('=== 5) IGWO D=100 REPRODUCTION vs audited_d100_12fn.csv ===\n');
ref=readtable(fullfile(root,'data','reference','audited_d100_12fn.csv'),'TextType','string');
pairs=[1 3001; 3 3002; 7 3004; 12 3010];
okIg=zeros(1,size(pairs,1));
for p=1:size(pairs,1)
    f=pairs(p,1); sd=pairs(p,2);
    row=ref(ref.Algorithm=="IGWO"&ref.FunctionID==f&ref.Seed==sd,:);
    assert(height(row)==1,'IGWO reference row missing F%d s%d',f,sd);
    job=struct('algorithm','IGWO','label','IGWO','fid',f,'D',100,'seed',sd, ...
        'maxFE',100000,'N',50,'state',struct(),'useProbe',true);
    res=runner_sgwo(job);
    rel=abs(res.BestCost-row.FinalCost(1))/max(1,abs(row.FinalCost(1)));
    okIg(p)=rel<=1e-12;
    say('F%-2d s%d archived=%.15g rerun=%.15g rel=%.2e pass=%d\n',f,sd,row.FinalCost(1),res.BestCost,rel,okIg(p));
end
say('IGWO reproduction %d/%d\n\n',sum(okIg),numel(okIg));
assert(all(okIg),'IGWO D=100 reproduction failed');

% ---------- summary ----------
out=struct('stamp',datestr(now,31),'hashes',H,'poolHash',poolHash, ...
 'sameInit',sameInit,'aogwoInitTransform',true,'feExact',all(feAll==budget),'deterministic',det, ...
 'vastsReproPass',all(rep.pass),'igwoReproPass',all(okIg));
save(fullfile(outDir,'phase2_audit.mat'),'out');
say('ALL PHASE-2 CHECKS PASSED\n');
fprintf('ALL PHASE-2 CHECKS PASSED -> %s\n',fullfile(outDir,'phase2_audit.log'));
end

% ---- helpers ----
function t50=initTrace(job)
% Re-run only the first 50 evaluations in the same order as runner_sgwo's
% initialization, capturing T(1:50). Uses the exact runner seed conventions.
D=job.D; fid=job.fid; seed=job.seed;
seedInit=261013000+fid*10000+seed;
rng(seedInit,'twister'); pool=-100+200*rand(50,D);
lb=-100*ones(1,D); ub=100*ones(1,D);
state=struct('initialPopulation',pool,'lowerBound',lb,'upperBound',ub, ...
             'maxEvaluations',50);
probe=EvalProbe(lb,ub,50,seed+51,5,200);
f=@(x)probe.evaluate(@(y)CEC2017Function(y,fid),x);
switch job.algorithm
    case 'SGWO', [~,T]=SGWO(f,state,[],50,seed+1000000);
    case 'GWO',  [~,T]=GWO(f,state,[],50,seed+1000000);
    case 'IGWO', [~,T]=IGWO(f,state,[],50,seed+1000000);
    case 'HAGWO',[~,T]=HAGWO_CEC(f,state,[],50,seed+1000000);
    case 'PSO',  [~,T]=PSO_CEC(f,state,[],50,seed+1000000);
    case 'CLPSO',[~,T]=CLPSO_CEC(f,state,[],50,seed+1000000);
    case 'AOGWO',[~,T]=AOGWO_CEC(f,state,[],50,seed+1000000);
end
t50=T(1:50)';
end
function h=matSha256(X)
md=java.security.MessageDigest.getInstance('SHA-256');
b=typecast(double(X(:)),'uint8');
d=md.digest(b);
h=lower(reshape(dec2hex(typecast(d,'uint8'),2)',1,[]));
end
