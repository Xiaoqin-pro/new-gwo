# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2"
tex = r"""
\section{Proposed method}
\label{sec:method}
\subsection{Overview and the verified-state discipline}
Figure~\ref{fig:framework} shows one generation of \method{}. A pool of
$M=100$ candidate positions is generated from three routes without any
objective evaluation. Exactly $K=10$ pool members are then drawn uniformly at
random without replacement and evaluated with the real objective; every call
is billed, and a runtime probe asserts that the audited count equals the
budget exactly. The evaluated subset drives \emph{all} state updates: the
leaders $\alpha,\beta,\delta$, the verified elite archive, and the statistics
used by the routes. Unevaluated candidates have no effect on any of
them---this is the verified-state discipline. With $N=50$ initialization
evaluations, a budget of 100{,}000 evaluations decomposes into 50
initialization calls plus $(100000-50)/10=9995$ generations of ten
evaluations.

The discipline has three consequences that matter for the claims made in this
paper. It removes optimistic bias, because the archive can never contain a
position whose value is a guess. It makes the budget interpretable, because
every change to the search state can be traced to a billed evaluation. And it
makes the comparison fair, because every method in the study---including all
baselines---consumes exactly the same number of real evaluations.

\begin{figure}[t]
\centering
\includegraphics[width=0.86\linewidth]{figures/fig1_framework.png}
\caption{One generation of \method{}. A pool of 100 cheap candidates is
generated from three routes; only $K=10$ uniformly sampled candidates receive
a real (billed) evaluation, and only verified information flows back into the
leaders and the archive.}
\label{fig:framework}
\end{figure}

\subsection{Candidate generation routes}
\paragraph{Route G1: leader moves (50 candidates).}
For each wolf $i$ the standard aggregation of the three leader-attracted
positions is formed,
\begin{equation}
X_i^{G1}=\frac{1}{3}\sum_{k\in\{\alpha,\beta,\delta\}}
\left(X_k - A_k \odot \left| C_k \odot X_k - X_i \right|\right),
\end{equation}
with per-dimension coefficients
$A_k=2a\,r_1-a$, $C_k=2r_2$, $r_1,r_2\sim U(0,1)^D$, and the convergence
factor
\begin{equation}
a=2-2\,\frac{\mathrm{FE}}{\mathrm{FE}_{\max}}
\end{equation}
driven by the \emph{true} evaluation count rather than by an iteration
counter. This route preserves the classical hunting behaviour and is the only
route that moves the wolves themselves: an evaluated G1 candidate replaces its
own parent if it improves its parent's objective value.

\paragraph{Route G2: success-scale shells around the incumbent (12 candidates).}
Local refinement is generated in shells around the incumbent $\alpha$ wolf,
\begin{equation}
X^{G2}=X_\alpha+\sigma\odot(2u-1),\qquad u\sim U(0,1)^D,
\end{equation}
where the shell scale adapts to the observed geometry of successful moves.
Let $\sS$ be a ring buffer holding the Euclidean lengths of the last (at most
25) \emph{verified} successful moves, i.e.\ displacements of evaluated
candidates that were accepted. Then
\begin{equation}
\sigma=\max\!\left(\tilde L,\;0.01\,d_{\mathrm{diag}}\right)\sqrt{3/D},
\qquad
\tilde L=\begin{cases}
\mathrm{median}(\sS), & |\sS|\ge 5,\\[2pt]
0.05\,d_{\mathrm{diag}}, & \text{otherwise},
\end{cases}
\label{eq:sigma}
\end{equation}
with $d_{\mathrm{diag}}=\lVert ub-lb\rVert$ the diagonal of the search space.
The factor $\sqrt{3/D}$ makes the expected Euclidean radius of a shell equal
to $\max(\tilde L, 0.01\,d_{\mathrm{diag}})$, so the same scale rule applies
in any dimension. The scale therefore follows the geometry of moves that
actually paid off instead of following a fixed schedule, and the fallback
$0.05\,d_{\mathrm{diag}}$ keeps the route valid during the first generations,
before five verified successes exist.

\paragraph{Route E: verified multi-region archive (38 candidates).}
The archive $\arc$ stores at most $|\arc|_{\max}=24$ real-evaluated solutions.
An evaluated position may enter only if it improves the worst archived value,
and it must be separated from the stored solutions: if its distance to the
nearest archived solution is at least $2\%$ of $d_{\mathrm{diag}}$, it is
inserted (or, when the archive is full, replaces the worst entry); if it is
not sufficiently separated but is better than its nearest neighbour, it
replaces that neighbour. Each stored centre carries a credit that counts how
often it has contributed to an accepted candidate. Of the 38 archive
candidates, nineteen are single-centre shells. A centre $c$ is drawn with
probability proportional to $1+\text{credit}(c)$ and perturbed as
\begin{equation}
X^{E_1}=c+\sigma\,(0.5+v)\odot(2u-1),\qquad v\sim U(0,1),
\end{equation}
which is an isotropic shell whose radius is modulated by a random factor
between $0.5$ and $1.5$. The remaining nineteen candidates are two-centre
segments,
\begin{equation}
X^{E_2}=c_1+\lambda\,(c_2-c_1)+0.25\,\sigma\odot(2u-1),
\qquad \lambda\sim U(0.15,0.85),
\label{eq:segment}
\end{equation}
where $c_1$ and $c_2$ are distinct archive centres drawn uniformly. Because
archived centres are separated by construction and span different regions of
the search space, the archive route proposes candidates in several distinct
regions simultaneously, while the segments probe the space \emph{between}
regions that have already produced verified improvements. When the archive is
still empty---only possible in the earliest generations---the archive slots
fall back to $\alpha$-centred shells.

All candidates are clamped to the box $[lb,ub]$ before evaluation. Clamping
is the only boundary handling used; no reflection, re-sampling or repair is
applied, so the number of real evaluations per generation remains exactly
$K$ regardless of the geometry of the search space.

\subsection{Sparse allocation, commit rules and archive maintenance}
The $K=10$ evaluated candidates are drawn uniformly at random from the pool
without replacement. This keeps the allocation free of additional
hyperparameters, and Section~\ref{sec:ablation} shows that it is not improved
upon by screening, stratification, fixed quotas or Q-learning. The commit
rule follows the origin of a candidate:
\begin{itemize}
\item a G1 candidate that improves its own parent replaces that parent;
\item a G2 or E candidate that is strictly better than the current worst wolf
replaces the worst wolf;
\item every evaluated position is offered to the archive, and the archive
update follows the insertion, separation and replacement rules above;
\item all accepted moves are appended to $\sS$ (with the ring-buffer
capacity of 25), and the leaders $\alpha,\beta,\delta$ are updated only from
evaluated positions.
\end{itemize}
Algorithm~\ref{alg:vast} summarises the procedure and
Algorithm~\ref{alg:archive} states the archive maintenance and credit update
explicitly.

\begin{algorithm}[t]
\caption{\method{} (one run)}
\label{alg:vast}
\begin{algorithmic}[1]
\State initialize $N$ wolves by real evaluation; set
$\alpha,\beta,\delta$ and $\arc\leftarrow\emptyset$;
$\mathrm{FE}\leftarrow N$
\While{$\mathrm{FE}<\mathrm{FE}_{\max}$}
  \State $a\leftarrow 2-2\,\mathrm{FE}/\mathrm{FE}_{\max}$;\;
  compute $\sigma$ from $\sS$ by Eq.~\eqref{eq:sigma}
  \State build pool: 50 G1 moves (Eq.~1), 12 G2 shells (Eq.~3), 38 archive
  candidates (Eqs.~4--\ref{eq:segment})
  \State sample $K=10$ candidates uniformly without replacement
  \For{each sampled candidate $x$ from route $r$}
     \State $f(x)\leftarrow$ real evaluation; $\mathrm{FE}\mathrel{+}=1$
     \State update $\alpha,\beta,\delta$ with $(x,f(x))$
     \State commit $x$ to its parent ($r$: G1) or to the worst wolf ($r$:
     G2/E) if it improves that reference
     \State update $\arc$ and the credits by
     Algorithm~\ref{alg:archive}
     \State append the accepted displacement length to $\sS$
  \EndFor
\EndWhile
\State \Return best verified solution
\end{algorithmic}
\end{algorithm}

\begin{algorithm}[t]
\caption{Archive maintenance and credit update (applied to each evaluated
candidate $x$ with value $v$; $d_{\mathrm{sep}}=2\%\,d_{\mathrm{diag}}$)}
\label{alg:archive}
\begin{algorithmic}[1]
\If{$\arc=\emptyset$}
   \State insert $x$
\Else
   \State $j\leftarrow$ nearest stored solution to $x$;\;
   $d\leftarrow\lVert x-X_{\arc_j}\rVert$;\;
   $w\leftarrow$ index of the worst stored value
   \If{$v<\text{value}(X_{\arc_w})$}
      \If{$d\ge d_{\mathrm{sep}}$}
         \State insert $x$, or replace $X_{\arc_w}$ when $|\arc|$ is at
         capacity (credit of the evicted entry resets to 0)
      \ElsIf{$v<\text{value}(X_{\arc_j})$}
         \State replace entry $j$ by $x$
      \EndIf
   \EndIf
\EndIf
\If{candidate $x$ came from route E and improved its reference or the archive}
   \State credit(centre of $x$) $\mathrel{+}=1$
\EndIf
\end{algorithmic}
\end{algorithm}

\subsection{Design rationale}
Three design choices carry the mechanism and are worth stating explicitly
because the ablation tests each of them.
\emph{(i) Verification.} Memory is restricted to positions whose value was
actually measured. This is what allows archive candidates to be generated far
from the current leaders without injecting optimistic bias, and it is the
property that distinguishes the route from a surrogate or from an unverified
swarm memory.
\emph{(ii) Multi-region generation.} The archive is used as a generator, not
merely as an elite list. Single-centre shells exploit a verified basin; segments
between two centres interpolate between verified basins. Together they cover
several regions of the space at once, which is what counters the
leader-driven contraction of GWO on multimodal landscapes. Candidate points
generated in one region are only accepted if they are actually better, so the
mechanism cannot degrade the incumbent by construction.
\emph{(iii) Uniform allocation.} With the allocation fixed and uniform, the
pool has to contain useful candidates by construction; the search cannot
depend on a scheduler that might be tuned to a particular function family.
The boundary experiments in Section~\ref{sec:ablation} confirm that this
simplicity is a feature rather than a limitation: every scheduler tested
against it---including three Q-learning policies---was at best equal to it.

The slot counts of the frozen configuration ($50/12/38$ for G1/G2/E) and the
evaluated subset size $K=10$ were fixed by a pre-registered development scan
on held-out development functions and development seeds, after which the
configuration was frozen and the formal batch was run once, without
re-tuning. Sections~\ref{sec:setup} and \ref{sec:ablation} describe the
protocol and report the negative outcomes of that scan alongside the positive
ones.

\subsection{Computational complexity}
One generation constructs $M=100$ cheap candidates of cost $O(MD)$, selects
$K=10$ of them in $O(M)$, performs $K$ real objective evaluations, and
maintains the archive, whose nearest-neighbour queries cost $O(K|\arc|D)$ with
$|\arc|\le 24$. The arithmetic cost of the search machinery is therefore a few
thousand scalar operations per real evaluation at $D=50$---negligible when
evaluations are expensive, and measurable when they are cheap, which is why
the wall-clock cost at equal budget is reported explicitly in
Section~\ref{sec:results}. Memory is $O(ND+|\arc|D+25)$ and is dominated by
the population matrix. The number of real evaluations per generation is fixed
at $K$ by construction, so the evaluation budget is spent in exactly
$(\mathrm{FE}_{\max}-N)/K$ generations and is never overshot.
"""
with open(os.path.join(OUT,"main.tex"),"a",encoding="utf-8") as f:
    f.write(tex.rstrip()+"\n")
print("chunk 2 appended, chars:", len(tex))
