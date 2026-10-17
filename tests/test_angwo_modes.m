function test_angwo_modes()
%TEST_ANGWO_MODES  Regression test for module scheduling (catches padded-empty
%   option bugs and verifies that fixed/random/adaptive shares actually differ).
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
fprintf('== test_angwo_modes ==\n');
D=4; N=10; budget=2400;
rng(3,'twister'); X0=-5+10*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-5*ones(1,D), ...
    'upperBound',5*ones(1,D),'maxEvaluations',budget);
f=@(x)sum(x.^2);

% fixed 10%: every 50-FE window (5 iterations) has exactly 1 rover x 5 = 5 evals
stF=st; stF.exploreMode='fixed'; stF.exploreShare=0.10;
[~,~,iF]=ANGWO(f,stF,[],N,5);
rt=iF.RoleTrace;
assert(~isempty(rt),'fixed mode must produce role traces');
assert(all(rt(:,3)==5),'fixed10 must schedule round(0.1*N) rovers per iteration');
fprintf('  fixed10: %d windows, %d rover evals/window ok\n',size(rt,1),rt(1,3));

% random: share redraws per window and stays inside [0.02,0.30]
stR=st; stR.exploreMode='random';
[~,~,iR]=ANGWO(f,stR,[],N,5);
rtR=iR.RoleTrace;
assert(numel(unique(rtR(:,5)))>=3,'random theta must vary across windows');
assert(all(rtR(:,5)>=0.02-1e-12 & rtR(:,5)<=0.30+1e-12),'random theta out of range');
assert(~isequal(iR.RoleTrace(:,3),iF.RoleTrace(:,3)),'random and fixed schedules must differ');
fprintf('  random: %d distinct theta values ok\n',numel(unique(rtR(:,5))));

% adaptive: theta stays bounded and finite
stA=st; stA.exploreMode='adaptive'; stA.exploreShare=0.20;
[~,~,iA]=ANGWO(f,stA,[],N,5);
assert(~isempty(iA.ThetaTrace) && all(isfinite(iA.ThetaTrace(:,2))));
assert(all(iA.ThetaTrace(:,2)>=0.02-1e-12 & iA.ThetaTrace(:,2)<=0.30+1e-12));
fprintf('  adaptive: theta range [%.3f, %.3f] ok\n',min(iA.ThetaTrace(:,2)),max(iA.ThetaTrace(:,2)));

% alpha-centered rover: budget kept, and destination rule changes the trace
stC=st; stC.exploreMode='fixed'; stC.exploreShare=0.20; stC.roverCenter='alpha'; stC.roverDest='random';
[~,TC,iC]=ANGWO(f,stC,[],N,5);
assert(iC.Evaluations==budget && all(diff(TC)<=0));
stN=stC; stN.roverDest='novelty';
[~,TN,~]=ANGWO(f,stN,[],N,5);
assert(~isequal(TC,TN),'novelty and random destinations must not be identical');
fprintf('  alpha-centered + destination switch ok\n');
fprintf('== test_angwo_modes PASS ==\n');
end

