# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
tex = r"""
\section{Experimental protocol}
\label{sec:protocol}
\subsection{Benchmarks and budgets}
All optimization experiments use the CEC2017 real-parameter suite in its
official 29-function form (F1 and F3--F30; F2 is omitted as in the official
definition) at dimension $D=50$, with a search domain of $[-100,100]^D$ and a
budget of 100{,}000 true objective evaluations per run, initialization
included \citep{awad2016problem}. Every algorithm is run 30 times per function
on seeds 3001--3030. For a given (function, seed) pair all algorithms start
from the same initial population, and the initialization and search random
streams are kept separate so that sharing the initial population does not
couple the trajectories. Two additional operating points are used to test
whether the conclusions are tied to one configuration: $D=100$ with
100{,}000 evaluations and ten seeds, and a five-times smaller budget of
20{,}000 evaluations at $D=50$ with ten seeds.

The mechanism study in Section~\ref{sec:ablation} uses a disjoint,
out-of-sample seed block (3071--3100). All five ablation arms are executed in
the same batch with identical pools, identical evaluated subset sizes and
identical budgets, so that only the composition of the candidate pool differs.

\subsection{Evaluation auditing and parallel execution}
Every objective call passes through an independent probe that counts true
evaluations, maintains a bounded reservoir of evaluated positions for unbiased
novelty estimation, and never perturbs the algorithm's random streams. Each
run asserts that the probe count equals the budget exactly, so no method can
gain from uncounted evaluations, restarts or cached duplicates. Runs are
executed on MATLAB R2025b with exactly four parallel workers (local
\texttt{parpool}, no serial fallback); each run writes its result atomically
and batches are resumable, so an interrupted batch resumes at the run level
without changing the experimental unit. All timings reported below are in-run
wall-clock times of the search phase, measured identically for every method on
the same machine (8-core AMD Ryzen 7 8745H, 16 threads, 15.3\,GB RAM).

\subsection{Baselines}
Six baselines are compared. Four are established methods: standard GWO
\citep{mirjalili2014gwo}, the strong improved GWO (I-GWO) with
dimension-wise opposition-based initialization, nonlinear control parameter
and dynamic position update \citep{nadimi2021igwo}, classic inertia-weight PSO
\citep{kennedy1995pso,shi1998modified} and CLPSO \citep{liang2006clpso}. Two
are recent 2026 variants whose authors provide open code: HAGWO, a hierarchical
adversarial GWO used here in its author implementation \citep{su2026hagwo}, and
AOGWO, an adaptive oppositional GWO, also in its author implementation
\citep{khalid2026aogwo}. Table~\ref{tab:setup} lists the source of each
implementation and the configuration used under the common protocol. Each
port to the common framework was restricted to interface and accounting
levels---initial population supplied by the framework, scheduling variable
expressed as a fraction of true evaluations, and one billed evaluation per
distinct position---so the search behaviour of every baseline is that of its
published or author-released form.

\begin{table}[t]
\centering
\small
\caption{Baselines, sources and configuration under the common protocol
($N=50$, identical initial populations, 100{,}000 true evaluations).}
\label{tab:setup}
\input{tables/table_setup.tex}
\end{table}

\subsection{Statistics}
For each baseline we report the mean rank over the 29 functions, the
function-level win--loss record, the median paired error ratio of \method{}
over the baseline, the pooled $p$ value of the paired Wilcoxon signed-rank test
on $\log_{10}$ errors over identical seeds, and the Holm-corrected per-function
significant wins and losses. The primary evidence is the per-function paired
comparison: for each function the 30 paired runs are tested with a two-sided
Wilcoxon signed-rank test on $\log_{10}$ errors, and the resulting $p$ values
are corrected across the 29 functions with the Holm procedure; the sign of the
median paired difference determines whether a significant result counts as a
win or a loss. Median paired error ratios below one favour \method.
Bootstrap 95\% confidence intervals for median $\log_{10}$ gains are obtained
by resampling the paired differences. Pooled tests over all function--seed
pairs are reported for completeness but are not used as primary evidence,
because those pairs are not independent. Effect sizes in the application study
are reported as rank-biserial correlations.

Development and formal evaluation were separated. Hyperparameters, slot
allocations and the evaluated subset size were selected during a
pre-registered development phase on development functions and seeds; the
configuration was then frozen, and the formal batches reported here were
executed once. All configurations---including those that failed---are retained
in the experiment registry. The method's frozen implementation is
hash-identified, and a sampling audit confirms bitwise agreement between the
frozen configuration and the implementation used in the ablation batches.

\section{Results}
\label{sec:results}
\subsection{Comparison with strong baselines}
Table~\ref{tab:main} reports the final seven-method comparison and
Fig.~\ref{fig:ranks} the corresponding mean ranks. \method{} attains the best
mean rank, 2.24, ahead of the strong improved GWO (2.28), the 2026 hierarchical
HAGWO (3.41), PSO (4.41), CLPSO (4.48), the 2026 adaptive oppositional AOGWO
(5.07) and standard GWO (6.10). Against standard GWO the result is decisive:
28 wins in 29 functions, a median error ratio of 0.525, and 24 significant
wins with no significant loss after Holm correction. Against HAGWO, PSO, CLPSO
and AOGWO the margins are also significant (median ratios 0.806, 0.652, 0.668
and 0.586; Holm $+19/-3$, $+19/-2$, $+20/-5$, $+21/-0$). Against I-GWO---the
strongest classical improvement---the comparison is a statistical tie on
pooled error (ratio 0.938, 17 wins to 12 losses, pooled $p=0.55$), with a
median paired gain of $+0.023$ decades (95\% CI $[0.011,0.032]$) and large
function-level swings in both directions. The precise claim that this table
supports is therefore: \method{} is the best-ranked method of the seven and is
significantly better than five of six baselines, including both recent GWO
variants, while reaching parity with the strongest classical improvement.

\begin{table}[t]
\centering
\small
\caption{Final seven-method comparison (CEC2017, $D=50$, 100{,}000 true
evaluations, 29 functions, 30 runs on identical seeds). ``Median ratio'' is
the median paired error ratio of \method{} over the baseline (below one favours
\method); W--L counts functions whose mean error is lower/higher; Holm counts
per-function significant wins/losses after Holm correction; time is the mean
wall-clock time per run.}
\label{tab:main}
\input{tables/table_main7.tex}
\end{table}

\begin{figure}[t]
\centering
\includegraphics[width=0.75\linewidth]{figures/ranks7.png}
\caption{Mean rank over the 29 CEC2017 functions for the seven compared
methods ($D=50$, 100{,}000 true evaluations, 30 runs each).}
\label{fig:ranks}
\end{figure}

\subsection{Where the advantage lies: function families and per-function
structure}
The aggregate ranking hides a structured picture. \method{} holds the lowest
median error of the seven methods on 16 of the 29 functions: both unimodal
functions, four of the seven simple-multimodal functions, three of the ten
hybrid functions and seven of the ten composition functions. The largest
single-function margins are on F9, where the median error is 2.43 against
581.2 for the best competitor (a factor of 238), and on F1, where it is
$1.24\times10^{6}$ against $7.47\times10^{6}$ for the best competitor (a
factor of six) and roughly $5\times10^{3}$ better than standard GWO. Large but
narrower margins occur on F8, F20 and F21 (factors 1.46, 1.39 and 1.16).

Table~\ref{tab:family} and Fig.~\ref{fig:heatmap} break the comparison down by
benchmark family. Against the four weaker baselines and standard GWO the
advantage holds in every family, with ratios between 0.141 and 0.882; the
widest margins are on unimodal and simple-multimodal functions and the
narrowest on composition functions. Against I-GWO the picture is
function-dependent: \method{} leads on the unimodal, simple-multimodal and
composition families (median ratios 0.432, 0.796 and 0.932) while I-GWO
retains an advantage on hybrid functions (1.184). This is the honest
resolution of the parity reported above---the two strongest methods have
complementary family strengths---and it identifies hybrid functions as the
natural target for future mechanism work rather than as a deficit of the
comparison.

\begin{table}[t]
\centering
\small
\caption{Function-family median paired error ratios of \method{} over each
baseline (below one favours \method), with function-level win--loss counts in
parentheses. Families follow the CEC2017 classification: 2 unimodal, 7 simple
multimodal, 10 hybrid and 10 composition functions.}
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

\subsection{Convergence and exploration efficiency}
The advantage appears early and grows with the budget. At 10\%, 20\% and 50\%
of the evaluation budget the median error ratios against standard GWO are
0.802, 0.777 and 0.726, with 25, 26 and 27 of 29 functions respectively
better. Against the frozen reference GWO of the development phase the ratios
are 0.732 and 0.768 at 10\% and 20\% of the budget, and on the
simple-multimodal subset (F4--F10) the ratio is 0.714. The same trajectories
explain how the budget is used: \method{} recovers from stagnation windows
more often than standard GWO (recovery probability 0.823 against 0.757) and
spends less of the budget inside long stagnation (long-stagnation share 0.813
against 0.844). On the exploration side, the useful-novelty rate---the share
of novel evaluations that are followed by a real improvement within a window
of $W=\max(50,1\%\,\mathrm{FE}_{\max})$ evaluations---is 0.00640 against
0.00347 for GWO and 0.00578 for the frozen reference, and the novelty rate in
the final quarter of the budget is 0.712 against 0.588 for GWO. The
improving-evaluation rate in the final quarter is lower (0.00308 against
0.00481), which is consistent with a search that has already located its
productive regions and spends the remaining budget on novel exploration rather
than on incremental refinement. Table~\ref{tab:behaviour} reports all
behaviour metrics, and Fig.~\ref{fig:conv} shows representative convergence
curves.

\begin{table}[t]
\centering
\small
\caption{Behaviour metrics on the formal tier, computed from the stored
best-so-far traces with the definitions given in the text. S1 is the $K=50$
sparse variant, S3 a fixed quota policy and S5 a Q-learning policy
(Section~\ref{sec:ablation}); ANGWO is the frozen development-phase
reference.}
\label{tab:behaviour}
\input{tables/table_behaviour.tex}
\end{table}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{figures/fig_convergence.png}
\caption{Median best-so-far error of the seven compared methods over 30 runs on
five CEC2017 functions. The panels show the five functions on which
\method{} attains the largest final margin, one from each benchmark family plus
a second simple-multimodal function, so they illustrate the mechanism rather
than the average; the complete per-function picture is given by
Fig.~\ref{fig:heatmap} and Table~\ref{tab:main}.}
\label{fig:conv}
\end{figure}

\subsection{Additional operating points}
Table~\ref{tab:tiers} reports two further configurations. At $D=100$,
\method{} again ranks first (1.72 against 2.00, 2.33, 3.52 and 3.67 for the
compared variants), with a median ratio of 0.703 and 10 wins against 2 losses
(Holm $+5/-1$) against I-GWO on the twelve functions that both methods share,
and a ratio of 0.549 against a dense synchronous variant that evaluates every
individual. Under a budget five times smaller, \method{} also ranks first
(1.97), winning 24 of 29 functions against standard GWO (ratio 0.721), 24 of
29 against the frozen reference (0.807) and 24 of 29 against its dense variant
(0.678). The sparse-evaluation candidate pool therefore scales upward in
dimension and downward in budget, which is the regime relevant to engineering
problems where large budgets are unavailable.

\begin{table}[t]
\centering
\small
\caption{Additional operating points. Panel (a): $D=100$, 100{,}000
evaluations, 29 functions, ten seeds; the I-GWO ratio is computed on the twelve
functions shared with that implementation. Panel (b): 20{,}000 evaluations,
$D=50$, 29 functions, ten seeds. Ratios are relative to \method{} (below one
favours \method) with win--loss counts in parentheses.}
\label{tab:tiers}
\input{tables/table_tiers.tex}
\end{table}

\subsection{Computational cost}
At equal budgets \method{} is the most expensive method in wall-clock terms:
5.93\,s per run at $D=50$ with 100{,}000 evaluations, against 3.63\,s for GWO,
3.41\,s for HAGWO, 2.59\,s for PSO, 2.41\,s for CLPSO, 2.32\,s for I-GWO and
4.54\,s for AOGWO; at $D=100$ the same budget costs 11.97\,s against 8.32\,s
and 7.83\,s for the compared dense and sparse variants. The overhead relative
to GWO is $1.6\times$ and originates in pool construction and archive
maintenance, both of which are arithmetic. In the regime \method{} targets---a
scarce number of expensive evaluations---this cost is negligible compared with
the objective, and it buys both the leading rank and the stagnation recovery
reported above. In the opposite regime, where evaluations are nearly free, the
runtime figures above allow the trade-off to be evaluated directly rather than
assumed.
"""
open(OUT,"a",encoding="utf-8").write(tex.strip()+"\n")
print("written part 3:", len(tex))
