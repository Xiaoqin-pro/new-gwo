function [Best,T,info]=SVADGWO2_core(f,state,N,seed,g2Mode,ablateE,opts)
%SVADGWO_CORE  Reference implementation shared by SVADGWO.m and the ablation harness.
%   The trailing arguments (g2Mode, ablateE, opts) are ablation hooks and are always
%   set to their proposed values by SVADGWO.m.  Do not treat them as tuning knobs.
%
%   Sparse-evaluation grey wolf optimizer for expensive black-box problems.
%   Three candidate sources share one budget of real function evaluations:
%
%     (1) Leader-guided wolves (N)
%         Standard GWO aggregation of alpha/beta/delta.
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
K        = fieldOr(opts,'K',10);   % nominal real evaluations per generation
% ---- adaptive evaluation frequency ------------------------------------------
% The allocation problem has a second, purely temporal dimension: how many real
% evaluations to spend in the current generation.  Under a fixed FE budget this is
% a direct trade-off between depth (more evaluations now) and reach (more
% generations).  Stagnation is the natural trigger: when the global best has not
% moved for many evaluations there is nothing left to refine locally, so paying for
% a wide batch is worthwhile; while the search is still improving, generations are
% cheap and should stay cheap.  This changes WHEN budget is spent, never WHICH
% candidate is evaluated, so it introduces no spatial bias.
Kmin     = fieldOr(opts,'Kmin',4);
Kmax     = fieldOr(opts,'Kmax',25);
stallTol = fieldOr(opts,'stallTol',2000);   % evaluations without a new global best
adaptK   = fieldOr(opts,'adaptK',0);        % 0 = fixed K
K        = max(1,K);
M      = fieldOr(opts,'M',K);   % candidate budget (>= K); M==K means no pool

if nargin<7 || isempty(opts), opts=struct(); end
% ---- candidate-source budget -------------------------------------------------
% The three sources share M = 2N candidate slots.  Instead of freezing a slot
% count per source (the old 50/12/38 split), the split is re-estimated every
% adaptEvery generations from the observed yield of each source, so the search
% spends its cheap-candidate budget where it is actually paying off.
%   yield_i  = (accepted improvements from source i + 1) / (evaluations + 2)
%   share_i ∝ exp(beta * yield_i),  clipped to [loShare, hiShare]
% Only two structural constants remain: M = 2N candidates and K = 0.1*M real
% evaluations, i.e. the sparse ratio.  No per-source number is hard coded.
useE    = fieldOr(opts,'useE',1);
useDiff = fieldOr(opts,'useDiff',1);
nG2      = fieldOr(opts,'nG2',round(0.3*K));  % DiffA evaluation quota
nE       = fieldOr(opts,'nE', round(0.3*K));  % archive evaluation quota
if ~useE,    nE  = 0; end     % no archive => no archive quota
if ~useDiff, nG2 = 0; end     % no differential => no DiffA quota
% remaining quota goes to the leader-guided GWO moves
adaptOn  = fieldOr(opts,'adaptSlots',0) && (nG2==0 && nE==0);
allocBeta= fieldOr(opts,'allocBeta',2.0);
loShare  = fieldOr(opts,'loShare',0.10);
hiShare  = fieldOr(opts,'hiShare',0.60);
adaptEvery = fieldOr(opts,'adaptEvery',20);
capG2 = 0; capE = 0;            % current allocation, filled below
if ~adaptOn
    capG2=nG2; capE=nE;      % fixed EVALUATION quota; zero is legitimate
end
% ---- candidate generation counts (independent of the evaluation quota) -------
% The pool factor pf = M/K says how many cheap candidates are produced per real
% evaluation.  Candidate counts scale the quota by pf, so the evaluation quota
% 4/3/3 stays fixed while the pool can be larger; screening then decides WHICH
% candidates inside each source are worth the quota.
pf = max(1, round(M/K));
cG2 = fieldOr(opts,'cG2',capG2*pf);
cE  = fieldOr(opts,'cE', capE *pf);
if ~useE,    cE  = 0; end
if ~useDiff, cG2 = 0; end
F0       = 1.0;   % differential scale at t=0
F1       = 0.3;   % differential scale at t=1
tc       = 0.7;   % contraction onset, fraction of budget
arcCap   = 24;    % archive capacity
dSep     = 0.02;  % archive separation threshold, fraction of search span

% ==================== setup ====================
clockStart = tic;
D      = size(state.initialPopulation,2);
lb     = state.lowerBound;
ub     = state.upperBound;
budget = state.maxEvaluations;
span   = max(ub-lb);
% With M == K every generated candidate is evaluated: there is no pool and no
% screening step, so the algorithm generates exactly what it pays for.
% When M equals the evaluation budget there is no pool and no screening at all:
% each generation draws exactly the candidates it will evaluate.
assert(size(state.initialPopulation,1)>=N && budget>=N);
rng(seed,'twister');
sAux = RandStream('mt19937ar','Seed',seed+424242);   % screening / secondary draws

