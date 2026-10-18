# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
tex = r"""
\section{Discussion}
\label{sec:discussion}
\subsection{Candidate-source structure is a first-class design variable}
The experiments support a compact statement about optimizer design under
scarce real evaluations: \emph{the composition of the candidate pool is a
first-class design variable, and engineering it can outweigh engineering the
evaluation scheduler}. In \method{} that composition is a verified archive
spanning several regions of the search space. Because every archived centre is
backed by a billed evaluation, the archive can safely generate candidates far
from the current leaders without introducing unverified optimism; because it
spans multiple regions, it counteracts the leader-driven contraction that makes
GWO stagnate on multimodal landscapes; and because the allocation remains a
simple uniform draw, none of the gain depends on a fragile controller. The
boundary experiments make the contrast explicit: of the scheduling
mechanisms tested---directed screening, informed stratification, fixed quotas,
random quotas and three Q-learning policies---none improved on the uniform
draw, and the learned policies were never better than the best fixed policy.
This is a negative result that strengthens the paper's claim rather than
weakening it: it shows that the gain comes from the information the pool
contains, not from a particular way of spending the budget.

The behaviour metrics describe how the mechanism produces its effect.
\method{} recovers from stagnation windows more frequently than standard GWO
(0.823 against 0.757) and spends less of the budget inside long stagnation
(0.813 against 0.844). At the same time, its evaluations are individually more
valuable: the useful-novelty rate is almost twice that of standard GWO, and
the novelty rate in the final quarter remains high, which indicates that the
method continues to open new ground late in the run instead of refining a
single basin. These two observations correspond exactly to the dual objective
of the study---stagnation recovery and exploration efficiency under a fixed
true-evaluation budget---and both are measured from the same audit trail as
the final errors.

\subsection{Why the verified-state discipline matters}
Three of this paper's claims depend on the counting discipline rather than on
the algorithm alone. The comparison with strong baselines is meaningful only
if every method consumes exactly the same number of real evaluations, which is
why an independent probe audits every call. The ablation is meaningful only if
the evaluation budget, the pool size and the accepted-subset size are held
constant, which is why the disabled routes in the ablation are replaced by
standard candidates rather than removed. And the mechanism claim is meaningful
only if the archive contains measured information, which is why no unevaluated
candidate is allowed to influence leaders, archive or rankings. The same
discipline makes the method reproducible: the frozen configuration is
hash-identified, every configuration tested during development is retained
(including the ones that failed), and the formal batches are executed once
after freezing.

\subsection{Relation to the strong improved GWO}
The comparison with I-GWO deserves a precise reading. On the pooled statistic
the two methods are a tie, and the mean-rank advantage of \method{} is small
(2.24 against 2.28). The family decomposition shows why: \method{} leads on
unimodal, simple-multimodal and composition functions, while I-GWO retains an
advantage on hybrid functions. A defensible summary is therefore that the
method advances the state of the art in this comparison set---it is ranked
first among seven methods and is significantly better than five of
six---rather than that it dominates every competitor on every function. The
complementary structure also suggests a concrete direction for future work:
the hybrid functions, which combine subcomponents with different landscapes,
are exactly the case in which archive candidates could be complemented by a
stronger local search inside each subcomponent.

\subsection{Limitations and scope}
Four limitations bound the conclusions. First, the benchmark evidence covers
the CEC2017 suite at $D=50$ and $D=100$; whether the mechanism transfers to
thousands of dimensions or to constrained CEC suites remains open. Second, the
application evidence covers one family of terrain-constrained delivery
problems with hard time windows, simulated on five real terrain tiles; it is an
engineering-grade testbed, not a flight test. Third, the archive parameters
(capacity 24, separation threshold 2\% of the diagonal) were fixed from the
development phase and were not re-tuned per problem class; they behaved well
across the two dimensions and two budget levels tested here, but a broader
sensitivity study would be needed before deploying the method on problems with
very different geometry. Fourth, \method{} is the slowest method in wall-clock
time at equal budget ($1.6\times$ standard GWO), which is irrelevant when the
objective is expensive but should be weighed when it is not. None of these
limitations affects the paper's central claim, which concerns the composition
of the candidate pool rather than a claim of universal superiority.

\subsection{Future work}
Three directions follow directly from the results. First, the ablation
identifies a simpler configuration: because A2 is statistically
indistinguishable from the full method, a two-route variant that keeps only the
leader moves and the archive deserves a dedicated study, both for simplicity
and to test whether the archive alone can carry even more of the budget.
Second, the verified archive is a natural training set for a lightweight
surrogate, because every entry is a real measurement; coupling the two would
extend the method to objectives whose evaluations are expensive by orders of
magnitude. Third, the application evidence motivates delivery problems with
moving obstacles, stochastic time windows and multi-UAV fleets, where the
candidate pool would have to cover several vehicles simultaneously---a setting
in which the multi-region property of the archive should be even more valuable.

\section{Conclusion}
\label{sec:conclusion}
This paper introduced \method{}, a verified archive-guided sparse-evaluation
grey wolf optimizer for optimization under limited real-evaluation budgets.
The method separates cheap candidate generation---100 candidates from leader
moves, success-scale alpha shells and a verified multi-region elite
archive---from real evaluation, of which exactly ten uniformly drawn
candidates are paid for per generation, and admits only verified information
into the leaders, the archive and the rankings. On CEC2017 at $D=50$ with
100{,}000 probe-audited evaluations and 30 independent runs, \method{} attains
the best mean rank among seven methods, significantly outperforms five of the
six baselines---including a 2026 hierarchical GWO and a 2026 oppositional
GWO---and reaches statistical parity with the strongest classical improvement
while leading it on the rank summary. Controlled equal-slot ablations show
that the verified multi-region archive is the performance engine: removing it
produces 27 losses in 29 functions, and replacing it with a single-centre
sampler with identical slots, scale and acceptance rule collapses the method
to 2 wins, whereas the alpha-shell route becomes optional once the archive is
present. The method holds its rank both at $D=100$ and with a budget five
times smaller, and every tested alternative scheduler---including three
Q-learning policies---failed to improve on the uniform draw. In a
209-dimensional DEM-based 3D UAV delivery application with hard time windows,
\method{} is the only method feasible in all 150 runs and achieves both the
best censored time to feasibility and the best paired final route quality
against every baseline.

The broader lesson is that when real evaluations are the scarce resource, the
structure of the candidate pool is a first-class design variable. Verifying
everything that enters memory, and generating candidates from several verified
regions, proved to be a more effective use of a fixed evaluation budget than
adding scheduling complexity. We hope this encourages future work to treat the
candidate pool, and the accounting of what enters the search state, as a
primary object of study in population-based optimization under expensive
evaluations.

\section*{Data and code availability}
All optimization and application experiments, including raw per-run records,
the experiment registry (every configuration and negative result), the
ablation implementation, the five UAV scenarios and the analysis scripts, are
available in the accompanying repository. The evaluation counts of all runs
are asserted by an independent probe, and the frozen method configuration is
bitwise audited against its archived implementation.

\bibliographystyle{unsrtnat}
\bibliography{references}

\end{document}
"""
open(OUT,"a",encoding="utf-8").write(tex.strip()+"\n")
print("written part 5:", len(tex))
