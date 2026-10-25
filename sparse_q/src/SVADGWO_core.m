function [Best,T,info]=SVADGWO_core(f,state,N,seed,g2Mode,ablateE,pSteerOn)
%SVADGWO_CORE  Reference implementation shared by SVADGWO.m and the ablation harness.
%   The three trailing arguments (g2Mode, ablateE, pSteerOn) are ablation hooks and are
%   always set to their proposed values by SVADGWO.m.  Do not treat them as tuning knobs.
%
%   Sparse-evaluation grey wolf optimizer for expensive black-box problems.
%   Three candidate sources share one budget of real function evaluations:
%
%     (1) Leader-guided wolves (N)
%         Standard GWO aggregation of alpha/beta/delta, optionally extended by an
%         equal-length random-direction perturbation (directional coverage).
%
%     (2) Differential slots (nG2)  -- the DiffA mechanism
%         y = x_r1 + F(t)*(alpha - x_r1) + F(t)*(x_r2 - x_r3)
%         where r1,r2,r3 are distinct members of the joint pool of wolves and
%         verified archive solutions.  The scale F(t) contracts over the run:
%             F(t) = F0 - (F0-F1)*max(0,(t-tc)/(1-tc)),  t = FE/FE_max
%         so the slots start as archive/population differential exploration and
%         end as alpha-centred refinement.
%
%     (3) Verified-archive slots (nE)  -- the VMA mechanism
%         Single-centre shells around verified elite centres (credit weighted)
%         and two-centre line segments between verified elites.  The shell
%         radius adapts to the median of recent verified successful steps.
%
%   Only K candidates per generation receive a real evaluation.  A candidate is
%   never ranked, promoted to a leader, or admitted to the archive without a
%   real evaluation, and every real call is charged exactly once.
%
%   Usage: [Best,T,info] = DAGWO(f,state,[],N,seed)
%     state.initialPopulation  N-by-D initial population (already sampled)
%     state.lowerBound        1-by-D lower bound
%     state.upperBound        1-by-D upper bound
%     state.maxEvaluations    total real-evaluation budget (includes the N initial)
%
%   Reference implementation of the final structure reported in
%   sparse_q/docs/145_FINAL_STRUCTURE_PREREG.md.  Ablation switches are kept in
%   the separate ablation harness, not here.

% ==================== structural parameters ====================
K        = 10;    % real evaluations per generation (sparse discipline)
nG2      = 12;    % differential slots
nE       = 38;    % verified-archive slots
F0       = 1.0;   % differential scale at t=0
F1       = 0.3;   % differential scale at t=1
tc       = 0.7;   % contraction onset, fraction of budget
pSteer   = 0.5;   % directional perturbation probability for G1
lamSteer = 0.5;   % perturbation length, fraction of the G1 step
arcCap   = 24;    % archive capacity
dSep     = 0.02;  % archive separation threshold, fraction of search span

% ==================== setup ====================
clockStart = tic;
D      = size(state.initialPopulation,2);
lb     = state.lowerBound;
ub     = state.upperBound;
budget = state.maxEvaluations;
span   = max(ub-lb);
M      = N + nG2 + nE;
assert(size(state.initialPopulation,1)>=N && budget>=N);
rng(seed,'twister');
sAux = RandStream('mt19937ar','Seed',seed+424242);   % screening / secondary draws

Xv = state.initialPopulation(1:N,:);
fv = inf(N,1);
fe = 0;
T  = nan(budget,1);

Alpha = struct('Cost',inf,'Vector',zeros(1,D));
Beta  = Alpha; Delta = Alpha;

for i=1:N
    v = f(Xv(i,:));
    fe = fe+1;
    fv(i) = v;
    [Alpha,Beta,Delta] = insertLeader(Alpha,Beta,Delta,Xv(i,:),v);
    T(fe) = Alpha.Cost;
end

% verified archive (only real evaluations enter)
Arc     = zeros(arcCap,D);
Arcv    = inf(arcCap,1);
ArcCred = zeros(arcCap,1);
ArcN    = 0;
succ    = zeros(0,1);     % recent verified successful step lengths
succCap = 25;

rounds = 0;
nIns   = 0;
nEvalG = zeros(1,3);      % [G1 G2 E] real evaluations
nImpG  = zeros(1,3);      % [G1 G2 E] accepted improvements
Ftrace = zeros(0,2);      % [FE, F(t)]