% ---- factorial ablation switches (default = the proposed algorithm) ----
%   useE      : 1 = verified archive exists, feeds E slots and the DiffA pool;
%               0 = no archive at all (no admission, no credit, no E slots from it,
%                   DiffA pool = wolves only).
%   useDiff   : 1 = 12 differential slots; 0 = 12 filler slots (opts.diffFiller).
% Legacy positional arguments are preserved: ablateE=1 means 'E slots replaced by
% fillers but the archive still exists and still feeds DiffA' (the NoE-Slots arm).
diffFiller = char(fieldOr(opts,'diffFiller','gwo'));    % always 'gwo' in v2
eSlotsOn   = useE && ~ablateE;        % E slots generated from the archive
fixedF     = fieldOr(opts,'fixedF',NaN); % if finite, F(t) is pinned to this value
diffPool   = char(fieldOr(opts,'diffPool','joint'));  % 'joint' | 'wolves'
% screening policy: 'rand' (uniform random, the v2 default), 'geo' (alpha + centroid),
% 'arc' (alpha + verified archive).  Kcvg / Kdiv split the K evaluation slots.
screening  = char(fieldOr(opts,'screening','rand'));
Kcvg       = fieldOr(opts,'Kcvg',floor(K/2));
Kdiv       = fieldOr(opts,'Kdiv',K-Kcvg);

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
nEvalW = zeros(1,3);      % windowed counters, reset on each allocation step
nImpW  = zeros(1,3);
Ftrace = zeros(0,2);      % [FE, F(t)]
bestFE = 0;               % FE at which the global best last improved

% ---- deferred-submission candidate buffer ------------------------------------
% Candidates that were generated but not yet evaluated are NOT discarded; they
% stay in a bounded buffer and compete for evaluation slots in later generations.
% This is what makes a selective evaluation rule meaningful: because a candidate
% survives to be judged again, screening no longer changes how much budget each
% operator receives in expectation - it only decides which candidate to honour
% first.  With deferral off the buffer holds exactly one generation.
deferOn = fieldOr(opts,'defer',0);
capBuf  = fieldOr(opts,'capBuf',4*(2*N));   % buffer capacity in candidates
bufY    = zeros(0,D); bufSrc = zeros(0,1); bufPar = zeros(0,1); bufCtr = zeros(0,1);

