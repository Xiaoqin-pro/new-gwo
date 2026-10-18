# -*- coding: utf-8 -*-
"""Hand-written LaTeX tables for the v2 single-column manuscript."""
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\tables"
os.makedirs(OUT, exist_ok=True)
def w(name, s): open(os.path.join(OUT,name),"w",encoding="utf-8").write(s.strip()+"\n")

w("table_taxonomy.tex", r"""
\begin{tabular}{p{3.9cm}p{4.6cm}p{5.6cm}}
\toprule
Research line & Typical intervention & Relation to this work \\
\midrule
GWO and its operator-level variants & New movement, mutation, hybridisation or grouping rules \citep{nadimishahraki2024iot,makhadmeh2023review,wang2019igwode,zhang2025mutation,singh2025tlbo,zhang2025bagwo,shaikh2025hybrid,li2021sustainability} & Change what the wolves do each iteration; the candidate pool itself is left unchanged \\
Improved GWO for engineering design & Nonlinear control parameters, dimension-wise initialization, dynamic position updates \citep{nadimi2021igwo} & The strongest classical baseline used here; complements rather than duplicates the archive mechanism \\
Learning-driven and adaptive GWO & Q-learning or reinforcement learning selects strategies, leaders or budgets \citep{yin2026amsgwo,huang2026qlfdgwo,khalid2026aogwo,wang2026dmsgwo} & Report gains against tuned competitors, but rarely against a matched random or fixed-allocation control \\
Memory, archive and multi-population GWO & Elite memories, cross-search memories, two-archive structures \citep{zamani2026egwo,tejani2025twoarchive} & Closest in spirit; here the archive is \emph{verified} and generates candidates across several regions \\
GWO for UAV path planning & Q-learning or reinforcement-learning guided trajectory planning \citep{nayeem2025drones,jia2025drones,huang2026qlfdgwo} & Motivates the 209-dimensional application; the present study adds censored time-to-feasibility and per-map reliability \\
Surrogate-assisted expensive optimization & Models replace real evaluations and are refined with infill criteria \citep{yu2021multimodel,liu2024survey,zhao2025surrogate} & A different regime; here every state variable is backed by a billed real evaluation \\
\bottomrule
\end{tabular}
""")

w("table_setup.tex", r"""
\begin{tabular}{p{1.7cm}p{5.4cm}p{7.9cm}}
\toprule
Method & Source of the implementation & Configuration under the common protocol \\
\midrule
GWO & Original formulation, reimplemented and audited against the published equations \citep{mirjalili2014gwo} & $N=50$; whole pack evaluated once per iteration; linearly decreasing $a$; canonical boundary clamping \\
I-GWO & Published improved GWO \citep{nadimi2021igwo} & $N=50$; dimension-wise opposition-based initialization, nonlinear control parameter and dynamic position update as published \\
HAGWO & Author MATLAB code (commit \texttt{bdfda96}), hierarchical adversarial GWO \citep{su2026hagwo} & $N=50$; dynamic three-layer division, elite refinement, L\'evy perturbation and adversarial escape retained; per-iteration fitness reused instead of re-evaluated \\
PSO & Classic inertia-weight particle swarm \citep{kennedy1995pso,shi1998modified} & $N=50$; $w$ decreasing linearly from 0.9 to 0.4; $c_1=c_2=2$; $v_{\max}=0.2\,(\mathrm{ub}-\mathrm{lb})$ \\
CLPSO & TEC2006 author code package \citep{liang2006clpso} & $N=50$; $P_c$ schedule, five-stagnation refresh, $c=1.49445$; out-of-range positions are not re-evaluated, as in the original code \\
AOGWO & Author MATLAB code (commit \texttt{4122cef}), adaptive oppositional GWO \citep{khalid2026aogwo} & $N=50$; oppositional initialization, cosine-adaptive $a$, decaying jump rate with L\'evy perturbation and selective opposition retained; search domain adapted to $[-100,100]^D$ \\
\bottomrule
\end{tabular}
""")

w("table_ablation_design.tex", r"""
\begin{tabular}{p{1.2cm}p{4.0cm}p{3.4cm}p{6.4cm}}
\toprule
Arm & Candidate pool (equal total $M=100$) & Mechanism under test & Rationale \\
\midrule
A0 & 100 GWO leader moves & Sparse evaluation alone & Isolates the effect of evaluating only $K$ of $M$ candidates \\
A1 & 50 GWO moves $+$ 50 $\alpha$-shells & Leader-centred refinement & Tests whether local refinement around $\alpha$ can replace multi-region memory \\
A2 & 50 GWO moves $+$ 50 archive candidates & Verified multi-region archive & Isolates the archive without the $\alpha$-shell route \\
A3 & 50 GWO moves $+$ 12 $\alpha$-shells $+$ 38 archive candidates & Full \method{} & Reference configuration \\
A5 & 50 GWO moves $+$ 12 $\alpha$-shells $+$ 38 single-centre draws around $\alpha$ & Archive replaced by a single centre with identical slots, scale and acceptance rule & Tests whether several regions, rather than extra perturbation, produce the gain \\
\bottomrule
\end{tabular}
""")

