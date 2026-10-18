# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2"
tex = r"""
\section{Experimental setup}
\label{sec:setup}
\subsection{Benchmark and protocol}
All optimization experiments use the CEC2017 real-parameter benchmark in its
official form of 29 functions (F1 and F3--F30; F2 is not part of the suite),
dimension $D=50$, search space $[-100,100]^D$, and a budget of 100{,}000 real
objective evaluations per run, initialization included
\citep{awad2016problem}. Every (algorithm, function) pair is run 30 times with
seeds 3001--3030, and all algorithms start from the same initial population for
a given (function, seed) pair. Initialization and search random streams are
kept separate, so sharing the initial population does not couple the search
trajectories.

Budgets are audited rather than asserted: every objective call passes through
a probe that counts true evaluations independently of the algorithm, and the
runner asserts that the probe count equals the budget exactly. The probe also
maintains a bounded reservoir of evaluated positions, which provides unbiased
novelty measurements without perturbing any algorithm stream. All runs were
executed on MATLAB R2025b using exactly four parallel workers (local
\texttt{parpool}, no serial fallback); each independent run writes its result
atomically, and batches are resumable. Reported runtimes are in-run wall-clock
times of the search phase, measured identically for every method.

Two additional tiers are used to probe the operating range: a $D=100$ tier
(29 functions, ten seeds, 100{,}000 evaluations) and a resource-constrained
tier in which the budget is reduced five-fold (20{,}000 evaluations, 29
functions, ten seeds). The source ablation uses a disjoint out-of-sample seed
block (3071--3100) and holds the pool size ($M=100$), the number of evaluated
candidates ($K=10$), the budget and the acceptance rules fixed in every arm;
disabled routes are replaced by additional standard GWO moves, so the
comparison isolates the \emph{composition} of the candidate pool rather than
the amount of sparse evaluation.

\subsection{Baselines}
The comparison set contains six methods, all implemented and audited inside
the same codebase: standard GWO \citep{mirjalili2014gwo}; the strong improved
GWO of \citet{nadimi2021igwo} (I-GWO); a 2026 hierarchical GWO
\citep{su2026hagwo} (HAGWO, author code); classic inertia-weight PSO
\citep{kennedy1995pso,shi1998modified}; CLPSO \citep{liang2006clpso}; and a
2026 adaptive oppositional GWO \citep{khalid2026aogwo} (AOGWO, author code).
Table~\ref{tab:setup} lists the source of each implementation, its
configuration and the adaptations that were necessary to run it under one
protocol. Adaptations are limited to the interface and to evaluation
accounting; no search operator of any baseline was modified.

\begin{table}[t]
\centering
\small
\caption{Baselines: sources, configurations and adaptations. All methods run
with $N=50$ and an identical budget of 100{,}000 true evaluations.}
\label{tab:setup}
\input{tables/table_setup.tex}
\end{table}

\subsection{Metrics and statistics}
For every baseline we report the median paired error ratio (VAST-GWO over the
baseline, computed per function and then medianed over the 29 functions, so
that values below one favour \method), the function-level win--loss count, the
paired Wilcoxon signed-rank test on $\log_{10}$ errors with identical seeds,
and the Holm correction of those $p$ values across the 29 functions. Mean
ranks are computed from per-function median errors across all seven methods.
Bootstrap 95\% confidence intervals for the median $\log_{10}$ gain use
10{,}000 resamples over the pooled paired differences. Pooled tests are
reported for completeness but are not used as primary evidence, because paired
samples across different functions are not independent. Effect sizes for the
application study are reported as rank-biserial correlations.

Behaviour metrics are derived from the stored best-so-far traces with
definitions fixed before the formal batch: a stagnation episode is a run of
evaluations without a best-so-far improvement of length at least
$W=\max(50,1\%\,\mathrm{FE}_{\max})=1000$; the \emph{recovery probability} is
the fraction of such episodes that return to improvement within a further
$4W$ evaluations; the \emph{long-stagnation share} is the fraction of the
budget spent inside episodes of length $\ge W$; an evaluation is \emph{novel}
if its normalized nearest-neighbour distance to previously evaluated positions
exceeds 1\% of the search-space diagonal; the \emph{useful-novelty rate} is
the fraction of novel evaluations that are the last novel evaluation preceding
a strict improvement within $W$ evaluations; and \emph{improving rates} are
counted over the four quarters of the budget.

\section{Results}
\label{sec:results}
\subsection{Comparison with strong baselines}
Table~\ref{tab:main} reports the final seven-method comparison and
Fig.~\ref{fig:ranks} the corresponding mean ranks. \method{} attains the best
mean rank, 2.24, ahead of the strong improved GWO (2.28), the 2026
hierarchical HAGWO (3.41), PSO (4.41), CLPSO (4.48), the 2026 adaptive
oppositional AOGWO (5.07) and standard GWO (6.10). Against standard GWO the
improvement is decisive: 28 wins in 29 functions, a median error ratio of
0.525, and 24 significant wins with no significant loss under Holm
correction. Against HAGWO, PSO, CLPSO and AOGWO the margins are likewise
significant (ratios 0.806, 0.652, 0.668 and 0.586; Holm $+19/-3$, $+19/-2$,
$+20/-5$ and $+21/-0$, respectively). Against I-GWO---the strongest classical
improvement---the comparison is a statistical tie on pooled error (ratio
0.938, 17--12, pooled $p=0.55$), with a median paired gain of 0.023 decades
(95\% CI $[0.011,0.032]$) and large function-level swings in both directions.
The claim this table supports is therefore precise: \method{} is the
best-ranked method in the set and is significantly better than five of six
baselines, including both recent GWO variants, while remaining statistically
indistinguishable from the strongest classical improvement.

\begin{table}[t]
\centering
\small
\caption{Final seven-method comparison (CEC2017, $D=50$, 100{,}000 true
evaluations, 29 functions, 30 runs on identical seeds). ``Median ratio'' is
the median paired error ratio of \method{} over the baseline (below one
favours \method); W--L counts functions whose mean error is lower/higher; Holm
counts per-function significant wins/losses after Holm correction; time is the
mean wall-clock time per run.}
\label{tab:main}
\input{tables/table_main7.tex}
\end{table}

\begin{figure}[t]
\centering
\includegraphics[width=0.78\linewidth]{figures/ranks7.png}
\caption{Mean ranks over the 29 CEC2017 functions for the final seven-method
comparison ($D=50$, 100{,}000 true evaluations, 30 runs each).}
\label{fig:ranks}
\end{figure}

Function-level inspection shows where the rank advantage comes from.
\method{} has the lowest median error of the seven methods on 16 of the 29
functions (2 of 2 unimodal, 4 of 7 simple multimodal, 3 of 10 hybrid and 7 of
10 composition functions). The largest single-function margins are on F9,
where its median error is 2.43 against 581.2 for the second-best method (a
factor of 238), and on F1, where its median error is $1.24\times10^{6}$
against $7.47\times10^{6}$ for the best comparator---a factor of six on a
function where standard GWO ends five thousand times higher. Large but
narrower margins occur on F8, F20 and F21 (factors 1.46, 1.39 and 1.16), all
of which are functions on which \method{} is ranked first.

\subsection{Function-family analysis}
Table~\ref{tab:family} and Fig.~\ref{fig:heatmap} break the comparison down by
benchmark family. Two patterns are informative. First, against the four
weaker baselines (HAGWO, PSO, CLPSO and AOGWO) and standard GWO the advantage
holds in every family, with ratios between 0.141 and 0.882; the widest margins
are on unimodal and simple-multimodal functions and the narrowest on
composition functions, which is the expected behaviour of a method that
maintains several search regions rather than converging to a single basin.
Second, the comparison with I-GWO is family-dependent: \method{} is better on
unimodal (0.432), simple-multimodal (0.796) and composition functions (0.932),
while I-GWO retains an advantage on hybrid functions (1.184). This is exactly
the pattern that produces the pooled parity with I-GWO reported above, and it
identifies the hybrid family as the natural target for further work. The heat
map in Fig.~\ref{fig:heatmap} shows the same structure at function
resolution: the blue cells (VAST-GWO better) dominate, with the red cells
concentrated on F6, F19 and F30 against the two strongest comparators.

\begin{table}[t]
\centering
\small
\caption{Function-family median paired error ratios of \method{} over each
baseline (below one favours \method), with the number of functions whose mean
error is lower/higher in parentheses. Families follow the CEC2017
classification: 2 unimodal, 7 simple multimodal, 10 hybrid, 10 composition
functions.}
\label{tab:family}
\input{tables/table_family.tex}
\end{table}

\begin{figure}[t]
\centering
\includegraphics[width=0.62\linewidth]{figures/fig_heatmap.png}
\caption{Function-level median error ratios, $\log_{10}(\text{VAST-GWO} /
\text{baseline})$, for the six baselines. Blue indicates that \method{} has
the lower median error; values are clipped at $\pm 2$ decades. Horizontal
lines separate the unimodal, simple-multimodal, hybrid and composition
families.}
\label{fig:heatmap}
\end{figure}

\subsection{Convergence and exploration behaviour}
The advantage appears early and grows with the budget. At 10\%, 20\% and 50\%
of the evaluation budget the median error ratios against standard GWO are
0.802, 0.777 and 0.726, with 25, 26 and 27 of 29 functions respectively
better. Against the frozen ANGWO reference the ratios are 0.732 and 0.768 at
10\% and 20\% of the budget, and on the simple-multimodal subset (F4--F10) the
ratio is 0.714. Figure~\ref{fig:conv} shows the median best-so-far curves on
the five functions with the largest final margin; the separation is visible
from the middle of the budget onwards on F1 and F8, and from the first
thousand evaluations on F9, where the pack converges an order of magnitude
faster than every comparator.

The trace-instrumented behaviour metrics in Table~\ref{tab:behaviour} explain
the shape of the curves. \method{} recovers from stagnation windows more often
than standard GWO (0.823 vs.\ 0.757), spends less of the budget inside long
stagnation episodes (0.813 vs.\ 0.844), and keeps proposing novel positions
late in the budget (novelty rate 0.712 vs.\ 0.588 in the final quarter).
Its useful-novelty rate is 0.00640 against 0.00347 for GWO: novel positions
are followed by an actual improvement far more often. Its improving-evaluation
rate is lower (0.00308 vs.\ 0.00481), which is the expected signature of
allocating five times fewer evaluations per generation---progress per
evaluation and progress per budget are different quantities, and the
comparisons in Table~\ref{tab:main} and Fig.~\ref{fig:conv} measure the
latter.

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{figures/fig_convergence.png}
\caption{Median best-so-far error over 30 runs for the seven compared methods
on the five CEC2017 functions where \method{} has the largest final margin
(F1 and F8: unimodal and simple multimodal; F9: simple multimodal; F20:
hybrid; F21: composition). All curves are computed from the frozen traces of
the formal batch on identical seeds.}
\label{fig:conv}
\end{figure}

\begin{table}[t]
\centering
\small
\caption{Behaviour metrics on the formal tier, computed from the stored
best-so-far traces with the pre-registered definitions and $W=1000$
evaluations. S1 is the $K=50$ sparse variant, S3 a fixed quota policy and S5 a
Q-learning policy (Section~\ref{sec:ablation}).}
\label{tab:behaviour}
\input{tables/table_behaviour.tex}
\end{table}

\subsection{Operating points: higher dimension and smaller budget}
Table~\ref{tab:tiers} reports the two additional tiers. At $D=100$ \method{}
again ranks first (1.72, ahead of 2.00, 2.33, 3.52 and 3.67 for the compared
variants), with a 0.703 median ratio and 10 wins against 2 losses (Holm
$+5/-1$) against I-GWO on the 12-function subset they share, and a 0.549 ratio
against a dense synchronous variant that evaluates every individual. Under a
budget five times smaller, \method{} also ranks first (1.97), winning 24 of 29
functions against standard GWO (ratio 0.721), 24 of 29 against the frozen
ANGWO reference (0.807) and 24 of 29 against its dense variant (0.678). The
sparse candidate-pool framework therefore scales upward in dimension and
downward in budget, which is the profile needed for engineering problems in
which large budgets are unavailable.

\begin{table}[t]
\centering
\small
\caption{Additional operating points. Panel (a): $D=100$, 100{,}000
evaluations, 29 functions, ten seeds; the ratio for I-GWO is computed on the
12-function subset. Panel (b): 20{,}000 evaluations, $D=50$, 29 functions, ten
seeds. Ratios are relative to \method{} (below one favours \method).}
\label{tab:tiers}
\input{tables/table_tiers.tex}
\end{table}

\subsection{Computational cost}
At equal budgets \method{} is the most expensive method in wall-clock terms:
5.93\,s per run at $D=50$ with 100{,}000 evaluations, against 3.63\,s for GWO,
3.41\,s for HAGWO, 2.59\,s for PSO, 2.41\,s for CLPSO, 2.32\,s for I-GWO and
4.54\,s for AOGWO. The overhead is 1.6$\times$ GWO and comes from building and
maintaining the 100-candidate pool and the verified archive; at $D=100$ the
same budget costs 11.97\,s. This is the transparent price of the mechanism: in
the regime the method targets---expensive black-box evaluations---the
arithmetic overhead is negligible relative to the objective, and the extra
time buys the best rank position and the largest error reductions in
Table~\ref{tab:main}. In the regime where evaluations are nearly free, the
comparison should be made on time as well as quality, and the measurements
above allow that.
"""
with open(os.path.join(OUT,"main.tex"),"a",encoding="utf-8") as f:
    f.write(tex.rstrip()+"\n")
print("chunk 3 appended, chars:", len(tex))