% ==================== main loop ====================
while fe < budget
    rounds = rounds + 1;
    t   = fe/budget;
    if isfinite(fixedF)
        F = fixedF;                            % auxiliary arm: no late contraction
    else
        F = F0 - (F0-F1)*max(0,(t-tc)/max(1e-9,1-tc));
    end
    if adaptK
        % stall-driven frequency: widen the batch while stagnant, narrow it while
        % the search is still making progress
        if (fe - bestFE) >= stallTol
            Kj = Kmax;
        else
            Kj = Kmin;
        end
    else
        Kj = K;
    end
    aA  = 2-2*t;                              % standard GWO convergence factor
    sig = shellSigma(succ,span,D);            % adaptive shell radius
    Ftrace(end+1,:) = [fe F];

    % ---- 0) re-estimate the source budget split from observed yield ----
    if adaptOn && (mod(rounds-1,adaptEvery)==0)
        % Yield-based allocation with a strong prior toward the equal split so the
        % budget only shifts once enough evidence has accumulated.
        yld = (nImpW + 1) ./ (nEvalW + 2);       % Laplace-smoothed yield, recent window
        evidence = min(1, sum(nEvalW) / fieldOr(opts,'priorEvals',300));
        prior = ones(1,3)/3;
        post  = yld / sum(yld);
        mix   = (1-evidence)*prior + evidence*post;
        e = exp(allocBeta * (mix - mean(mix))*3);
        sh = e / sum(e);
        sh = min(max(sh, loShare), hiShare);
        sh = sh / sum(sh);
        % G1 occupies the remaining slots, so it must be part of the same
        % normalisation: allocate all M slots by share, then let G1 take the rest.
        total = M - N;                            % slots beyond the wolf base set
        sG1 = sh(1); sG2 = sh(2); sE = sh(3);
        capG2 = max(2, round(sG2/(1-sG1) * total));
        capE  = max(2, round(sE /(1-sG1) * total));
        over  = (capG2 + capE) - total;
        if over > 0
            % trim proportionally so G1 always keeps N slots
            capE = max(2, capE - min(over, capE-2));
            over2 = (capG2 + capE) - total;
            if over2 > 0, capG2 = max(2, capG2 - over2); end
        end
        if (capG2 + capE) > total
            capG2 = max(2, total - 2);
        end
    end
    if adaptOn && (mod(rounds-1,adaptEvery)==0)
        nEvalW(:) = 0; nImpW(:) = 0;             % start a fresh measurement window
    end
    nG2 = max(0,capG2); nE = max(0,capE);

    % ---- 1) candidate generation (no real evaluation here) ----
    Y   = zeros(M,D);
    src = zeros(M,1);
    par = zeros(M,1);
    ctr = zeros(M,1);
    m   = 0;

    % --- (1) leader-guided wolves (standard three-leader GWO) ---
    nG1 = M - cG2 - cE;                 % remaining candidates go to leader-guided moves
    nG1 = max(1,nG1);
    for kk=1:nG1
        i = mod(kk-1,N)+1;
        m = m+1;
        R6 = rand(1,6*D);
        A1 = 2*aA*R6(1:D)-aA;        C1 = 2*R6(D+1:2*D);
        A2 = 2*aA*R6(2*D+1:3*D)-aA;  C2 = 2*R6(3*D+1:4*D);
        A3 = 2*aA*R6(4*D+1:5*D)-aA;  C3 = 2*R6(5*D+1:6*D);
        X1 = Alpha.Vector - A1.*abs(C1.*Alpha.Vector - Xv(i,:));
        X2 = Beta.Vector  - A2.*abs(C2.*Beta.Vector  - Xv(i,:));
        X3 = Delta.Vector - A3.*abs(C3.*Delta.Vector - Xv(i,:));
        xg = (X1+X2+X3)/3;
        Y(m,:) = min(max(xg,lb),ub);
        src(m) = 1; par(m) = i;
    end

    % --- (2) differential slots (DiffA) ---
    % The pool is the joint set of wolves and verified elites, but only when the
    % archive mechanism exists.  With useE=0 there is no archive to draw from.
    if useE && ArcN>0 && strcmpi(diffPool,'joint')
        pool = [Xv; Arc(1:ArcN,:)];
    else
        pool = Xv;
    end
    nP = size(pool,1);
    for j=1:cG2
        m = m+1;
        if ~useDiff
            % Differential budget occupied by plain GWO candidates: switching DiffA
            % off means "replaced by ordinary GWO", never "replaced by a shell".
            iw = mod(j-1,N)+1;
            Y(m,:) = gwoMove(aA,Alpha,Beta,Delta,Xv(iw,:),lb,ub);
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
    for j=1:cE
        m = m+1;
        if ~eSlotsOn
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

    % ---- 1b) deferred submission: merge the surviving buffer with new candidates ----
    if deferOn
        Y    = [bufY; Y];
        src  = [bufSrc; src];
        par  = [bufPar; par];
        ctr  = [bufCtr; ctr];
        Mcur = size(Y,1);
    else
        Mcur = M;
    end

    % ---- 2) screening: which K of the M candidates get a real evaluation ----
    switch lower(screening)
        case 'geo'
            % convergence set: closest to alpha; diversity set: farthest from the
            % population centroid (parameter-free geometric screening)
            ctr0 = mean(Xv,1);
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            dC = sqrt(sum((Y-ctr0).^2,2));
            [~,ordA] = sort(dA,'ascend');
            [~,ordC] = sort(dC,'descend');
            sel = unique([ordA(1:min(Kcvg,M)); ordC(1:min(Kdiv,M))]);
        case 'arc'
            % convergence set: closest to alpha; diversity set: farthest from every
            % verified elite, i.e. novelty measured against real evaluated optima
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            [~,ordA] = sort(dA,'ascend');
            if ArcN>0
                dmin = zeros(Mcur,1);
                for mm=1:Mcur
                    dmin(mm) = min(sqrt(sum((Arc(1:ArcN,:)-Y(mm,:)).^2,2)));
                end
            else
                dmin = sqrt(sum((Y-mean(Xv,1)).^2,2));
            end
            [~,ordC] = sort(dmin,'descend');
            sel = unique([ordA(1:min(Kcvg,M)); ordC(1:min(Kdiv,M))]);
        case 'strat'
            % Stratified unbiased screening: each candidate source receives a fixed
            % share of the K evaluation slots and is sampled uniformly within the
            % source.  This keeps the within-source draw unbiased (no positional
            % preference, unlike distance-based screening) while removing the
            % structural under-sampling of sources that occupy few slots.
            kG1 = fieldOr(opts,'kG1',3);
            kG2s= fieldOr(opts,'kG2s',3);
            kEs = fieldOr(opts,'kEs',Kj-kG1-kG2s);
            idx1 = find(src(:)==1);              % G1 leader-guided candidates
            idx2 = find(src(:)==2);              % differential-budget slots
            idx3 = find(src(:)==3);              % archive-budget slots
            sel = zeros(0,1);
            for blk = { {idx1,kG1}, {idx2,kG2s}, {idx3,kEs} }
                ii = blk{1}{1}; kk = blk{1}{2};
                if isempty(ii) || kk<=0, continue; end
                kk = min(kk, numel(ii));
                take = randperm(sAux,numel(ii),kk)';
                sel = [sel; ii(take)];
            end
        case 'inner'
            % Quota-respecting inner-source screening.
            % The evaluation quota (4/3/3) is FIXED, so every mechanism keeps its
            % exact share of real evaluations.  Screening only decides which
            % candidates inside each source deserve that share:
            %   half the quota -> candidates closest to the current alpha
            %                     (the source's own refinement opportunity)
            %   half the quota -> maximin-spread candidates within the source
            %                     (coverage of that source's own distribution)
            % Because the quota is fixed, a "clever" pick can no longer steal budget
            % from another mechanism - which is exactly the confound that made every
            % earlier screening experiment fail.
            nq = [fieldOr(opts,'qG1n',4) fieldOr(opts,'qG2n',3) fieldOr(opts,'qE3n',3)];
            if sum(nq)~=Kj
                nq = round([0.4 0.3 0.3]*Kj);
                while sum(nq)<Kj, [~,im]=max([0.4 0.3 0.3]*Kj-nq); nq(im)=nq(im)+1; end
                while sum(nq)>Kj, [~,im]=max(nq-[0.4 0.3 0.3]*Kj); nq(im)=max(1,nq(im)-1); end
            end
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            sel = zeros(0,1);
            for ss = 1:3
                ii = find(src(:)==ss);
                kk = min(nq(ss), numel(ii));
                if isempty(ii) || kk<=0, continue; end
                if kk>=numel(ii)
                    sel = [sel; ii]; continue;
                end
                nNear = ceil(kk/2); nFar = kk-nNear;
                [~,oN] = sort(dA(ii),'ascend');
                pick = ii(oN(1:nNear));
                if nFar>0
                    rest = setdiff(ii,pick);
                    if isempty(rest)
                        pick = ii(oN(1:kk));
                    else
                        chosen = rest(1);
                        dd = sqrt(sum((Y(rest,:)-Y(chosen,:)).^2,2));
                        guard=0;
                        while numel(chosen)<nFar && guard<numel(rest)+5
                            guard=guard+1;
                            dd(ismember(rest,chosen)) = -inf;
                            [mv,nx] = max(dd);
                            if ~isfinite(mv), break; end
                            chosen(end+1,1) = rest(nx);
                            dd = min(dd, sqrt(sum((Y(rest,:)-Y(rest(nx),:)).^2,2)));
                        end
                        pick = [pick; chosen(:)];
                    end
                end
                sel = [sel; pick];
            end
            sel = unique(sel,'stable'); sel = sel(:);
        case 'innerph'
            % Phase-switched inner-source screening (quota fixed at 4/3/3).
            % Within each source the quota is split between two channels:
            %   refine channel : candidates closest to alpha   (exploit the basin)
            %   cover  channel : maximin-spread candidates     (probe other basins)
            % The split is governed by whether the global best is still moving.
            % While the search improves, refinement pays (the right basin is known);
            % once it stagnates, coverage pays (the basin must be escaped).  The
            % EVALUATION QUOTA never changes - only how the quota is spent.
            nq = [fieldOr(opts,'qG1n',4) fieldOr(opts,'qG2n',3) fieldOr(opts,'qE3n',3)];
            if sum(nq)~=Kj
                nq = round([0.4 0.3 0.3]*Kj);
                while sum(nq)<Kj, [~,im]=max([0.4 0.3 0.3]*Kj-nq); nq(im)=nq(im)+1; end
                while sum(nq)>Kj, [~,im]=max(nq-[0.4 0.3 0.3]*Kj); nq(im)=max(1,nq(im)-1); end
            end
            stagn = (fe - bestFE) >= fieldOr(opts,'phStall',1000);
            if stagn
                wNear = fieldOr(opts,'wNearStag',0.25);   % mostly coverage
            else
                wNear = fieldOr(opts,'wNearMove',0.75);   % mostly refinement
            end
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            sel = zeros(0,1);
            for ss = 1:3
                ii = find(src(:)==ss);
                kk = min(nq(ss), numel(ii));
                if isempty(ii) || kk<=0, continue; end
                if kk>=numel(ii)
                    sel = [sel; ii]; continue;
                end
                nNear = max(0, min(kk, round(wNear*kk)));
                nFar  = kk-nNear;
                pick = zeros(0,1);
                if nNear>0
                    [~,oN] = sort(dA(ii),'ascend');
                    pick = ii(oN(1:nNear));
                end
                if nFar>0
                    rest = setdiff(ii,pick);
                    if numel(rest)<=nFar
                        pick = [pick; rest(:)];
                    else
                        chosen = rest(1);
                        dd = sqrt(sum((Y(rest,:)-Y(chosen,:)).^2,2));
                        guard=0;
                        while numel(chosen)<nFar && guard<numel(rest)+5
                            guard=guard+1;
                            dd(ismember(rest,chosen)) = -inf;
                            [mv,nx] = max(dd);
                            if ~isfinite(mv), break; end
                            chosen(end+1,1) = rest(nx);
                            dd = min(dd, sqrt(sum((Y(rest,:)-Y(rest(nx),:)).^2,2)));
                        end
                        pick = [pick; chosen(:)];
                    end
                end
                sel = [sel; pick];
            end
            sel = unique(sel,'stable'); sel = sel(:);
        case 'stratshare'
            % Fixed evaluation quota per source, scaled to the current K.
            % The three mechanisms receive a pre-declared share of the real
            % evaluations - at K=10 that is 4 / 3 / 3 for G1 / DiffA / E - and the
            % share is rescaled when K changes, so the rule stays defined for any
            % batch size.  Within a source the draw is uniform, so no positional
            % preference is introduced.  This replaces the old hand-set 50/12/38
            % CANDIDATE ratio with an explicit, interpretable EVALUATION quota.
            qG1 = fieldOr(opts,'qG1',0.4);
            qG2 = fieldOr(opts,'qG2',0.3);
            qE  = max(0,1-qG1-qG2);
            q   = [qG1 qG2 qE];
            nq  = max(1, round(q*Kj));
            nq  = min(nq, Kj);
            % top up / trim so the quotas sum exactly to Kj
            while sum(nq) < Kj
                [~,im] = max(q*Kj - nq); nq(im) = nq(im)+1;
            end
            while sum(nq) > Kj
                [~,im] = max(nq - q*Kj); nq(im) = max(1,nq(im)-1);
                if all(nq<=1) && sum(nq)>Kj, break; end
            end
            sel = zeros(0,1);
            for ss = 1:3
                ii = find(src(:)==ss);
                if isempty(ii) || nq(ss)<=0, continue; end
                kk = min(nq(ss), numel(ii));
                take = randperm(sAux,numel(ii),kk)';
                sel = [sel; ii(take)];
            end
        case 'fps'
            % Anchored maximin (farthest-point) screening.
            % Slot 1 is the candidate closest to alpha, so the locally refining
            % opportunity is never missed; the remaining slots greedily maximise the
            % minimum distance to the already-selected set.  The evaluated subset is
            % therefore a small maximin coreset of the candidate distribution: every
            % real evaluation covers a region no other evaluation covers, which is
            % the resource-constrained rationale.  Unlike "farthest from alpha" or
            % "farthest from the archive", the criterion is relative to the SELECTED
            % set, so it cannot pile up on the domain boundary.
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            [~,first] = min(dA);
            sel = first;
            dmin = sqrt(sum((Y-Y(first,:)).^2,2));
            for qq=2:K
                dmin(sel) = -inf;
                [~,nx] = max(dmin);
                sel(end+1,1) = nx;
                dmin = min(dmin, sqrt(sum((Y-Y(nx,:)).^2,2)));
            end
            sel = sel(:);
        case 'core'
            % Source-guaranteed maximin coreset.
            % Step 1: every candidate source contributes at least one evaluation, so
            %   no mechanism can be starved by the screening rule.
            % Step 2: the remaining slots greedily maximise the minimum distance to
            %   the already-selected set, i.e. the evaluated subset is a maximin
            %   coreset of the candidate distribution.
            % Rationale (resource constrained): with only K real evaluations, the
            %   best use of each call is to probe a region no other call probes.
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            sel = zeros(0,1);
            for ss = 1:3
                ii = find(src(:)==ss);
                if isempty(ii), continue; end
                [~,o2] = sort(dA(ii),'ascend');
                sel(end+1,1) = ii(o2(1));
            end
            if numel(sel)==0, sel = 1; end
            sel = sel(:);
            dmin = inf(Mcur,1);
            for qq=1:numel(sel)
                dmin = min(dmin, sqrt(sum((Y-Y(sel(qq),:)).^2,2)));
            end
            while numel(sel)<Kj
                dmin(sel) = -inf;
                [~,nx] = max(dmin);
                sel(end+1,1) = nx;
                dmin = min(dmin, sqrt(sum((Y-Y(nx,:)).^2,2)));
            end
            sel = sel(:);
        case 'softpot'
            % Soft potential-weighted sampling (probability matching).
            % Each candidate i receives an evaluation probability proportional to
            %   score_i = exp(-dA_i / mean(dA))^gammaA * (1 + dR_i / mean(dR))^gammaR
            % where dA is the distance to alpha (potential) and dR the distance to
            % the nearest verified archive point (novelty).  K candidates are drawn
            % WITHOUT replacement from this distribution.
            % Unlike a hard rule, every candidate keeps a non-zero probability, so no
            % source or region is starved: the sampling is only *tilted*, not
            % restricted.  This is the "soft" counterpart of geometric screening.
            gA = fieldOr(opts,'gammaA',1.0);
            gR = fieldOr(opts,'gammaR',0.5);
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            mA = max(mean(dA),1e-9);
            pot = exp(-gA*dA/mA);
            if ArcN>0
                dR = zeros(Mcur,1);
                for mm=1:Mcur
                    dR(mm) = min(sqrt(sum((Arc(1:ArcN,:)-Y(mm,:)).^2,2)));
                end
            else
                dR = sqrt(sum((Y-mean(Xv,1)).^2,2));
            end
            mR = max(mean(dR),1e-9);
            nov = (1+dR/mR).^gR;
            wgt = pot.*nov;
            wgt = wgt/sum(wgt);
            sel = sampleW(sAux,wgt,K);
        case 'stratgeo'
            % Per-source geometric screening.
            % The candidate pool is heterogeneous (G1 / DiffA / E), so applying one
            % global distance rule silently re-weights the operators: "closest to
            % alpha" hits G1 moves because GWO already converges there, while
            % "farthest from the archive" hits the domain boundary.  This rule keeps
            % every source's slot budget exactly as designed and only replaces the
            % WITHIN-source draw by a spatial one: half of a source's slots go to its
            % alpha-nearest candidates (refinement) and half to its maximin-spread
            % candidates (coverage).  Operator weights stay untouched, so the sparse
            % budget allocation is preserved while the evaluated subset becomes a
            % small spatial coreset of each source distribution.
            kG1 = fieldOr(opts,'kG1',3);
            kG2s= fieldOr(opts,'kG2s',3);
            kEs = fieldOr(opts,'kEs',Kj-kG1-kG2s);
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            ctr0 = mean(Xv,1);
            dC = sqrt(sum((Y-ctr0).^2,2));
            sel = zeros(0,1);
            blkSpec = {1,kG1; 2,kG2s; 3,kEs};
            for bi=1:3
                ii = find(src(:)==blkSpec{bi,1});
                kk = blkSpec{bi,2};
                if isempty(ii) || kk<=0, continue; end
                kk = min(kk, numel(ii));
                nNear = ceil(kk/2); nFar = kk-nNear;
                % refinement half: nearest to alpha within this source
                [~,oN] = sort(dA(ii),'ascend');
                pick = ii(oN(1:nNear));
                % coverage half: maximin among the rest of this source
                if nFar>0
                    rest = setdiff(ii,pick);
                    if numel(rest)>=nFar
                        dd = dC(rest);
                        [~,oF] = sort(dd,'descend');
                        pick = [pick; rest(oF(1:nFar))];
                    else
                        pick = [pick; rest];
                    end
                end
                sel = [sel; pick];
            end
            sel = unique(sel,'stable'); sel = sel(:);
        case 'stratcore'
            % Per-source maximin: every source contributes its most spread-out
            % candidates, budgets unchanged.  Tests coverage-within-source without
            % any alpha term.
            kG1 = fieldOr(opts,'kG1',3);
            kG2s= fieldOr(opts,'kG2s',3);
            kEs = fieldOr(opts,'kEs',Kj-kG1-kG2s);
            sel = zeros(0,1);
            blkSpec = {1,kG1; 2,kG2s; 3,kEs};
            for bi=1:3
                ii = find(src(:)==blkSpec{bi,1});
                kk = min(blkSpec{bi,2}, numel(ii));
                if isempty(ii) || kk<=0, continue; end
                sub = Y(ii,:);
                chosen = ii(1);
                dd = sqrt(sum((sub-Y(chosen(1),:)).^2,2));
                guard = 0;
                while numel(chosen)<kk && guard<numel(ii)+5
                    guard = guard+1;
                    dd(ismember(ii,chosen)) = -inf;
                    [mv,nx] = max(dd);
                    if ~isfinite(mv), break; end
                    chosen(end+1,1) = ii(nx);
                    dd = min(dd, sqrt(sum((sub-Y(ii(nx),:)).^2,2)));
                end
                sel = [sel; chosen(:)];
            end
            sel = unique(sel,'stable'); sel = sel(:);
        case 'corehyb'
            % Dual-potential maximin screening:
            %   kLocal slots  -> candidates closest to alpha (refine the current basin)
            %   remaining     -> maximin over the candidate set (cover other basins)
            % When kLocal = 0 this reduces to the pure maximin coreset.
            kLocal = fieldOr(opts,'kLocal',3);
            dA = sqrt(sum((Y-Alpha.Vector).^2,2));
            [~,oA] = sort(dA,'ascend');
            sel = oA(1:min(kLocal,Mcur))';
            sel = sel(:);
            dmin = inf(Mcur,1);
            for qq=1:numel(sel)
                dmin = min(dmin, sqrt(sum((Y-Y(sel(qq),:)).^2,2)));
            end
            while numel(sel)<Kj
                dmin(sel) = -inf;
                [~,nx] = max(dmin);
                if ~isfinite(dmin(nx)), break; end
                sel(end+1,1) = nx;
                dmin = min(dmin, sqrt(sum((Y-Y(nx,:)).^2,2)));
            end
            sel = unique(sel,'stable'); sel = sel(:);
        case 'corephase'
            % Phase-adaptive maximin: cover distinct basins early, refine later.
            th = fieldOr(opts,'phaseThresh',0.5);
            if t < th
                dA = sqrt(sum((Y-Alpha.Vector).^2,2));
                [~,first] = min(dA);
                sel = first;
                dmin = sqrt(sum((Y-Y(first,:)).^2,2));
                for qq=2:K
                    dmin(sel) = -inf;
                    [~,nx] = max(dmin);
                    sel(end+1,1) = nx;
                    dmin = min(dmin, sqrt(sum((Y-Y(nx,:)).^2,2)));
                end
                sel = sel(:);
            else
                sel = randperm(sAux,Mcur,Kj)';
            end
        case 'fpsr'
            % Same maximin rule, seeded by a uniformly random candidate instead of
            % the alpha-nearest one (control arm: isolates the value of the anchor).
            first = randperm(sAux,Mcur,1);
            sel = first;
            dmin = sqrt(sum((Y-Y(first,:)).^2,2));
            for qq=2:K
                dmin(sel) = -inf;
                [~,nx] = max(dmin);
                sel(end+1,1) = nx;
                dmin = min(dmin, sqrt(sum((Y-Y(nx,:)).^2,2)));
            end
            sel = sel(:);
        otherwise
            sel = randperm(sAux,Mcur,Kj)';
    end
    sel = sel(:);
    if Mcur<=Kj
        sel = (1:Mcur)';           % M == K: every candidate is evaluated, no screening
    end
    if numel(sel)>Kj, sel = sel(1:Kj); end
    if numel(sel)<Kj
        rest = setdiff(1:Mcur,sel);
        need = Kj-numel(sel);
        if numel(rest)>=need
            pick = randperm(sAux,numel(rest),need);
            sel = [sel; rest(pick)'];
        end
    end

    % ---- 3) real evaluation and atomic commit ----
    if strcmpi(fieldOr(opts,'evalMode','batch'),'seq')
        % Sequential greedy evaluation.  Instead of fixing K candidates up front,
        % pick one, evaluate it, update the leaders/alpha, then re-rank the
        % remaining candidates with the refreshed information.  Cost model: the
        % ranking proxy is the distance to the CURRENT alpha, i.e. the candidate
        % most likely to refine the best basin is evaluated next.  This is the
        % "one expensive call at a time" form of the sparse-evaluation rationale.
        remaining = (1:M)';
        for q=1:K
            if fe>=budget, break; end
            if strcmpi(fieldOr(opts,'seqRank','alpha'),'alt')
                % Alternate criteria within the generation: odd calls refine the
                % current basin (closest to alpha), even calls cover new territory
                % (farthest from everything already called).  Balances the two
                % failure modes of the pure rules.
                if mod(q,2)==1
                    dd = sqrt(sum((Y(remaining,:)-Alpha.Vector).^2,2));
                    [~,o2] = sort(dd,'ascend');
                else
                    taken = setdiff((1:M)',remaining);
                    if isempty(taken)
                        [~,o2] = min(sqrt(sum((Y(remaining,:)-Alpha.Vector).^2,2)));
                    else
                        dm = inf(numel(remaining),1);
                        for tt=1:numel(taken)
                            dm = min(dm, sqrt(sum((Y(remaining,:)-Y(taken(tt),:)).^2,2)));
                        end
                        [~,o2] = sort(dm,'descend');
                    end
                end
            elseif strcmpi(fieldOr(opts,'seqRank','alpha'),'maximin')
                % pick the candidate farthest from everything evaluated so far in
                % this generation, so the K calls keep covering new territory
                dd = sqrt(sum((Y(remaining,:)-Alpha.Vector).^2,2));
                if numel(remaining)==M
                    [~,o2]=min(dd);
                else
                    taken = setdiff((1:M)',remaining);
                    dm = inf(numel(remaining),1);
                    for tt=1:numel(taken)
                        dm = min(dm, sqrt(sum((Y(remaining,:)-Y(taken(tt),:)).^2,2)));
                    end
                    dd = dm;
                    [~,o2] = sort(dd,'descend');
                end
            else
                dd = sqrt(sum((Y(remaining,:)-Alpha.Vector).^2,2));
                [~,o2] = sort(dd,'ascend');
            end
            j = remaining(o2(1));
            remaining = setdiff(remaining,j);
            y = Y(j,:);
            v = f(y); fe = fe+1;
            [Alpha,Beta,Delta] = insertLeader(Alpha,Beta,Delta,y,v);
            T(fe) = Alpha.Cost;
            if fe==1 || T(fe)<T(fe-1), bestFE = fe; end
            srcJ = src(j);
            if srcJ==1
                i = par(j);
                if v < fv(i)
                    succ = pushSucc(succ,norm(y-Xv(i,:)),succCap);
                    nImpG(1) = nImpG(1)+1; nImpW(1) = nImpW(1)+1;
                end
                Xv(i,:) = y; fv(i) = v;
                nEvalG(1) = nEvalG(1)+1; nEvalW(1) = nEvalW(1)+1;
            else
                [worstF,wi] = max(fv);
                if v < worstF
                    succ = pushSucc(succ,norm(y-Xv(wi,:)),succCap);
                    Xv(wi,:) = y; fv(wi) = v;
                    if srcJ==2, nImpG(2)=nImpG(2)+1; nImpW(2)=nImpW(2)+1; else, nImpG(3)=nImpG(3)+1; nImpW(3)=nImpW(3)+1; end
                end
                if srcJ==2, nEvalG(2)=nEvalG(2)+1; nEvalW(2)=nEvalW(2)+1; else, nEvalG(3)=nEvalG(3)+1; nEvalW(3)=nEvalW(3)+1; end
            end
            arcImp=false;
            if useE
                % archive admission uses the SAME rule as the batch path
                if ArcN==0
                    ArcN=1; Arc(1,:)=y; Arcv(1)=v; nIns=nIns+1; arcImp=true;
                elseif ArcN<arcCap
                    dminA=nearestDist(y,Arc,ArcN);
                    if v<max(Arcv(1:ArcN))
                        if dminA/span>=dSep
                            ArcN=ArcN+1; Arc(ArcN,:)=y; Arcv(ArcN)=v; nIns=nIns+1; arcImp=true;
                        else
                            [~,ni]=nearestIdx(y,Arc,ArcN);
                            if v<Arcv(ni), Arc(ni,:)=y; Arcv(ni)=v; end
                        end
                    end
                else
                    [worstA,wa]=max(Arcv);
                    if v<worstA
                        dminA=nearestDist(y,Arc,ArcN);
                        if dminA/span>=dSep
                            Arc(wa,:)=y; Arcv(wa)=v; ArcCred(wa)=0; nIns=nIns+1; arcImp=true;
                        else
                            [~,ni]=nearestIdx(y,Arc,ArcN);
                            if v<Arcv(ni), Arc(ni,:)=y; Arcv(ni)=v; end
                        end
                    end
                end
                if srcJ==3 && ctr(j)>0 && arcImp
                    ArcCred(ctr(j))=ArcCred(ctr(j))+1;
                end
            end
        end
    else
    for q=1:numel(sel)
        if fe>=budget, break; end
        j = sel(q);
        y = Y(j,:);
        v = f(y);
        fe = fe+1;
        [Alpha,Beta,Delta] = insertLeader(Alpha,Beta,Delta,y,v);
        T(fe) = Alpha.Cost;
        if fe==1 || T(fe)<T(fe-1), bestFE = fe; end

        if src(j)==1
            % leader-guided: the wolf always moves; improvement only recorded
            i = par(j);
            if v < fv(i)
                d = norm(y-Xv(i,:));
                succ = pushSucc(succ,d,succCap);
                nImpG(1) = nImpG(1)+1; nImpW(1) = nImpW(1)+1;
            end
            Xv(i,:) = y; fv(i) = v;
            nEvalG(1) = nEvalG(1)+1; nEvalW(1) = nEvalW(1)+1;
        else
            % differential / archive: compete with the worst wolf
            [worstF,wi] = max(fv);
            if v < worstF
                d = norm(y-Xv(wi,:));
                Xv(wi,:) = y; fv(wi) = v;
                succ = pushSucc(succ,d,succCap);
                if src(j)==2, nImpG(2) = nImpG(2)+1; nImpW(2)=nImpW(2)+1; else, nImpG(3) = nImpG(3)+1; nImpW(3)=nImpW(3)+1; end
            end
            if src(j)==2, nEvalG(2) = nEvalG(2)+1; nEvalW(2)=nEvalW(2)+1; else, nEvalG(3) = nEvalG(3)+1; nEvalW(3)=nEvalW(3)+1; end
        end

        % ---- archive admission: verified, strictly better, spatially separated ----
        % With useE=0 no archive is maintained at all (no admissions, no credit);
        % this is what makes the E factor genuinely off rather than merely idle.
        arcImp = false;
        if ~useE
            % archive disabled: nothing is admitted, nothing is credited
        elseif ArcN==0
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
        if useE && src(j)==3 && ctr(j)>0 && arcImp
            ArcCred(ctr(j)) = ArcCred(ctr(j))+1;
        end
    end
    end

    % ---- 4) carry the unevaluated candidates forward ----------------------------
    if deferOn
        usedMask = false(Mcur,1); usedMask(sel(sel<=Mcur)) = true;
        keep = find(~usedMask);
        if ~isempty(keep)
            Yk = Y(keep,:); sk = src(keep); pk = par(keep); ck = ctr(keep);
            % bounded buffer: keep the most recent survivors, drop the oldest
            allY = [bufY(zeros(0,1),:); Yk];   % survivors only
            if size(allY,1) > capBuf
                allY   = allY(end-capBuf+1:end,:);
                sk     = sk(end-capBuf+1:end);
                pk     = pk(end-capBuf+1:end);
                ck     = ck(end-capBuf+1:end);
            end
            bufY = allY; bufSrc = sk; bufPar = pk; bufCtr = ck;
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
info.Parameters      = struct('K',K,'adaptK',adaptK,'Kmin',Kmin,'Kmax',Kmax,'nG2',nG2,'nE',nE,'F0',F0,'F1',F1, ...
                              'tc',tc,'arcCap',arcCap,'dSep',dSep);
info.Ablation        = struct('useE',useE,'useDiff',useDiff,'fixedF',fixedF, ...
                              'screening',screening,'Kcvg',Kcvg,'Kdiv',Kdiv, ...
                              'diffPool',diffPool,'eSlotsOn',eSlotsOn, ...
                              'diffFiller',diffFiller,'g2Mode',g2Mode, ...
                              'archiveAdmission',useE);
info.Seconds = toc(clockStart);
assert(fe==budget && numel(T)==budget && abs(T(end)-Best.Cost)<1e-12, ...
    'SVAD-GWO evaluation contract violated.');
end

% ==================== helpers ====================
function sel=sampleW(sAux,wgt,K)
% Weighted sampling WITHOUT replacement using the auxiliary stream.
wgt=wgt(:); n=numel(wgt); K=min(K,n);
sel=zeros(K,1);
for q=1:K
    c=cumsum(wgt); c=c/c(end);
    r=rand(sAux);
    j=find(c>=r,1); if isempty(j), j=n; end
    sel(q)=j;
    wgt(j)=0;
end
end

function v=fieldOr(s,name,default)
if isfield(s,name) && ~isempty(s.(name)), v=s.(name); else, v=default; end
end

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
