function test_angwo_equivalence()
%TEST_ANGWO_EQUIVALENCE  ANGWO with all modules off must be bit-identical to GWO.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
fprintf('== test_angwo_equivalence ==\n');
D=6; N=8; budget=400;
rng(7,'twister'); X0=-5+10*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-5*ones(1,D), ...
    'upperBound',5*ones(1,D),'maxEvaluations',budget);
f=@(x)sum(x.^2)+0.5*sum(sin(3*x));
for seed=[11 12 13]
    [BestG,TG,infoG]=GWO(f,st,[],N,seed);
    [BestA,TA,infoA]=ANGWO(f,st,[],N,seed);
    assert(isequal(TG,TA),'T differs: ANGWO(off) must equal GWO bitwise (seed %d)',seed);
    assert(BestG.Cost==BestA.Cost,'best cost differs (seed %d)',seed);
    assert(isequal(BestG.Vector,BestA.Vector),'best vector differs (seed %d)',seed);
    assert(infoG.Evaluations==infoA.Evaluations && infoG.Evaluations==budget);
    fprintf('  seed %d: bitwise identical (best=%.10g) ok\n',seed,BestA.Cost);
end
% modules ON must not break the FE budget and must keep a monotone trace
stON=st; stON.exploreMode='adaptive'; stON.recoveryMode='stagnation';
[BestO,TO,infoO]=ANGWO(f,stON,[],N,21); %#ok<ASGLU>
assert(infoO.Evaluations==budget,'FE budget violated with modules on');
assert(numel(TO)==budget);
assert(all(diff(TO)<=0),'trace must stay monotone with modules on');
fprintf('  modules ON: FE=%d monotone trace ok\n',infoO.Evaluations);
fprintf('== test_angwo_equivalence PASS ==\n');
end
