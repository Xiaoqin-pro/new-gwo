# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2"
tex = r"""
\section{Discussion}
\label{sec:discussion}
\subsection{Candidate-source structure versus scheduler complexity}
The results support a compact statement about optimizer design under scarce
real evaluations: \emph{the composition of the candidate pool is a first-class
design variable, and engineering it can outweigh engineering the scheduler}.
In \method{} that composition is a verified archive that spans several regions
of the search space. Because every archived centre is backed by a billed
evaluation, the archive can safely generate candidates far from the current
leaders without introducing unverified optimism; because it spans multiple
regions, it counteracts the leader-driven contraction that makes GWO stagnate
on multimodal landscapes; and because the allocation remains a simple uniform
draw, none of the gain depends on a fragile controller---as the boundary
experiments in Table~\ref{tab:bound} confirm. The ablation makes the same
point from the opposite direction: once the archive is present, the
$\alpha$-shell route is optional, and a single-centre substitute with
identical slots, scale and acceptance rule destroys performance. Multi-region
verified memory, not local refinement, is what the sparse budget needs.

The behaviour metrics close the argument at the level of search dynamics.
Compared with standard GWO, \method{} recovers from stagnation windows more
often (0.823 vs.\ 0.757), spends less of the budget inside long stagnation
episodes (0.813 vs.\ 0.844), and keeps producing novel, improvement-bearing
positions late in the budget. These are exactly the two capabilities the
design targets: escaping premature convergence, and making each budgeted
evaluation more likely to be informative.

\subsection{Ranking, significance and the comparison with I-GWO}
\method{} leads the mean rank (2.24 vs.\ 2.28) and is significantly better
than five of the six baselines, including both 2026 variants; against the
strongest classical improvement, I-GWO, the pooled comparison is a tie. Two
points keep this result honest and useful. First, the parity is a property of
the pooled error statistic, not of every function: \method{} is clearly better
on the unimodal, simple-multimodal and composition families and clearly worse
on hybrid functions (Table~\ref{tab:family}), which is why the pooled test
averages out to parity. Second, the mean rank is the appropriate summary when
each method has different failure modes: \method{} is first on 16 of 29
functions and never worse than fifth, whereas I-GWO's wins are concentrated in
one family. The comparison is therefore not saturated---there is a real
difference in \emph{where} the two methods are strong---and it identifies the
hybrid family as a concrete target for future work rather than a reason to
change the claim.

\subsection{Interpretation, cost and scope}
Two properties recommend \method{} for practice. Its behaviour is robust
across operating points: it ranks first both at $D=100$ and under a budget
five times smaller than the formal one, which matters because practitioners
rarely know the dimension or budget for which a method was tuned. And it
transfers to a demanding constrained application without re-tuning: on the
209-dimensional UAV delivery problem it is the only method feasible in every
run, has the best censored time-to-feasibility, and has the best paired final
route quality against all five baselines.

The cost is transparent. \method{} spends 1.6$\times$ the wall-clock time of
standard GWO at equal budget, because it builds a hundred candidates per
generation and maintains the archive. In the targeted regime---where a single
objective evaluation may take seconds to hours---this arithmetic overhead is
irrelevant next to the reduction in final error and the gain in reliability;
in the regime where evaluations are almost free, practitioners should compare
methods on time as well, and the measurements in Section~\ref{sec:results}
allow that comparison to be made directly.

The scope of the evidence is equally clear. The benchmark evidence covers the
CEC2017 family at $D=50$ and $D=100$ and two budget levels; the application
evidence covers one family of terrain-constrained delivery problems with hard
time windows on five real terrain tiles, modelled as a normalized simulation
rather than flight-tested. The archive parameters (capacity 24, separation
2\% of the space diagonal) and the slot counts were fixed before the formal
batch and were not re-tuned afterwards; the boundary experiments show that
adding scheduling complexity on top does not help, but they do not establish
that these particular constants are optimal for every problem class.
Finally, the ablation isolates source composition under equal pool size,
evaluated-subset size and budget; it deliberately does not claim that fewer or
more evaluated candidates per generation would behave the same way.

\subsection{Future directions}
Three directions follow directly from the present evidence. First, the
ablation identifies a simpler configuration: because A2 (leader moves plus
archive candidates, no $\alpha$-shells) is statistically indistinguishable
from the full method, a two-route variant that removes the shell route and
re-allocates its slots deserves a dedicated study of its own---both for
simplicity and to test whether the archive route alone can carry even more of
the budget. Second, the verified archive is an unusually clean training set
for a surrogate: every entry is a real measurement, so a lightweight model
could be coupled to the archive without violating the verified-state
discipline, which is a natural extension for objectives that are expensive by
orders of magnitude. Third, the application evidence suggests where the
mechanism should be tested next: delivery problems with moving obstacles or
stochastic windows, multi-UAV fleets where the candidate pool would have to
cover several vehicles simultaneously, and engineering suites beyond the
CEC2017 family in which the evaluation budget is imposed by hardware rather
than by the experimenter.

\section{Conclusion}
\label{sec:conclusion}
This paper introduced \method{}, a verified archive-guided sparse-evaluation
grey wolf optimizer for optimization under limited real-evaluation budgets.
The method separates cheap candidate generation---100 candidates from leader
moves, success-scale $\alpha$ shells and a verified multi-region elite
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
to 2 wins, whereas the $\alpha$-shell route becomes optional once the archive
is present. The method holds its rank both at $D=100$ and with a budget five
times smaller. In a 209-dimensional DEM-based 3D UAV delivery application with
hard time windows, \method{} is the only method feasible in all 150 runs and
achieves both the best censored time to feasibility and the best paired final
route quality against every baseline.

The broader lesson is that when real evaluations are the scarce resource, the
structure of the candidate pool is a first-class design variable. Verifying
everything that enters memory and generating candidates from several verified
regions proved to be a more effective use of a fixed evaluation budget than
adding scheduling complexity: of the eight alternative allocation policies
tested, including three learned ones, none improved on the simple uniform
draw. Engineering the sources of candidates---and being disciplined about what
enters the search state---is therefore a practical design principle, not only
for grey wolf optimization but for population-based search under expensive
evaluations in general.

\section*{Data and code availability}
All optimization and application experiments are archived in the accompanying
repository, including the raw per-run records, the experiment registry (every
configuration and negative result with its pre-registered hypothesis and
decision), the ablation implementations, the five UAV scenarios, the analysis
scripts and the figure-generation code. The evaluation counts of every run are
asserted by an independent probe, and the frozen method configuration is
hashed and audited against its archived implementation, so every number
reported here can be regenerated from the frozen batches.

\bibliographystyle{unsrtnat}
\bibliography{references}

\end{document}
"""
with open(os.path.join(OUT,"main.tex"),"a",encoding="utf-8") as f:
    f.write(tex.rstrip()+"\n")
print("chunk 5 appended, chars:", len(tex))
