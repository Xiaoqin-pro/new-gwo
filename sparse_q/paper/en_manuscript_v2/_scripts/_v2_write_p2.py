# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
tex = r"""
\section{Proposed method}
\label{sec:method}
\subsection{Overview and the verified-state discipline}
Figure~\ref{fig:framework} shows one generation of \method{}. A pool of
$M=100$ candidate positions is generated from three routes without any
objective evaluation. Exactly $K=10$ pool members are then sampled uniformly
at random without replacement and evaluated with the real objective; each call
is billed, and a runtime probe asserts that the audited count equals the
budget exactly. The evaluated subset drives all state updates: the leaders
$\alpha,\beta,\delta$, the verified elite archive, and the statistics used by
the routes. Unevaluated candidates have no effect on any of them---the
verified-state discipline. With $N=50$ initialization evaluations, a budget
of $\mathrm{FE}_{\max}=100{,}000$ evaluations decomposes into 50
initialization calls plus $(100000-50)/10=9995$ generations of ten
evaluations.

The discipline is not a presentational detail; it is what makes the mechanism
auditable. Because no unevaluated position can enter the leaders, the archive
or any ranking, every element of the search state is backed by a real
measurement, and the improvement of the method can be attributed to a
measurable set of decisions. It also removes a failure mode that is common in
learned or surrogate-driven variants, where a mechanism can appear to work
because a cheap model is optimistic about positions that were never evaluated.

\begin{figure}[t]
\centering
\includegraphics[width=0.92\linewidth]{figures/fig1_framework.png}
\caption{One generation of \method{}. A pool of 100 cheap candidates is
generated from three routes; only $K=10$ uniformly sampled candidates receive
a real (billed) evaluation, and only verified information flows back into the
leaders and the archive.}
\label{fig:framework}
\end{figure}

The three routes are complementary by design. Route G1 preserves the classical
hunting behaviour and moves the wolves themselves. Route G2 refines the
incumbent leader with a step scale that adapts to the geometry of recent
successful moves. Route E generates candidates from a verified multi-region
archive, providing both exploitation of verified basins (single-centre shells)
and interpolation between basins (two-centre segments). The allocation of
slots across the three routes ($50/12/38$) and the evaluated subset size
($K=10$) were fixed by a pre-registered development scan on development seeds
and functions before any formal run was executed
(Sections~\ref{sec:protocol}--\ref{sec:ablation}).

\subsection{Candidate generation routes}
\paragraph{G1: GWO leader moves (50 candidates).} For each wolf $i$ the
standard aggregation of the three leader-attracted positions is formed,
\begin{equation}
X_i^{G1}=\frac{1}{3}\sum_{k\in\{\alpha,\beta,\delta\}}
\left(X_k - A_k \odot \left| C_k \odot X_k - X_i \right|\right),
\end{equation}
with $A_k=2a\,r_1-a$ and $C_k=2r_2$, where $r_1,r_2\sim U(0,1)^D$ are drawn
per dimension and the convergence factor
\begin{equation}
a=2-2\,\mathrm{FE}/\mathrm{FE}_{\max}
\end{equation}
is driven by the true evaluation count rather than by an iteration counter.
This route preserves the classical exploration--exploitation schedule.

\paragraph{G2: success-scale alpha shells (12 candidates).} Local refinement is
generated in shells around the incumbent alpha wolf,
\begin{equation}
X^{G2}=X_\alpha+\sigma\odot(2u-1),\qquad u\sim U(0,1)^D,
\end{equation}
where the shell scale adapts to the observed geometry of successful moves,
\begin{equation}
\sigma=L\sqrt{3/D},\qquad
L=\max\!\left(\operatorname{median}(\sS_{25}),\;0.01\,d_{\mathrm{diag}}\right).
\label{eq:sigma}
\end{equation}
Here $\sS_{25}$ is the set of the 25 most recent \emph{verified} successful
step lengths (the Euclidean distance of an accepted move), $d_{\mathrm{diag}}$
is the diagonal of the search space, and $\sqrt{3/D}$ converts the
per-dimension half-width into an isotropic shell whose expected Euclidean
radius equals $L$. When fewer than five successful steps are available---only
at the start of a run---$L$ is initialised to $0.05\,d_{\mathrm{diag}}$. The
scale therefore follows the measured geometry of moves that worked instead of
a fixed schedule.

\paragraph{E: verified elite archive (38 candidates).} The archive stores up
to 24 real-evaluated solutions under two rules: a candidate may enter only if
it improves the worst archived objective value, and archived solutions are
kept separated by at least $2\%$ of $d_{\mathrm{diag}}$. If an evaluated
position is not separated from its nearest neighbour but is better than it,
the neighbour is replaced instead. Each archived centre carries a
\emph{credit} that counts how often it has contributed to an accepted
candidate. Nineteen of the 38 archive candidates are single-centre shells. A
centre $c$ is drawn with probability proportional to $1+\mathrm{credit}(c)$,
and the candidate is placed on a modulated shell,
\begin{equation}
X^{E_1}=c+\sigma\,(0.5+v)\odot(2u-1),\qquad v\sim U(0,1),
\end{equation}
so the shell radius varies in $[0.5\sigma,1.5\sigma]$ around the centre. The
remaining nineteen are two-centre segments between distinct archived centres
$c_1,c_2$,
\begin{equation}
X^{E_2}=c_1+\lambda\,(c_2-c_1)+0.25\,\sigma\odot(2u-1),
\qquad \lambda\sim U(0.15,0.85),
\label{eq:segment}
\end{equation}
which interpolate between verified basins. Because archived centres are
separated by construction, this route proposes candidates in several distinct
regions of the search space at the same time---the property that
Section~\ref{sec:ablation} identifies as the source of the method's
advantage.

\subsection{Sparse allocation and commit rules}
The $K=10$ evaluated candidates are drawn uniformly at random from the pool
without replacement. This keeps the allocation free of additional
hyperparameters and, as Section~\ref{sec:ablation} shows, is not improved upon
by screening, quota or learning-based alternatives. Commits follow the origin
of the candidate:
\begin{itemize}
\item an evaluated G1 candidate replaces its parent wolf if it improves that
parent's objective value;
\item an evaluated G2 or E candidate replaces the current worst wolf if it is
strictly better than that wolf;
\item every accepted move is appended to the verified-step record that drives
$\sigma$;
\item the archive and the leaders $\alpha,\beta,\delta$ are updated
exclusively from real-evaluated results.
\end{itemize}
All candidates are clamped to the search box before evaluation. Clamping is
the only boundary handling used; no reflection, re-sampling or repair is
applied, so the number of real evaluations consumed per generation is exactly
$K$ regardless of the geometry of the search space.

\begin{algorithm}[t]
\caption{\method{} (one run)}
\label{alg:vast}
\begin{algorithmic}[1]
\State initialize $N$ wolves by real evaluation; set
$\alpha,\beta,\delta$ and $\arc\!\leftarrow\!\emptyset$;
$\mathrm{FE}\!\leftarrow\!N$
\While{$\mathrm{FE}<\mathrm{FE}_{\max}$}
  \State build pool: 50 G1 moves, 12 G2 shells with scale
  $\sigma$ from Eq.~\eqref{eq:sigma}, 38 archive candidates
  \State sample $K=10$ candidates uniformly without replacement
  \For{each sampled candidate $x$}
     \State $f(x)\leftarrow$ real evaluation; $\mathrm{FE}\!\mathrel{+}\!=\!1$
     \State commit $x$ according to its route (parent or worst wolf, if
     better)
     \State update verified-step record, archive and
     $\alpha,\beta,\delta$ from verified results only
  \EndFor
\EndWhile
\State \Return best verified solution
\end{algorithmic}
\end{algorithm}

\subsection{Archive maintenance}
Algorithm~\ref{alg:archive} states the archive update and credit rule
explicitly, because the ablation in Section~\ref{sec:ablation} manipulates
this rule. The update is applied to every real-evaluated candidate, including
those that do not replace a wolf: the archive therefore accumulates the best
verified information of the run rather than only the winners of the current
generation. When the archive is full, an improving candidate that is
sufficiently separated from the stored solutions replaces the worst stored
solution; a candidate that is better than its nearest neighbour but too close
to it replaces that neighbour. The cold-start case is handled by an explicit
fallback: while the archive is empty, the archive slots are filled by
$\alpha$-centred shells, so the pool composition remains constant.

\begin{algorithm}[t]
\caption{Archive update (applied to every verified candidate $x$, value $v$)}
\label{alg:archive}
\begin{algorithmic}[1]
\If{$\arc=\emptyset$}
   \State $\arc\leftarrow\{x\}$
\ElsIf{$v<\max$ value in $\arc$}
   \If{distance from $x$ to nearest archive centre
   $\ge 0.02\,d_{\mathrm{diag}}$}
      \State insert $x$; if $\arc$ is full, replace the entry with the
      worst value and reset its credit
   \ElsIf{$v<$ value of the nearest archive centre}
      \State replace that centre by $x$
   \EndIf
\EndIf
\State if $x$ came from route E and was accepted, increment the credit of its
parent centre
\end{algorithmic}
\end{algorithm}

\subsection{Complexity}
Per generation, \method{} constructs $M=100$ candidates at cost $O(MD)$,
selects $K=10$ of them, performs $K$ objective evaluations, and maintains the
archive at cost $O(|\arc|D)$ per evaluated candidate with $|\arc|\le 24$. The
arithmetic cost of the search machinery is therefore a few thousand scalar
operations per real evaluation at $D=50$---negligible when evaluations are
expensive, and measurable when they are cheap. The number of generations is
fixed by the budget at $(\mathrm{FE}_{\max}-N)/K=9995$, so a run constructs
$999{,}500$ candidates for $100{,}000$ evaluations, i.e.\ ten candidates per
evaluation, and the additional arithmetic cost is reported as wall-clock time
at equal budget in Section~\ref{sec:results}.
"""
open(OUT,"a",encoding="utf-8").write(tex.strip()+"\n")
print("written part 2:", len(tex))
