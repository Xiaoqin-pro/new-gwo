# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
tex = r"""
\section{Ablation and mechanism analysis}
\label{sec:ablation}
\subsection{Equal-slot source ablation}
The ablation answers a single question by design: with the pool size, the
evaluated subset size, the budget and the acceptance rules held constant, which
compositions of the candidate pool produce the performance? Table~\ref{tab:abldesign}
lists the five arms. Arm A0 contains only standard GWO leader moves and
therefore measures what sparse evaluation alone achieves. A1 adds
leader-centred refinement, A2 adds the verified archive, A3 is the full method,
and A5 replaces the archive by a single alpha-centred sampler with identical
slot count, identical shell scale and identical acceptance rule, which isolates
the multi-region property of the archive from the mere presence of extra
perturbation.

\begin{table}[t]
\centering
\small
\caption{Equal-slot source ablation. All arms use $M=100$, $K=10$,
100{,}000 true evaluations and identical acceptance rules; only the
composition of the pool differs.}
\label{tab:abldesign}
\input{tables/table_ablation_design.tex}
\end{table}

Table~\ref{tab:abl} reports the outcome. Removing both auxiliary routes (A0)
degrades the method to 27 losses in 29 functions (median ratio 0.538, Holm
$+23/-0$): sparse evaluation by itself is not the source of the advantage.
Removing the archive while keeping the alpha shells (A1) still leaves the
method 25 functions behind the full version (0.812, Holm $+21/-1$). Keeping
the archive but removing the alpha shells (A2) leaves performance
statistically unchanged (0.994, 14--15, pooled $p=0.326$), so the alpha-shell
route is optional once the archive is present. Finally, replacing the archive
by a single-centre sampler with identical slots, scale and acceptance rule
(A5) collapses the method to 2 wins in 29 functions (1.407, Holm $+2/-23$).
The mean ranks over the five arms mirror the same ordering: A3 1.72, A2 1.79,
A5 3.34, A1 3.52, A0 4.62.

Two conclusions follow. First, the verified elite archive is the performance
engine of \method: A2, which contains only GWO moves and archive candidates,
is statistically indistinguishable from the full method while beating the
GWO-only pool 29--0. Second, it is the \emph{multi-region} character of the
archive that matters rather than the amount of additional perturbation: A5
uses the same number of extra candidates, the same shell scale and the same
acceptance rule, and differs from the full method only in drawing those
candidates from one centre instead of several, yet its performance falls by a
factor of 1.41. The source-level attribution in Fig.~\ref{fig:sources}
confirms the same picture at the level of accepted events: in a full run the
archive route produces on average 24{,}068 accepted improvements, against
11{,}325 for the GWO-move route and 4{,}742 for the alpha-shell route.

\begin{table}[t]
\centering
\small
\caption{Equal-slot candidate-source ablation (29 functions, 30 seeds
3071--3100, 100{,}000 true evaluations each). Ratios are relative to the full
configuration; Holm counts the significant wins/losses of the listed
comparison.}
\label{tab:abl}
\input{tables/table_ablation.tex}
\end{table}

\begin{figure}[t]
\centering
\includegraphics[width=0.70\linewidth]{figures/fig4_sources.png}
\caption{Accepted real improvements per run by candidate route, averaged over
the ablation batch. The verified archive route dominates; the alpha-shell
route is the smallest contributor, consistent with its optional role once the
archive is present.}
\label{fig:sources}
\end{figure}

\subsection{Design-space boundaries and rejected alternatives}
The same controlled protocol was used to test the natural alternatives to
uniform random allocation and to two popular enhancement strategies
(Table~\ref{tab:bound}). Every one of them was rejected by its pre-registered
criterion. Directed screening by proximity to the incumbent and by archive
credit is worse than uniform sampling (median ratio 1.394) because it starves
the GWO route of evaluations; informed stratified allocation (1.528),
pool-ratio allocation (1.255) and trend-informed allocation (1.348) are also
worse than the uniform draw; fixed exploration quotas of 0.25, 0.50 and 0.75
degrade performance (1.070, 1.064 and 1.672); and three Q-learning quota
schedulers---with zero, tuned and prior-initialised Q tables---never exceed the
best fixed policy (0.988, 1.024 and 1.130), although all of them beat random
quota perturbation (0.748--0.870). A stagnation-triggered radius boost
degrades final quality (1.204). Finally, steering moves along previously
successful directions improves the final error against the frozen
configuration (0.897, 21 wins in 29 functions), but an equal-magnitude
random-direction control reproduces the effect (0.988 between the two steering
variants, pooled $p=0.155$), and the gain appears only in the last 20\% of the
budget while wall-clock time rises by 17--25\%. The mechanism was therefore
rejected as an information-driven contribution and is not part of \method.

\begin{table}[t]
\centering
\small
\caption{Design-space boundary experiments. Each hypothesis was tested with a
matched control under the common protocol; ratios below one favour the control
variant and ratios above one favour the reference configuration.}
\label{tab:bound}
\input{tables/table_boundaries.tex}
\end{table}

\subsection{Interpretation of the mechanism evidence}
Three statements are supported by the ablation and boundary results, and one
is not. Supported: (i) sparse evaluation alone is not sufficient---the
GWO-only pool loses 27 of 29 functions to the full method; (ii) verified
multi-region memory is the dominant source of the improvement---removing the
archive costs 25 functions, replacing it with a single centre costs 27, and
the archive route accounts for the majority of accepted improvements; (iii)
the allocation rule does not need to be learned or tuned---uniform sampling
dominates or matches every alternative tested, including three Q-learning
schedulers with matched controls. Not supported: alpha-centred local
refinement is not necessary once the archive exists, since A2 and A3 are
statistically indistinguishable. The implication is a design rule rather than
a mechanism stack: make the candidate pool contain verified information from
several regions, and keep the evaluation rule simple.

\section{Application: 3D UAV delivery path planning}
\label{sec:uav}
\subsection{Problem formulation}
The application is a three-dimensional UAV delivery problem with hard time
windows, built on real terrain data. Each instance contains 20 delivery
stations with individual time windows, a depot, three cylindrical threat zones
and three intermediate control points per flight leg. A candidate solution is
a decision vector of dimension
\begin{equation}
D=20+\underbrace{21\times3\times3}_{\text{21 legs, 3 control points, 3 offsets}}
=209 .
\end{equation}
The first 20 coordinates define the visiting order through their rank; the
remaining 189 coordinates define, for each leg, three control points by a
position ratio along the straight line from the current point to the next
target, a lateral offset and a height offset. The decoded trajectory is a
sequence of legs from the depot through all stations and back to the depot.

The objective combines total flight distance, waiting time and path
smoothness,
\begin{equation}
\label{eq:uavobj}
J=\sum_{\ell} d_\ell+0.05\sum_{\ell} w_\ell+2\sum_{\ell} s_\ell ,
\end{equation}
where $d_\ell$ is the length of leg $\ell$, $w_\ell$ is the waiting time
accumulated before a station's ready time, and $s_\ell$ penalises turn and
pitch changes. Hard constraints are imposed on terrain clearance, threat-zone
avoidance, maximum altitude, climb and turn limits, the delivery time windows
and the return to the depot, with penalty terms that keep infeasible solutions
strictly behind feasible ones. Table~\ref{tab:uavmodel} lists the model
parameters; the five scenarios use real Copernicus GLO-90 terrain tiles with
distinct morphology (ridge, peaks, mountain, hills and plateau) and were frozen
before the formal runs.

\begin{table}[t]
\centering
\small
\caption{Parameters of the 3D UAV delivery benchmark (benchmark-v1). The
benchmark is a normalized simulation derived from real terrain data, not a
flight test.}
\label{tab:uavmodel}
\input{tables/table_uav_model.tex}
\end{table}

\subsection{Protocol and metrics}
All six methods run with $N=50$ and 30{,}000 true evaluations per run,
initialization included, on 30 repetitions for each of the five scenarios,
giving $6\times5\times30=900$ independent runs. Each method starts from the
same initial population for a given (map, repetition), the search random
stream is offset identically, and every run is verified after the search with
the full evaluator outside the billed budget. Four quantities are reported
because they answer different engineering questions: the final feasibility
rate; the time to the first feasible route, summarised by the restricted mean
survival time (RMST) under a 30{,}000-evaluation censoring horizon, in which
every run enters the statistic; the cumulative feasibility at 2k, 5k, 10k, 20k
and 30k evaluations; and the final route cost on paired runs in which both
methods were feasible. Final feasibility is compared with McNemar tests,
route cost with paired Wilcoxon tests and rank-biserial effect sizes, and time
to feasibility with a censoring-aware ordered test on the checkpoint at which
feasibility was first reached.

\subsection{Results}
\method{} is the only method that finds a feasible route in every one of its
150 runs; the runner-up reliability is 97.3\% (I-GWO and HAGWO), followed by
PSO (95.3\%), GWO (94.0\%) and CLPSO (61.3\%). It also attains the smallest
RMST, 7{,}062 evaluations (95\% CI 6{,}449--7{,}731), ahead of HAGWO (8{,}133),
PSO (8{,}138), GWO (10{,}936), I-GWO (12{,}270) and CLPSO (24{,}427). The
cumulative feasibility curves show where the advantage appears: at 10{,}000
evaluations \method{} has already reached 82.0\% feasibility, against 76.0\%
for HAGWO and 74.0\% for PSO, and at 20{,}000 evaluations it reaches 100\%
while every other method is still between 26.7\% and 97.3\%. Table~\ref{tab:uav}
summarises reliability and quality, Figs.~\ref{fig:uavfeas}--\ref{fig:uavroutes}
show the behaviour in detail, and Table~\ref{tab:uavmaps} reports the per-map
feasibility rates, where \method{} achieves 100\% on all five terrains.

Final route quality favours \method{} against every baseline. Over the pairs
in which both methods were feasible, the median paired cost ratios are 0.939
against GWO, 0.898 against I-GWO, 0.967 against HAGWO, 0.843 against PSO and
0.631 against CLPSO, and all five remain significant after Holm correction
($p$ from $3.3\times10^{-16}$ to $0.0458$, rank-biserial 0.19--1.00). The
censoring-aware ordered test is significant against GWO, I-GWO, HAGWO and
CLPSO; the exception is PSO ($p=0.598$), which finds feasible routes earlier
in the first few thousand evaluations (median 5{,}357 against 6{,}314 in
successful runs) and then stalls: its final routes are markedly worse (median
cost 766.4 against 667.4) and it misses feasibility in seven runs. HAGWO's
marginal median cost (663.4) is slightly below that of \method{} (667.4) when
each method's own successful runs are considered separately; on the 146 runs
where both methods succeed, \method{} is significantly better (ratio 0.967,
Holm $p=0.0458$). McNemar tests on final feasibility are significant against
GWO ($p=0.016$), PSO ($p=0.047$) and CLPSO ($p<10^{-16}$) after Holm
correction, while the reliability difference against I-GWO and HAGWO---both of
which fail four runs---is not significant on four discordant pairs.

\begin{table}[t]
\centering
\small
\caption{3D UAV delivery application (150 runs per method: five maps, 30
repetitions). Feasibility is the share of runs that found a feasible route
within 30{,}000 evaluations; RMST is the restricted mean time to first
feasibility under a 30{,}000-evaluation censoring horizon, so all runs enter
the statistic; the first-feasible median is conditional on successful runs and
is shown for reference; cost is the median final route cost over feasible runs
(lower is better).}
\label{tab:uav}
\input{tables/table_uav.tex}
\end{table}

\begin{table}[t]
\centering
\small
\caption{Per-map feasibility (\% of 30 runs) on the five terrain scenarios.}
\label{tab:uavmaps}
\input{tables/table_uav_maps.tex}
\end{table}

\begin{figure}[t]
\centering
\includegraphics[width=0.92\linewidth]{figures/uav_feasibility_curve.png}
\caption{Cumulative feasible runs versus real evaluations on the five
DEM-based delivery scenarios (150 runs per method). Checkpoints are early
observations within the single 30k protocol.}
\label{fig:uavfeas}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=0.92\linewidth]{figures/uav_rmst_bar.png}
\caption{Censored mean time to first feasible route (RMST, 30k horizon,
bootstrap 95\% confidence intervals). Every run enters the statistic.}
\label{fig:uavrmst}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=0.92\linewidth]{figures/uav_final_cost_box.png}
\caption{Distribution of final feasible route cost per method over the five
scenarios and 30 repetitions.}
\label{fig:uavcost}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{figures/uav_routes_montage.png}
\caption{Best feasible delivery routes found by \method{} on the five
DEM-based scenarios (costs 481.7--600.7). Terrain colour encodes elevation;
red cylinders are threat zones with safety margins; the blue polyline is the
route, dots are stations and the square is the depot.}
\label{fig:uavroutes}
\end{figure}

\subsection{Discussion of the application results}
The application reproduces the mechanism in a setting where the objective is
209-dimensional, the constraints are hard and the terrain is real: the method
that combines sparse evaluation with a verified multi-region archive is the
only one that is reliable on all five maps, it reaches feasibility faster than
every method except PSO---and that exception reverses by the end of the
budget---and it produces better final routes than all five baselines on the
paired runs where the comparison is meaningful. The trade-off that PSO
exhibits is instructive for practice: reaching any feasible route slightly
earlier is attractive in operations, but a method that then stalls at routes
19\% longer and misses 7 of 150 runs is a poor choice for a delivery plan. The
UAV results are therefore not an additional leaderboard but an independent
demonstration of the paper's central claim: with a scarce real-evaluation
budget, the composition of the candidate pool determines both whether feasible
solutions are found at all and how good they become.
"""
open(OUT,"a",encoding="utf-8").write(tex.strip()+"\n")
print("written part 4:", len(tex))
