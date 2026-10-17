function [Best,T,info]=GWO(f,state,~,N,seed)
%GWO  Canonical Grey Wolf Optimizer, fresh re-implementation from the
%   original paper (Mirjalili, Mirjalili & Lewis, 2014, Advances in
%   Engineering Software 69:46-61), written for NEW_GWO_2026.
%
%   [Best,T,info]=GWO(f,state,[],N,seed)
%
%   Semantics (paper-faithful, per-dimension independent random numbers):
%     * initialisation evaluates the supplied population in index order;
%     * every generation moves each wolf once, in index order, using
%       A_c = 2*a*r1 - a, C_c = 2*r2 drawn independently per dimension;
%     * alpha/beta/delta are refreshed immediately after every true
%       evaluation (the update order of the published reference code);
%     * a decays linearly from 2 to 0 over the TRUE-evaluation budget,
%       evaluated at the start of every generation.
%
%   Harness interface (identical for every algorithm in this project):
%     state.initialPopulation   N-by-D starting positions (caller controls RNG)
%     state.lowerBound/upperBound  1-by-D
%     state.maxEvaluations     total TRUE evaluations, initialisation included
%   Outputs:
%     Best.Cost/Best.Vector    best true fitness and its position
%     T                        budget-by-1 record, T(fe)=best after fe evals
%     info.Evaluations         true evaluations consumed (== budget)
%     info.Rounds              completed generations
%
%   Randomness: rng(seed,'twister') drives the search stream; the initial
%   population is drawn by the caller from a different seed.
%
%   This file is the reference core for the NEW_GWO_2026 study. The new
%   method (ANGWO.m) must reproduce it bit-for-bit when every module is
%   switched off; tests/test_angwo_equivalence.m enforces that.

X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch: state holds %d rows, N=%d.',N0,N);
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D,'Bound vectors must match D=%d.',D);
assert(budget>=N && budget==floor(budget),'Budget must be integer >= N.');
assert(all(isfinite(X),'all') && all(X>=lb & X<=ub,'all'), ...
    'Initial population must be finite and inside the bounds.');
rng(seed,'twister');
clockStart=tic;

T=nan(budget,1);
Alpha=struct('Cost',inf,'Vector',zeros(1,D));
Beta=Alpha; Delta=Alpha;
fe=0;
for i=1:N
    v=f(X(i,:));
    fe=fe+1;
    [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,X(i,:),v);
    T(fe)=Alpha.Cost;
end
rounds=0;

% ==================== main loop ====================
while fe<budget
    rounds=rounds+1;
    a=2-2*(fe/budget);            % linear 2 -> 0 over the true FE budget
    for i=1:N
        if fe>=budget, break; end
        A1=2*a*rand(1,D)-a;  C1=2*rand(1,D);
        A2=2*a*rand(1,D)-a;  C2=2*rand(1,D);
        A3=2*a*rand(1,D)-a;  C3=2*rand(1,D);
        X1=Alpha.Vector-A1.*abs(C1.*Alpha.Vector-X(i,:));
        X2=Beta.Vector -A2.*abs(C2.*Beta.Vector -X(i,:));
        X3=Delta.Vector-A3.*abs(C3.*Delta.Vector-X(i,:));
        Xn=(X1+X2+X3)/3;
        Xn=max(min(Xn,ub),lb);
        X(i,:)=Xn;
        v=f(Xn);
        fe=fe+1;
        [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,Xn,v);
        T(fe)=Alpha.Cost;
    end
end

Best.Cost=Alpha.Cost;
Best.Vector=Alpha.Vector;
info.Evaluations=fe;
info.Rounds=rounds;
info.MeanEvalsPerRound=fe/max(rounds,1);
info.WallClock=toc(clockStart);
info.Algorithm='GWO';
end

% ==================== helpers ====================
function [A,B,Dl]=insertLeader(A,B,Dl,x,v)
if v<A.Cost
    Dl=B; B=A; A=struct('Cost',v,'Vector',x);
elseif v<B.Cost
    Dl=B; B=struct('Cost',v,'Vector',x);
elseif v<Dl.Cost
    Dl=struct('Cost',v,'Vector',x);
end
end
