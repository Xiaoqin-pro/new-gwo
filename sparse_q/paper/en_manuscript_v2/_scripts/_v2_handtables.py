# -*- coding: utf-8 -*-
"""Hand-written LaTeX tables for the v2 single-column manuscript."""
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\tables"
os.makedirs(OUT, exist_ok=True)
def w(name, s): open(os.path.join(OUT,name),"w",encoding="utf-8").write(s.strip()+"\n")

# ---- related-work taxonomy ----
w("table_related.tex", r"""
\begin{tabular}{p{2.6cm}p{4.0cm}p{4.0cm}p{4.6cm}}
\toprule
Family & What is changed & Typical mechanisms & What remains unaddressed \\
\midrule
Operator-level GWO variants & The movement or update equation &
Differential evolution and elimination; mutation with evolutionary population
dynamics; teaching--learning and beetle-antennae hybrids; self-repulsion &
The evaluation budget is not treated as a design variable; every individual is
usually evaluated each generation \\
Learning-driven GWO variants & The control policy of the search &
Reinforcement or Q-learning selection of strategies, leaders or quotas &
Gains are attributed to the scheduler, and simple matched controls (uniform or
fixed allocation) are rarely reported \\
Memory and archive mechanisms & What the search remembers &
Elite memories, cross-search memories, two-archive structures &
Memory stores candidates of mixed provenance; archives act as reservoirs rather
than as direct generators of new candidates \\
Budget-aware and surrogate methods & How evaluations are allocated or modelled &
Multi-model surrogates, infill criteria, surrogate-assisted evolutionary
optimization &
Requires a surrogate per problem; reported savings depend on model quality and
are not directly comparable to a fixed true-evaluation budget \\
\bottomrule
\end{tabular}
""")

# ---- baseline provenance ----
w("table_setup.tex", r"""
\begin{tabular}{p{1.9cm}p{5.4cm}p{7.7cm}}
\toprule
Method & Source of the implementation & Configuration and adaptation \\
\midrule
GWO & Original algorithm \citep{mirjalili2014gwo}; in-house implementation audited against the reference semantics & $N=50$; one evaluation per wolf per iteration; linearly decreasing $a$ driven by true FE \\
I-GWO & Published improved GWO \citep{nadimi2021igwo}; configuration follows the paper & $N=50$; dimension-wise OBL initialization, nonlinear control parameter and dynamic position update as published \\
HAGWO & Author MATLAB code (commit \texttt{bdfda96}); hierarchical GWO \citep{su2026hagwo} & $N=50$; dynamic three-layer division, elite refinement, L\'evy perturbation, oppositional escape; per-iteration fitness reuse instead of repeated calls (accounting fix, search unchanged) \\
PSO & Classic inertia-weight particle swarm \citep{kennedy1995pso,shi1998modified} & $N=50$; $w$ linearly $0.9\!\to\!0.4$, $c_1=c_2=2$, $v_{\max}=0.2\,(ub-lb)$ \\
CLPSO & Frozen benchmark-suite runs of the author-source CLPSO \citep{liang2006clpso} & $N=50$; $P_c$ schedule, five-iteration refresh, $c=1.49445$, out-of-bounds positions skipped as in the original; a strict re-implementation of the TEC2006 code package is statistically indistinguishable (median ratio 1.017, $p=0.085$) \\
AOGWO & Author MATLAB code (commit \texttt{4122cef}); adaptive oppositional GWO \citep{khalid2026aogwo} & $N=50$; cosine-adaptive $a$, decaying jump rate with L\'evy perturbation, selective opposition on the leader; search domain mapped to $[-100,100]^D$ \\
\bottomrule
\end{tabular}
""")

# ---- ablation design ----
w("table_ablation_design.tex", r"""
\begin{tabular}{p{1.4cm}p{5.6cm}p{3.4cm}p{4.6cm}}
\toprule
Arm & Candidate pool (total $M=100$ in every arm) & Mechanism under test & Design intent \\
\midrule
A0 & 100 standard GWO leader moves & Sparse evaluation only & Isolates what sparse evaluation alone achieves \\
A1 & 50 GWO moves $+$ 50 $\alpha$-shells & Local refinement around the leader & Tests whether single-centre refinement substitutes for memory \\
A2 & 50 GWO moves $+$ 50 archive candidates & Verified multi-region memory & Isolates the archive without the $\alpha$-shell route \\
A3 & 50 GWO moves $+$ 12 $\alpha$-shells $+$ 38 archive candidates & Full method & The frozen configuration \\
A5 & 50 GWO moves $+$ 12 $\alpha$-shells $+$ 38 single-centre draws at the $\alpha$ wolf & Archive replaced by a single-centre sampler with identical slots, scale and acceptance rule & Tests whether \emph{multi-region} memory matters, or only the extra perturbation \\
\bottomrule
\end{tabular}
""")

