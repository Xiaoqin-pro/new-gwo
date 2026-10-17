function test_sgwo_unit()
%TEST_SGWO_UNIT  CEC-free unit tests of the new SGWO branch.
%   Checks: exact FE accounting in every mode/policy; the reported best is a
%   genuinely evaluated point whose recorded value matches Best.Cost (no
%   fabricated fitness can ever pass this); determinism; Q bookkeeping.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
fprintf('== test_sgwo_unit ==\n');

D=5; N=8; budget=1000;
rng(11,'twister'); X0=-5+10*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-5*ones(1,D), ...
    'upperBound',5*ones(1,D),'maxEvaluations',budget);
f=@(x)sum(x.^2);
modes={
    struct('mode','dense-sync'), ...
    struct('mode','sparse','K',8,'screenPolicy','random'), ...
    struct('mode','sparse','K',4,'screenPolicy','random'), ...
    struct('mode','sparse','K',8,'screenPolicy','directed','quotaPolicy','fixed','quotaFixed',0.5), ...
    struct('mode','sparse','K',8,'screenPolicy','directed','quotaPolicy','random'), ...
    struct('mode','sparse','K',8,'screenPolicy','directed','quotaPolicy','q'), ...
    };
for k=1:numel(modes)
    s=st; fn=fieldnames(modes{k});
    for q=1:numel(fn), s.(fn{q})=modes{k}.(fn{q}); end
    [B,T,info]=SGWO(f,s,[],N,71);
    assert(info.Evaluations==budget,'mode %d: FE accounting off (%d/%d)',k,info.Evaluations,budget);
    assert(all(diff(T)<=0) && T(end)==B.Cost,'mode %d: monotone/trace-end invariant broken',k);
    fprintf('  mode %d (%s,%s): FE=%d best=%.4g ok\n',k,modes{k}.mode, ...
        getfieldSafe(modes{k},'quotaPolicy','-'),info.Evaluations,B.Cost);
end

% ---- reported best must be a genuinely evaluated point ----
evalLog=zeros(0,D); fvals=zeros(0,1);
    function v=probeWrapped(x)
        v=f(x);
        evalLog(end+1,:)=x; fvals(end+1,1)=v; %#ok<AGROW>
    end
st2=st; st2.mode='sparse'; st2.K=4; st2.screenPolicy='directed';
[B2,~,info2]=SGWO(@probeWrapped,st2,[],N,72);
assert(info2.Evaluations==budget);
assert(size(evalLog,1)==budget,'wrapper must see exactly budget calls');
[hasMatch,mi]=ismember(round(B2.Vector,12),round(evalLog,12),'rows');
assert(hasMatch,'reported Best.Vector is not among truly evaluated points');
assert(abs(fvals(mi)-B2.Cost)<1e-12,'reported Best.Cost does not match the true evaluation');
fprintf('  best-point authenticity: evaluated=%d, match ok\n',numel(fvals));

% ---- determinism ----
[~,Ta]=SGWO(f,st2,[],N,73); [~,Tb]=SGWO(f,st2,[],N,73);
assert(isequal(Ta,Tb),'same seed must reproduce bitwise');
[~,Tc]=SGWO(f,st2,[],N,74);
assert(~isequal(Ta,Tc),'different seed should differ');
fprintf('  determinism + seed sensitivity ok\n');

% ---- Q bookkeeping ----
s=st; s.mode='sparse'; s.K=8; s.screenPolicy='directed'; s.quotaPolicy='q'; s.qWindow=250;
[~,~,iq]=SGWO(f,s,[],N,75);
assert(~isnan(iq.QActionCounts(1)));
assert(sum(iq.QActionCounts)==size(iq.QuotaTrace,1),'action counts must equal settled windows');
assert(size(iq.QTable,1)==6 && size(iq.QTable,2)==3,'Q table must be 6x3');
assert(all(iq.QStateVisits>=0));
fprintf('  Q bookkeeping: windows=%d actions=[%d %d %d] ok\n', ...
    size(iq.QuotaTrace,1),iq.QActionCounts(1),iq.QActionCounts(2),iq.QActionCounts(3));
fprintf('== test_sgwo_unit PASS ==\n');
end

function v=getfieldSafe(s,name,def)
if isfield(s,name), v=s.(name); else, v=def; end
end

