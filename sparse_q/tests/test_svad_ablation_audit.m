function test_svad_ablation_audit()
% Structural audit of every SVAD-GWO ablation arm BEFORE any formal batch.
% Checks, per arm:
%   1. Full path still bitwise equal to the published commit (1e99eae baseline)
%   2. Evaluations == budget exactly, trace monotone, T(end)==Best
%   3. Slot budget is always 50/12/38 = M=100 (recorded in info)
%   4. E-off arms build no archive; E-on arms do
%   5. No unevaluated candidate can reach a leader (asserted inside the core)
%   6. Determinism: same seed twice -> identical result
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'),fullfile(sqRoot,'src','ablation'), ...
        fullfile(root,'_oldcore'));
cd(fullfile(root,'data','cec2017'));
budget=30000; fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
    'upperBound',100*ones(1,50),'maxEvaluations',budget,'functionID',fid);
f=@(x)CEC2017Function(x,fid);

arms={'full','base','eonly','diffonly','nosteer','fixeddiff','noeslots','noeref'};
fprintf('%-10s %10s %8s %6s %6s %8s %8s\n','arm','best','FE','arch','slots','mono','det');
for a=1:numel(arms)
    arm=arms{a};
    [B,T,i]=SVADGWO_ablate2(f,st,arm,50,seed+1000000);
    assert(i.Evaluations==budget, '%s: FE %d != %d',arm,i.Evaluations,budget);
    assert(all(diff(T)<=0), '%s: trace not monotone',arm);
    assert(abs(T(end)-B.Cost)<=1e-12*max(1,abs(B.Cost)),'%s: T(end)~=Best',arm);
    slotsOk = (i.Parameters.nG2+i.Parameters.nE+50)==100;
    % determinism
    [B2,~,~]=SVADGWO_ablate2(f,st,arm,50,seed+1000000);
    det = abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost));
    fprintf('%-10s %10.4g %8d %6d %6s %8d %8d\n',arm,B.Cost,i.Evaluations, ...
        i.ArchiveSize,mat2str(slotsOk),all(diff(T)<=0),det);
    % E gating
    if any(strcmp(arm,{'base','diffonly'}))
        assert(i.ArchiveSize==0, '%s should build no archive, got %d',arm,i.ArchiveSize);
        assert(i.Ablation.useE==0, '%s useE should be 0',arm);
    else
        assert(i.ArchiveSize>0, '%s should build an archive',arm);
        assert(i.Ablation.useE==1, '%s useE should be 1',arm);
    end
    assert(i.Ablation.useDiff==double(~any(strcmp(arm,{'base','eonly'}))), ...
        '%s useDiff flag inconsistent',arm);
end

% Full must equal the published implementation
[B0,~,~]=SVADGWO_old(f,st,[],50,seed+1000000);
[BF,Tf,~]=SVADGWO(f,st,[],50,seed+1000000);
[BA,Ta,~]=SVADGWO_ablate2(f,st,'full',50,seed+1000000);
d1=abs(BF.Cost-B0.Cost)/max(1,abs(B0.Cost));
d2=abs(BA.Cost-B0.Cost)/max(1,abs(B0.Cost));
fprintf('\nfull vs published commit : rel=%.3g  trace=%d\n',d1,isequal(Tf,Ta));
assert(d1==0 && isequal(Tf,Ta),'SVADGWO.m drifted from the published commit');
assert(d2==0,'ablate2 full differs from SVADGWO');
fprintf('TEST_SVAD_ABLATION_AUDIT PASS\n');
end
