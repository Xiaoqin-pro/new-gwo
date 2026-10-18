# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2"
tex = r"""
\section{Ablation and mechanism analysis}
\label{sec:ablation}
\subsection{Design of the source ablation}
The ablation varies one thing: which routes populate the candidate pool. Every
arm keeps the pool size $M=100$, the number of evaluated candidates $K=10$, the
budget and the acceptance rules fixed; disabled routes are replaced by
additional standard GWO moves, so that an arm never loses slots or
evaluations. Table~\ref{tab:abldesign} lists the five arms. The ablation batch
uses the independent, out-of-sample seed block 3071--3100, so no run that was
used to freeze the method enters the mechanism claims.

\begin{table}[t]
\centering
\small
\caption{Equal-slot source ablation. All arms keep $M=100$, $K=10$ and the
100{,}000-evaluation budget; only the composition of the pool differs.}
\label{tab:abldesign}
\input{tables/table_ablation_design.tex}
\end{table}

\subsection{Results}
Table~\ref{tab:abl} reports the outcome. Removing both auxiliary routes (A0:
GWO moves only) degrades the method to 27 losses in 29 functions
(ratio 0.538, Holm $+23/-0$): sparse evaluation by itself is \emph{not} the
source of the advantage. Removing the archive while keeping the
$\alpha$-shells (A1) still leaves the method 25 functions behind the full
version (0.812, Holm $+21/-1$). Keeping the archive but removing the
$\alpha$-shells (A2) leaves performance statistically unchanged
(0.994, 14--15, pooled $p=0.326$), so the $\alpha$-shell route is optional
once the archive is present. Replacing the archive by a single-centre
$\alpha$-sampler with identical slots, scale and acceptance rule (A5)
collapses the method to 2 wins in 29 functions (1.407, Holm $+2/-23$).

Two conclusions follow with unusual clarity for a metaheuristic ablation.
First, the verified multi-region archive is the performance engine: A2, which
contains only GWO moves and archive candidates, is statistically
indistinguishable from the full method and beats the GWO-only pool 29--0
(ratio 0.510). Second, what matters is the \emph{multi-region} character of
the memory rather than the mere presence of extra perturbation: A5 applies the
same number of extra candidates, the same shell scale and the same acceptance
rule as the full method, but draws them from one centre, and its performance
falls by a factor of 1.41 relative to the full configuration. Mean ranks
across the five arms are also ordered accordingly: A3 1.72, A2 1.79, A5 3.34,
A1 3.52, A0 4.62.

\begin{table}[t]
\centering
\small
\caption{Equal-slot candidate-source ablation (29 functions, 30 seeds
3071--3100, 100{,}000 true evaluations). Ratios are relative to the full
configuration; Holm counts the significant wins/losses of the listed
comparison.}
\label{tab:abl}
\input{tables/table_ablation.tex}
\end{table}

\subsection{Source-level attribution}
Instrumenting every accepted move with its route explains the ablation at the
level of search events. In a full run the archive route produces on average
24{,}068 accepted improvements per run, against 11{,}325 for the GWO-move
route and 4{,}742 for the $\alpha$-shell route (Fig.~\ref{fig:sources}).
Counting events of this kind over 99{,}950 evaluated candidates, the archive
route is not merely present in the winning configuration---it is the route
that converts the largest share of evaluations into progress, which is what
the equal-slot design predicts if multi-region verified memory is the active
ingredient.

\begin{figure}[t]
\centering
\includegraphics[width=0.72\linewidth]{figures/fig4_sources.png}
\caption{Accepted real improvements per run by candidate route, averaged over
the ablation batch. The verified archive route dominates; the $\alpha$-shell
route is the smallest contributor, consistent with its optional role once the
archive is present.}
\label{fig:sources}
\end{figure}

\subsection{Design-space boundaries}
The same controlled protocol was used to test the natural alternatives to
uniform random allocation and to two popular enhancement strategies
(Table~\ref{tab:bound}). Every one of them was rejected by its pre-registered
criterion. Directed screening by incumbent geometry and credit (S2) is worse
than uniform sampling (1.394, 4--4) because it starves the GWO route of
evaluations; informed stratified allocation (1.528), pool-ratio allocation
(1.255) and trend-guided quota allocation (1.348) are all worse than the
uniform draw; fixed exploration quotas above the pool share degrade
performance (up to 1.672); and three Q-learning quota schedulers never exceed
the best fixed policy (0.988, 1.024, 1.130) although they comfortably beat
random quota perturbation (0.870, 0.748). A stagnation-triggered radius boost
degrades final quality (1.204). Finally, steering moves along previously
successful directions improves the final error against the frozen
configuration (ratio 0.934; 22 wins in 29 functions against the frozen
method), but an equal-magnitude random-direction control reproduces the effect
(ratio 0.988 between the two steering variants, pooled $p=0.155$), and the
gain appears only in the last 20\% of the budget while runtime rises by
16.8--24.9\%. The mechanism was therefore rejected as an
information-driven contribution and is not part of \method.

The value of these boundary results is that they define the design space in
which the method \emph{does} work. The uniform random draw is not a
simplification adopted for convenience; it is the best of seven tested
allocation policies, including a learned one. The lesson is consistent with
the mechanism: once the candidate pool contains verified information from
several regions, the allocation rule has little left to add, whereas
sophisticated schedulers consume engineering effort and add failure modes
without measurable gain.

\begin{table}[t]
\centering
\small
\caption{Design-space boundary experiments, each with a matched control and a
pre-registered decision rule. Ratios below one favour the variant in the
middle column; ratios above one favour the reference configuration.}
\label{tab:bound}
\input{tables/table_boundaries.tex}
\end{table}

\section{Application: 3D UAV delivery path planning}
\label{sec:uav}
\subsection{Problem formulation}
The application is a three-dimensional UAV delivery problem with hard time
windows, built on real terrain data. Each instance contains $n=20$ delivery
stations, a depot, three cylindrical threat zones, and $K_c=3$ free control
points per flight leg. A candidate solution is a vector
$x\in[0,1]^{D}$ with
\begin{equation}
D=\underbrace{n}_{\text{visiting order}}+\underbrace{(n+1)K_c\cdot 3}_{\text{leg geometry}},
\qquad D=20+21\cdot3\cdot3=209 .
\end{equation}
The first $n$ coordinates define the visiting order by rank (the station with
the smallest value is served first). The remaining coordinates define, for
each of the $n+1$ legs, three intermediate control points: a position ratio
$\lambda\in[0.2,0.8]$ along the straight line to the next target, a lateral
offset in $[-4,4]$ and a height offset in $[0,4]$ above that line, with the
control points of each leg re-ordered by $\lambda$. The resulting polyline is
a flyable route depot $\to$ station $\to\cdots\to$ depot.

The objective to be minimised combines travel distance, waiting time and
smoothness,
\begin{equation}
J=\sum_{\text{legs}} d_\ell
\;+\;0.05\sum_{\text{legs}} w_\ell
\;+\;2\sum_{\text{legs}} s_\ell ,
\label{eq:uavcost}
\end{equation}
where $d_\ell$ is the three-dimensional leg length, $w_\ell$ is the waiting
time accumulated when the UAV arrives before a station's ready time, and
$s_\ell$ accumulates squared normalised turn angles and pitch changes along
the leg. Five sets of hard constraints are enforced: (i) terrain clearance of
at least 4\,m along every leg, evaluated with bilinear interpolation of a
51$\times$51 digital elevation model and exact cell-crossing analysis;
(ii) no intersection with any threat cylinder, expanded by a 2\,m safety
margin; (iii) a maximum altitude of 42\,m; (iv) climb and turn limits of
$35^\circ$ and $120^\circ$; and (v) hard time windows at every station
(service must start before the due time; waiting is allowed) together with a
depot return within the depot window. Violations are penalised by
$10^{5}+10^{3}\times(\text{late units})$ for time-window violations and
$10^{5}+10^{4}\times(\text{violation magnitude})$ for the geometric
constraints, so that every feasible solution strictly dominates every
infeasible one. Table~\ref{tab:uavmodel} lists the model parameters.

\begin{table}[t]
\centering
\small
\caption{Parameters of the 3D UAV delivery benchmark (benchmark-v1). Five
real Copernicus GLO-90 terrain tiles are used; the coordinates are expressed
in the normalized map units of the benchmark.}
\label{tab:uavmodel}
\input{tables/table_uav_model.tex}
\end{table}

\subsection{Scenarios and protocol}
The five scenarios use real Copernicus GLO-90 elevation tiles with distinct
morphology---ridge, peaks, mountain, hills and plateau---resampled onto a
$100\times100$ grid. Each scenario has 20 stations with individual hard time
windows, three threat zones, and the same depot. The scenarios and time
windows were frozen before the formal batch and were not adjusted afterwards.
This is a simulation derived from real terrain data, not a flight test.

All six comparison methods run with $N=50$, 30{,}000 true evaluations per run
(initialization included) and 30 repetitions per (map, method), giving
$6\times5\times30=900$ runs, all of which completed successfully. Within a
map, every method starts from the same initial population for a given
repetition, and the search random stream is offset identically. Each run
re-evaluates its returned solution with the full (non-accelerated) evaluator
outside the counted budget; the verification call is recorded separately and
never used for search. The accelerated evaluator used inside the search was
audited to be numerically equivalent to the reference evaluator before the
batch was released.

Four quantities are reported, because they answer different engineering
questions. \emph{Feasibility} is the fraction of runs that find at least one
feasible route within the budget. \emph{Time to first feasibility} is measured
with the restricted mean survival time (RMST) under a 30{,}000-evaluation
censoring horizon, which uses \emph{all} runs, successful or not; reporting
only the median of successful runs would favour methods that fail more often.
\emph{Cumulative feasibility} at 2{,}000, 5{,}000, 10{,}000, 20{,}000 and
30{,}000 evaluations describes how quickly a method becomes usable, and the
5{,}357-style early advantage of some methods is a real engineering asset. And
\emph{final route quality} is compared on paired runs in which both methods
were feasible, with Wilcoxon tests and rank-biserial effect sizes.

\subsection{Results}
Table~\ref{tab:uav} and Figs.~\ref{fig:uavfeas}--\ref{fig:uavcostbp} report
the outcome. \method{} is the only method that finds a feasible route in every
one of its 150 runs; the runner-up reliability is 97.3\% (I-GWO and HAGWO),
followed by PSO (95.3\%), GWO (94.0\%) and CLPSO (61.3\%). Under the censored
horizon \method{} also attains the smallest RMST, 7{,}062 evaluations (95\% CI
6{,}449--7{,}731), ahead of HAGWO (8{,}133), PSO (8{,}138), GWO (10{,}936),
I-GWO (12{,}270) and CLPSO (24{,}427). The censoring-aware ordered test
favours \method{} against GWO, I-GWO, HAGWO and CLPSO after Holm correction;
the exception is PSO ($p=0.598$), which finds feasible routes earlier in the
first few thousand evaluations (median 5{,}357 against 6{,}314 for
\method{} in successful runs) and then stalls: its final routes are markedly
worse (median cost 766.4 against 667.4) and it misses feasibility in seven
runs. Figure~\ref{fig:uavfeas} shows the cumulative feasibility curves: at
10{,}000 evaluations \method{} has reached 82.0\% feasibility against 76.0\%
for HAGWO and 74.0\% for PSO, and by 20{,}000 evaluations it has reached
100\% while every other method is still between 26.7\% and 97.3\%.

\begin{table}[t]
\centering
\small
\caption{Formal 3D UAV delivery comparison (150 runs per method: 5 maps
$\times$ 30 repetitions). Feasibility is the share of runs that find a
feasible route within 30{,}000 evaluations; RMST is the restricted mean time
to first feasibility with a 30{,}000-evaluation censoring horizon, so all runs
enter the statistic; the first-feasible median is conditional on successful
runs and is shown for reference; cost is the median final route cost over
feasible runs (lower is better).}
\label{tab:uav}
\input{tables/table_uav.tex}
\end{table}

\begin{figure}[t]
\centering
\includegraphics[width=0.86\linewidth]{figures/uav_feasibility_curve.png}
\caption{Cumulative feasibility versus real evaluations on the five
DEM-based delivery scenarios (150 runs per method). Checkpoints are early
observations within the single 30{,}000-evaluation protocol.}
\label{fig:uavfeas}
\end{figure}

Final route quality favours \method{} against every baseline: over the pairs
in which both methods were feasible, the median paired cost ratios are 0.939
against GWO, 0.898 against I-GWO, 0.967 against HAGWO, 0.843 against PSO and
0.631 against CLPSO, and all five remain significant after Holm correction
($p$ from $3.3\times10^{-16}$ to $0.0458$, rank-biserial 0.19--1.00). Two
comparisons deserve an explicit reading. First, PSO's early feasibility
advantage is genuine, and it is bought at the far end of the budget: its final
routes are on average 19\% longer or less smooth than those of \method, and
it fails in 7 of 150 runs. Second, HAGWO's conditional median cost (663.4) is
marginally below that of \method{} (667.4) when each method's own successful
runs are treated separately; that statistic conditions away HAGWO's four
infeasible runs, and on the 146 runs where both methods succeed \method{} is
significantly better (ratio 0.967, Holm $p=0.0458$). McNemar tests on final
feasibility are significant against GWO ($p=0.016$), PSO ($p=0.047$) and
CLPSO ($p<10^{-16}$) after Holm correction. Table~\ref{tab:uavmaps} reports
feasibility per map, where the pattern is uniform: 100\% for \method{} on all
five terrains, with the largest gaps on the mountain scenario, where GWO and
PSO reach 83.3\% and CLPSO 36.7\%.

\begin{table}[t]
\centering
\small
\caption{Feasibility (\%) per terrain scenario (30 runs per cell). The five
scenarios differ in morphology and time windows; no scenario was adjusted
after the protocol was frozen.}
\label{tab:uavmaps}
\input{tables/table_uav_maps.tex}
\end{table}

\begin{figure}[t]
\centering
\includegraphics[width=0.86\linewidth]{figures/uav_rmst_bar.png}
\caption{Restricted mean time to first feasible route with a
30{,}000-evaluation censoring horizon and bootstrap 95\% confidence intervals;
every run enters the statistic.}
\label{fig:uavrmst}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=0.86\linewidth]{figures/uav_final_cost_box.png}
\caption{Distribution of final route cost over feasible runs for each method
(5 maps $\times$ 30 repetitions). Lower is better; the frequency of
infeasible runs is reported in Table~\ref{tab:uav}.}
\label{fig:uavcostbp}
\end{figure}

\begin{figure*}[t]
\centering
\includegraphics[width=\textwidth]{figures/uav_routes_montage.png}
\caption{Best feasible delivery routes found by \method{} on the five
DEM-based scenarios (costs 481.7--600.7). Terrain colour encodes elevation;
red cylinders are threat zones with their safety margins; the blue polyline is
the route, dots are stations and the square is the depot.}
\label{fig:uavroutes}
\end{figure*}

\subsection{What the application shows}
The application adds a third kind of evidence to the benchmark results. On
CEC2017 the method is the best-ranked of seven and significantly better than
five of six baselines; here, in a 209-dimensional constrained problem with
real terrain and hard time windows, it is simultaneously the most reliable
method (100\% feasibility), the fastest to feasibility under a censoring-aware
metric, and the best in paired final route quality against every baseline.
Those three properties do not have to coexist---PSO demonstrates that early
feasibility can be traded against final quality, and CLPSO demonstrates that a
method can be reasonable on some maps and unusable on others---and the
combination is what makes the mechanism attractive for delivery planning,
where an unfeasible plan has no operational value regardless of how close it
came.
"""
with open(os.path.join(OUT,"main.tex"),"a",encoding="utf-8") as f:
    f.write(tex.rstrip()+"\n")
print("chunk 4 appended, chars:", len(tex))