% ==================== main loop ====================
while fe < budget
    rounds = rounds + 1;
    t   = fe/budget;
    F   = F0 - (F0-F1)*max(0,(t-tc)/max(1e-9,1-tc));
    aA  = 2-2*t;                              % standard GWO convergence factor
    sig = shellSigma(succ,span,D);            % adaptive shell radius
    Ftrace(end+1,:) = [fe F];

    % ---- 1) candidate generation (no real evaluation here) ----
    Y   = zeros(M,D);
    src = zeros(M,1);
    par = zeros(M,1);
    ctr = zeros(M,1);
    m   = 0;

    % --- (1) leader-guided wolves with directional perturbation ---
    trig = rand(sAux,N,1);
    for i=1:N
        m = m+1;
        R6 = rand(1,6*D);
        A1 = 2*aA*R6(1:D)-aA;        C1 = 2*R6(D+1:2*D);
        A2 = 2*aA*R6(2*D+1:3*D)-aA;  C2 = 2*R6(3*D+1:4*D);
        A3 = 2*aA*R6(4*D+1:5*D)-aA;  C3 = 2*R6(5*D+1:6*D);
        X1 = Alpha.Vector - A1.*abs(C1.*Alpha.Vector - Xv(i,:));
        X2 = Beta.Vector  - A2.*abs(C2.*Beta.Vector  - Xv(i,:));
        X3 = Delta.Vector - A3.*abs(C3.*Delta.Vector - Xv(i,:));
        xg = (X1+X2+X3)/3;
        if trig(i) < pSteerOn
            sd = randn(1,D); nrm = norm(sd);
            if nrm>0
                stepv = norm(xg-Xv(i,:));
                xg = xg + lamSteer*(sd/nrm)*stepv;
            end
        end
        Y(m,:) = min(max(xg,lb),ub);
        src(m) = 1; par(m) = i;
    end

    % --- (2) differential slots (DiffA) ---
    if ArcN>0
        pool = [Xv; Arc(1:ArcN,:)];
    else
        pool = Xv;
    end
    nP = size(pool,1);
    for j=1:nG2
        m = m+1;
        if strcmpi(g2Mode,'shell')
            Y(m,:) = min(max(Alpha.Vector + sig*(2*rand(1,D)-1),lb),ub);
            src(m) = 2; continue;
        end
        r1 = randi(sAux,nP);
        r2 = randi(sAux,nP); while r2==r1, r2 = randi(sAux,nP); end
        r3 = randi(sAux,nP); while r3==r1 || r3==r2, r3 = randi(sAux,nP); end
        y = pool(r1,:) + F*(Alpha.Vector-pool(r1,:)) + F*(pool(r2,:)-pool(r3,:));
        Y(m,:) = min(max(y,lb),ub);
        src(m) = 2;
    end

    % --- (3) verified-archive slots (VMA) ---
    if ArcN>0
        ww = 1+ArcCred(1:ArcN);
        cw = cumsum(ww/sum(ww));
    end
    for j=1:nE
        m = m+1;
        if ablateE
            iw = mod(j-1,N)+1;
            Y(m,:) = gwoMove(aA,Alpha,Beta,Delta,Xv(iw,:),lb,ub);
            src(m) = 3; continue;
        end
        if ArcN==0
            Y(m,:) = min(max(Alpha.Vector + sig*(2*rand(1,D)-1),lb),ub);
            src(m) = 3;
        elseif mod(j,2)==1 || ArcN==1
            % single-centre shell around a credit-weighted verified elite
            c  = find(rand(sAux)<=cw,1); if isempty(c), c = ArcN; end
            RR = rand(1,D+1);
            Y(m,:) = min(max(Arc(c,:) + sig*(0.5+RR(1))*(2*RR(2:end)-1),lb),ub);
            src(m) = 3; ctr(m) = c;
        else
            % two-centre line segment between two verified elites
            [c1,c2] = pickTwoCenters(ArcN,sAux);
            lam = 0.15+0.7*rand(sAux);
            path = Arc(c1,:) + lam*(Arc(c2,:)-Arc(c1,:));
            Y(m,:) = min(max(path + 0.25*sig*(2*rand(1,D)-1),lb),ub);
            src(m) = 3; ctr(m) = c1;
        end
    end

    % ---- 2) screening: K uniformly random candidates ----
    sel = randperm(sAux,M,K)';

    % ---- 3) real evaluation and atomic commit ----
    for q=1:numel(sel)
        if fe>=budget, break; end
        j = sel(q);
        y = Y(j,:);
        v = f(y);
        fe = fe+1;
        [Alpha,Beta,Delta] = insertLeader(Alpha,Beta,Delta,y,v);
        T(fe) = Alpha.Cost;

        if src(j)==1
            % leader-guided: the wolf always moves; improvement only recorded
            i = par(j);
            if v < fv(i)
                d = norm(y-Xv(i,:));
                succ = pushSucc(succ,d,succCap);
                nImpG(1) = nImpG(1)+1;
            end
            Xv(i,:) = y; fv(i) = v;
            nEvalG(1) = nEvalG(1)+1;
        else
            % differential / archive: compete with the worst wolf
            [worstF,wi] = max(fv);
            if v < worstF
                d = norm(y-Xv(wi,:));
                Xv(wi,:) = y; fv(wi) = v;
                succ = pushSucc(succ,d,succCap);
                if src(j)==2, nImpG(2) = nImpG(2)+1; else, nImpG(3) = nImpG(3)+1; end
            end
            if src(j)==2, nEvalG(2) = nEvalG(2)+1; else, nEvalG(3) = nEvalG(3)+1; end
        end

        % ---- archive admission: verified, strictly better, spatially separated ----
        arcImp = false;
        if ArcN==0
            ArcN = 1; Arc(1,:) = y; Arcv(1) = v;
            nIns = nIns+1; arcImp = true;
        elseif ArcN<arcCap
            dmin = nearestDist(y,Arc,ArcN);
            if v < max(Arcv(1:ArcN))
                if dmin/span >= dSep
                    ArcN = ArcN+1; Arc(ArcN,:) = y; Arcv(ArcN) = v;
                    nIns = nIns+1; arcImp = true;
                else
                    [~,ni] = nearestIdx(y,Arc,ArcN);
                    if v < Arcv(ni), Arc(ni,:) = y; Arcv(ni) = v; end
                end
            end
        else
            [worstA,wa] = max(Arcv);
            if v < worstA
                dmin = nearestDist(y,Arc,ArcN);
                if dmin/span >= dSep
                    Arc(wa,:) = y; Arcv(wa) = v; ArcCred(wa) = 0;
                    nIns = nIns+1; arcImp = true;
                else
                    [~,ni] = nearestIdx(y,Arc,ArcN);
                    if v < Arcv(ni), Arc(ni,:) = y; Arcv(ni) = v; end
                end
            end
        end

        % archive credit: a verified improvement credited to the source centre
        if src(j)==3 && ctr(j)>0 && arcImp
            ArcCred(ctr(j)) = ArcCred(ctr(j))+1;
        end
    end