# ---- ablation results ----
w("table_ablation.tex", r"""
\begin{tabular}{lrrrr}
\toprule
Comparison & Median ratio & W--L & Holm $+/-$ & Pooled $p$ \\
\midrule
A3 (full) vs A0 (GWO moves only) & 0.538 & 27--2 & $+23/-0$ & $7\times10^{-102}$ \\
A3 (full) vs A1 (G1$+$G2) & 0.812 & 25--4 & $+21/-1$ & $5\times10^{-60}$ \\
A3 (full) vs A2 (G1$+$E) & 0.994 & 14--15 & $+1/-0$ & 0.326 \\
A2 (G1$+$E) vs A0 & 0.510 & 29--0 & $+27/-0$ & $7\times10^{-117}$ \\
A5 ($\alpha$-centred) vs A3 (full) & 1.407 & 2--27 & $+2/-23$ & $1\times10^{-64}$ \\
\bottomrule
\end{tabular}
""")

# ---- design-space boundaries ----
w("table_boundaries.tex", r"""
\begin{tabular}{p{4.5cm}p{3.3cm}p{2.4cm}p{4.8cm}}
\toprule
Design question & Control variant & Median ratio vs reference & Outcome \\
\midrule
Should the $K$ evaluated candidates be screened rather than drawn at random? &
Geometry$+$credit directed screening (S2) & 1.394 vs uniform & Screening starves the GWO route and degrades quality \\
Should the pool be searched in strata with informed allocation? &
Informed-in-strata / pool-ratio allocation / trend-guided $q_E$ & 1.528 / 1.255 / 1.348 & All three worse than uniform allocation \\
Should a fixed exploration quota replace the pool share? &
$q_E\in\{0.25,0.5,0.75\}$ & 1.070 / 1.064 / 1.672 & Quotas above the pool share are harmful \\
Can a Q-learning scheduler beat a fixed allocation? &
Three Q-learning quota policies & 0.988 / 1.024 / 1.130 vs best fixed policy; 0.870 / 0.748 vs random & Never better than the best fixed policy; only better than random quotas \\
Should a stagnation-triggered radius boost be added? &
$\times 3$ shell radius after stagnation & 1.204 & Degrades final quality \\
Is success-direction steering an information-driven contribution? &
Steering along recent successful directions; equal-magnitude random-direction control & 0.934 (steering); 0.988 random vs steering ($p=0.155$) & Improved final error, but an equal-magnitude random perturbation reproduces the effect and the gain appears only in the last 20\% of the budget \\
\bottomrule
\end{tabular}
""")

# ---- UAV results ----
w("table_uav.tex", r"""
\begin{tabular}{lrrrrr}
\toprule
Method & Feasibility (\%) & RMST (FE) & RMST 95\% CI & First feasible (median) & Cost (median) \\
\midrule
VAST-GWO & \textbf{100.0} & \textbf{7062} & [6449, 7731] & 6314 & 667.4 \\
GWO & 94.0 & 10936 & [9941, 11983] & 8920 & 699.8 \\
I-GWO & 97.3 & 12270 & [11374, 13179] & 11152 & 724.7 \\
HAGWO & 97.3 & 8133 & [7355, 8950] & 7432 & 663.4 \\
PSO & 95.3 & 8138 & [7058, 9324] & 5357 & 766.4 \\
CLPSO & 61.3 & 24427 & [23312, 25383] & 21330 & 1015.4 \\
\bottomrule
\end{tabular}
""")

# ---- UAV per-map feasibility ----
w("table_uav_maps.tex", r"""
\begin{tabular}{lrrrrr}
\toprule
Method & Hills & Mountain & Peaks & Plateau & Ridge \\
\midrule
VAST-GWO & \textbf{100.0} & \textbf{100.0} & \textbf{100.0} & \textbf{100.0} & \textbf{100.0} \\
GWO & 96.7 & 83.3 & 100.0 & 90.0 & 100.0 \\
I-GWO & 100.0 & 86.7 & 100.0 & 100.0 & 100.0 \\
HAGWO & 96.7 & 93.3 & 100.0 & 96.7 & 100.0 \\
PSO & 100.0 & 83.3 & 100.0 & 96.7 & 96.7 \\
CLPSO & 56.7 & 36.7 & 80.0 & 60.0 & 73.3 \\
\bottomrule
\end{tabular}
""")

# ---- UAV model parameters ----
w("table_uav_model.tex", r"""
\begin{tabular}{p{5.2cm}p{3.4cm}p{5.9cm}}
\toprule
Quantity & Value & Role in the model \\
\midrule
Depot position / service height & $(40,50)$ / 16 m above terrain & Depot above the terrain surface \\
Map extent & $100\times100$ (normalized) & Bounds on the horizontal plane; altitude ceiling 42 m \\
Delivery stations & 20 per map, hard windows & Each station has ready time, due time and service duration \\
Control points per leg & 3 & Intermediate waypoints, 189 of the 209 decision variables \\
Cruise speed & 10 units per time unit & Converts leg distance into arrival times \\
Clearance above terrain & 4 m & Minimum vertical distance along each leg \\
Threat zones & 3 cylinders per map, 2 m safety margin & No-fly volumes; a route may not intersect them \\
Climb / turn limits & $35^\circ$ / $120^\circ$ & Attitude feasibility along each leg \\
Smoothness weight & 2.0 per leg & Penalizes accumulated turn and pitch changes \\
Waiting weight & 0.05 per time unit & Penalizes early arrival and waiting \\
Penalties & $10^5$ per violated class, plus $10^3$ per late unit and $10^4$ per constraint magnitude & Keeps infeasible solutions strictly behind feasible ones \\
\bottomrule
\end{tabular}
""")
print("tables written:", sorted(os.listdir(OUT)))
