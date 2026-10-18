# -*- coding: utf-8 -*-
import io, os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
tex = r"""
\documentclass[11pt,a4paper]{article}
\usepackage[margin=2.4cm]{geometry}
\usepackage{newtxtext,newtxmath}
\usepackage{microtype}
\usepackage{amsmath,amssymb}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{array}
\usepackage[labelsep=period,font=small]{caption}
\usepackage[numbers,sort&compress]{natbib}
\usepackage{algorithm}
\usepackage{algpseudocode}
\usepackage{setspace}
\usepackage{xcolor}
\usepackage[hidelinks]{hyperref}
\setlength{\parskip}{0.35em}
\newcommand{\method}{VAST-GWO}
\newcommand{\arc}{\mathcal{A}}
\newcommand{\sS}{\mathcal{S}}
\title{\bfseries \method{}: a verified archive-guided sparse-evaluation grey wolf
optimizer for global optimization and 3D UAV delivery path planning}
\author{}
\date{}

\begin{document}
\maketitle
\vspace{-1.6cm}

\begin{abstract}
\noindent
In black-box optimization the resource that decides solution quality is the
number of real objective evaluations, not the number of arithmetic operations.
The grey wolf optimizer (GWO) spends this resource uniformly over the whole
pack and derives all movement from three leaders, which invites premature
convergence and makes each evaluation less informative than it could be. This
paper proposes \method{}, a verified archive-guided sparse-evaluation GWO. In
every generation, 100 cheap candidates are generated from three complementary
routes: standard GWO leader moves (50), success-scale shells around the current
alpha wolf (12), and multi-region shells and two-centre segments produced from
a verified elite archive (38). Only $K=10$ uniformly sampled candidates receive
a real evaluation, and no unevaluated candidate ever influences leaders,
archives or rankings---a verified-state discipline that keeps every piece of
search memory backed by a billed evaluation. On CEC2017 at $D=50$ with
100{,}000 true evaluations and 30 independent runs, \method{} ranks first among
seven methods (mean rank 2.24), significantly outperforming the 2026
hierarchical HAGWO, PSO, CLPSO, the 2026 adaptive oppositional AOGWO and
standard GWO, and reaching statistical parity with the strong improved GWO
while leading it on mean rank. A controlled equal-slot ablation shows that the
verified archive carries the improvement---removing it degrades the method to
27 losses in 29 functions, and replacing it with a single alpha-centred sampler
collapses it to 2 wins---while the alpha-shell route is optional once the
archive is present. Directed screening, fixed quotas and three Q-learning
schedulers were all rejected against matched controls, indicating that the
candidate-source structure, not the evaluation scheduler, is the decisive
design variable. In a 209-dimensional, DEM-based 3D UAV delivery application
with hard time windows, \method{} is the only method that finds feasible routes
in all 150 runs, attains the smallest censored mean time to feasibility, and
produces the best paired final route quality against every baseline after Holm
correction.
\end{abstract}

\vspace{0.2cm}
\noindent\textbf{Keywords:} grey wolf optimizer; sparse evaluation; verified
elite archive; multi-region search; limited evaluation budget; UAV path
planning; CEC2017.

\section{Introduction}
\label{sec:intro}
Nature-inspired optimizers are routinely used for engineering design,
scheduling and path planning because they assume little about the objective
and scale to black-box simulators. Their practical cost, however, is dominated
by the objective function itself. In finite-element calibration,
computational-fluid design or UAV mission planning a single evaluation may
take seconds to hours, so the total number of \emph{real} evaluations is the
binding constraint rather than the number of arithmetic operations
\citep{yu2021multimodel,liu2024survey,zhao2025surrogate}. Under such budgets an
optimizer has to answer one question well: \emph{where should the next real
evaluation be spent?}

The grey wolf optimizer (GWO) \citep{mirjalili2014gwo} is an attractive
starting point. It is parameter-light, easy to implement and has been applied
across the Internet of Things, feature selection, agriculture and UAV planning
\citep{nadimishahraki2024iot,makhadmeh2023review}. Its classic form, however,
evaluates the entire pack every generation and derives all movement from the
three leaders $\alpha$, $\beta$ and $\delta$. When evaluations are scarce this
design has two structural consequences. First, the search state is thin: apart
from the three leaders, the pack retains no memory of the regions it has
visited, so a region that produced a verified improvement but no current
leader is forgotten immediately. Second, the movement distribution contracts
around the same three attractors, which is the classical route to premature
convergence and stagnation on multimodal landscapes. Both effects are visible
in the behaviour of standard GWO on the CEC2017 suite and are documented across
the GWO literature \citep{makhadmeh2023review,nadimishahraki2024iot}.

A large recent literature improves GWO from different angles. Operator-level
variants change the movement rule itself, adding differential evolution and
elimination \citep{wang2019igwode}, mutation with evolutionary population
dynamics \citep{zhang2025mutation}, teaching--learning hybridisation
\citep{singh2025tlbo}, beetle-antennae search \citep{zhang2025bagwo}, grey
wolf--particle swarm hybrids \citep{shaikh2025hybrid}, self-repulsion
\citep{wang2025selfrepulsion} and engineering-oriented forms
\citep{nadimi2021igwo,li2021sustainability}. Learning-driven variants let
reinforcement or Q-learning choose strategies, leaders or budgets
\citep{yin2026amsgwo,huang2026qlfdgwo,khalid2026aogwo,wang2026dmsgwo}, and
memory-based variants extend what the search retains
\citep{zamani2026egwo,tejani2025twoarchive}. UAV-specific versions embed such
mechanisms in trajectory planning \citep{nayeem2025drones,jia2025drones}. These
methods deliver strong results, yet three gaps remain. Most of them are
evaluated under protocols in which every individual is evaluated once per
iteration, so the budget is expressed in iterations rather than in real
evaluations and the two are not interchangeable. Most of them change the
movement rule, so it is rarely isolated which design element produces the gain.
And the natural alternative to a new mechanism---allocating the same budget
differently, or simply enlarging the candidate set that the budget is drawn
from---is seldom tested against matched controls.

This paper takes the real-evaluation budget itself as the design constraint and
asks a deliberately narrow question: \emph{given a fixed number of real
evaluations per generation, how should the candidate pool be composed?} We
propose \method{} (verified archive-guided sparse-evaluation technique for grey
wolf optimization), which separates cheap candidate generation from real
evaluation and admits information into the search state only after it has been
paid for by a real evaluation---a \emph{verified-state discipline}. In every
generation, $M=100$ candidates are produced from three routes: 50 standard GWO
leader moves, 12 success-scale shells around $\alpha$, and 38 multi-region
candidates generated from a verified elite archive. Exactly $K=10$ candidates
are drawn uniformly at random and evaluated; the evaluated subset is the only
information that updates the leaders, the archive and the route statistics.
Because the pool is never ranked, the composition of the pool is the design
variable that matters, and it can be varied in isolation while the pool size,
the evaluated subset size and the budget are held constant.

The hypotheses tested in this paper are three, and each is falsifiable with a
matched control. \textbf{H1 (stagnation recovery).} A verified multi-region
archive produces candidates in regions that the current leaders no longer
represent, so \method{} should leave stagnation episodes more frequently and
spend less of its budget inside long stagnation than standard GWO.
\textbf{H2 (exploration efficiency).} Because the pool contains verified
information from several regions, a uniformly drawn evaluation should be more
likely to open useful new ground, so \method{} should achieve a lower final
error at equal true evaluation count, with a larger advantage on
simple-multimodal and hybrid functions than on unimodal ones. \textbf{H3
(scheduler redundancy).} If the candidate sources are the active ingredient,
then elaborate allocation rules should not improve on a uniform draw once the
pool is fixed---including a learned policy.

The evidence assembled in this paper supports H1, H2 and H3, and it does so
with the same audited budget for every method. On CEC2017 at $D=50$ with
100{,}000 true evaluations and 30 independent runs, \method{} attains the best
mean rank among seven methods (2.24), is significantly better than five of six
baselines under Holm correction, and reaches statistical parity with the strong
improved GWO while leading it on mean rank; it also ranks first at $D=100$ and
under a budget five times smaller. A five-arm equal-slot ablation shows that
the verified archive is the performance engine: removing it produces 27 losses
in 29 functions, replacing it with a single alpha-centred sampler with
identical slots, scale and acceptance rule collapses the method to 2 wins, and
the alpha-shell route is optional once the archive is present. The boundary
experiments reject directed screening, informed allocation, fixed quotas,
stagnation-triggered radius boosting, success-direction steering and three
Q-learning schedulers---the last only beating a random-quota control, never the
best fixed policy. In a 209-dimensional DEM-based 3D UAV delivery problem with
hard time windows and five real terrain tiles, \method{} is the only method
feasible in all 150 runs, attains the smallest censored mean time to
feasibility, and produces the best paired final route quality against every
baseline after Holm correction.

The remainder of this paper is organised as follows. Section~\ref{sec:related}
reviews related work and identifies the research gap.
Section~\ref{sec:method} presents \method{}. Section~\ref{sec:protocol}
describes the experimental protocol, Section~\ref{sec:results} reports the
optimization results and Section~\ref{sec:ablation} the ablation and mechanism
analysis. Section~\ref{sec:uav} presents the UAV application,
Section~\ref{sec:discussion} discusses implications and limitations, and
Section~\ref{sec:conclusion} concludes.

\section{Related work}
\label{sec:related}
\subsection{Grey wolf optimizer and its variants}
GWO \citep{mirjalili2014gwo} mimics the leadership hierarchy and cooperative
hunting of grey wolves: the three best solutions guide the pack through
encircling and attacking equations whose exploration--exploitation balance is
controlled by a linearly decreasing parameter. Comprehensive reviews document
its variants and applications in IoT, energy, scheduling and engineering
design \citep{nadimishahraki2024iot,makhadmeh2023review}. The dominant line of
research changes the movement equation: hybridisation with differential
evolution and an elimination mechanism \citep{wang2019igwode}, mutation
combined with evolutionary population dynamics and nonlinear population
reduction \citep{zhang2025mutation}, teaching--learning hybrids
\citep{singh2025tlbo}, beetle-antennae hybrids \citep{zhang2025bagwo}, particle
swarm hybrids \citep{shaikh2025hybrid}, self-repulsion strategies for feature
selection \citep{wang2025selfrepulsion} and improved forms for classical
engineering design problems \citep{nadimi2021igwo,li2021sustainability}. A
second line lets learning control the search: Q-learning or reinforcement
learning selects strategies, leaders or budget shares
\citep{yin2026amsgwo,huang2026qlfdgwo,khalid2026aogwo,wang2026dmsgwo}, and
UAV-specific variants embed such policies into trajectory planning
\citep{nayeem2025drones,jia2025drones}. \method{} belongs to neither line in
its mechanism: it keeps the classical leader move for one route of the pool and
changes \emph{which candidates exist} under a fixed number of real evaluations
per generation.

\subsection{Memory and archive mechanisms in swarm intelligence}
Memory is a recurring idea in population-based search, where it stabilises the
search and preserves diversity. Recent GWO variants use elite memories,
cross-search memories or two-archive structures for large-scale and
multi-objective problems \citep{zamani2026egwo,tejani2025twoarchive}. \method{}
shares the motivation but differs in three respects. First, the archive is
\emph{verified}: only positions that received a real evaluation may enter, so
the archive never stores a surrogate prediction or an unmeasured guess, and
every archived value is a billed measurement. Second, the archive is
\emph{generative}: its centres and the segments between pairs of centres
directly produce candidates, rather than serving only as a diversity reservoir
or as a set of reference points. Third, it is \emph{multi-region} by
construction: a separation threshold prevents the archive from collapsing into
a single cluster, so its candidates cover several verified basins at once.
Section~\ref{sec:ablation} shows that these properties are not decorative---the
multi-region generative role, not the mere presence of extra candidates,
produces the measured improvement.

\subsection{Optimization under expensive evaluations}
When evaluations are expensive, surrogate-assisted evolutionary algorithms are
the dominant paradigm: a model of the objective guides the search and is
updated with a small number of real evaluations
\citep{yu2021multimodel,liu2024survey,zhao2025surrogate}. \method{} is
complementary rather than competing. It uses no surrogate; it targets the
regime in which a real evaluation is affordable but scarce enough that the
per-generation allocation must be fixed and audited. This keeps the comparison
clean---every method receives exactly the same number of billed evaluations and
no method benefits from a model the others do not have---and it leaves the
archive in a form that a future surrogate could use, because every entry is a
real measurement.

\subsection{UAV path planning with metaheuristics}
Metaheuristics are widely used for three-dimensional UAV path planning, where
objectives combine path length, energy or smoothness with hard constraints on
terrain, obstacles, flight envelope and, in delivery missions, time windows.
GWO and its hybrids are among the most frequently applied methods in this area
\citep{nayeem2025drones,jia2025drones,huang2026qlfdgwo}. Reported evaluations
typically emphasise a single aggregate objective value and a success rate at
the final budget, with the budget expressed in iterations. The application
study in Section~\ref{sec:uav} adds three measurements that matter in practice
for delivery: the time to first feasible route under a censoring horizon, the
cumulative feasibility as a function of the real-evaluation budget, and the
final route quality among feasible runs. The three rank methods differently,
and separating them allows the trade-offs among the compared algorithms to be
described precisely rather than summarised by one number.

\subsection{Research gap}
Table~\ref{tab:taxonomy} summarises the landscape. Operator-level variants
change the movement rule; learning-driven variants change the controller;
memory mechanisms change what is retained; budget-aware and surrogate methods
change how evaluations are modelled or allocated. What has not been examined
systematically in GWO is the composition of the candidate pool under a fixed,
audited real-evaluation budget---that is, which candidates are \emph{offered}
for evaluation when only a small random subset of them can be paid for. This
paper addresses that gap, and it does so with a protocol designed to falsify
the natural alternatives: identical pool size, identical evaluated subset
size, identical budget, matched controls for every scheduling variant, and an
out-of-sample seed block for the mechanism study.

\begin{table}[t]
\centering
\small
\caption{Research lines in GWO and expensive optimization, and their relation
to the present work.}
\label{tab:taxonomy}
\input{tables/table_taxonomy.tex}
\end{table}
"""
open(OUT,"w",encoding="utf-8").write(tex.strip()+"\n")
print("written part 1:", len(tex))