end

Best = struct('Cost',Alpha.Cost,'Vector',Alpha.Vector);
info = struct();
info.Algorithm       = 'SVAD-GWO';
info.Evaluations     = fe;
info.Rounds          = rounds;
info.FinalPopulation = Xv;
info.FinalFitness    = fv;
info.FinalArchive    = Arc(1:ArcN,:);
info.FinalArchiveFit = Arcv(1:ArcN);
info.ArchiveSize     = ArcN;
info.ArchiveInserts  = nIns;
info.EvalBySource    = nEvalG;    % [G1 G2 E]
info.ImpBySource     = nImpG;     % [G1 G2 E]
info.FTrace          = Ftrace;
info.Parameters      = struct('K',K,'nG2',nG2,'nE',nE,'F0',F0,'F1',F1, ...
                              'tc',tc,'pSteer',pSteer,'lamSteer',lamSteer, ...
                              'arcCap',arcCap,'dSep',dSep);
info.Seconds = toc(clockStart);
assert(fe==budget && numel(T)==budget && abs(T(end)-Best.Cost)<1e-12, ...
    'SVAD-GWO evaluation contract violated.');
end

% ==================== helpers ====================
function s=pushSucc(s,d,cap)
if numel(s)<cap, s(end+1,1)=d; else, s(1)=[]; s(end+1,1)=d; end
end

function sig=shellSigma(succ,span,D)
% Adaptive shell radius: median of recent verified successful steps.
if numel(succ)>=5, L=median(succ); else, L=0.05*span; end
L = max(L,0.01*span);
sig = L*sqrt(3/D);
end

function [A,B,Dl]=insertLeader(A,B,Dl,x,v)
if v<A.Cost
    Dl=B; B=A; A=struct('Cost',v,'Vector',x);
elseif v<B.Cost
    Dl=B; B=struct('Cost',v,'Vector',x);
elseif v<Dl.Cost
    Dl=struct('Cost',v,'Vector',x);
end
end

function d=nearestDist(y,Arc,ArcN)
d = sqrt(min(sum((Arc(1:ArcN,:)-repmat(y,ArcN,1)).^2,2)));
end

function [d,ni]=nearestIdx(y,Arc,ArcN)
[dd,ii] = min(sum((Arc(1:ArcN,:)-repmat(y,ArcN,1)).^2,2));
d = sqrt(dd); ni = ii;
end

function [c1,c2]=pickTwoCenters(ArcN,sAux)
c1 = randi(sAux,ArcN);
c2 = randi(sAux,ArcN);
while c2==c1, c2 = randi(sAux,ArcN); end
end


function y=gwoMove(aA,A,B,Dl,xw,lb,ub)
% Standard GWO move of a single wolf around the three leaders (ablation filler).
D=numel(xw);
A1=2*aA*rand(1,D)-aA;  C1=2*rand(1,D);
A2=2*aA*rand(1,D)-aA;  C2=2*rand(1,D);
A3=2*aA*rand(1,D)-aA;  C3=2*rand(1,D);
X1=A.Vector -A1.*abs(C1.*A.Vector -xw);
X2=B.Vector -A2.*abs(C2.*B.Vector -xw);
X3=Dl.Vector-A3.*abs(C3.*Dl.Vector-xw);
y=(X1+X2+X3)/3;
y=min(max(y,lb),ub);
end
