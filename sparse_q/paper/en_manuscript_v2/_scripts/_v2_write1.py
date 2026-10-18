# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2"
tex = r"""
\documentclass[11pt]{article}
\usepackage[a4paper,top=2.4cm,bottom=2.6cm,left=2.5cm,right=2.5cm]{geometry}
\usepackage{newtxtext,newtxmath}
\usepackage{microtype}
\usepackage{amsmath,amssymb}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{array}
\usepackage{multirow}
\usepackage[labelsep=period,font=small,labelfont=bf]{caption}
\usepackage[super,comma,sort&compress]{natbib}
\usepackage{algorithm}
\usepackage{algpseudocode}
\usepackage{setspace}
\usepackage{xcolor}
\usepackage[hidelinks]{hyperref}
\setlength{\parskip}{0.30em}
\setlength{\abovedisplayskip}{6pt}
\setlength{\belowdisplayskip}{6pt}
\newcommand{\method}{VAST-GWO}
\newcommand{\arc}{\mathcal{A}}
\newcommand{\sS}{\mathcal{S}}
\newcommand{\R}{\mathbb{R}}

\title{\vspace{-1.2cm}\large\bfseries \method{}: a verified archive-guided
sparse-evaluation grey wolf optimizer for global optimization and 3D UAV
delivery path planning}
\author{\normalsize Draft manuscript -- all experiments are archived in the
accompanying repository and every reported number is reproducible from the
frozen batches.}
\date{\vspace{-0.4cm}}

\begin{document}
\maketitle
\vspace{-0.8cm}

\begin{abstract}
\noindent
In black-box optimization the binding resource is the number of real objective
evaluations, not the amount of arithmetic. The grey wolf optimizer (GWO)
evaluates its whole pack every generation and derives all movement from three
leaders, so when evaluations are scarce the budget is spent on candidates of
unknown value and the search distribution contracts around the same
attractors---the classical route to premature convergence. This paper proposes
\method{}, a verified archive-guided sparse-evaluation grey wolf optimizer.
Each generation builds a pool of $M=100$ cheap candidates from three
complementary sources---standard leader moves (50), success-scale shells
around the incumbent $\alpha$ wolf (12), and multi-region shells and
two-centre segments generated from a verified elite archive (38)---and spends
exactly $K=10$ real evaluations on a uniformly drawn subset. Nothing that has
not received a real evaluation enters the leaders, the archive or any ranking:
the search state is verified by construction. On CEC2017 at $D=50$ (29
functions, 30 independent runs, 100{,}000 probe-audited true evaluations),
\method{} attains the best mean rank among seven methods (2.24, ahead of 2.28
for the strong improved GWO, 3.41 for a 2026 hierarchical GWO, 4.41 PSO, 4.48
CLPSO, 5.07 for a 2026 oppositional GWO and 6.10 for standard GWO),
outperforms five of the six baselines with Holm-corrected significance, and
reaches statistical parity with the strongest classical improvement while
leading it on the mean rank. A five-arm, equal-slot source ablation shows that
the verified multi-region archive is the performance engine: disabling it
turns the method into 27 losses in 29 functions, and replacing it by a
single-centre $\alpha$ sampler with identical slots, scale and acceptance rule
collapses it to 2 wins in 29, whereas the $\alpha$-shell route becomes
optional once the archive is present. In a 209-dimensional DEM-based 3D UAV
delivery problem with hard time windows, \method{} is the only method that
finds a feasible route in all 150 runs, attains the smallest censored mean
time to first feasibility (7062 evaluations) and the best paired final route
quality against every baseline after Holm correction. The broader finding is
that when real evaluations are the scarce resource, the \emph{composition of
the candidate pool} is a first-class design variable whose value can exceed
that of additional evaluation-scheduling complexity.
\end{abstract}

\vspace{0.2cm}
\noindent\textbf{Keywords:} grey wolf optimizer; sparse evaluation; verified
elite archive; multi-region search; limited evaluation budget; UAV path
planning; CEC2017.

\section{Introduction}
\label{sec:intro}
Nature-inspired optimizers are a standard tool in engineering design,
scheduling and path planning because they assume little about the objective
and scale to black-box simulators. Their practical cost, however, is dominated
by the objective function itself: in finite-element calibration,
computational-fluid design or UAV mission planning a single evaluation may
take seconds to hours, so the number of \emph{real} evaluations is the binding
constraint rather than the number of arithmetic operations
\citep{yu2021multimodel,liu2024survey,zhao2025surrogate}. Under such budgets an
optimizer has to answer one question well: \emph{where should the next real
evaluation be spent?}

The grey wolf optimizer (GWO) \citep{mirjalili2014gwo} is an attractive
starting point: it is parameter-light, easy to implement and has been applied
across the Internet of Things, feature selection, agriculture and UAV planning
\citep{nadimishahraki2024iot,makhadmeh2023review}. Its classic form, however,
evaluates the entire pack every generation and derives all movement from the
three leaders $\alpha$, $\beta$ and $\delta$. When evaluations are scarce this
design has two consequences. First, the budget is consumed on candidates whose
information value is unknown and, in the classical scheduler, identical: every
generation re-evaluates every individual whether or not the search has
stagnated. Second, all new positions are attracted to the same three leaders,
so the search distribution contracts and the pack loses the ability to
re-enter regions it has left---premature convergence on multimodal
landscapes. Reviews of GWO and its variants document both behaviours
\citep{makhadmeh2023review,nadimishahraki2024iot}.

A large recent literature improves GWO from different angles: new movement
equations and hybrids \citep{wang2019igwode,z Zhang2025placeholder}, learning
or reinforcement-learning driven control of strategies and quotas
\citep{yin2026amsgwo,huang2026qlfdgwo,khalid2026aogwo}, memory and archive
structures \citep{zamani2026egwo,tejani2025twoarchive}, and applications to
UAV trajectory planning \citep{nayeem2025drones,jia2025drones}. These methods
deliver strong results, but they are typically evaluated under protocols in
which every individual is evaluated once per iteration or the budget is
measured in iterations, and they usually add mechanisms to the search
dynamics. As a result it is rarely isolated \emph{which} design element
produces the gain, or whether the gain survives when the scheduler is held
fixed.

This paper takes the real-evaluation budget itself as the design constraint
and asks a deliberately narrow question: \emph{given a fixed number of real
evaluations per generation, how should the candidate pool be composed?} We
propose \method{} (verified archive-guided sparse-evaluation technique for
grey wolf optimization), which separates cheap candidate generation from real
evaluation and admits information into the search state only after it has been
paid for by a real evaluation---a \emph{verified-state discipline}. Each
generation generates $M=100$ cheap candidates from three routes---standard GWO
leader moves (50), success-scale $\alpha$ shells (12) and multi-region
candidates drawn from a verified elite archive (38)---and evaluates only
$K=10$ uniformly sampled candidates against the real objective. Because the
pool is never ranked, the composition of the pool is the only design variable
that matters, and it can be tested in isolation.

The contributions of this paper are the following.
\begin{itemize}
\item \textbf{A verified-state sparse-evaluation framework.} Each generation
generates $M=100$ cheap candidates, evaluates $K=10$ of them under a strictly
audited true-evaluation budget, and lets no unevaluated candidate influence
leaders, archives, rankings or statistics. \method{} is therefore the first
GWO variant, to our knowledge, whose memory is \emph{exactly} the set of
positions that were paid for by a real evaluation.
\item \textbf{A verified multi-region archive used as a candidate source.} The
archive stores only real-evaluated improvements, enforces a separation
threshold, tracks a per-centre credit, and \emph{generates} candidates---shells
around its centres and segments between pairs of centres---rather than
serving as a passive reservoir. A five-arm, equal-slot source ablation shows
that this route is the performance engine of the method.
\item \textbf{Design-space boundaries under matched controls.} Directed
screening, informed stratified allocation, fixed exploration quotas, three
Q-learning quota schedulers, stagnation-triggered radius boosting and
success-direction steering are each tested against a matched control. None of
them improves on uniform random allocation, and steering along successful
directions is reproduced by an equal-magnitude random-direction control---which
identifies the candidate-source structure, not scheduler complexity, as the
lever that works.
\item \textbf{Evidence at several operating points.} A seven-method CEC2017
comparison at $D=50$ (29 functions, 30 seeds, 100{,}000 true evaluations), two
additional resource tiers ($D=100$; a five-times smaller budget), behaviour
diagnostics for stagnation and novelty, and a 209-dimensional UAV application
are reported under one protocol with identical initial populations and
probe-audited budgets.
\item \textbf{A demanding engineering application.} On a 209-dimensional
DEM-based 3D UAV delivery problem with hard time windows on five real terrain
scenarios, \method{} is the only method that finds feasible routes in all 150
runs, has the smallest censored mean time to feasibility, and delivers the
best paired final route quality against every baseline after Holm correction.
\end{itemize}

The remainder of the paper is organised as follows. Section~\ref{sec:related}
reviews related work and states the design gap.
Section~\ref{sec:method} presents \method{} and analyses its complexity.
Section~\ref{sec:setup} describes the experimental protocol, the baselines and
the statistical machinery. Section~\ref{sec:results} reports the benchmark
results and Section~\ref{sec:ablation} the ablation and mechanism analysis.
Section~\ref{sec:uav} presents the UAV application,
Section~\ref{sec:discussion} discusses implications and scope, and
Section~\ref{sec:conclusion} concludes.

\section{Related work}
\label{sec:related}
\subsection{Grey wolf optimizer and its variant families}
GWO \citep{mirjalili2014gwo} models the leadership hierarchy and cooperative
hunting of grey wolves: the three best solutions guide the pack through
encircling and attacking equations whose exploration--exploitation balance is
controlled by a parameter that decreases over the course of the search.
Comprehensive reviews document its variants and applications
\citep{makhadmeh2023review,nadimishahraki2024iot}. Operator-level
improvements add differential evolution and elimination
\citep{wang2019igwode}, mutation with evolutionary population dynamics
\citep{zhang2025mutation}, teaching--learning hybridisation
\citep{singh2025tlbo}, beetle-antennae search \citep{zhang2025bagwo},
grey wolf--particle swarm hybrids \citep{shaikh2025hybrid}, self-repulsion
strategies \citep{wang2025selfrepulsion} and engineering-oriented forms
\citep{li2021sustainability,nadimi2021igwo}. Learning-driven variants couple
GWO with reinforcement or Q-learning for strategy, leader or quota selection
\citep{yin2026amsgwo,huang2026qlfdgwo,khalid2026aogwo,wang2026dmsgwo}, and
UAV-specific versions embed learning into trajectory planning
\citep{nayeem2025drones,jia2025drones}. These families change \emph{how wolves
move} or \emph{who decides}. The present work changes neither: it reorganises
\emph{which candidates exist} when only a small, fixed number of them can be
evaluated per generation, and it holds the allocation rule fixed at a uniform
draw so that the effect of the candidate sources can be isolated.

\subsection{Memory and archive mechanisms}
Memory is a recurring idea in swarm intelligence, where it stabilises search
and preserves diversity. Recent GWO variants use elite memories, cross-search
memory or two-archive structures for large-scale and multi-objective problems
\citep{zamani2026egwo,tejani2025twoarchive}. \method{} shares the motivation
but differs in three respects. First, its archive is \emph{verified}: only
positions that received a real evaluation may enter, so the archive never
stores a guess or a surrogate prediction. Second, the archive is not only a
diversity reservoir---its centres and the segments between them directly
\emph{generate} candidates, which is the property that the equal-slot
ablation of Section~\ref{sec:ablation} isolates. Third, the archive is
credit-aware: each stored centre accumulates how often it has contributed to
an accepted candidate, and this credit biases which centres are used.

\subsection{Optimization under expensive evaluations}
When evaluations are expensive, surrogate-assisted evolutionary algorithms are
the dominant paradigm: a model of the objective guides the search and is
updated with a limited number of real evaluations
\citep{yu2021multimodel,liu2024survey,zhao2025surrogate}. \method{} is
complementary rather than competing. It uses no surrogate and targets the
regime in which each real evaluation is affordable but scarce enough that the
per-generation allocation must be fixed and audited; the comparison is then
clean, because every method receives exactly the same number of billed
evaluations and no method benefits from a model that the others do not have.
The verified-state discipline also makes the archive a natural training set
for a future surrogate, because every entry is a real measurement.

\subsection{UAV path planning with metaheuristics}
UAV path planning with metaheuristics is an active field: GWO and its variants
have been applied to three-dimensional trajectory planning and cooperative
mission planning with obstacle avoidance and kinematic constraints
\citep{nayeem2025drones,jia2025drones}, and hybrid GWO variants are routinely
tested on UAV mission benchmarks \citep{zhang2025bagwo}. Most studies report
one aggregate objective value and a success rate at the final budget. The
application study in Section~\ref{sec:uav} adds three measurements that matter
in practice for delivery missions: the \emph{time to first feasible route}
under a censoring horizon, the cumulative feasibility as a function of the
real-evaluation budget, and the final route quality among feasible runs. These
three quantities can rank methods differently, and separating them is what
allows the trade-offs of the compared methods to be described precisely.

\subsection{The design gap}
Table~\ref{tab:related} summarises the landscape. Operator-level variants
change the movement equation; learning-driven variants change the controller;
memory mechanisms change what is retained; budget-aware methods change how
evaluations are allocated or modelled. What has not been systematically
studied in GWO is the composition of the candidate pool under a fixed,
audited real-evaluation budget---that is, which candidates are \emph{offered}
for evaluation when only a small random subset of them can be paid for. This
paper addresses that gap with a controlled design: the pool composition is
varied while the pool size, the number of evaluated candidates, the budget,
the acceptance rules and the initial populations are held fixed.

\begin{table}[t]
\centering
\small
\caption{Improvement families in the GWO literature and the design dimension
each of them addresses. The present work addresses the last column: the
composition of the candidate pool under a fixed, audited real-evaluation
budget.}
\label{tab:related}
\input{tables/table_related.tex}
\end{table}
"""
open(os.path.join(OUT,"main.tex"),"w",encoding="utf-8").write(tex.strip()+"\n")
print("chunk 1 written, chars:", len(tex))
