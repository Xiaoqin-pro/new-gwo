Title: An improved Grey Wolf Optimizer based on mutation operator, evolutionary population dynamics, and nonlinear population size reduction strategy

URL Source: https://www.nature.com/articles/s41598-025-33301-2

Markdown Content:
## Introduction

Optimization problems are ubiquitous in real-world domains[1](https://www.nature.com/articles/s41598-025-33301-2#ref-CR1 "Asif, M. et al. Combined emission economic dispatch using quantum-inspired particle swarm optimization and its variants. Energy Explor. Exploit. 42, 1602–1644 (2024)."),[2](https://www.nature.com/articles/s41598-025-33301-2#ref-CR2 "Singh, N. et al. Novel heuristic optimization technique to solve economic load dispatch and economic emission load dispatch problems. Electronics 12, 2921 (2023)."),[3](https://www.nature.com/articles/s41598-025-33301-2#ref-CR3 "Goel, N. & Yadav, N. K. Sustainable microgrid operations: multi-objective hybrid optimization for combined economic emission dispatch. Electr. Eng. 
                  https://doi.org/10.1007/s00202-024-02912-9
                  
                 (2025)."),[4](https://www.nature.com/articles/s41598-025-33301-2#ref-CR4 "Chun, J. & Huang, P. Integration of engineering optimization in architectural design. J. Archit. Eng. 30, 04024034 (2024)."),[5](https://www.nature.com/articles/s41598-025-33301-2#ref-CR5 "Wang, X. Bighorn sheep optimization algorithm: a novel and efficient approach for wireless sensor network coverage optimization. Phys. Scr. 100, 075230 (2025)."),[6](https://www.nature.com/articles/s41598-025-33301-2#ref-CR6 "Frangedaki, E. et al. Optimisation-driven design in the architecturngineering and construction industry. Proc. Inst. Civil Eng.-Struct. Build. 176, 998–1009 (2023)."),[7](https://www.nature.com/articles/s41598-025-33301-2#ref-CR7 "Silva, B. & Lopes, L. G. GPU acceleration of the GWO optimization algorithm: application to the solution of large nonlinear equation systems. Concurr Comput. -Pract Exp. 37, e70043 (2025)."),[8](https://www.nature.com/articles/s41598-025-33301-2#ref-CR8 "Lu, Z. et al. Dynamic parameter identification of modular robot manipulators based on hybrid optimization strategy: genetic algorithm and least squares method. Soft Comput. 28, 9991–10005 (2024)."),[9](https://www.nature.com/articles/s41598-025-33301-2#ref-CR9 "Xiao, Y., Yin, K., Chen, X., Chen, Z. & Gao, F. Multi-objective optimization design method for the dimensions and control parameters of curling hexapod robot based on application performance. Mech. Mach. Theory. 204, 105831 (2024)."),[10](https://www.nature.com/articles/s41598-025-33301-2#ref-CR10 "Zhang, Y., Bi, Y. & Li, J. Underwater image processing and target detection from particle swarm optimization algorithm. Signal. Image Video Process. 19, 132 (2025)."),[11](https://www.nature.com/articles/s41598-025-33301-2#ref-CR11 "Abdolmaleki, M. & Farahani, B. Sync-GWO: highly private and Bandwidth-Efficient federated learning with a case study in healthcare. IEEE J. Biomed. Health Inf. PP, 1–8 (2025)."), including economic dispatch, robot control, and image processing. However, the growing mathematical complexity of many modern problems can reduce the effectiveness of traditional methods in locating optimal solutions[12](https://www.nature.com/articles/s41598-025-33301-2#ref-CR12 "Sharma, H. et al. Improved Aquila optimizer for swarm-based solutions to complex engineering problems. Sci. Rep. 14, 30714 (2024)."). Consequently, swarm intelligence algorithms have attracted significant attention in recent decades, due to their flexibility, robustness, and ease of implementation, leading to their widespread application in diverse optimization problems[13](https://www.nature.com/articles/s41598-025-33301-2#ref-CR13 "Li, K., Li, S., Huang, Z., Zhang, M. & Xu, Z. Grey Wolf optimization algorithm based on Cauchy-Gaussian mutation and improved search strategy. Sci. Rep. 12, 18961 (2022)."). Swarm intelligence algorithms, which belong to a class of methods inspired by collective behaviors, locate optimal solutions through information exchange and collaborative mechanisms within a population. These algorithms are capable of addressing diverse problem types, including nonlinear, uncertain, multimodal, and high-dimensional problems, as well as multi-objective and dynamic optimization[14](https://www.nature.com/articles/s41598-025-33301-2#ref-CR14 "Tu, B., Wang, F., Huo, Y. & Wang, X. A hybrid algorithm of grey Wolf optimizer and Harris Hawks optimization for solving global optimization problems with improved convergence performance. Sci. Rep. 13, 22909 (2023)."). Many swarm intelligence algorithms have been developed, including Grey Wolf Optimizer (GWO)[15](https://www.nature.com/articles/s41598-025-33301-2#ref-CR15 "Mirjalili, S., Mirjalili, S. M. & Lewis, A. Grey Wolf optimizer. Adv. Eng. Softw. 69, 46–61 (2014)."), Whale Optimization Algorithm (WOA)[16](https://www.nature.com/articles/s41598-025-33301-2#ref-CR16 "Mirjalili, S. & Lewis, A. The Whale optimization algorithm. Adv. Eng. Softw. 95, 51–67 (2016)."), Gyro Fireworks Algorithm (GFA)[17](https://www.nature.com/articles/s41598-025-33301-2#ref-CR17 "Wang, X. Gyro fireworks algorithm: a new metaheuristic algorithm. AIP Adv. 14, 085210 (2024)."), Starling Murmuration Optimizer (SMO)[18](https://www.nature.com/articles/s41598-025-33301-2#ref-CR18 "Zamani, H., Nadimi-Shahraki, M. H. & Gandomi, A. H. Starling murmuration optimizer: a novel bio-inspired algorithm for global and engineering optimization. Comput. Meth Appl. Mech. Eng. 392, 114616 (2022)."), African Vulture Optimization Algorithm (AVOA)[19](https://www.nature.com/articles/s41598-025-33301-2#ref-CR19 "Abdollahzadeh, B., Gharehchopogh, F. S. & Mirjalili, S. African vultures optimization algorithm: a new nature-inspired metaheuristic algorithm for global optimization problems. Comput. Ind. Eng. 158, 107408 (2021)."), Frigatebird Optimizer (FBO)[20](https://www.nature.com/articles/s41598-025-33301-2#ref-CR20 "Wang, X. Frigatebird optimizer: a novel metaheuristic algorithm. Phys. Scr. 99, 125233 (2024)."), Competitive Framework Differential Evolution (CFDE)[21](https://www.nature.com/articles/s41598-025-33301-2#ref-CR21 "Zhong, R. et al. Integrating competitive framework into differential evolution: comprehensive performance analysis and application in brain tumor detection. Appl. Soft Comput. 174, 112995 (2025)."), and Self-Adaptive Competitive Swarm Optimizer (SACSO)[22](https://www.nature.com/articles/s41598-025-33301-2#ref-CR22 "Zhong, R. et al. Self-adaptive competitive swarm optimizer: a memetic approach for global optimization and human-powered aircraft design. Memetic Comp. 17, 32 (2025).").

As a swarm intelligence algorithm modeling wolf pack hunting behavior, GWO has attracted significant research interest due to its structural simplicity, robust convergence, and high accuracy[23](https://www.nature.com/articles/s41598-025-33301-2#ref-CR23 "Faris, H., Aljarah, I., Al-Betar, M. A. & Mirjalili, S. Grey Wolf optimizer: a review of recent variants and applications. Neural Comput. Appl. 30, 413–435 (2018)."). Since its inception, some scholars have proposed variants of GWO to achieve a better balance between exploration and exploitation. Teng et al.[24](https://www.nature.com/articles/s41598-025-33301-2#ref-CR24 "Teng, Z., Lv, J. & Guo, L. An improved hybrid grey Wolf optimization algorithm. Soft Comput. 23, 6617–6631 (2019).") hybridized GWO with PSO. Their method utilizes a Tent chaotic sequence for population initialization to enhance diversity and incorporates the personal best position mechanism from PSO to avoid local optima. Daniel[25](https://www.nature.com/articles/s41598-025-33301-2#ref-CR25 "Daniel, E. Optimum Wavelet-Based homomorphic medical image fusion using hybrid Genetic–Grey Wolf optimization algorithm. IEEE Sens. J. 18, 6804–6811 (2018).") integrated a genetic operator into GWO to improve the performance of the algorithm in terms of both structural and functional information in the fused image. To solve global optimization and engineering design problems, Nadimi-Shahraki et al.[26](https://www.nature.com/articles/s41598-025-33301-2#ref-CR26 "Nadimi-Shahraki, M. H., Taghian, S. & Mirjalili, S. An improved grey Wolf optimizer for solving engineering problems. Expert Syst. Appl. 166, 113917 (2021).") proposed an improved GWO by introducing a dimension learning-based hunting (DLH) search strategy to enhance both global and local search capabilities. Makhadmeh et al.[27](https://www.nature.com/articles/s41598-025-33301-2#ref-CR27 "Makhadmeh, S. N. et al. A novel hybrid grey Wolf optimizer with min-conflict algorithm for power scheduling problem in a smart home. Swarm Evol. Comput. 60, 100793 (2021).") hybridized the min-conflict local search algorithm (MCA) with GWO for the power scheduling problem in a smart home. The MCA was incorporated as an operator within the GWO framework to enhance its exploitation capability. Ahmed et al.[28](https://www.nature.com/articles/s41598-025-33301-2#ref-CR28 "Ahmed, R. et al. Memory, evolutionary operator, and local search based improved grey Wolf optimizer with linear population size reduction technique. Knowl.-Based Syst. 264, 110297 (2023).") proposed a new variant of GWO incorporating memory, evolutionary operators, a stochastic local search technique, and Linear Population Size Reduction (LPSR) strategy to achieve a proper balance between exploitation and exploration during the search for the global optimum.

Furthermore, evolutionary population dynamics (EPD) has proven to be an effective and low-cost method for improving the performance of meta-heuristics. Relatively few studies have employed EPD mechanisms to enhance the performance of GWO. Saremi et al.[29](https://www.nature.com/articles/s41598-025-33301-2#ref-CR29 "Saremi, S., Mirjalili, S. Z. & Mirjalili, S. M. Evolutionary population dynamics and grey Wolf optimizer. Neural Comput. Appl. 26, 1257–1263 (2015).") proposed a variant called GWO-EPD, in which the EPD mechanism relocates underperforming search agents with equal probability near the current best solutions (\(\alpha\), \(\beta\), and \(\delta\)) or random positions within the search space. This mechanism reinitializes the worst search agents at each iteration to maintain diversity among the search agents and further promote exploration and mitigating stagnation at local optima. Rezaei et al.[30](https://www.nature.com/articles/s41598-025-33301-2#ref-CR30 "Rezaei, F. et al. Diversity-Based evolutionary population dynamics: a new operator for grey Wolf optimizer. Processes 10, 2615 (2022).") introduced a novel diversity-based EPD operator. This approach first identifies the three most diverse search agents in each iteration; it then eliminates and repositions half of the best-performing agents around these diverse agents with equal probability. Zhang et al.[31](https://www.nature.com/articles/s41598-025-33301-2#ref-CR31 "Zhang, X., Wang, X., Chen, H., Wang, D. & Fu, Z. Improved GWO for large-scale function optimization and MLP optimization in cancer identification. Neural Comput. Applic. 32, 1305–1325 (2020).") proposed a GWO based on random opposition learning, strengthening hierarchy of grey wolves, and modified EPD. In this method, each agent uses two kinds of updating modes, including a global-best search strategy based on random dimensions and the original search strategies of GWO, to improve the optimization performance. The modified EPD strategy eliminates the worst-performing quartile of agents each iteration and repositions them using one of four random methods, selected with equal probability.

**Table 1 Summary of GWO variants in recent literature; see the text for more discussion.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/1)

The literature review and Table[1](https://www.nature.com/articles/s41598-025-33301-2#Tab1) above summarize the studies on the development and modifications of GWO in recent years. The body of work demonstrates that since its inception, GWO has found successful applications across numerous fields, and its recent variants remain competitive among newer metaheuristics. However, most existing GWO variants primarily rely on a single strategy for updating search agent positions. This strategy coordinates exploitation and exploration through a convergence factor that decreases linearly over iterations, resulting in limited flexibility. Moreover, while EPD can enhance GWO performance, its implementation in previous studies has been rigid. The EPD strategies typically reposition underperforming agents at a fixed ratio or probability, either to areas near the optimal solution or to random positions within the search space. Such static allocation lacks the adaptability needed for the dynamically shifting balance between exploitation and exploration required throughout the iterative process. In general, the pack requires a more dispersed search for prey to avoid premature convergence during the early stages of the optimization process. Conversely, in the later search phases, a more concentrated search is required to locate the optimal solution. To address these limitations, this paper proposes a novel GWO variant incorporating a mutation operator, a modified EPD, and a nonlinear population size reduction (NPSR) strategy. The update process incorporates the mutation operator that functions in two modes. Each search agent updates its position based on the probability that varies with each iteration, operating in either exploration or exploitation mode. Similarly, the proposed EPD employs a probability that varies with the iterative process to allocate underperforming search agents either near the current optimal solution or at random locations within the search space. The proposed mutation operator and EPD operate synergistically to control the dispersion or concentration of the population, thereby dynamically balancing the algorithm’s exploration and exploitation capabilities throughout the optimization process. Furthermore, the NPSR adjusts the population size at each iteration according to a nonlinear function to reduce redundant exploration. The performance of the proposed algorithm is validated through extensive experiments on standard benchmark functions and real-world engineering case studies.

The rest of the paper proceeds as follows. Section ‘‘[Grey wolf optimizer](https://www.nature.com/articles/s41598-025-33301-2#Sec2)’’ provides an overview of the original GWO. Section ‘‘[Proposed algorithm](https://www.nature.com/articles/s41598-025-33301-2#Sec03)’’ introduces the proposed GWO variant. Experiments are conducted, and their results are analyzed in the section ‘‘[Experiment results and analysis](https://www.nature.com/articles/s41598-025-33301-2#Sec9)’’. Finally, conclusion and future work are presented in the section ‘‘[Conclusion and future work](https://www.nature.com/articles/s41598-025-33301-2#Sec005)’’.

## Grey Wolf optimizer

GWO is a swarm intelligence optimization algorithm inspired by the hunting behavior of grey wolves, proposed by Seyedali Mirjalili et al. in 2014[15](https://www.nature.com/articles/s41598-025-33301-2#ref-CR15 "Mirjalili, S., Mirjalili, S. M. & Lewis, A. Grey Wolf optimizer. Adv. Eng. Softw. 69, 46–61 (2014)."). Grey wolves are top predators with unique social hierarchies. Their population structure follows a strict hierarchy, typically conceptualized as a pyramid. The apex level \(\alpha\) represents the dominant leader responsible for group decision-making. The second level \(\beta\) supports \(\alpha\) as an advisor. The third level \(\delta\) follows higher-ranked individuals and directs the lowest tier \(\omega\). This hierarchy enables efficient cooperative hunting, orchestrated primarily by \(\alpha\). Initially, the pack collectively searches for, tracks, and approaches prey. Subsequently, they surround the prey from multiple directions. When the encirclement is sufficiently compact, \(\beta\) and \(\delta\) initiate the attack under \(\alpha\)‘s command. If the prey is not found, the pack dynamically adjusts the encirclement and continues the pursuit until capture occurs.

To solve a continuous function optimization problem using the GWO algorithm, assume that the population size of search agents is _N_, and the dimension of the search space is _D_. The search agent with the optimal fitness is denoted as \(\alpha\). The second and third best are \(\beta\) and \(\delta\), respectively. All others are classified as \(\omega\). The prey’s position represents the estimated global optimum.

During the predation process, _D_ is first calculated according to Eq.([1](https://www.nature.com/articles/s41598-025-33301-2#Equ1)).

$$D=\left| {C \cdot {X_p}\left( t \right) - X\left( t \right)} \right|$$

(1)

Where \({X_p}\left( t \right)\) is the position of the prey at generation _t_, \(X\left( t \right)\) denotes the current position of the search agent at generation _t_, and _C_ is computed as the Eq.([2](https://www.nature.com/articles/s41598-025-33301-2#Equ2)).

$$C=2{r_1}$$

(2)

Where \({r_1} \in \left[ {0,1} \right]\) is a random number.

The position update of search agents depends on Eq.([3](https://www.nature.com/articles/s41598-025-33301-2#Equ3)).

$$X\left( {t+1} \right)={X_p}\left( t \right) - A \cdot D$$

(3)

Where _A_ is the coefficient vector, determined by the Eq.([4](https://www.nature.com/articles/s41598-025-33301-2#Equ4)).

$$A=2a{r_2} - a$$

(4)

Where \({r_2} \in \left[ {0,1} \right]\) is a random number, and _a_ decreases from 2 to 0 throughout iterations.

Upon detecting the prey’s position, \(\alpha\) directs \(\beta\) and \(\delta\) to initiate the hunting process. Within the pack, \(\alpha\), \(\beta\), and \(\delta\) occupy the positions closest to the prey. Their coordinates collectively determine the prey’s estimated location.

$${D_\alpha }=\left| {{C_1} \cdot {X_\alpha }\left( t \right) - X\left( t \right)} \right|$$

(5)

$${D_\beta }=\left| {{C_2} \cdot {X_\beta }\left( t \right) - X\left( t \right)} \right|$$

(6)

$${D_\delta }=\left| {{C_3} \cdot {X_\delta }\left( t \right) - X\left( t \right)} \right|$$

(7)

$${X_1}={X_\alpha } - {A_1} \cdot {D_\alpha }$$

(8)

$${X_2}={X_\beta } - {A_2} \cdot {D_\beta }$$

(9)

$${X_3}={X_\delta } - {A_3} \cdot {D_\delta }$$

(10)

$$X\left( {t+1} \right)=\frac{{{X_1}+{X_2}+{X_3}}}{3}$$

(11)

Where \({A_1}\), \({A_2}\), and \({A_3}\) are analogous to _A_, and \({C_1}\), \({C_2}\), and \({C_3}\) are analogous to _C_. Using Eqs.([5](https://www.nature.com/articles/s41598-025-33301-2#Equ5)) through ([10](https://www.nature.com/articles/s41598-025-33301-2#Equ10)), the distances of the search agents from \(\alpha\), \(\beta\), and \(\delta\) are calculated. Subsequently, the final positions of the search agents are defined by Eq.([11](https://www.nature.com/articles/s41598-025-33301-2#Equ11)).

## Proposed algorithm

Despite existing variants of GWO, slow convergence speed, premature convergence, and exploration-exploitation imbalance are limitations of GWO. To mitigate these limitations, this study develops a GWO variant, called MENGWO, incorporating a mutation operator, an enhanced EPD, and an NPSR strategy. Specifically, the mutation operator dynamically modulates the balance between exploration and exploitation. The enhanced EPD mechanism repositions the underperforming search agents. Concurrently, the NPSR strategy dynamically reduces the computational effort. The integration of these three components is designed to enhance the search performance. Details of each addition to GWO are provided in subsequent sections.

### Mutation operator

The Differential Evolution (DE) algorithm[32](https://www.nature.com/articles/s41598-025-33301-2#ref-CR32 "Storn, R. & Price, K. Differential evolution – a simple and efficient heuristic for global optimization over continuous spaces. J. Global Optim. 11, 341–359 (1997)."), as an evolutionary algorithm, has been widely studied and applied due to its simple principle and few control parameters. The main principle of the DE algorithm is to recombine the population and create a middle generation by exploiting individual variances, and subsequently to create the next generation of the population by exploiting the differences between the parental and offspring individuals.

Inspired by DE, a mutation operator is incorporated into the basic GWO position update process to balance exploration and exploitation capabilities and to avoid local optima. This new updated method, replacing Eq.([11](https://www.nature.com/articles/s41598-025-33301-2#Equ11)), is mathematically expressed as follows.

$$X(t+1)=\left\{ {\begin{array}{*{20}{c}} {\frac{{{X_1}+{X_2}+{X_3}}}{3}+{r_3} \cdot \left( {{X_{rand1}} - {X_{rand2}}} \right)}&{\left| A \right| \geqslant 1} \\ {\frac{{{X_1}+{X_2}+{X_3}}}{3}+B \cdot R \cdot \left( {{X_\alpha } - \frac{{{X_1}+{X_2}+{X_3}}}{3}} \right)}&{\left| A \right|<1} \end{array}} \right.$$

(12)

$$B=\frac{{b \cdot NFE}}{{MaxNFE}}$$

(13)

Where \({r_3} \in \left[ {0,1} \right]\) denotes a random number. \(rand1\) and \(rand2\) are the index numbers of two randomly chosen members of the population, different from the target member. \(NFE\) denotes current function evaluation number. \(MaxNFE\) is the maximum quantity of \(NFE\). _R_ is random vector in \(\left[ {0,1} \right]\). Equation([12](https://www.nature.com/articles/s41598-025-33301-2#Equ12)) switches between two modes based on _A_ from Eq.([4](https://www.nature.com/articles/s41598-025-33301-2#Equ4)). _B_ is a dynamic scaling factor jointly determined by \(NFE\)and _b_. In this study, _b_ is set to 1.5. The detailed parameter analysis is presented in sub-section “Ablation and sensitivity analysis”.

As parameter _a_ decreases linearly from 2 to 0 during iterations, \({\text{a}} \geqslant {\text{1}}\) allows the condition \(\left| {\text{A}} \right| \geqslant {\text{1}}\) to occur in the first half of the search. During this phase, Eq.([12](https://www.nature.com/articles/s41598-025-33301-2#Equ12)) enables each search agent to update its position through a probabilistic selection between exploration and exploitation modes. In exploration mode, the algorithm enhances its search capability by dispersing search agents through the diversity present in the current population. In the second half of the search process, \({\text{a}}<{\text{1}}\) ensures \(\left| {\text{A}} \right|{\text{<1}}\) throughout, shifting Eq.([12](https://www.nature.com/articles/s41598-025-33301-2#Equ12)) into exploitation mode. In this mode, search agents are guided toward the current optimal solution, thereby enhancing the local search capability of the algorithm.

### Evolutionary population dynamics

Evolutionary population dynamics (EPD) is applied in various meta-heuristic algorithms as an efficient method to eliminate the underperforming search agents based on the survival of the fittest[33](https://www.nature.com/articles/s41598-025-33301-2#ref-CR33 "Zhong, C., Li, G., Meng, Z. & He, W. Opposition-based learning equilibrium optimizer with levy flight and evolutionary population dynamics for high-dimensional global optimization problems. Expert Syst. Appl. 215, 119303 (2023)."). The EPD consists of two phases: eliminating the relatively underperforming search agents and repositioning these agents.

At each iteration’s end, sort the fitness values of all search agents, then the underperforming search agents constitute the bottom proportion _k_ of the population size, with \(k \in \left[ {0,1} \right]\). Experiments across various _k_ values indicate optimal efficiency at \(k=0.25\). The analysis of the parameter _k_ is presented in sub-section “Ablation and sensitivity analysis”. The underperforming agents are repositioned via Eq.([14](https://www.nature.com/articles/s41598-025-33301-2#Equ14)).

$$X\left( {t+1} \right)=\left\{ {\begin{array}{*{20}{c}} {X\left( t \right)+\left( {{X_\alpha } - {R_2} \cdot X\left( t \right)} \right)}&{{r_4}<q} \\ {lb+\left( {ub - lb} \right) \cdot {R_3}}&{{r_4} \geqslant q} \end{array}} \right.$$

(14)

Where \({R_2}\) and \({R_3}\) are random vectors in \(\left[ {0,1} \right]\). \({r_4}\) represents a random number in \(\left[ {0,1} \right]\). \(ub\) denotes the upper bound of the search space and \(lb\) denotes the lower bound. _q_ is defined as follows.

$$q={q_{ini}}+\frac{{\left( {{q_{end}} - {q_{ini}}} \right) \cdot NFE}}{{MaxNFE}}$$

(15)

Where _q_ increases linearly from \({q_{ini}}\) to \({q_{end}}\) as \(NFE\) increases, with \(0 \leqslant {q_{ini}} \leqslant {q_{end}} \leqslant 1\). The analysis of the parameter \({q_{ini}}\) and \({q_{end}}\) is presented in sub-section “Ablation and sensitivity analysis”. According to Eq.([14](https://www.nature.com/articles/s41598-025-33301-2#Equ14)), the repositioned search agents are predominantly randomly distributed in the search space to enhance population diversity during the early stage. As \(NFE\) increases, the repositioned search agents gradually converge to the current optimal solution, thereby enhancing local search capability.

### Nonlinear population size reduction

Reduction of population can effectively capture valuable search agent information, reduce unnecessary computational resource consumption, and improve convergence speed[34](https://www.nature.com/articles/s41598-025-33301-2#ref-CR34 "Zhou, B. & Huang, Y. An adaptive archive differential evolution with non-linear population size reduction and selective pressure. Inf. Sci. 682, 121273 (2024)."). This paper proposes a nonlinear population size reduction (NPSR) strategy to control the reduction of population size and minimize redundant exploration.

In each iteration, after ranking search agents according to fitness value, underperforming search agents are eliminated. The population size follows the nonlinear function according to Eq.([16](https://www.nature.com/articles/s41598-025-33301-2#Equ16)).

$${N_{G+1}}=round\left( {{N_0} \cdot \left( {1 - {n_1}{{\left( {\frac{{NFE}}{{MaxNFE}}} \right)}^{{n_2}}}} \right)} \right)$$

(16)

Where the round function is used to round a number to the nearest integer. \({N_{G+1}}\) is the population size of the next generation. \({N_0}\) is the initial population size. \({n_1}\), which satisfies \(0<{n_1}<1\), affects the terminal population size. \({n_2}\) is a nonlinear adjustment coefficient. Specifically, Eq.([16](https://www.nature.com/articles/s41598-025-33301-2#Equ16)) simplifies to a linear function when \({n_2}\) takes the value of 1. In this study, \({n_1}\) and \({n_2}\) are set to 0.8 and 3, respectively. The detailed parameter analysis is presented in sub-section “Ablation and sensitivity analysis”.

**Fig. 1**

Comparison of the population size reduction between NPSR and LPSR.

Figure [1](https://www.nature.com/articles/s41598-025-33301-2#Fig1) shows a comparison of the population size reduction between NPSR and LPSR. During the earlier stage, a slower reduction rate in NPSR helps preserve population diversity, thereby ensuring global search capability. As the search process proceeds, search agents converge around the optimal solution. In the later stage, population size reduction is accelerated to eliminate search agents that are distant from the optimal solution. This strategy conserves computational resources and increases the convergence speed.

### MENGWO algorithm

By embedding all the aforementioned strategies in GWO, the MENGWO algorithm is proposed. The pseudo-code of the MENGWO containing all the strategies is provided in Fig.[2](https://www.nature.com/articles/s41598-025-33301-2#Fig2).

**Fig. 2**

Pseudo-code of the MENGWO algorithm.

Crucially, all three incorporated strategies exhibit mechanisms that vary throughout the iterative process, working synergistically to enhance the algorithm’s exploration and exploitation capabilities.

In the early stages of the search, the population size is reduced slowly, ensuring sufficient search agents for exploration. Concurrently, the update process of the introduced mutation operator updates search agents based on randomly selected agent mutations with a greater probability. Subsequently, the EPD mechanism predominantly relocates underperforming agents to random positions across the search space. Together, these strategies ensure robust exploratory capability.

As the search process proceeds, exploitation mode progressively becomes the dominant method. Correspondingly, the EPD mechanism shifts to repositioning a greater proportion of underperforming agents nearer to the current best solutions. As the search space for local search shrinks, the rate of population size reduction increases. Consequently, the algorithm enhances its exploitation capability while accelerating convergence.

### Computational complexity

This research employs Big-O notation to evaluate the computational complexity of MENGWO[35](https://www.nature.com/articles/s41598-025-33301-2#ref-CR35 "Chen, S. & Zheng, J. A hybrid grey Wolf optimizer for engineering design problems. J. Comb. Optim. 47, 86 (2024)."). The computational complexity is influenced by the population size _N_, the dimension _D_, and \(MaxNFE\). It should be noted that the computational complexity of the fitness function evaluation is \(O(F(D))\). The computational complexity of the basic GWO is \(O(MaxNFE \times F(D)+MaxNFE \times D)\). The computational complexity of MENGWO is detailed in Table [2](https://www.nature.com/articles/s41598-025-33301-2#Tab2). The total computational complexity of the MENGWO is \(O(MaxNFE \times F(D)+MaxNFE \times \log N+MaxNFE \times D)\). Consequently, the proposed algorithm introduces additional computational complexity compared to the basic GWO due to the sorting of fitness values \(O(MaxNFE \times \log N)\).When addressing complex problems, \(O(F(D))\) is often significantly greater than \(O(\log N)\) and \(O(D)\). Under these conditions, the computational complexity of both algorithms becomes \(O(MaxNFE \times F(D))\). Comprehensive performance comparisons in the following section demonstrate that the proposed algorithm significantly enhances GWO’s performance, with only marginal increases in runtime overall. Thus, the substantial performance gains are achieved at an acceptable computational complexity.

**Table 2 Computational complexity of MENGWO.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/2)

## Experiment results and analysis

To ensure the fairness and reasonableness of the experiments, all algorithms are implemented and run on MATLAB (R2020b). The experiments are run on hardware comprising an Intel Core i7-8700 CPU @ 3.20 GHz with 16.0 GB RAM, under the Windows 10 operating system.

### Results on low-dimensional CEC2005

23 benchmark functions from the CEC 2005 special session on real parameter optimization[36](https://www.nature.com/articles/s41598-025-33301-2#ref-CR36 "Suganthan, P. et al. Problem definitions and evaluation criteria for the CEC 2005 special session on Real-Parameter optimization. Natural Comput. 2005, 341–357  (2005).") are selected for experiment as they are widely used to validate the performance of optimization algorithms[37](https://www.nature.com/articles/s41598-025-33301-2#ref-CR37 "Acharya, D. & Das, D. K. A novel human conception optimizer for solving optimization problems. Sci. Rep. 12, 21631 (2022)."),[38](https://www.nature.com/articles/s41598-025-33301-2#ref-CR38 "Ye, Z. et al. Hybrid rice optimization algorithm inspired grey Wolf optimizer for high-dimensional feature selection. Sci. Rep. 14, 30741 (2024)."). These functions can be divided into three groups of functions: unimodal functions (F1-F7), multimodal functions (F8-F13), and fixed-dimension multimodal functions (F14-F23). All benchmark functions are minimization problems. The details of these functions are detailed in Tables [3](https://www.nature.com/articles/s41598-025-33301-2#Tab3) and [4](https://www.nature.com/articles/s41598-025-33301-2#Tab4), and [5](https://www.nature.com/articles/s41598-025-33301-2#Tab5).

**Table 3 Unimodal functions.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/3)

**Table 4 Multimodal functions.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/4)

**Table 5 Fixed-dimension multimodal functions.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/5)

To assess the optimization efficacy of MENGWO, two classical algorithms and five GWO variants are selected for comparison experiments. The chosen algorithms include PSO[39](https://www.nature.com/articles/s41598-025-33301-2#ref-CR39 "Kennedy, J. & Eberhart, R. Particle swarm optimization. In Proceedings of ICNN’95 - International Conference on Neural Networks, vol. 4 1942–1948  (IEEE, 1995)."), GWO[15](https://www.nature.com/articles/s41598-025-33301-2#ref-CR15 "Mirjalili, S., Mirjalili, S. M. & Lewis, A. Grey Wolf optimizer. Adv. Eng. Softw. 69, 46–61 (2014)."), MELGWO[28](https://www.nature.com/articles/s41598-025-33301-2#ref-CR28 "Ahmed, R. et al. Memory, evolutionary operator, and local search based improved grey Wolf optimizer with linear population size reduction technique. Knowl.-Based Syst. 264, 110297 (2023)."), LGWO[40](https://www.nature.com/articles/s41598-025-33301-2#ref-CR40 "Heidari, A. A. & Pahlavani, P. An efficient modified grey Wolf optimizer with Lévy flight for optimization tasks. Appl. Soft Comput. 60, 115–134 (2017)."), AGWO[41](https://www.nature.com/articles/s41598-025-33301-2#ref-CR41 "Qais, M. H., Hasanien, H. M. & Alghuwainem, S. Augmented grey Wolf optimizer for grid-connected PMSG-based wind energy conversion systems. Appl. Soft Comput. 69, 504–515 (2018)."), WVGGWO[42](https://www.nature.com/articles/s41598-025-33301-2#ref-CR42 "Premkumar, M. et al. A reliable optimization framework for parameter identification of single-diode solar photovoltaic model using weighted velocity‐guided grey Wolf optimization algorithm and Lambert‐W function. IET Renew. Power Gener. 17, 2711–2732 (2023)."), and OGWO[43](https://www.nature.com/articles/s41598-025-33301-2#ref-CR43 "Yu, X., Xu, W. & Li, C. Opposition-based learning grey Wolf optimizer for global optimization. Knowledge-Based Syst. 226, 107139 (2021)."). Algorithm parameters, values, and sources are listed in Table [6](https://www.nature.com/articles/s41598-025-33301-2#Tab6).

**Table 6 Parameters of algorithms.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/6)

Identical initial conditions are used for each algorithm. The \(MaxNFE\) is set to 50,000. The population size is set to 30. Each algorithm is executed independently 30 times for each function. All algorithms are ensured to have the same common parameters for the test functions, such as limits, constraints, and dimensions.

The performance indices, including average (Ave) and standard deviation (Std), are summarized in Tables[7](https://www.nature.com/articles/s41598-025-33301-2#Tab7) and [8](https://www.nature.com/articles/s41598-025-33301-2#Tab8), and [9](https://www.nature.com/articles/s41598-025-33301-2#Tab9). Bold values indicate the best performance per benchmark function across all algorithms.

**Table 7 Comparison of tested algorithms for low-dimensional unimodal functions (F1-F7).**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/7)

### Exploitation analysis

Unimodal functions have a single global optimum, which can be used to evaluate the exploitation capability of algorithms. Table[7](https://www.nature.com/articles/s41598-025-33301-2#Tab7) demonstrates the results achieved by the algorithms for seven unimodal functions. GWO and AGWO demonstrate relatively superior performance, each achieving the best average for 2 functions. MENGWO, PSO, and WVGGWO each achieve the best average for 1 function. Regarding standard deviations, AGWO achieves the best standard deviation in 3 cases, PSO and GWO each achieve the best standard deviation in 2 cases, and MENGWO in 1 case. Collectively, no algorithm demonstrates dominant exploitation capability across the 7 unimodal functions, while MENGWO maintains competitiveness in exploitation.

**Table 8 Comparison of tested algorithms for low-dimensional multimodal functions (F8-F13).**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/8)

**Table 9 Comparison of tested algorithms for low-dimensional fixed-dimension multimodal functions (F14-F23).**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/9)

### Exploration analysis

The results of multimodal functions in Table[8](https://www.nature.com/articles/s41598-025-33301-2#Tab8) and fixed-dimension multimodal functions in Table[9](https://www.nature.com/articles/s41598-025-33301-2#Tab9) exhibit multiple local optima. These functions serve as effective tools for assessing the exploration capability and local optima avoidance. As shown in Table[8](https://www.nature.com/articles/s41598-025-33301-2#Tab8), MENGWO achieves the best performance for 4 of the 6 multimodal functions. While PSO attains the best standard deviations for 3 functions, MENGWO’s overall performance in multimodal functions remains highly competitive. Furthermore, Table[9](https://www.nature.com/articles/s41598-025-33301-2#Tab9) demonstrates MENGWO’s superior performance on the fixed-dimension multimodal functions, where it achieves the best average results for all 10 functions and the best standard deviations for 8 of them. In conclusion, MENGWO’s highly competitive results across both multimodal functions and fixed-dimension multimodal functions indicate superior exploration capability and local optima avoidance compared to the other tested algorithms. The enhanced performance can be attributed to the inclusion of its mutation operator and EPD.

Success rate analysis.

Building upon the exploitation and exploration capability assessment, convergence performance is further assessed via the success rate. The success rate is defined as the proportion of the total runs (30 in this case) in which the algorithm obtains an optimal solution within a specified accuracy threshold, defining the maximum allowable error relative to the global optimum. The accuracy threshold is set to \({10^{ - 6}}\) for unimodal functions and \({10^{ - 4}}\) for multimodal functions[28](https://www.nature.com/articles/s41598-025-33301-2#ref-CR28 "Ahmed, R. et al. Memory, evolutionary operator, and local search based improved grey Wolf optimizer with linear population size reduction technique. Knowl.-Based Syst. 264, 110297 (2023)."). A success rate of 1 indicates convergence within the accuracy threshold in all runs, while a rate of 0 indicates failure across all runs.

**Table 10 Comparison of algorithms in terms of success rate.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/10)

Table[10](https://www.nature.com/articles/s41598-025-33301-2#Tab10) lists the success rates of all algorithms for the 23 benchmark functions. For F5-F8, F12, and F20, all algorithms yield a success rate of 0, indicating these functions present significant challenges for the algorithms to solve. By contrast, MENGWO achieves the best performance for all other 17 functions, indicating its superiority from the perspective of success rate.

### Computational effort analysis

Since the main computational effort of the algorithms in solving many optimization problems is typically solving cost functions and constraints, the computational effort index is selected to further assess the convergence performance of the algorithms and quantified by the average \(NFE\) required for successful convergence. A lower average \(NFE\) indicates reduced computational demands. N/A is used to denote that the computational effort index is not applicable in cases where the algorithm fails to reach the required accuracy for any run within the given \(MaxNFE\).

**Table 11 Comparison of algorithms in terms of computational effort.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/11)

Table[11](https://www.nature.com/articles/s41598-025-33301-2#Tab11) presents the computational effort indices obtained by the algorithms. Consistent with the success rate results in Table[10](https://www.nature.com/articles/s41598-025-33301-2#Tab10), for algorithms that failed to converge on specific functions, the computational effort indices are inapplicable, indicating that successful convergence would require additional computational effort. Among the 17 functions where convergence occurred, the MELGWO algorithm achieves the lowest average \(NFE\) among all algorithms for 5 functions, while MENGWO achieves the lowest average \(NFE\) for 8 functions. Hence, the results demonstrate MENGWO’s superior computational efficiency compared to other tested algorithms.

### Convergence analysis

Convergence curves of the 23 benchmark functions obtained by the tested algorithms are plotted to further analyze their convergence properties. The vertical axis represents the average error (over 30 independent runs per function) between the best solution obtained by the algorithm and the theoretical optimal. The horizontal axis represents the \(NFE\) (with an upper limit of 50,000).

**Fig. 3**

Convergence curves for the F1–F4 test functions.

**Fig. 4**

Convergence curves for the F4–F8 test functions.

**Fig. 5**

Convergence curves for the F9–F12 test functions.

**Fig. 6**

Convergence curves for the F13–F16 test functions.

**Fig. 7**

Convergence curves for the F17–F20 test functions.

**Fig. 8**

Convergence curves for the F21–F23 test functions.

Figures[3](https://www.nature.com/articles/s41598-025-33301-2#Fig3), [4](https://www.nature.com/articles/s41598-025-33301-2#Fig4), [5](https://www.nature.com/articles/s41598-025-33301-2#Fig5), [6](https://www.nature.com/articles/s41598-025-33301-2#Fig6), [7](https://www.nature.com/articles/s41598-025-33301-2#Fig7) and [8](https://www.nature.com/articles/s41598-025-33301-2#Fig8) exhibit the convergence curves of the tested algorithms. The figures show the lowest average error achieved by MENGWO for 15 of the 23 functions, and the results are consistent with those in Tables[7](https://www.nature.com/articles/s41598-025-33301-2#Tab7) and [8](https://www.nature.com/articles/s41598-025-33301-2#Tab8), and [9](https://www.nature.com/articles/s41598-025-33301-2#Tab9). Among them, MENGWO demonstrates significantly superior convergence performance compared to the other algorithms for F6, F9, F13-F15, F17, and F21-F23. While MENGWO, PSO, and GWO stand out as the best performers for F16 with comparable convergence results, MENGWO demonstrates marginally superior performance among them. Furthermore, MENGWO achieves the second-best convergence for F5, F8, and F10. Overall, the superior convergence of MENGWO is further demonstrated in the results of the convergence curves.

Among the comparison algorithms, GWO achieves significantly faster convergence than other algorithms for F1 and F2, and yields satisfactory results on F3, F4, F16, and F17. AGWO achieves the best performance for F3, F4, and F10, while achieving second-best results for F1, F2, and F11. WVGGWO achieves superior results for F5 and F8; however, the results for F3, F9, F11, F16, and F20 are unsatisfactory. PSO achieves the best performance for F7 and the second-best performance for F6, F9, F15, and F16. However, it converges to local optima and exhibits poor convergence for F8, F10, F14, and F17 to F23, indicating weaker exploration capability.

### Statistical analysis

This section employs non-parametric statistical methods[44](https://www.nature.com/articles/s41598-025-33301-2#ref-CR44 "Derrac, J., García, S., Molina, D. & Herrera, F. A practical tutorial on the use of nonparametric statistical tests as a methodology for comparing evolutionary and swarm intelligence algorithms. Swarm Evol. Comput. 1, 3–18 (2011)."), the Wilcoxon rank sum test, and the Friedman test, to further validate the performance of the proposed MENGWO algorithm. The Wilcoxon rank sum test is conducted to assess the significance of differences between the proposed algorithm and the selected comparison algorithms. The Friedman test, as a non-parametric method for comparing multiple algorithms, is applied to assess the statistical significance of performance differences across all algorithms and to rank them. The significance level p is set to 0.05.

**Table 12 p-values from the Wilcoxon rank sum test.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/12)

**Table 13 Overall ranks and p-values from the Friedman test.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/13)

The Wilcoxon rank sum test results comparing MENGWO with the other algorithms are presented in Table[12](https://www.nature.com/articles/s41598-025-33301-2#Tab12). For most comparisons, the p-values are below 0.05, the p-values are below the significance level of 0.05, indicating that the performance differences between MENGWO and the other algorithms are statistically significant. Table[13](https://www.nature.com/articles/s41598-025-33301-2#Tab13) lists the ranks of each algorithm and the corresponding p-values for each benchmark function. The low p-values across all functions confirm the statistical significance of the Friedman test results. Furthermore, the results indicate that MENGWO ranks first for 14 of the 23 functions and second for an additional 4 functions. Among the comparison algorithms, GWO ranks first for functions F1 and F2. AGWO obtains the highest rank for F3, F4, F10, and F11. WVGGWO achieves the best rank for F5 and F8. PSO obtains the highest rank for F7. Collectively, the Friedman test results indicate that MENGWO exhibits superior performance, achieving the highest overall rank among the compared algorithms.

### Results on high-dimensional CEC2005

The complexity of solving optimization problems increases significantly with the number of decision variables. Thus, to validate the algorithm’s performance in high-dimensional problems, the dimension of the non-fixed-dimension benchmark functions (F1-F13) is extended from 30 to 100. The algorithms used for comparison remain consistent with those in the previously described experiments. The population size is set to 50, and \(MaxNFE\) is set to 100,000 for the high-dimensional benchmark functions. Each algorithm is executed independently 30 times for each problem.

**Table 14 Comparison of tested algorithms for high-dimensional unimodal functions (F1-F7).**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/14)

Table [14](https://www.nature.com/articles/s41598-025-33301-2#Tab14) presents the results of the algorithms for seven high-dimensional unimodal functions. MENGWO and GWO demonstrate relatively superior performance, each achieving the best average and the best standard deviation for 2 functions. PSO achieves the best average for 1 function and the best standard deviation for 2 functions. AGWO achieves the best average and standard deviation for 1 function. Consistent with the low-dimensional cases, no algorithm demonstrates dominant exploitation capability across all seven high-dimensional unimodal functions, with MENGWO performing comparatively better.

**Table 15 Comparison of tested algorithms for high-dimensional multimodal functions (F8-F13).**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/15)

The results for the high-dimensional multimodal functions in Table 15 show that MENGWO achieves the best average for 4 of the 6 functions and the best standard deviation for 2 functions, indicating its superior performance in handling high-dimensional multimodal functions. Notably, after 100,000 function evaluations, GWO, AGWO, and MENGWO all achieve globally optimal solutions for functions F9 and F11.

In conclusion, MENGWO’s performance on high-dimensional functions is consistent with its performance on low-dimensional functions: it remains competitive for unimodal functions while demonstrating superior capability for multimodal functions.

### Results on CEC2022

To validate the comprehensive performance of the proposed algorithm on complex problems, 12 benchmark functions are selected from the CEC2022 test suite[45](https://www.nature.com/articles/s41598-025-33301-2#ref-CR45 "Kumar, A., Price, K. V., Mohamed, A. W. & Hadi, A. A. Problem definitions and evaluation criteria for the CEC 2022 Special session and competition on single objective bound constrained numerical optimization (2025)."),which features significantly increased complexity and greater alignment with real-world problems compared to the classic CEC2005 benchmarks. The population size and \(MaxNFE\) are set to 100 and 10,000 for 10-dimensional benchmark functions, and to 200 and 20,000 for 20-dimensional functions, respectively. Each algorithm is independently executed 30 times for each function. The details of these benchmark functions are listed in Table [16](https://www.nature.com/articles/s41598-025-33301-2#Tab16).

**Table 16 The details of the CEC2022 benchmark functions.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/16)

**Table 17 Comparison of tested algorithms for 10-dimensional functions. Bold indicates the optimal value.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/17)

**Table 18 Comparison of tested algorithms for 20-dimensional functions.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/18)

Tables[17](https://www.nature.com/articles/s41598-025-33301-2#Tab17) and [18](https://www.nature.com/articles/s41598-025-33301-2#Tab18) present the results for 10-dimensional functions and 20-dimensional functions, respectively. Analysis of both tables reveals that none of the algorithms converge close to the known optimum of F6 within the given \(MaxNFE\). Furthermore, PSO, which is the earliest proposed algorithm among those tested, fails to converge close to the optimum for 10 of 12 functions, underscoring the challenge posed by this benchmark set. In contrast, MENGWO achieves the best average for 6 of 12 10-dimensional functions and 9 of 12 20-dimensional functions. In conclusion, the results on CEC 2022 demonstrate the comprehensive performance of the MENGWO algorithm.

### Results on engineering problems

To validate the practical performance of the proposed algorithm, seven engineering case studies are selected from real-world non-convex constrained optimization problems of CEC 2020[46](https://www.nature.com/articles/s41598-025-33301-2#ref-CR46 "Kumar, A. et al. A test-suite of non-convex constrained optimization problems from the real-world and some baseline results. Swarm Evol. Comput. 56, 100693 (2020)."), including process synthesis, process synthesis and design, process flow sheeting, tension/compression spring design, pressure vessel design, welded beam design, and three-bar truss design. Given that these engineering problems involve multiple constraints, the hard penalty approach[47](https://www.nature.com/articles/s41598-025-33301-2#ref-CR47 "Coello Coello, C. A. Theoretical and numerical constraint-handling techniques used with evolutionary algorithms: a survey of the state of the Art. Comput. Meth. Appl. Mech. Eng. 191, 1245–1287 (2002).") is employed as the constraint handling technique. Consistent with the previous experiment, MENGWO’s performance is compared with that of PSO, GWO, MELGWO, LGWO, AGWO, WVGGWO, and OGWO. The population size is set to 30, and \(MaxNFE\) is set to 50,000 for the seven engineering problems. Each algorithm is executed independently 30 times for each problem. The details of the engineering problems are listed in Table [19](https://www.nature.com/articles/s41598-025-33301-2#Tab19).

**Table 19 The details of the engineering problems.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/19)

**Table 20 Comparison of tested algorithms for engineering problems.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/20)

Table[20](https://www.nature.com/articles/s41598-025-33301-2#Tab20) presents the results of the tested algorithms for the seven engineering problems. MENGWO achieves the best average and standard deviation for 5 of the 7 engineering problems. Among the compared algorithms, PSO obtains the best average in 1 case and the best standard deviation in 2 cases. OGWO achieves the best average in 2 cases, and MENGWO in 1 case. In summary, the results demonstrate the superiority of MENGWO relative to other tested algorithms in solving complex engineering problems.

### Run-time analysis

As established in sub-section “Computational complexity”, the MENGWO algorithm incurs additional computational complexity compared to the traditional GWO. However, when the fitness function evaluation is sufficiently complex, it becomes the dominant cost, causing the overall computational complexities of both algorithms to converge. The run time is the average amount of time it takes to find a solution, which can be used to quantify the practical effect of the additional computational complexity. The run time can be calculated using the following equation[28](https://www.nature.com/articles/s41598-025-33301-2#ref-CR28 "Ahmed, R. et al. Memory, evolutionary operator, and local search based improved grey Wolf optimizer with linear population size reduction technique. Knowl.-Based Syst. 264, 110297 (2023).").

$${R_A}=\frac{1}{M}\sum\limits_{{i=1}}^{M} {RunTim{e_{A,i}}}$$

(17)

Where _M_ and \(RunTim{e_{A,i}}\) indicate the total run number and algorithm A’s computational time for ith run. _M_ is set to 30. The average run time of GWO and MENGWO for several benchmark functions is presented in Table[21](https://www.nature.com/articles/s41598-025-33301-2#Tab21).

**Table 21 Run time (in s) of GWO and MENGWO.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/21)

Table[21](https://www.nature.com/articles/s41598-025-33301-2#Tab21) demonstrates that MEMGWO requires slightly more run time than the basic GWO. This difference is attributable not only to the added computational complexity from sorting operations but also to the integration of the EPD and NPSR mechanisms in each iteration. However, as the complexity of the fitness function evaluation increases, the difference in runtime between MENGWO and GWO diminishes significantly. In summary, for complex problems, the preceding experimental results demonstrate that MENGWO achieves superior performance with runtime comparable to that of the basic GWO.

### Ablation and sensitivity analysis

For MENGWO, improvements involve several parameters that require analysis. To identify parameter impact, sensitivity analysis is conducted based on 23 benchmark functions in Tables[13](https://www.nature.com/articles/s41598-025-33301-2#Tab13), [14](https://www.nature.com/articles/s41598-025-33301-2#Tab14) and [15](https://www.nature.com/articles/s41598-025-33301-2#Tab15). These analyses incorporate ablation tests, implemented by setting parameters controlling specific modules to zero, thereby disabling them. Consistent with previous experiments, the \(MaxNFE\) is set to 50,000. The population size is set to 30. Each algorithm is executed 30 times. The average results of the sensitivity analysis for each parameter are presented in Tables[22](https://www.nature.com/articles/s41598-025-33301-2#Tab22), [23](https://www.nature.com/articles/s41598-025-33301-2#Tab23), [24](https://www.nature.com/articles/s41598-025-33301-2#Tab24), [25](https://www.nature.com/articles/s41598-025-33301-2#Tab25) and [26](https://www.nature.com/articles/s41598-025-33301-2#Tab26).

**Table 22 Comparison results of MENGWO using different \({n_1}\) values.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/22)

Table [22](https://www.nature.com/articles/s41598-025-33301-2#Tab22) provides the results of the sensitivity analysis for \({n_1}\). For F1 and F2, the average results indicate a positive correlation with \({n_1}\). Conversely, the average results for F5, F6, F12, and F13 indicate a negative correlation with \({n_1}\). When \({n_1}=0\), denoting that the NPSR strategy is not applied and the population size is constant, this configuration yields the best values for 4 functions. In comparison, \({n_1}=0.8\) achieves the best results for 16 of the 23 functions, Establishing it as the best value for \({n_1}\) confirming the necessity of the NPSR strategy.

**Table 23 Comparison results of MENGWO using different \({n_2}\) values.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/23)

Table [23](https://www.nature.com/articles/s41598-025-33301-2#Tab23) exhibits the results of the sensitivity analysis for \({n_2}\). The average results decrease as \({n_2}\) increases for F1, F2, F4, and F10. Overall, \({n_2}=3\) proves to be the best value, achieving the best results for 15 of the 23 functions.

**Table 24 Comparison results of MENGWO using different _b_ values.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/24)

Table [24](https://www.nature.com/articles/s41598-025-33301-2#Tab24) shows the results of the sensitivity analysis for _b_. In this context, “origin” denotes the conventional GWO update method in Eq.([11](https://www.nature.com/articles/s41598-025-33301-2#Equ11)), while setting \(b=0\) restricts the application of this method solely to instances where \(\left| A \right|<1\) in Eq.([12](https://www.nature.com/articles/s41598-025-33301-2#Equ12)). While the conventional GWO method yields optimal results for 6 benchmark functions, its performance on multimodal functions is comparatively weaker than that of other parameter settings. In contrast, \(b=1.5\) achieves the best results for 15 of the 23 functions, leading to its selection as the optimal parameter value and confirming the necessity of the proposed update method.

**Table 25 Comparison results of MENGWO using different _k_ values.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/25)

Table [25](https://www.nature.com/articles/s41598-025-33301-2#Tab25) displays the results of the sensitivity analysis for _k_. The values of _k_ are chosen as 0, 0.25, 0.5, and 0.75, where \(k=0\) indicates that the proposed EPD method is not applied. A distinct negative correlation is observed between the average results and the values of _k_ for F1, F2, and F4. Conversely, the average results for F5, F6, F12, and F13 indicate a positive correlation with _k_. Considering the overall performance across all functions, \(k=0.25\) is selected as the best value and confirms the necessity of the proposed EPD method, as it achieves the best results for 12 of the 23 functions.

**Table 26 Comparison results of MENGWO using different \({q_{ini}}\) and \({q_{end}}\) values.**

[Full size table](https://www.nature.com/articles/s41598-025-33301-2/tables/26)

The results of the sensitivity analysis for \({q_{ini}}\) and \({q_{end}}\) are listed in Table[26](https://www.nature.com/articles/s41598-025-33301-2#Tab26). \({q_{ini}}\) and \({q_{end}}\) define the range of _q_. Notably, \({q_{ini}}={q_{end}}=0.5\) indicates that _q_ is fixed at 0.5 without varying with \(NFE\), yielding the best results for 8 functions. In contrast, \({q_{ini}}=0.1\), \({q_{end}}=0.9\) achieves optimal results for 11 of the 23 functions, proving to be the best parameter combination.

## Conclusion and future work

This study establishes that the proposed MENGWO algorithm significantly enhances the performance of the standard GWO framework through the synergistic integration of a mutation operator, an improved EPD mechanism, and an NPSR strategy. These modifications accelerate convergence and promote a more dynamic and effective balance between exploration and exploitation across different phases of the search process. In the early phase, the algorithm maintains population diversity and expands exploration, preventing premature convergence. In the later phase, the focus gradually shifts to intensive local search within promising regions. The NPSR strategy complements this process through efficient computational resource management, maintaining a sufficient population size initially and progressively accelerating its reduction as the search evolves.

To rigorously validate MENGWO, comprehensive comparative analyses are performed with a suite of established and state-of-the-art algorithms, including PSO, GWO, MELGWO, LGWO, AGWO, WVGGWO, and OGWO. The evaluation commences with 23 low-dimensional benchmark functions, where the capability of MENGWO to handle different problem types is thoroughly examined. While MENGWO demonstrates competitive exploitation by achieving the best result for 1 of the 7 unimodal functions, its pronounced capability to escape local optima is evidenced by its performance on multimodal functions. It achieves superior results for 4 of 6 multimodal functions and, most notably, obtains the best results across all 10 fixed-dimension multimodal functions. Evaluations, including success rate, computational effort, convergence properties, Wilcoxon rank-sum test, and Friedman test, further demonstrate its competitive exploitation capability and superior exploration capability. Furthermore, experimental results on 13 high-dimensional benchmark functions demonstrate that MENGWO exhibits superior performance compared to the other algorithms for 2 of 7 unimodal functions and 4 of 6 multimodal functions, consistent with its performance on low-dimensional functions. Additionally, the algorithm achieves the best results for 4 of 7 engineering problems, thereby confirming the practical potential of the MENGWO algorithm in engineering applications.

This study has comprehensively evaluated the MENGWO algorithm using benchmark functions and engineering problems. Although MENGWO enhances the performance of GWO, it incurs additional computational complexity compared to standard GWO due to fitness value sorting operations when solving simpler problems. Future research will focus on reducing this computational complexity. Furthermore, the study demonstrates that MENGWO exhibits greater advantages when addressing complex problems. Future work will therefore focus on further validating the method’s applicability through additional case studies, such as parameter optimization and robotic control, and on assessing its performance on increasingly complex problems.

## Data availability

The datasets generated and/or analyzed during the current study are available from the corresponding author on reasonable request.

## References

1.   Asif, M. et al. Combined emission economic dispatch using quantum-inspired particle swarm optimization and its variants. _Energy Explor. Exploit._**42**, 1602–1644 (2024).

[Article](https://doi.org/10.1177%2F01445987241235419)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BB2cXitFertLvM)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Combined%20emission%20economic%20dispatch%20using%20quantum-inspired%20particle%20swarm%20optimization%20and%20its%20variants&journal=Energy%20Explor.%20Exploit.&doi=10.1177%2F01445987241235419&volume=42&pages=1602-1644&publication_year=2024&author=Asif%2CM)

2.   Singh, N. et al. Novel heuristic optimization technique to solve economic load dispatch and economic emission load dispatch problems. _Electronics_**12**, 2921 (2023).

[Article](https://doi.org/10.3390%2Felectronics12132921)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Novel%20heuristic%20optimization%20technique%20to%20solve%20economic%20load%20dispatch%20and%20economic%20emission%20load%20dispatch%20problems&journal=Electronics&doi=10.3390%2Felectronics12132921&volume=12&publication_year=2023&author=Singh%2CN)

3.   Goel, N. & Yadav, N. K. Sustainable microgrid operations: multi-objective hybrid optimization for combined economic emission dispatch. _Electr. Eng._[https://doi.org/10.1007/s00202-024-02912-9](https://doi.org/10.1007/s00202-024-02912-9) (2025).

[Article](https://link.springer.com/doi/10.1007/s00202-024-02912-9)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Sustainable%20microgrid%20operations%3A%20multi-objective%20hybrid%20optimization%20for%20combined%20economic%20emission%20dispatch&journal=Electr.%20Eng.&doi=10.1007%2Fs00202-024-02912-9&publication_year=2025&author=Goel%2CN&author=Yadav%2CNK)

4.   Chun, J. & Huang, P. Integration of engineering optimization in architectural design. _J. Archit. Eng._**30**, 04024034 (2024).

[Article](https://doi.org/10.1061%2FJAEIED.AEENG-1732)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Integration%20of%20engineering%20optimization%20in%20architectural%20design&journal=J.%20Archit.%20Eng.&doi=10.1061%2FJAEIED.AEENG-1732&volume=30&publication_year=2024&author=Chun%2CJ&author=Huang%2CP)

5.   Wang, X. Bighorn sheep optimization algorithm: a novel and efficient approach for wireless sensor network coverage optimization. _Phys. Scr._**100**, 075230 (2025).

[Article](https://doi.org/10.1088%2F1402-4896%2Fade378)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BB2MXhsVWqtLbE)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2025PhyS..100g5230W)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Bighorn%20sheep%20optimization%20algorithm%3A%20a%20novel%20and%20efficient%20approach%20for%20wireless%20sensor%20network%20coverage%20optimization&journal=Phys.%20Scr.&doi=10.1088%2F1402-4896%2Fade378&volume=100&publication_year=2025&author=Wang%2CX)

6.   Frangedaki, E. et al. Optimisation-driven design in the architecturngineering and construction industry. _Proc. Inst. Civil Eng.-Struct. Build._**176**, 998–1009 (2023).

7.   Silva, B. & Lopes, L. G. GPU acceleration of the GWO optimization algorithm: application to the solution of large nonlinear equation systems. _Concurr Comput. -Pract Exp._**37**, e70043 (2025).

[Article](https://doi.org/10.1002%2Fcpe.70043)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=GPU%20acceleration%20of%20the%20GWO%20optimization%20algorithm%3A%20application%20to%20the%20solution%20of%20large%20nonlinear%20equation%20systems&journal=Concurr%20Comput.%20-Pract%20Exp.&doi=10.1002%2Fcpe.70043&volume=37&publication_year=2025&author=Silva%2CB&author=Lopes%2CLG)

8.   Lu, Z. et al. Dynamic parameter identification of modular robot manipulators based on hybrid optimization strategy: genetic algorithm and least squares method. _Soft Comput._**28**, 9991–10005 (2024).

[Article](https://link.springer.com/doi/10.1007/s00500-024-09846-1)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Dynamic%20parameter%20identification%20of%20modular%20robot%20manipulators%20based%20on%20hybrid%20optimization%20strategy%3A%20genetic%20algorithm%20and%20least%20squares%20method&journal=Soft%20Comput.&doi=10.1007%2Fs00500-024-09846-1&volume=28&pages=9991-10005&publication_year=2024&author=Lu%2CZ)

9.   Xiao, Y., Yin, K., Chen, X., Chen, Z. & Gao, F. Multi-objective optimization design method for the dimensions and control parameters of curling hexapod robot based on application performance. _Mech. Mach. Theory_. **204**, 105831 (2024).

[Article](https://doi.org/10.1016%2Fj.mechmachtheory.2024.105831)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Multi-objective%20optimization%20design%20method%20for%20the%20dimensions%20and%20control%20parameters%20of%20curling%20hexapod%20robot%20based%20on%20application%20performance&journal=Mech.%20Mach.%20Theory&doi=10.1016%2Fj.mechmachtheory.2024.105831&volume=204&publication_year=2024&author=Xiao%2CY&author=Yin%2CK&author=Chen%2CX&author=Chen%2CZ&author=Gao%2CF)

10.   Zhang, Y., Bi, Y. & Li, J. Underwater image processing and target detection from particle swarm optimization algorithm. _Signal. Image Video Process._**19**, 132 (2025).

[Article](https://link.springer.com/doi/10.1007/s11760-024-03638-8)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Underwater%20image%20processing%20and%20target%20detection%20from%20particle%20swarm%20optimization%20algorithm&journal=Signal.%20Image%20Video%20Process.&doi=10.1007%2Fs11760-024-03638-8&volume=19&publication_year=2025&author=Zhang%2CY&author=Bi%2CY&author=Li%2CJ)

11.   Abdolmaleki, M. & Farahani, B. Sync-GWO: highly private and Bandwidth-Efficient federated learning with a case study in healthcare. _IEEE J. Biomed. Health Inf._**PP**, 1–8 (2025).

[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Sync-GWO%3A%20highly%20private%20and%20Bandwidth-Efficient%20federated%20learning%20with%20a%20case%20study%20in%20healthcare&journal=IEEE%20J.%20Biomed.%20Health%20Inf.&volume=PP&pages=1-8&publication_year=2025&author=Abdolmaleki%2CM&author=Farahani%2CB)

12.   Sharma, H. et al. Improved Aquila optimizer for swarm-based solutions to complex engineering problems. _Sci. Rep._**14**, 30714 (2024).

[Article](https://doi.org/10.1038%2Fs41598-024-79577-8)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BB2MXnsl2isQ%3D%3D)[PubMed](http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=39730432)[PubMed Central](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC11680820)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2024NatSR..1430714S)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Improved%20Aquila%20optimizer%20for%20swarm-based%20solutions%20to%20complex%20engineering%20problems&journal=Sci.%20Rep.&doi=10.1038%2Fs41598-024-79577-8&volume=14&publication_year=2024&author=Sharma%2CH)

13.   Li, K., Li, S., Huang, Z., Zhang, M. & Xu, Z. Grey Wolf optimization algorithm based on Cauchy-Gaussian mutation and improved search strategy. _Sci. Rep._**12**, 18961 (2022).

[Article](https://doi.org/10.1038%2Fs41598-022-23713-9)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BB38XivVOisrrL)[PubMed](http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=36348083)[PubMed Central](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC9643465)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2022NatSR..1218961L)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Grey%20Wolf%20optimization%20algorithm%20based%20on%20Cauchy-Gaussian%20mutation%20and%20improved%20search%20strategy&journal=Sci.%20Rep.&doi=10.1038%2Fs41598-022-23713-9&volume=12&publication_year=2022&author=Li%2CK&author=Li%2CS&author=Huang%2CZ&author=Zhang%2CM&author=Xu%2CZ)

14.   Tu, B., Wang, F., Huo, Y. & Wang, X. A hybrid algorithm of grey Wolf optimizer and Harris Hawks optimization for solving global optimization problems with improved convergence performance. _Sci. Rep._**13**, 22909 (2023).

[Article](https://doi.org/10.1038%2Fs41598-023-49754-2)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BB2cXnslE%3D)[PubMed](http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=38129472)[PubMed Central](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC10739963)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2023NatSR..1322909T)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20hybrid%20algorithm%20of%20grey%20Wolf%20optimizer%20and%20Harris%20Hawks%20optimization%20for%20solving%20global%20optimization%20problems%20with%20improved%20convergence%20performance&journal=Sci.%20Rep.&doi=10.1038%2Fs41598-023-49754-2&volume=13&publication_year=2023&author=Tu%2CB&author=Wang%2CF&author=Huo%2CY&author=Wang%2CX)

15.   Mirjalili, S., Mirjalili, S. M. & Lewis, A. Grey Wolf optimizer. _Adv. Eng. Softw._**69**, 46–61 (2014).

[Article](https://doi.org/10.1016%2Fj.advengsoft.2013.12.007)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Grey%20Wolf%20optimizer&journal=Adv.%20Eng.%20Softw.&doi=10.1016%2Fj.advengsoft.2013.12.007&volume=69&pages=46-61&publication_year=2014&author=Mirjalili%2CS&author=Mirjalili%2CSM&author=Lewis%2CA)

16.   Mirjalili, S. & Lewis, A. The Whale optimization algorithm. _Adv. Eng. Softw._**95**, 51–67 (2016).

[Article](https://doi.org/10.1016%2Fj.advengsoft.2016.01.008)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=The%20Whale%20optimization%20algorithm&journal=Adv.%20Eng.%20Softw.&doi=10.1016%2Fj.advengsoft.2016.01.008&volume=95&pages=51-67&publication_year=2016&author=Mirjalili%2CS&author=Lewis%2CA)

17.   Wang, X. Gyro fireworks algorithm: a new metaheuristic algorithm. _AIP Adv._**14**, 085210 (2024).

[Article](https://doi.org/10.1063%2F5.0213886)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2024AIPA...14h5210W)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Gyro%20fireworks%20algorithm%3A%20a%20new%20metaheuristic%20algorithm&journal=AIP%20Adv.&doi=10.1063%2F5.0213886&volume=14&publication_year=2024&author=Wang%2CX)

18.   Zamani, H., Nadimi-Shahraki, M. H. & Gandomi, A. H. Starling murmuration optimizer: a novel bio-inspired algorithm for global and engineering optimization. _Comput. Meth Appl. Mech. Eng._**392**, 114616 (2022).

[Article](https://doi.org/10.1016%2Fj.cma.2022.114616)[MathSciNet](http://www.ams.org/mathscinet-getitem?mr=4379773)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Starling%20murmuration%20optimizer%3A%20a%20novel%20bio-inspired%20algorithm%20for%20global%20and%20engineering%20optimization&journal=Comput.%20Meth%20Appl.%20Mech.%20Eng.&doi=10.1016%2Fj.cma.2022.114616&volume=392&publication_year=2022&author=Zamani%2CH&author=Nadimi-Shahraki%2CMH&author=Gandomi%2CAH)

19.   Abdollahzadeh, B., Gharehchopogh, F. S. & Mirjalili, S. African vultures optimization algorithm: a new nature-inspired metaheuristic algorithm for global optimization problems. _Comput. Ind. Eng._**158**, 107408 (2021).

[Article](https://doi.org/10.1016%2Fj.cie.2021.107408)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=African%20vultures%20optimization%20algorithm%3A%20a%20new%20nature-inspired%20metaheuristic%20algorithm%20for%20global%20optimization%20problems&journal=Comput.%20Ind.%20Eng.&doi=10.1016%2Fj.cie.2021.107408&volume=158&publication_year=2021&author=Abdollahzadeh%2CB&author=Gharehchopogh%2CFS&author=Mirjalili%2CS)

20.   Wang, X. Frigatebird optimizer: a novel metaheuristic algorithm. _Phys. Scr._**99**, 125233 (2024).

[Article](https://doi.org/10.1088%2F1402-4896%2Fad8e0e)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BB2cXisFCrurnO)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2024PhyS...99l5233W)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Frigatebird%20optimizer%3A%20a%20novel%20metaheuristic%20algorithm&journal=Phys.%20Scr.&doi=10.1088%2F1402-4896%2Fad8e0e&volume=99&publication_year=2024&author=Wang%2CX)

21.   Zhong, R. et al. Integrating competitive framework into differential evolution: comprehensive performance analysis and application in brain tumor detection. _Appl. Soft Comput._**174**, 112995 (2025).

[Article](https://doi.org/10.1016%2Fj.asoc.2025.112995)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Integrating%20competitive%20framework%20into%20differential%20evolution%3A%20comprehensive%20performance%20analysis%20and%20application%20in%20brain%20tumor%20detection&journal=Appl.%20Soft%20Comput.&doi=10.1016%2Fj.asoc.2025.112995&volume=174&publication_year=2025&author=Zhong%2CR)

22.   Zhong, R. et al. Self-adaptive competitive swarm optimizer: a memetic approach for global optimization and human-powered aircraft design. _Memetic Comp._**17**, 32 (2025).

[Article](https://link.springer.com/doi/10.1007/s12293-025-00465-3)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Self-adaptive%20competitive%20swarm%20optimizer%3A%20a%20memetic%20approach%20for%20global%20optimization%20and%20human-powered%20aircraft%20design&journal=Memetic%20Comp.&doi=10.1007%2Fs12293-025-00465-3&volume=17&publication_year=2025&author=Zhong%2CR)

23.   Faris, H., Aljarah, I., Al-Betar, M. A. & Mirjalili, S. Grey Wolf optimizer: a review of recent variants and applications. _Neural Comput. Appl._**30**, 413–435 (2018).

[Article](https://link.springer.com/doi/10.1007/s00521-017-3272-5)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Grey%20Wolf%20optimizer%3A%20a%20review%20of%20recent%20variants%20and%20applications&journal=Neural%20Comput.%20Appl.&doi=10.1007%2Fs00521-017-3272-5&volume=30&pages=413-435&publication_year=2018&author=Faris%2CH&author=Aljarah%2CI&author=Al-Betar%2CMA&author=Mirjalili%2CS)

24.   Teng, Z., Lv, J. & Guo, L. An improved hybrid grey Wolf optimization algorithm. _Soft Comput._**23**, 6617–6631 (2019).

[Article](https://link.springer.com/doi/10.1007/s00500-018-3310-y)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=An%20improved%20hybrid%20grey%20Wolf%20optimization%20algorithm&journal=Soft%20Comput.&doi=10.1007%2Fs00500-018-3310-y&volume=23&pages=6617-6631&publication_year=2019&author=Teng%2CZ&author=Lv%2CJ&author=Guo%2CL)

25.   Daniel, E. Optimum Wavelet-Based homomorphic medical image fusion using hybrid Genetic–Grey Wolf optimization algorithm. _IEEE Sens. J._**18**, 6804–6811 (2018).

[Article](https://doi.org/10.1109%2FJSEN.2018.2822712)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2018ISenJ..18.6804D)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Optimum%20Wavelet-Based%20homomorphic%20medical%20image%20fusion%20using%20hybrid%20Genetic%E2%80%93Grey%20Wolf%20optimization%20algorithm&journal=IEEE%20Sens.%20J.&doi=10.1109%2FJSEN.2018.2822712&volume=18&pages=6804-6811&publication_year=2018&author=Daniel%2CE)

26.   Nadimi-Shahraki, M. H., Taghian, S. & Mirjalili, S. An improved grey Wolf optimizer for solving engineering problems. _Expert Syst. Appl._**166**, 113917 (2021).

[Article](https://doi.org/10.1016%2Fj.eswa.2020.113917)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=An%20improved%20grey%20Wolf%20optimizer%20for%20solving%20engineering%20problems&journal=Expert%20Syst.%20Appl.&doi=10.1016%2Fj.eswa.2020.113917&volume=166&publication_year=2021&author=Nadimi-Shahraki%2CMH&author=Taghian%2CS&author=Mirjalili%2CS)

27.   Makhadmeh, S. N. et al. A novel hybrid grey Wolf optimizer with min-conflict algorithm for power scheduling problem in a smart home. _Swarm Evol. Comput._**60**, 100793 (2021).

[Article](https://doi.org/10.1016%2Fj.swevo.2020.100793)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20novel%20hybrid%20grey%20Wolf%20optimizer%20with%20min-conflict%20algorithm%20for%20power%20scheduling%20problem%20in%20a%20smart%20home&journal=Swarm%20Evol.%20Comput.&doi=10.1016%2Fj.swevo.2020.100793&volume=60&publication_year=2021&author=Makhadmeh%2CSN)

28.   Ahmed, R. et al. Memory, evolutionary operator, and local search based improved grey Wolf optimizer with linear population size reduction technique. _Knowl.-Based Syst._**264**, 110297 (2023).

[Article](https://doi.org/10.1016%2Fj.knosys.2023.110297)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Memory%2C%20evolutionary%20operator%2C%20and%20local%20search%20based%20improved%20grey%20Wolf%20optimizer%20with%20linear%20population%20size%20reduction%20technique&journal=Knowl.-Based%20Syst.&doi=10.1016%2Fj.knosys.2023.110297&volume=264&publication_year=2023&author=Ahmed%2CR)

29.   Saremi, S., Mirjalili, S. Z. & Mirjalili, S. M. Evolutionary population dynamics and grey Wolf optimizer. _Neural Comput. Appl._**26**, 1257–1263 (2015).

[Article](https://link.springer.com/doi/10.1007/s00521-014-1806-7)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Evolutionary%20population%20dynamics%20and%20grey%20Wolf%20optimizer&journal=Neural%20Comput.%20Appl.&doi=10.1007%2Fs00521-014-1806-7&volume=26&pages=1257-1263&publication_year=2015&author=Saremi%2CS&author=Mirjalili%2CSZ&author=Mirjalili%2CSM)

30.   Rezaei, F. et al. Diversity-Based evolutionary population dynamics: a new operator for grey Wolf optimizer. _Processes_**10**, 2615 (2022).

[Article](https://doi.org/10.3390%2Fpr10122615)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Diversity-Based%20evolutionary%20population%20dynamics%3A%20a%20new%20operator%20for%20grey%20Wolf%20optimizer&journal=Processes&doi=10.3390%2Fpr10122615&volume=10&publication_year=2022&author=Rezaei%2CF)

31.   Zhang, X., Wang, X., Chen, H., Wang, D. & Fu, Z. Improved GWO for large-scale function optimization and MLP optimization in cancer identification. _Neural Comput. Applic_. **32**, 1305–1325 (2020).

[Article](https://link.springer.com/doi/10.1007/s00521-019-04483-4)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Improved%20GWO%20for%20large-scale%20function%20optimization%20and%20MLP%20optimization%20in%20cancer%20identification&journal=Neural%20Comput.%20Applic&doi=10.1007%2Fs00521-019-04483-4&volume=32&pages=1305-1325&publication_year=2020&author=Zhang%2CX&author=Wang%2CX&author=Chen%2CH&author=Wang%2CD&author=Fu%2CZ)

32.   Storn, R. & Price, K. Differential evolution – a simple and efficient heuristic for global optimization over continuous spaces. _J. Global Optim._**11**, 341–359 (1997).

[Article](https://doi.org/10.1023%2FA%3A1008202821328)[MathSciNet](http://www.ams.org/mathscinet-getitem?mr=1479553)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Differential%20evolution%20%E2%80%93%20a%20simple%20and%20efficient%20heuristic%20for%20global%20optimization%20over%20continuous%20spaces&journal=J.%20Global%20Optim.&doi=10.1023%2FA%3A1008202821328&volume=11&pages=341-359&publication_year=1997&author=Storn%2CR&author=Price%2CK)

33.   Zhong, C., Li, G., Meng, Z. & He, W. Opposition-based learning equilibrium optimizer with levy flight and evolutionary population dynamics for high-dimensional global optimization problems. _Expert Syst. Appl._**215**, 119303 (2023).

[Article](https://doi.org/10.1016%2Fj.eswa.2022.119303)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Opposition-based%20learning%20equilibrium%20optimizer%20with%20levy%20flight%20and%20evolutionary%20population%20dynamics%20for%20high-dimensional%20global%20optimization%20problems&journal=Expert%20Syst.%20Appl.&doi=10.1016%2Fj.eswa.2022.119303&volume=215&publication_year=2023&author=Zhong%2CC&author=Li%2CG&author=Meng%2CZ&author=He%2CW)

34.   Zhou, B. & Huang, Y. An adaptive archive differential evolution with non-linear population size reduction and selective pressure. _Inf. Sci._**682**, 121273 (2024).

[Article](https://doi.org/10.1016%2Fj.ins.2024.121273)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=An%20adaptive%20archive%20differential%20evolution%20with%20non-linear%20population%20size%20reduction%20and%20selective%20pressure&journal=Inf.%20Sci.&doi=10.1016%2Fj.ins.2024.121273&volume=682&publication_year=2024&author=Zhou%2CB&author=Huang%2CY)

35.   Chen, S. & Zheng, J. A hybrid grey Wolf optimizer for engineering design problems. _J. Comb. Optim._**47**, 86 (2024).

[Article](https://link.springer.com/doi/10.1007/s10878-024-01189-9)[MathSciNet](http://www.ams.org/mathscinet-getitem?mr=4768643)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20hybrid%20grey%20Wolf%20optimizer%20for%20engineering%20design%20problems&journal=J.%20Comb.%20Optim.&doi=10.1007%2Fs10878-024-01189-9&volume=47&publication_year=2024&author=Chen%2CS&author=Zheng%2CJ)

36.   Suganthan, P. et al. Problem definitions and evaluation criteria for the CEC 2005 special session on Real-Parameter optimization. _Natural Comput._**2005**, 341–357 (2005).

37.   Acharya, D. & Das, D. K. A novel human conception optimizer for solving optimization problems. _Sci. Rep._**12**, 21631 (2022).

[Article](https://doi.org/10.1038%2Fs41598-022-25031-6)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BB38XjtFart7rP)[PubMed](http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=36517488)[PubMed Central](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC9751073)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2022NatSR..1221631A)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20novel%20human%20conception%20optimizer%20for%20solving%20optimization%20problems&journal=Sci.%20Rep.&doi=10.1038%2Fs41598-022-25031-6&volume=12&publication_year=2022&author=Acharya%2CD&author=Das%2CDK)

38.   Ye, Z. et al. Hybrid rice optimization algorithm inspired grey Wolf optimizer for high-dimensional feature selection. _Sci. Rep._**14**, 30741 (2024).

[Article](https://doi.org/10.1038%2Fs41598-024-80648-z)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BB2MXnvVSjtA%3D%3D)[PubMed](http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=39730449)[PubMed Central](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC11680854)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2024NatSR..1430741Y)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Hybrid%20rice%20optimization%20algorithm%20inspired%20grey%20Wolf%20optimizer%20for%20high-dimensional%20feature%20selection&journal=Sci.%20Rep.&doi=10.1038%2Fs41598-024-80648-z&volume=14&publication_year=2024&author=Ye%2CZ)

39.   Kennedy, J. & Eberhart, R. Particle swarm optimization. In _Proceedings of ICNN’95 - International Conference on Neural Networks, vol. 4_ 1942–1948 (IEEE, 1995).

40.   Heidari, A. A. & Pahlavani, P. An efficient modified grey Wolf optimizer with Lévy flight for optimization tasks. _Appl. Soft Comput._**60**, 115–134 (2017).

[Article](https://doi.org/10.1016%2Fj.asoc.2017.06.044)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=An%20efficient%20modified%20grey%20Wolf%20optimizer%20with%20L%C3%A9vy%20flight%20for%20optimization%20tasks&journal=Appl.%20Soft%20Comput.&doi=10.1016%2Fj.asoc.2017.06.044&volume=60&pages=115-134&publication_year=2017&author=Heidari%2CAA&author=Pahlavani%2CP)

41.   Qais, M. H., Hasanien, H. M. & Alghuwainem, S. Augmented grey Wolf optimizer for grid-connected PMSG-based wind energy conversion systems. _Appl. Soft Comput._**69**, 504–515 (2018).

[Article](https://doi.org/10.1016%2Fj.asoc.2018.05.006)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Augmented%20grey%20Wolf%20optimizer%20for%20grid-connected%20PMSG-based%20wind%20energy%20conversion%20systems&journal=Appl.%20Soft%20Comput.&doi=10.1016%2Fj.asoc.2018.05.006&volume=69&pages=504-515&publication_year=2018&author=Qais%2CMH&author=Hasanien%2CHM&author=Alghuwainem%2CS)

42.   Premkumar, M. et al. A reliable optimization framework for parameter identification of single-diode solar photovoltaic model using weighted velocity‐guided grey Wolf optimization algorithm and Lambert‐W function. _IET Renew. Power Gener_. **17**, 2711–2732 (2023).

[Article](https://doi.org/10.1049%2Frpg2.12792)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20reliable%20optimization%20framework%20for%20parameter%20identification%20of%20single-diode%20solar%20photovoltaic%20model%20using%20weighted%20velocity%E2%80%90guided%20grey%20Wolf%20optimization%20algorithm%20and%20Lambert%E2%80%90W%20function&journal=IET%20Renew.%20Power%20Gener&doi=10.1049%2Frpg2.12792&volume=17&pages=2711-2732&publication_year=2023&author=Premkumar%2CM)

43.   Yu, X., Xu, W. & Li, C. Opposition-based learning grey Wolf optimizer for global optimization. _Knowledge-Based Syst._**226**, 107139 (2021).

[Article](https://doi.org/10.1016%2Fj.knosys.2021.107139)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Opposition-based%20learning%20grey%20Wolf%20optimizer%20for%20global%20optimization&journal=Knowledge-Based%20Syst.&doi=10.1016%2Fj.knosys.2021.107139&volume=226&publication_year=2021&author=Yu%2CX&author=Xu%2CW&author=Li%2CC)

44.   Derrac, J., García, S., Molina, D. & Herrera, F. A practical tutorial on the use of nonparametric statistical tests as a methodology for comparing evolutionary and swarm intelligence algorithms. _Swarm Evol. Comput._**1**, 3–18 (2011).

[Article](https://doi.org/10.1016%2Fj.swevo.2011.02.002)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20practical%20tutorial%20on%20the%20use%20of%20nonparametric%20statistical%20tests%20as%20a%20methodology%20for%20comparing%20evolutionary%20and%20swarm%20intelligence%20algorithms&journal=Swarm%20Evol.%20Comput.&doi=10.1016%2Fj.swevo.2011.02.002&volume=1&pages=3-18&publication_year=2011&author=Derrac%2CJ&author=Garc%C3%ADa%2CS&author=Molina%2CD&author=Herrera%2CF)

45.   Kumar, A., Price, K. V., Mohamed, A. W. & Hadi, A. A. Problem definitions and evaluation criteria for the CEC 2022 Special session and competition on single objective bound constrained numerical optimization (2025).

46.   Kumar, A. et al. A test-suite of non-convex constrained optimization problems from the real-world and some baseline results. _Swarm Evol. Comput._**56**, 100693 (2020).

[Article](https://doi.org/10.1016%2Fj.swevo.2020.100693)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20test-suite%20of%20non-convex%20constrained%20optimization%20problems%20from%20the%20real-world%20and%20some%20baseline%20results&journal=Swarm%20Evol.%20Comput.&doi=10.1016%2Fj.swevo.2020.100693&volume=56&publication_year=2020&author=Kumar%2CA)

47.   Coello Coello, C. A. Theoretical and numerical constraint-handling techniques used with evolutionary algorithms: a survey of the state of the Art. _Comput. Meth. Appl. Mech. Eng._**191**, 1245–1287 (2002).

[Article](https://doi.org/10.1016%2FS0045-7825%2801%2900323-1)[MathSciNet](http://www.ams.org/mathscinet-getitem?mr=1877684)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2002CMAME.191.1245C)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Theoretical%20and%20numerical%20constraint-handling%20techniques%20used%20with%20evolutionary%20algorithms%3A%20a%20survey%20of%20the%20state%20of%20the%20Art&journal=Comput.%20Meth.%20Appl.%20Mech.%20Eng.&doi=10.1016%2FS0045-7825%2801%2900323-1&volume=191&pages=1245-1287&publication_year=2002&author=Coello%20Coello%2CCA)

[Download references](https://citation-needed.springer.com/v2/references/10.1038/s41598-025-33301-2?format=refman&flavour=references)

## Funding

No funding.

## Author information

### Authors and Affiliations

1.   School of Aeronautics and Astronautics, Zhejiang University, Hangzhou, 310027, China

Yufei Zhang,Tao Li,Hua Yang&Weifang Chen

Authors

1.   Yufei Zhang
2.   Tao Li
3.   Hua Yang
4.   Weifang Chen

### Contributions

Y. Z.: Hypothesis, Method, and Methodology, Original-drafting. T. L. and H.Y. Review and Correction. W. C: Supervision.

### Corresponding author

Correspondence to [Hua Yang](mailto:yhsaa@zju.edu.cn).

## Ethics declarations

### Competing interests

The authors declare no competing interests.

## Additional information

### Publisher’s note

Springer Nature remains neutral with regard to jurisdictional claims in published maps and institutional affiliations.

## Rights and permissions

**Open Access** This article is licensed under a Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License, which permits any non-commercial use, sharing, distribution and reproduction in any medium or format, as long as you give appropriate credit to the original author(s) and the source, provide a link to the Creative Commons licence, and indicate if you modified the licensed material. You do not have permission under this licence to share adapted material derived from this article or parts of it. The images or other third party material in this article are included in the article’s Creative Commons licence, unless indicated otherwise in a credit line to the material. If material is not included in the article’s Creative Commons licence and your intended use is not permitted by statutory regulation or exceeds the permitted use, you will need to obtain permission directly from the copyright holder. To view a copy of this licence, visit [http://creativecommons.org/licenses/by-nc-nd/4.0/](http://creativecommons.org/licenses/by-nc-nd/4.0/).

[Reprints and permissions](https://s100.copyright.com/AppDispatchServlet?title=An%20improved%20Grey%20Wolf%20Optimizer%20based%20on%20mutation%20operator%2C%20evolutionary%20population%20dynamics%2C%20and%20nonlinear%20population%20size%20reduction%20strategy&author=Yufei%20Zhang%20et%20al&contentID=10.1038%2Fs41598-025-33301-2&copyright=The%20Author%28s%29&publication=2045-2322&publicationDate=2025-12-23&publisherName=SpringerNature&orderBeanReset=true&oa=CC%20BY-NC-ND)

## About this article

[![Image 1: Check for updates. Verify currency and authenticity via CrossMark](blob:http://localhost/df43c82f6cb6dcd2a87db38f317bf9f2)](https://crossmark.crossref.org/dialog/?doi=10.1038/s41598-025-33301-2)

### Cite this article

Zhang, Y., Li, T., Yang, H. _et al._ An improved Grey Wolf Optimizer based on mutation operator, evolutionary population dynamics, and nonlinear population size reduction strategy. _Sci Rep_**16**, 3351 (2026). https://doi.org/10.1038/s41598-025-33301-2

[Download citation](https://citation-needed.springer.com/v2/references/10.1038/s41598-025-33301-2?format=refman&flavour=citation)

*   Received: 30 June 2025

*   Accepted: 17 December 2025

*   Published: 23 December 2025

*   Version of record: 26 January 2026

*   DOI: https://doi.org/10.1038/s41598-025-33301-2

### Keywords

