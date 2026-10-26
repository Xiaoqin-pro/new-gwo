function test_ablate_budget()
% Every ablation arm must spend exactly the same evaluation budget and generate
% exactly K candidates.  Only the generator mix may differ.
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471; budget=30000;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
    'upperBound',100*ones(1,50),'maxEvaluations',budget,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
arms={'full','base','eonly','diffonly'};
fprintf('%-10s %12s %7s %8s %6s\n','arm','best','FE','cands/gen','arch');
for k=1:numel(arms)
    [B,T,i]=SVADGWO2_ablate(f,st,arms{k},50,seed+1000000);
    assert(i.Evaluations==budget,sprintf('%s FE',arms{k}));
    assert(all(diff(T)<=0),sprintf('%s mono',arms{k}));
    assert((i.Parameters.nG2+i.Parameters.nE)<=i.Parameters.K,sprintf('%s quota>K',arms{k}));
    [B2,~,~]=SVADGWO2_ablate(f,st,arms{k},50,seed+1000000);
    assert(abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)),sprintf('%s det',arms{k}));
    fprintf('%-10s %12.6g %7d %8d %6d\n',arms{k},B.Cost,i.Evaluations, ...
        i.Parameters.nG2+i.Parameters.nE+(i.Parameters.K-i.Parameters.nG2-i.Parameters.nE),i.ArchiveSize);
end
% full must equal the frozen entry point
[Bf,~,~]=SVADGWO2(f,st,[],50,seed+1000000);
[Ba,Ta,~]=SVADGWO2_ablate(f,st,'full',50,seed+1000000);
d=abs(Bf.Cost-Ba.Cost)/max(1,abs(Ba.Cost));
assert(d==0,'full arm != SVADGWO2 entry');
fprintf('\nfull == SVADGWO2 : rel=%.3g\nTEST_ABLATE_BUDGET PASS\n',d);
end