w("table_ablation.tex", r"""
\begin{tabular}{lrrrr}
\toprule
Comparison & Median ratio & W--L & Holm $+/-$ & Pooled $p$ \\
\midrule
A3 (full) vs A0 (GWO moves only) & 0.538 & 27--2 & $+23/-0$ & $7\times10^{-102}$ \\
A3 (full) vs A1 (G1$+$G2) & 0.812 & 25--4 & $+21/-1$ & $5\times10^{-60}$ \\
A3 (full) vs A2 (G1$+$E) & 0.994 & 14--15 & $+1/-0$ & 0.326 \\
A2 (G1$+$E) vs A0 & 0.510 & 29--0 & $+27/-0$ & $7\times10^{-117}$ \\
A5 (single centre) vs A3 (full) & 1.407 & 2--27 & $+2/-23$ & $1\times10^{-64}$ \\
\bottomrule
\end{tabular}
""")

w("table_boundaries.tex", r"""
\begin{tabular}{p{4.6cm}p{4.2cm}p{2.6cm}p{4.0cm}}
\toprule
Hypothesis & Control & Median ratio & Verdict \\
\midrule
Screening the best-looking candidates beats random allocation & Directed screening by proximity to $\alpha$ and archive credit (S2) & 1.394 vs uniform & Rejected; it starves the GWO route of evaluations \\
Stratified or informed allocation beats a uniform draw & Informed-in-strata, pool-ratio and trend-informed allocation & 1.528 / 1.255 / 1.348 & Rejected \\
A fixed exploration quota manages the budget better than the pool share & Fixed quota at 0.25 / 0.50 / 0.75 & 1.070 / 1.064 / 1.672 & Rejected; raising the quota above the pool share is harmful \\
Reinforcement learning schedules the budget better than the best fixed policy & Three Q-learning quota schedulers (zero, tuned and prior-initialised) & 0.988--1.130 vs best fixed; 0.748--0.870 vs random quota & Rejected as a contribution; always at or below the best fixed policy \\
A stagnation-triggered radius boost restores progress & Shell radius multiplied by three after stagnation & 1.204 & Rejected \\
Reusing verified successful directions adds information beyond extra perturbation & Steering along the mean recent successful direction & 0.897 vs frozen; 0.988 vs equal-magnitude random directions ($p=0.155$) & Rejected; the random control reproduces the gain \\
\bottomrule
\end{tabular}
""")

w("table_uav.tex", r"""
\begin{tabular}{rrrrrr}
\toprule
Method & Feasible (\%) & RMST & RMST 95\% CI & First feasible$^{\dagger}$ & Cost$^{\ddagger}$ \\
\midrule
\method{} & \textbf{100.0} & \textbf{7062} & [6449, 7731] & 6314 & 667.4 \\
GWO & 94.0 & 10936 & [9941, 11983] & 8920 & 699.8 \\
I-GWO & 97.3 & 12270 & [11374, 13179] & 11152 & 724.7 \\
HAGWO & 97.3 & 8133 & [7355, 8950] & 7432 & 663.4 \\
PSO & 95.3 & 8138 & [7058, 9324] & 5357 & 766.4 \\
CLPSO & 61.3 & 24427 & [23312, 25383] & 21330 & 1015.4 \\
\bottomrule
\end{tabular}
""")

w("table_uav_maps.tex", r"""
\begin{tabular}{lrrrrr}
\toprule
Method & Hills & Mountain & Peaks & Plateau & Ridge \\
\midrule
\method{} & \textbf{100} & \textbf{100} & \textbf{100} & \textbf{100} & \textbf{100} \\
GWO & 96.7 & 83.3 & 100 & 90.0 & 100 \\
I-GWO & 100 & 86.7 & 100 & 100 & 100 \\
HAGWO & 96.7 & 93.3 & 100 & 96.7 & 100 \\
PSO & 100 & 83.3 & 100 & 96.7 & 96.7 \\
CLPSO & 56.7 & 36.7 & 80.0 & 60.0 & 73.3 \\
\bottomrule
\end{tabular}
""")

w("table_uav_model.tex", r"""
\begin{tabular}{p{4.4cm}p{3.6cm}p{7.0cm}}
\toprule
Quantity & Value & Role in the model \\
\midrule
Decision vector & 209 dimensions & 20 ranking values for the visiting order $+$ 189 control offsets (21 legs $\times$ 3 control points $\times$ 3 offsets) \\
Map extent & $100\times100$ units & Horizontal extent of each terrain tile; depot at $(40,50)$ \\
Terrain & Copernicus GLO-90, five tiles & Ridge, peaks, mountain, hills and plateau; bilinear interpolation on a $51\times51$ grid \\
Delivery points & 20 per map & Fixed station coordinates; five-digit hard time windows per station \\
Cruise speed & 10 units per time unit & Converts leg length to arrival time \\
Service height & 16 m above ground & Station altitude; depot altitude follows the terrain \\
Terrain clearance & 4 m & Minimum vertical separation between route and terrain along each leg \\
Threat zones & 3 cylinders per map & Radius plus 2 m safety margin; vertical extent from terrain base to a specified ceiling \\
Operating ceiling & 42 m & Maximum flight altitude \\
Climb / turn limits & $35^\circ$ / $120^\circ$ & Maximum flight-path angle and heading change within a leg \\
Objective weights & 1 / 0.05 / 2 & Distance, waiting time and smoothness terms in Eq.~\eqref{eq:uavobj} \\
Penalties & $10^5+10^3\Delta t$ / $10^5+10^4\Delta g$ & Time-window lateness and geometric violations, respectively \\
\bottomrule
\end{tabular}
""")
print("ok")
