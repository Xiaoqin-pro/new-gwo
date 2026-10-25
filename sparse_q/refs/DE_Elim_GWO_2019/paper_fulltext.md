Title: An Improved Grey Wolf Optimizer Based on Differential Evolution and Elimination Mechanism

URL Source: https://www.nature.com/articles/s41598-019-43546-3

Markdown Content:
## Introduction

The swarm intelligence algorithms are proposed to mimic the swarm intelligence behavior of biological in nature, which has become a hot of cross-discipline and research field in recent years. The appearance of swarm intelligent optimization algorithm provides the fast and reliable methods for finding solutions on many complex problems[1](https://www.nature.com/articles/s41598-019-43546-3#ref-CR1 "Derrac, J., García, S. & Molina, D. A practical tutorial on the use of non-parametric statistical tests as a methodology for comparing evolutionary and swarm intelligence algorithms. J. Swarm and Evolutionary Computation. 1, 3–18 (2011)."),[2](https://www.nature.com/articles/s41598-019-43546-3#ref-CR2 "Cui, Z. H. & Gao, X. Z. Theory and applications of swarm intelligence. J. Neural Computing and Applications. 21, 205–206 (2012)."). Because the swarm intelligence algorithm have characteristics of self-organization, parallel, distributive, flexibility and robustness, now they have been very widespread used in many cases, such as electric power system, communication network, system identification and parameter estimation, robot control, transportation and other practical engineering problems[3](https://www.nature.com/articles/s41598-019-43546-3#ref-CR3 "Zhang, Z. et al. On swarm intelligence inspired self-organized networking: its bionic mechanisms, designing principles and optimization approaches. J. Communications Surveys & Tutorials IEEE. 16, 513–537 (2014)."),[4](https://www.nature.com/articles/s41598-019-43546-3#ref-CR4 "Leboucher, C. et al. A swarm intelligence method combined to evolutionary game theory applied to the resources allocation problem. J. International Journal of Swarm Intelligence Research (IJSIR). 3, 20–38 (2012)."),[5](https://www.nature.com/articles/s41598-019-43546-3#ref-CR5 "Parpinelli, R. S. & Lopes, H. S. New inspirations in swarm intelligence: a survey. J. International Journal of Bio-Inspired Computation. 3, 1–16 (2011)."). Therefore, the research on the swarm intelligence optimization algorithms has an important academic value and practical significance.

At present, a variety of swarm intelligence optimization algorithms have been proposed by simulating the biotic population and evolution process in nature, such as particle swarm optimization (PSO) algorithm, shuffled frog leaping algorithm (SFLA), artificial bee colony (ABC) algorithm, ant colony optimization (ACO) algorithm, biogeography-based optimization (BBO) algorithm, and cuckoo search (CS) algorithm. Particle Swarm Optimization (PSO) algorithm put forward by Kennedy and Eberhart to mimic the the foraging behavior of birds and fish flock[6](https://www.nature.com/articles/s41598-019-43546-3#ref-CR6 "Kennedy, J. & Eberhart R. Particle swarm optimization, in Neural Networks, 1995. Proceedings., IEEE International Conference on. pp. 1942–1948 (1995)."), but the convergence velocity and searching accuracy of PSO algorithm are unsatisfactory to some extend. Shuffled Frog-leaping Algorithm (SFLA) put forward by Eusuff in 2003 is a novel swarm intelligent cooperative searching strategy based on the natural memetics[7](https://www.nature.com/articles/s41598-019-43546-3#ref-CR7 "Ebrahimi, J., Hosseinian, S. H. & Gharehpetian, G. B. Unit commitment problem solution using shuffled frog leaping algorithm. J. Power Systems, IEEE Transactions on. 26, 573–581 (2011)."),[8](https://www.nature.com/articles/s41598-019-43546-3#ref-CR8 "Fang, C. & Wang, L. An effective shuffled frog-leaping algorithm for resource-constrained project scheduling problem. J. Computers & Operations Research. 39, 890–901 (2012)."). On the one hand, individuals exchange information in the global searching process, and its search precision is high. On the other hand, SFLA has the disadvantage of slow convergence velocity and easy to falling into the local optimum. Artificial Bee Colony (ABC) Algorithm put forward by Karaboga in 2005 to mimics the finding food source behavior of bees[9](https://www.nature.com/articles/s41598-019-43546-3#ref-CR9 "Karaboga, D. & Basturk, B. On the performance of artificial bee colony (ABC) algorithm. J. Applied soft computing. 8, 687–697 (2008)."). In order to mimic the social behavior of the ant colony, Dorigo _et al_. Proposed the an novel Ant Colony Optimization (ACO) Algorithm in 2006[10](https://www.nature.com/articles/s41598-019-43546-3#ref-CR10 "Dorigo, M., Birattari, M. & Stutzle, T. Ant colony optimization. IEEE Computational Intelligence Magazine 1, 28–39 (2006)."). But their disadvantages are the slow convergence speed and easy to premature. Biogeography-Based Optimization (BBO) algorithm was put forward by Simon in 2008[11](https://www.nature.com/articles/s41598-019-43546-3#ref-CR11 "Simon, D. Biogeography-based optimization. Evolutionary Computation, IEEE Transactions on 12, 702–713 (2008)."), whose idea is based on the geographical distribution principle in the biogeography. Cuckoo Search (CS) Algorithm was proposed by Yang and Deb in 2009 based on the cuckoo’s parasitic reproduction mechanism and Levy flights searching strategy[12](https://www.nature.com/articles/s41598-019-43546-3#ref-CR12 "Yang, X. S. & Deb, S. Cuckoo search via Lévy flights. A. Proceedings of World Congress on Nature & Biologically Inspired Computing. C. IEEE Publications. USA, 210–214 (2009)."),[13](https://www.nature.com/articles/s41598-019-43546-3#ref-CR13 "Mirjalili, S., Wang, G.-G., dos, L. & Coelho, S. Binary optimization using hybrid particle swarm optimization and gravitational search algorithm. J. Neural Computing and Applications. 25, 1423–1435 (2014)."), whose advantage is that CS algorithm is not easy to fall into the local optimum compared with other intelligent algorithms and has less parameters, and whose disadvantage is that the adding of Levy Flight search mechanism leads to strong leap in the process of search, thus, its local search is not careful.

The common shortcoming of these algorithms is that each swarm intelligence algorithm has problem in different degrees that the convergence velocity is slow, the optimization precision is low, and easy to fall into the local optimum[5](https://www.nature.com/articles/s41598-019-43546-3#ref-CR5 "Parpinelli, R. S. & Lopes, H. S. New inspirations in swarm intelligence: a survey. J. International Journal of Bio-Inspired Computation. 3, 1–16 (2011)."). The key reason cause these shortcoming is that whether an algorithm is able to achieve the proper compromise between exploration and exploitation in its each searching phase or not[14](https://www.nature.com/articles/s41598-019-43546-3#ref-CR14 "Črepinšek, M., Liu, S. H. & Marjan, M. Exploration and exploitation in evolutionary algorithms: a survey. ACM Comput. Surv. 45, 1–33 (2013)."). Exploration and exploration are contradictory. Exploration reflects the ability of the algorithm to search for new space, while exploration reflects the refining ability of the algorithm. These two criteria are generally used to evaluate stochastic optimization algorithms. Exploration is refers to that a particle leave the original search path in a certain extent and search towards a new direction, which reflects the ability of exploiting unknown regions. Exploitation is refers to that a particle continue to search more carefully on the original trajectory in a certain extent, which can insure the wolf make a detailed search to the region that have been explored. Too small exploration can cause a premature convergence and falling into a local optimum, however, too small exploitation will make the algorithm converge too slowly.

The grey wolf optimizer (GWO) as a novel swarm intelligent optimization algorithm was put forward by Seyedali Mirjalili etc in 2014, which mainly mimics wolf leadership hierarchy and hunting mechanism in nature[15](https://www.nature.com/articles/s41598-019-43546-3#ref-CR15 "Mirjalili, S., Mirjalili, S. M. & Lewis, A. Grey wolf optimizer. J. Advances in Engineering Software. 69, 46–61 (2014)."). Seyedali and Mirjalili etc has proved that the optimization performance of standard GWO is superior to that of PSO, GSA, DE and FEP algorithm. Due to the wolves algorithm with the advantages of simple in principle, fast seeking speed, high search precision, and easy to realize, it is more easily combined with the practical engineering problems. Therefore, GWO has high theoretical research value. But GWO is as a new biological intelligence algorithm, the research about it is just at the initial phase, so research and development of the theory are still not perfect. In order to make the algorithm plays a more superior performance, further exploration and research is needed.

Many swarm intelligence algorithms are mimic the hunting and searching behaviors of some animals. However, GWO simulates internal leadership hierarchy of wolves, thus, in the searching process the position of best solution can be comprehensively assessed by three solutions. But for other swarm intelligence algorithms, the best solution is searched only leaded by a single solution. So GWO can greatly decrease the probability of premature and falling into the local optimum. So as to achieve the proper compromise between exploration and exploitation, an improved GWO with evolution and elimination mechanism is proposed. The biological evolution and the SOF principle of biological updating of nature are added to the basic wolf algorithm. In order to verify the performance of the improved GWO, 12 typical benchmark functions are adopted to carry out simulation experiments, meanwhile, experimental results are compared with PSO algorithm, ABC algorithm and CS algorithm. The experimental results show that the improved grey wolf optimizer (IGWO) obtains the better convergence velocity and optimization accuracy.

The paper is organized as follows. In section 2, the grey wolf optimizer is introduced. A grey wolf optimizer with evolution and SOF mechanism is presented in section 3. In section 4, the simulation experiments are carried out and the simulation results are analyzed in details. Finally, the conclusion illustrates the last part.

## Grey Wolf Optimizer

The grey wolf optimizer is a novel heuristic swarm intelligent optimization algorithm proposed by Seyedali Mirjalili _et al_. in 2014. The wolf as top predators in the food chain, has a strong ability to capture prey. Wolves generally like social life and in the interior of the wolves exists a rigid social hierarchy[15](https://www.nature.com/articles/s41598-019-43546-3#ref-CR15 "Mirjalili, S., Mirjalili, S. M. & Lewis, A. Grey wolf optimizer. J. Advances in Engineering Software. 69, 46–61 (2014).").

In order to mimic wolves internal leadership hierarchy, the wolves is divided into four types of wolf: _alpha, beta, delta_ and _omega_, where the best individual, second best individual and third best individual are recorded as _alpha, beta_, and _delta, and_ the rest of the individuals are considered as _omega_. In the GWO, the hunting (optimization) is guided by _alpha, beta_, and _delta_[8](https://www.nature.com/articles/s41598-019-43546-3#ref-CR8 "Fang, C. & Wang, L. An effective shuffled frog-leaping algorithm for resource-constrained project scheduling problem. J. Computers & Operations Research. 39, 890–901 (2012)."). They guide other wolves (_W_) tend to the best area in searching space. In iterative searching process, the possible position of prey is assessed by three wolves _alpha, beta_, and _delta_. In optimization process, the locations of wolves are updated based on Eqs ([1](https://www.nature.com/articles/s41598-019-43546-3#Equ1)) and ([2](https://www.nature.com/articles/s41598-019-43546-3#Equ2)).

$$\overrightarrow{D}=|\overrightarrow{C}\cdot \overrightarrow{{X}_{P}}(t)-\overrightarrow{X}(t)|$$

(1)

$$\overrightarrow{X}(t+1)=\overrightarrow{{X}_{P}}(t)-\overrightarrow{A}\cdot \overrightarrow{D}$$

(2)

where, _t_ represents the _t_-th iteration, \(\overrightarrow{A}\) and \(\overrightarrow{C}\) are coefficient vector, \(\overrightarrow{{X}_{P}}\) is the position vector of prey, \(\overrightarrow{X}\) represents the wolf position. The vector \(\overrightarrow{A}\) and \(\overrightarrow{C}\) can be expressed by:

$$\overrightarrow{A}=2a\cdot \overrightarrow{{r}_{1}}-\overrightarrow{a}$$

(3)

$$\overrightarrow{C}=2\cdot \overrightarrow{{r}_{2}}$$

(4)

where, the coefficient \(\overrightarrow{a}\) linearly decreases from 2 to 0 with the increasing of iteration number, \(\overrightarrow{{r}_{1}}\) and \(\overrightarrow{{r}_{2}}\) are random vector located in the scope [0, 1].

Principle of the position updating rules described in Eqs ([1](https://www.nature.com/articles/s41598-019-43546-3#Equ1)) and ([2](https://www.nature.com/articles/s41598-019-43546-3#Equ2)) are shown in Fig.[1](https://www.nature.com/articles/s41598-019-43546-3#Fig1). It can be seen from Fig.[1](https://www.nature.com/articles/s41598-019-43546-3#Fig1) the wolf at the position (_X_, _Y_) can relocate itself position around the prey according to above updating formulas. Although Fig.[1](https://www.nature.com/articles/s41598-019-43546-3#Fig1) only shows 7 positions that the wolf possible move to, by adjusting the random parameters C and A it can make the wolf to relocate itself to any position in the continuous space near prey. In the GWO, it always assumes that position of alpha, beta and delta is likely to be the prey (optimum) position. In the iteration searching process, the best individual, second best individual and third best individual obtained so far are respectively recorded as _alpha, beta_, and _delta. H_ owever, other wolves who are regarded as omega relocate their locations according to the locations of _alpha, beta_, and _delta_. The following mathematical formulas are used to re-adjust positions of the wolf _omega_. The conceptual model that wolf update its position is shown in Fig.[2](https://www.nature.com/articles/s41598-019-43546-3#Fig2).

$${\overrightarrow{D}}_{\alpha }=|\overrightarrow{{C}_{1}}\cdot \overrightarrow{{X}_{\alpha }}-\overrightarrow{X}|$$

(5)

$${\overrightarrow{D}}_{\beta }=|\overrightarrow{{C}_{2}}\cdot \overrightarrow{{X}_{\beta }}-\overrightarrow{X}|$$

(6)

$${\overrightarrow{D}}_{\delta }=|\overrightarrow{{C}_{3}}\cdot \overrightarrow{{X}_{\delta }}-\overrightarrow{X}|$$

(7)

where, \(\overrightarrow{{X}_{\alpha }}\), \(\overrightarrow{{X}_{\beta }}\) and \(\overrightarrow{{X}_{\delta }}\) are the position vector of _alpha, beta_, and _delta_, respectively. \(\overrightarrow{{C}_{1}}\), \(\overrightarrow{{C}_{2}}\), \(\overrightarrow{{C}_{3}}\) are randomly generated vectors, \(\overrightarrow{X}\) represents the position vector of current individual. The Eqs ([5](https://www.nature.com/articles/s41598-019-43546-3#Equ5)), ([6](https://www.nature.com/articles/s41598-019-43546-3#Equ6)) and ([7](https://www.nature.com/articles/s41598-019-43546-3#Equ7)) respectively calculate the distances between the position of current individual and that of individual _alpha, beta_, and _delta_. So the final position vectors of the current individual are calculated by:

$$\overrightarrow{{X}_{1}}=\overrightarrow{{X}_{\alpha }}-\overrightarrow{{A}_{1}}\cdot (\overrightarrow{{D}_{\alpha }})$$

(8)

$$\overrightarrow{{X}_{2}}=\overrightarrow{{X}_{\beta }}-\overrightarrow{{A}_{2}}\cdot (\overrightarrow{{D}_{\beta }})$$

(9)

$$\overrightarrow{{X}_{3}}=\overrightarrow{{X}_{\delta }}-\overrightarrow{{A}_{3}}\cdot (\overrightarrow{{D}_{\delta }})$$

(10)

$$\overrightarrow{X}(t+1)=\frac{\overrightarrow{{X}_{1}}+\overrightarrow{{X}_{2}}+\overrightarrow{{X}_{3}}}{3}$$

(11)

where, \(\overrightarrow{{A}_{1}}\), \(\overrightarrow{{A}_{2}}\), \(\overrightarrow{{A}_{3}}\) are randomly generated vectors, and _t_ represents the number of iterations.

**Figure 1**

2D position vectors and possible next locations.

**Figure 2**

Position updating of IGWO.

In the plane, three points is able to determine a region. Thus, the scope of position of the prey can be determined by the best three wolves. The GWO that whose target solution is comprehensively assessed by three solutions, can greatly decrease the probability of trapping into the local extreme.

It can be seen from the above formula that Eqs ([5](https://www.nature.com/articles/s41598-019-43546-3#Equ5)–[7](https://www.nature.com/articles/s41598-019-43546-3#Equ7)) respectively define the step size of the omega tend to alpha, beta, and delta. The final positions of the omega wolves are defined by Eqs ([8](https://www.nature.com/articles/s41598-019-43546-3#Equ8)–[11](https://www.nature.com/articles/s41598-019-43546-3#Equ11)).

The exploration ability and exploitation ability have important influence on the searching performance of an algorithm. For the GWO, exploration is refers to a wolf leave the original search path in a certain extent and search towards a new direction, which reflects the wolf’s ability of exploiting unknown regions. Exploitation is refers to that a wolf continue to search more carefully on the original trajectory in a certain extent, which can insure the wolf make a detailed search to the region that have been explored. So how to make the algorithm achieve a proper compromise between exploration and exploitation is a question that worth research.

It can be observed that the two random and adaptive vectors \(\overrightarrow{A}\) and \(\overrightarrow{C}\) can be used to obtain a proper compromise between exploration ability and exploitation ability of the GWO. As is shown in Fig.[3](https://www.nature.com/articles/s41598-019-43546-3#Fig3), when \(\overrightarrow{A}\) is greater than 1 and is less than −1, that is \(|\overrightarrow{A}| > 1\), the wolf shows exploration ability. When the value of vector \(\overrightarrow{C}\) is greater than 1, it can also enhance the exploration ability of the wolf. In contrast, when \(|\overrightarrow{A}| < 1\) and _C_< 1 the wolf’s exploitation capacity is enhanced. For increasing the exploitation ability of the wolf gradually, the vector \(\overrightarrow{A}\) decreases linearly with the iterations number increasing. However, in the course of optimization the value of \(\overrightarrow{C}\) is generated randomly, which can make exploration and exploitation of the wolf reach a equilibrium at any stage. Especially in the final stages of the iteration, it is able to avoid the algorithm from trapping into a local extreme. The pseudo codes of the GWO are described as follows.

**Figure 3**

Exploration and exploitation of wolf in GWO.

Initialize the population _X_ _i_(_i_ = 1, 2, … _n_) of GWO

Initialize GWO parameters (_a_, A, C)

Calculate the individual fitness value in the population

Record the best individual, second best individual and third best individual as \(\overrightarrow{{X}_{\alpha }}\), \(\overrightarrow{{X}_{\beta }}\) and \(\overrightarrow{{X}_{\delta }}\)

While (_t_< maximum iteration number)

For each individual

Update the position of current individual by Eqs ([5](https://www.nature.com/articles/s41598-019-43546-3#Equ5)–[11](https://www.nature.com/articles/s41598-019-43546-3#Equ11))

End for

Update _a_, A, C

Calculate the fitness value of all individual in the population

Update \(\overrightarrow{{X}_{\alpha }}\), \(\overrightarrow{{X}_{\beta }}\), \(\overrightarrow{{X}_{\delta }}\)

_t_ = _t_ + 1

End While

Return \(\overrightarrow{{X}_{\alpha }}\)

The GWO has strong exploration ability, which can avoid the algorithm falling into the local optimum. For the GWO, the proper compromise between exploration ability and exploitation ability is very simple to be achieved, so it can effectively solve many complicated problems.

## Improved Grey Wolf Optimizer (IGWO)

For increasing the search performance of the GWO, an improved grey wolf optimizer (IGWO) is proposed. In the IGWO, the biological evolution and the SOF principle of biological updating of nature are added to the standard GWO. Due to the differential evolution algorithm having the advantages of simple principle, less algorithm parameters and easy implementation, differential evolution (DE) strategy is chose as the evolutionary pattern of wolves in this paper. The wolf pack is updated according to the SOF principle so as to make the algorithm not fall into the local optimum. That is, after each iteration of the algorithm sort the fitness value that corresponds to each wolf by ascending order, and then eliminate R wolves with larger fitness value, meanwhile randomly generate wolves that equal to the number of eliminated wolves.

### Grey Wolf Optimizer with evolution operation

In nature, organisms evolve from the low level to advanced level continually under the action of heredity, selection and mutation[16](https://www.nature.com/articles/s41598-019-43546-3#ref-CR16 "Brambilla, M. et al. Swarm robotics: a review from the swarm engineering perspective. J. Swarm Intelligence. 7, 1–41 (2013)."),[17](https://www.nature.com/articles/s41598-019-43546-3#ref-CR17 "Liao, J. et al. A neighbor decay cellular automata approach for simulating urban expansion based on particle swarm intelligence. J. International Journal of Geographical Information Science. 28, 720–738 (2014)."). Similarly, there are also a series of changes like heredity, selection and mutation in the searching process of the wolves. The evolution law of SOF make wolves gradually strong. In the same way, for increasing the searching performance of the algorithm, the evolution operation is added to basic GWO. Based on the biological evolution of nature, many evolution methods have been developed, such as differential evolution(DE), quantum evolution and cooperative evolution, etc.[18](https://www.nature.com/articles/s41598-019-43546-3#ref-CR18 "Das, S. & Suganthan, P. N. Differential evolution: a survey of the state-of-the-art. J. Evolutionary Computation, IEEE Transactions on. 15, 4–31 (2011)."). For all the evolution methods, the differential evolution strategy has simple principle, less parameters and easy implementation and it has been extensively researched and applied[19](https://www.nature.com/articles/s41598-019-43546-3#ref-CR19 "Palmer, Katie et al. Differential Evolution of Cognitive Impairment in Nondemented Older Persons: Results From the Kungsholmen Project. J. Psychiatry. 159, 436–442 (2014)."),[20](https://www.nature.com/articles/s41598-019-43546-3#ref-CR20 "Agrawal, R. et al. Parallelization of industrial process control program based on the technique of differential evolution using multi-threading[C]//Industrial Engineering and Engineering Management (IEEM), 2014 IEEE International Conference on. IEEE, 546–550 (2014)."). Therefore, the DE strategy is chose as the evolution method of GWO. The basic principle of DE operator is to adopt the difference among individuals to recombine the population and obtain intermediate individuals, and then get the next generation population through a competition between parent individual and offspring individual[21](https://www.nature.com/articles/s41598-019-43546-3#ref-CR21 "Islam, S. M. et al. An adaptive differential evolution algorithm with novel mutation and crossover strategies for global numerical optimization. J. Systems, Man, and Cybernetics, Part B: Cybernetics, IEEE Transactions on. 42, 482–500 (2012)."),[22](https://www.nature.com/articles/s41598-019-43546-3#ref-CR22 "Zheng, Y. J. et al. A hybrid fireworks optimization method with differential evolution operators. J. Neurocomputing. 148, 75–82 (2015)."). The basic operations of DE include three operations: mutation, crossover and selection. After the operation of evolution is added to GWO, the wolf’s position updating is shown as Fig.[2](https://www.nature.com/articles/s41598-019-43546-3#Fig2).

#### Mutation operation

The most prominent feature of differential evolution is mutation operation. When an individual is selected, two differences with weight are added to the individual to accomplish its variation[23](https://www.nature.com/articles/s41598-019-43546-3#ref-CR23 "Zhang, P., Wei, Y. X. & Xue, H. Q. Heterogeneous Multiple Colonies Ant Colony Algorithm Based on Survival of Fittest Rules. J. Computer Engineering. 38, 182–185 (2012)."). The basic variation ingredient of DE is the difference vector of the parents, and each vector contains two different individuals \(({X}_{r1}^{t},{X}_{r2}^{t})\) of parent (the _t-th_ generation). The difference vector is defined as follows.

$${\rm{D}}{d}_{r12}={X}_{r1}^{t}-{X}_{r2}^{t}$$

(12)

where, _r_ 1 and _r_ 2 express index number of two different individuals of the population. Thus the mutation operation can be described as:

$${V}_{i}^{t+1}={X}_{r3}^{t}+F\ast ({X}_{r1}^{t}-{X}_{r2}^{t})$$

(13)

where, _r_ 1, _r_ 2 and _r_ 3 are different integers in the scope (1, 2, … _n_) from the current target vector index _i_. F is the scaling factor to control the scaling of differential vector.

In order to produce an ideal variation factor, to ensure that wolves can evolve toward the direction that good for development of the wolves. So in this paper, chooses outstanding individuals of wolves as parents. After a large number of simulation experiments, beta and delta are chose as two parents, and then combined with the alpha wolf to form a variation factor. Therefore, the variation factor is designed as Eq. ([14](https://www.nature.com/articles/s41598-019-43546-3#Equ14)).

$${V}_{i}^{t+1}={X}_{\alpha }^{t}+F\ast ({X}_{\beta }^{t}-{X}_{\delta }^{t})$$

(14)

In order to make the algorithm has a high exploration ability in the early stage to avoid falling into local optimum, and has a high exploitation ability in the latter stage to increase the convergence speed, a dynamic scaling factor is employed. So scaling factor _F_ change from large to small according to the iteration number in Eq. ([15](https://www.nature.com/articles/s41598-019-43546-3#Equ15)).

$${\rm{F}}={f}_{{\rm{\min }}}+({f}_{{\rm{\max }}}-{f}_{{\rm{\min }}})\times \frac{Max\_iter-(iter-1)}{Max\_iter}$$

(15)

where, _f_ min and _f_ max are the minimum and maximum of the scaling factor, _Max_ _ _iter_ is maximum iteration number. _iter_ is the _iter_-th iteration number.

#### Crossover operation

For the target vector individual \({X}_{i}^{t}\) of the wolves, make it have a crossover operation with the variation vector \({V}_{i}^{t+1}\), and produce a test individual \({U}_{i}^{t+1}\). In order to guarantee the individual \({X}_{i}^{t}\) taking place a evolution, a random choice method is adopt to insure at least one bit of \({U}_{i}^{t+1}\) is contributed by \({U}_{i}^{t+1}\). For other bits of \({U}_{i}^{t+1}\), the crossover probability factor CR is used to decide which bit of \({U}_{i}^{t+1}\) is contributed by \({V}_{i}^{t+1}\), and which bit is contributed by \({X}_{i}^{t}\). Crossover operation is express as follows.

$${U}_{ij}^{t+1}=\{\begin{array}{cc}{V}_{ij}^{t+1} & rand(j)\le CR\,or\,j=randn(i)\\ {X}_{ij} & rand(j)\ge CR\,and\,j\ne randn(i)\end{array}\,j=1,2,\cdots ,D$$

(16)

where, _rand_(_j_) ∈ [0, 1] obeys the random-uniform distribution, _j_ is the _j_-th variable (gene), _CR_ is crossover probability, and _rand_(_i_) ∈ [1, 2, … D].

It can be known from the Eq. ([16](https://www.nature.com/articles/s41598-019-43546-3#Equ16)), if the _CR_ is larger, \({V}_{i}^{t+1}\) is able to make more contribution to \({U}_{i}^{t+1}\). When _CR_ = 1, \({U}_{i}^{t+1}={V}_{i}^{t+1}\). If the _CR_ is smaller, \({X}_{i}^{t}\) is able to make more contribution to \({U}_{i}^{t+1}\).

#### Selection operation

The “greedy choice” strategy is applied to the selection operation. After mutation operation and crossover operation generate the experiment individual \({U}_{i}^{t+1}\) and the compete it with \({X}_{i}^{t}\). It can be expressed as Eq. ([17](https://www.nature.com/articles/s41598-019-43546-3#Equ17)).

$${X}_{i}^{t+1}=\{\begin{array}{c}{U}_{i}^{t+1},\\ {X}_{i}^{t},\end{array}\,\begin{array}{c}f({U}_{i}^{t+1}) < f({X}_{i}^{t})\\ f({U}_{i}^{t+1})\ge f({X}_{i}^{t})\end{array}\,\,i=1,2,\cdots \,n$$

(17)

where, _f_ is the fitness function, \({X}_{i}^{t+1}\) is the individual of _t_-th generation. from \({U}_{i}^{t+1}\) and \({X}_{i}^{t}\) choose the individual with best fitness as an individual of _(t_ + _1)-_ generation, and replace the individual of the _t-th_ generation.

In the early stages of the algorithm, difference of the population is large, so mutation operation makes the algorithm has strong exploration ability. In the later stages of the algorithm iteration, namely when the algorithm tends to converge, difference between individuals of the population is small, which makes the algorithm has a strong exploitation ability.

### SOF wolves updating mechanism

SOF is a role of nature that formed in the process of the biological evolution[23](https://www.nature.com/articles/s41598-019-43546-3#ref-CR23 "Zhang, P., Wei, Y. X. & Xue, H. Q. Heterogeneous Multiple Colonies Ant Colony Algorithm Based on Survival of Fittest Rules. J. Computer Engineering. 38, 182–185 (2012)."),[24](https://www.nature.com/articles/s41598-019-43546-3#ref-CR24 "Eyler, C. E. & Rich, J. N. Survival of the fittest: cancer stem cells in therapeutic resistance and angiogenesis. J. Journal of Clinical Oncology. 26, 2839–2845 (2008)."),[25](https://www.nature.com/articles/s41598-019-43546-3#ref-CR25 "Whitley, D. An executable model of a simple genetic algorithm. J. Foundations of genetic algorithms. 2, 45–62 (2014)."). In nature, some vulnerable wolves will be eliminated because of uneven distribution of the prey, hunger, disease and other reasons. Meanwhile, new wolves will join to this wolf organization to enhance fighting capacity of the organization, which can insure the wolf organization survival well in the complicated world. The wolf pack is updated according to the SOF principle so as to make the algorithm not fall into the local optimum[26](https://www.nature.com/articles/s41598-019-43546-3#ref-CR26 "Vidal, T. et al. A hybrid genetic algorithm with adaptive diversity management for a large class of vehicle routing problems with time-windows. J. Computers & Operations Research. 40, 475–489 (2013)."),[27](https://www.nature.com/articles/s41598-019-43546-3#ref-CR27 "Kristian, B. & Frédéric, R. N. Survival of the Fittest in Cities: Urbanisation and Inequality. J. The Economic Journal. 124, 1371–1400 (2014)."),[28](https://www.nature.com/articles/s41598-019-43546-3#ref-CR28 "Bak, P. & Sneppen, K. Punctuated equilibrium and criticality in a simple model of evolution. Physical Review Letters. 24, 4083–4086 (1993)."),[29](https://www.nature.com/articles/s41598-019-43546-3#ref-CR29 "Boettcher, S. & Percus, A. Nature’s way of optimizing. Artificial Intelligence. 1–2, 275–286 (2000).").

In the new algorithm, assume the number of wolves in the pack is fixed, and the strength of wolves is measured by fitness value. The higher the fitness, the better the solution. Therefore, after each iteration of the algorithm sort the fitness value that corresponds to each wolf in ascending order, and then eliminate _R_ wolves with larger fitness value, meanwhile randomly generate new wolves that equal to the number of eliminated wolves. When R is large, the number of wolves that new generating is big, which will help to increase the diversity of wolves. But if the value of _R_ is too large, the algorithm tends to be searching randomly, which will results in the convergence speed becoming slow. If the value of _R_ is too small, it is not conducive to maintain the diversity of population, which results in the ability of exploring new solution space weakened. Therefore, in this paper, _R_ is a random integer between _n_/(2 × _ε_) and _n_/_ε_.

$$R=[n/\varepsilon ,n/0.75\times \varepsilon ]$$

(18)

where, _n_ is the total number of wolves, _ε_ is scale factor of wolves updating.

The flow chart of the improved grey wolf optimizer (IGWO) is illustrated in Fig.[4](https://www.nature.com/articles/s41598-019-43546-3#Fig4). The main procedure steps are described as follows.

1.   (1)
Initialize the grey wolf population. Randomly generated position of wolves _X_ _i_(_i_ = 1, 2, … _n_) Initialize parameters _a_, A and C.

2.   (2)
Calculate fitness of each wolf, choose the first three best wolves and save them as alpha beta and Delta in turn.

3.   (3)
Update position. According to Eqs ([5](https://www.nature.com/articles/s41598-019-43546-3#Equ5)–[11](https://www.nature.com/articles/s41598-019-43546-3#Equ11)) update position of the other wolves, that is, update position of omega wolf.

4.   (4)
Evolution operation. Use alpha, beta, and delta to form variation factor according to the Eq. ([14](https://www.nature.com/articles/s41598-019-43546-3#Equ14)). After crossover and selection operation, select the individual with good fitness as the wolf of next generation. Choose the first three best wolves and save them as alpha beta and Delta in turn.

5.   (5)
Update wolves. Sort fitness values that correspond by wolves from small to large, eliminate R wolves with larger fitness value. Meanwhile, randomly generate new R wolves.

6.   (6)
Update parameter _a_, A and C.

7.   (7)
Judge whether the termination condition is satisfied, if satisfied, output the position and fitness value of alpha as the optimal solution. If not satisfied, return to step (2).

**Figure 4**

Flow chart of IGWO algorithm.

## Simulation Experiments and Results Analysis

Before carrying out the simulation experiments to compare the performances of adopted optimization algorithm, twelve benchmark functions are selected[2](https://www.nature.com/articles/s41598-019-43546-3#ref-CR2 "Cui, Z. H. & Gao, X. Z. Theory and applications of swarm intelligence. J. Neural Computing and Applications. 21, 205–206 (2012)."), which are listed in Table[1](https://www.nature.com/articles/s41598-019-43546-3#Tab1). The experiment consists of two parts. For validating the performance of two improvements to the GWO, one part is that separately do experiments for the GWO with differential evolution (DGWO), GWO with SOF mechanism (SGWO) and IGWO. And meanwhile, compare results with DE algorithm. The second part is that do experiments to compare IGWO with other swarm intelligence algorithm, including PSO algorithm, ABC algorithm and CS algorithm. The parameter settings of GWO, PSO algorithm, ABC algorithm, CS algorithm and, DE algorithm are defined according with literature and can be found respectively in[8](https://www.nature.com/articles/s41598-019-43546-3#ref-CR8 "Fang, C. & Wang, L. An effective shuffled frog-leaping algorithm for resource-constrained project scheduling problem. J. Computers & Operations Research. 39, 890–901 (2012)."),[9](https://www.nature.com/articles/s41598-019-43546-3#ref-CR9 "Karaboga, D. & Basturk, B. On the performance of artificial bee colony (ABC) algorithm. J. Applied soft computing. 8, 687–697 (2008)."),[12](https://www.nature.com/articles/s41598-019-43546-3#ref-CR12 "Yang, X. S. & Deb, S. Cuckoo search via Lévy flights. A. Proceedings of World Congress on Nature & Biologically Inspired Computing. C. IEEE Publications. USA, 210–214 (2009)."),[13](https://www.nature.com/articles/s41598-019-43546-3#ref-CR13 "Mirjalili, S., Wang, G.-G., dos, L. & Coelho, S. Binary optimization using hybrid particle swarm optimization and gravitational search algorithm. J. Neural Computing and Applications. 25, 1423–1435 (2014)."),[23](https://www.nature.com/articles/s41598-019-43546-3#ref-CR23 "Zhang, P., Wei, Y. X. & Xue, H. Q. Heterogeneous Multiple Colonies Ant Colony Algorithm Based on Survival of Fittest Rules. J. Computer Engineering. 38, 182–185 (2012)."), which are listed in Table[2](https://www.nature.com/articles/s41598-019-43546-3#Tab2).

**Table 1 Test functions.**

[Full size table](https://www.nature.com/articles/s41598-019-43546-3/tables/1)

**Table 2 Parameters Settings of each algorithms.**

[Full size table](https://www.nature.com/articles/s41598-019-43546-3/tables/2)

### Experiment and analysis for two improvement of IGWO

For validating the performance of two improvements to the GWO, first of all, simulation experiments are separately carried out for the grey wolf optimizer with differential evolution (DGWO), grey wolf optimizer with SOF mechanism (SGWO) and IGWO. And meanwhile, The simulation results compared with GWO and DE algorithm are shown in Figs[5](https://www.nature.com/articles/s41598-019-43546-3#Fig5)–[11](https://www.nature.com/articles/s41598-019-43546-3#Fig11). It can be seen from the simulation convergence curves for the adopted testing functions, compared with GWO, the convergence velocity and optimization precision of DGWO, SGWO and IGWO all have been improved, but IGWO is the best.

**Figure 5**

Convergence curves Function _F8_ (D = 30).

**Figure 6**

Convergence curves Function _F9_ (D = 30).

**Figure 7**

Convergence curves Function _F10_ (D = 30).

**Figure 8**

Convergence curves Function _F12_. (D = 30).

**Figure 9**

Convergence curves Function _F4_. (D = 100).

**Figure 10**

Convergence curves Function _F8_ (D = 100).

**Figure 11**

Convergence curves Function _F9_ (D = 100).

Then for further validating the searching accuracy of DGWO, SGWO and IGWO, every optimization algorithm is run independently thirty times and the best, worst and average values are recorded for the adopted twelve testing functions under the 30-dimension and 100-dimension. The maximum iterations number is _Max Max\_iter_ = 500. The statistical results of D = 30 and D = 100 are shown in Tables[3](https://www.nature.com/articles/s41598-019-43546-3#Tab3) and [4](https://www.nature.com/articles/s41598-019-43546-3#Tab4) respectively.

**Table 3 Numerical statistics results of D = 30.**

[Full size table](https://www.nature.com/articles/s41598-019-43546-3/tables/3)

**Table 4 Numerical statistics results of D = 100.**

[Full size table](https://www.nature.com/articles/s41598-019-43546-3/tables/4)

### Simulation contrast experiments and results analysis

Three swarm intelligence algorithms (PSO algorithm, ABC algorithm and CS algorithm) are selected to carry out the simulation contrast experiments with the proposed IGWO so as to verify its superiority on the convergence velocity and searching precision. When dimension D = 30, the simulation convergence results on the adopted testing functions are shown in Figs[12](https://www.nature.com/articles/s41598-019-43546-3#Fig12)–[23](https://www.nature.com/articles/s41598-019-43546-3#Fig23). when D = 100, the simulation convergence results on the adopted testing functions are shown in Figs[24](https://www.nature.com/articles/s41598-019-43546-3#Fig24)–[27](https://www.nature.com/articles/s41598-019-43546-3#Fig27).

**Figure 12**

Convergence curves Function _F1_.

**Figure 13**

Convergence curves Function _F2_.

**Figure 14**

Convergence curves Function _F3_.

**Figure 15**

Convergence curves Function _F4_.

**Figure 16**

Convergence curves Function _F5_.

**Figure 17**

Convergence curves Function _F6_.

**Figure 18**

Convergence curves Function _F7_.

**Figure 19**

Convergence curves Function _F8_.

**Figure 20**

Convergence curves Function _F9_.

**Figure 21**

Convergence curves Function _F10_.

**Figure 22**

Convergence curves Function _F11_.

**Figure 23**

Convergence curves Function _F12_.

**Figure 24**

Convergence curves Function _F5_ (D = 100).

**Figure 25**

Convergence curves Function _F8_ (D = 100).

**Figure 26**

Convergence curves Function _F9_ (D = 100).

**Figure 27**

Convergence curves Function _F12_ (D = 100).

It can be seen from the simulation convergence curves, IGWO has better convergence velocity and searching precision than other three algorithms (ABC, CS and PSO). Especially for function F8, F9 and F12, compared with GWO, the IGWO make their convergence speed are improved obviously. It can be seen from their surface figure that the three functions are multimodal function. So there are a lot of local minimum values within the scope of search. For IGWO, the addition of differential evolution and the SOF mechanism can improving the weakness of easily falling into the local extreme and obtain smaller function value. Thus, the convergence speeds of the three functions are improved significantly. At the same time, it suggests that the IGWO has the superiority to jump out of the local optimal.

For further validating the searching accuracy, every optimization algorithm is run independently thirty times and the best, worst and average values are recorded for the adopted twelve testing functions under the 30-dimension and 100-dimension. The maximum iterations number is _Max Max\_iter_ = 500. The statistical results of D = 30 and D = 100 are shown in Tables[5](https://www.nature.com/articles/s41598-019-43546-3#Tab5) and [6](https://www.nature.com/articles/s41598-019-43546-3#Tab6) respectively. Seen from the numerical results listed in Tables[5](https://www.nature.com/articles/s41598-019-43546-3#Tab5) and [6](https://www.nature.com/articles/s41598-019-43546-3#Tab6), the IGWO proposed in this paper makes optimization accuracy of 12 typical functions have a certain improvement. And the optimization accuracy of IGWO is better than that of PSO, ABC, CS algorithm under the same dimension. For the F1 function, when its dimension D = 30, its average value is raised from e-27 to e-63, relative to GWO been increased by 36 orders of magnitude; and when D = 100, its average value is raised from e-12 to e-34, relative to GWO increased by 22 orders of magnitude. For the F2 function, when D = 30, its average value has been improved 35 orders of magnitude relative to GWO; and when D = 100, relative to GWO its average value is improved 22 orders of magnitude. For function F9 and F11, when D = 30 and D = 100, IGWO respectively search to their ideal minimum value 0. The optimization performance for other testing functions all has been improved.

**Table 5 Numerical statistics results of D = 30.**

[Full size table](https://www.nature.com/articles/s41598-019-43546-3/tables/5)

**Table 6 Numerical statistics results of D = 100.**

[Full size table](https://www.nature.com/articles/s41598-019-43546-3/tables/6)

Thus, the simulation experiments results, including convergence curves and statistics data, show that the proposed improved grey wolves optimizer has a better convergence rate and optimization performance. According to the improvement above, three reasons can be summarized: Firstly, the adding of evolution operation is able to increase the diversity of wolves, that is to say to increase the solution diversity so as to make the algorithm jump out the local extreme. Secondly, the selection method of parents of DE and dynamic scaling factor _F_ can make the algorithm has a good exploration ability in the early search stage and has a good exploitation ability in the later search stage, therefore, both search precision and convergence speed are improved. In addition, the adding of SOF wolf updating mechanism can also decrease the probability of the algorithm falling into the local extreme.

## Conclusions

For achieving the proper compromise between exploration and exploitation, further accelerate the convergence and increase the optimization accuracy of GWO, an improved grey wolf optimizer (IGWO) is proposed in this paper. The biological evolution and SOF principle in nature are added to the standard GWO. The simulation experiments are carried out by adopting twelve typical function optimization problems. The simulation results show the proposed IGWO has better convergence velocity and optimization performance than DE algorithm, PSO algorithm, ABC algorithm and CS algorithm. On the one hand, the adoption of evolution operation can increase the wolves diversity and make the algorithm has a good exploration ability in the early searching stage and has a good exploitation ability in the later search stage. On the other hand, the adoption of SOF wolf updating mechanism can decrease the probability of falling into the local optimum. In the future work, we will carry out similar hybridisation of other swarm intelligent optimization algorithms, such as dragonfly algorithm (DA), ant lion optimizer (ALO), multi-verse optimizer (MVO), coral reefs optimization (CRO) algorithm, etc.

## Data Availability

There are no data available for this paper.

## References

1.   Derrac, J., García, S. & Molina, D. A practical tutorial on the use of non-parametric statistical tests as a methodology for comparing evolutionary and swarm intelligence algorithms. _J. Swarm and Evolutionary Computation._**1**, 3–18 (2011).

[Article](https://doi.org/10.1016%2Fj.swevo.2011.02.002)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20practical%20tutorial%20on%20the%20use%20of%20non-parametric%20statistical%20tests%20as%20a%20methodology%20for%20comparing%20evolutionary%20and%20swarm%20intelligence%20algorithms&journal=J.%20Swarm%20and%20Evolutionary%20Computation.&doi=10.1016%2Fj.swevo.2011.02.002&volume=1&pages=3-18&publication_year=2011&author=Derrac%2CJ&author=Garc%C3%ADa%2CS&author=Molina%2CD)

2.   Cui, Z. H. & Gao, X. Z. Theory and applications of swarm intelligence. _J. Neural Computing and Applications._**21**, 205–206 (2012).

[Article](https://link.springer.com/doi/10.1007/s00521-011-0523-8)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Theory%20and%20applications%20of%20swarm%20intelligence&journal=J.%20Neural%20Computing%20and%20Applications.&doi=10.1007%2Fs00521-011-0523-8&volume=21&pages=205-206&publication_year=2012&author=Cui%2CZH&author=Gao%2CXZ)

3.   Zhang, Z. _et al_. On swarm intelligence inspired self-organized networking: its bionic mechanisms, designing principles and optimization approaches. _J. Communications Surveys & Tutorials IEEE._**16**, 513–537 (2014).

[Article](https://doi.org/10.1109%2FSURV.2013.062613.00014)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=On%20swarm%20intelligence%20inspired%20self-organized%20networking%3A%20its%20bionic%20mechanisms%2C%20designing%20principles%20and%20optimization%20approaches&journal=J.%20Communications%20Surveys%20%26%20Tutorials%20IEEE.&doi=10.1109%2FSURV.2013.062613.00014&volume=16&pages=513-537&publication_year=2014&author=Zhang%2CZ)

4.   Leboucher, C. _et al_. A swarm intelligence method combined to evolutionary game theory applied to the resources allocation problem. _J. International Journal of Swarm Intelligence Research (IJSIR)._**3**, 20–38 (2012).

[Article](https://doi.org/10.4018%2Fjsir.2012040102)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20swarm%20intelligence%20method%20combined%20to%20evolutionary%20game%20theory%20applied%20to%20the%20resources%20allocation%20problem&journal=J.%20International%20Journal%20of%20Swarm%20Intelligence%20Research%20%28IJSIR%29.&doi=10.4018%2Fjsir.2012040102&volume=3&pages=20-38&publication_year=2012&author=Leboucher%2CC)

5.   Parpinelli, R. S. & Lopes, H. S. New inspirations in swarm intelligence: a survey. _J. International Journal of Bio-Inspired Computation._**3**, 1–16 (2011).

[Article](https://doi.org/10.1504%2FIJBIC.2011.038700)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=New%20inspirations%20in%20swarm%20intelligence%3A%20a%20survey&journal=J.%20International%20Journal%20of%20Bio-Inspired%20Computation.&doi=10.1504%2FIJBIC.2011.038700&volume=3&pages=1-16&publication_year=2011&author=Parpinelli%2CRS&author=Lopes%2CHS)

6.   Kennedy, J. & Eberhart R. Particle swarm optimization, in Neural Networks, 1995. Proceedings., IEEE International Conference on. pp. 1942–1948 (1995).

7.   Ebrahimi, J., Hosseinian, S. H. & Gharehpetian, G. B. Unit commitment problem solution using shuffled frog leaping algorithm. _J. Power Systems, IEEE Transactions on._**26**, 573–581 (2011).

[Article](https://doi.org/10.1109%2FTPWRS.2010.2052639)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=2011ITPSy..26..573E)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Unit%20commitment%20problem%20solution%20using%20shuffled%20frog%20leaping%20algorithm&journal=J.%20Power%20Systems%2C%20IEEE%20Transactions%20on.&doi=10.1109%2FTPWRS.2010.2052639&volume=26&pages=573-581&publication_year=2011&author=Ebrahimi%2CJ&author=Hosseinian%2CSH&author=Gharehpetian%2CGB)

8.   Fang, C. & Wang, L. An effective shuffled frog-leaping algorithm for resource-constrained project scheduling problem. _J. Computers & Operations Research._**39**, 890–901 (2012).

[Article](https://doi.org/10.1016%2Fj.cor.2011.07.010)[MathSciNet](http://www.ams.org/mathscinet-getitem?mr=2834285)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=An%20effective%20shuffled%20frog-leaping%20algorithm%20for%20resource-constrained%20project%20scheduling%20problem&journal=J.%20Computers%20%26%20Operations%20Research.&doi=10.1016%2Fj.cor.2011.07.010&volume=39&pages=890-901&publication_year=2012&author=Fang%2CC&author=Wang%2CL)

9.   Karaboga, D. & Basturk, B. On the performance of artificial bee colony (ABC) algorithm. _J. Applied soft computing._**8**, 687–697 (2008).

[Article](https://doi.org/10.1016%2Fj.asoc.2007.05.007)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=On%20the%20performance%20of%20artificial%20bee%20colony%20%28ABC%29%20algorithm&journal=J.%20Applied%20soft%20computing.&doi=10.1016%2Fj.asoc.2007.05.007&volume=8&pages=687-697&publication_year=2008&author=Karaboga%2CD&author=Basturk%2CB)

10.   Dorigo, M., Birattari, M. & Stutzle, T. Ant colony optimization. _IEEE Computational Intelligence Magazine_**1**, 28–39 (2006).

[Article](https://doi.org/10.1109%2FMCI.2006.329691)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Ant%20colony%20optimization&journal=IEEE%20Computational%20Intelligence%20Magazine&doi=10.1109%2FMCI.2006.329691&volume=1&pages=28-39&publication_year=2006&author=Dorigo%2CM&author=Birattari%2CM&author=Stutzle%2CT)

11.   Simon, D. Biogeography-based optimization. _Evolutionary Computation, IEEE Transactions on_**12**, 702–713 (2008).

[Article](https://doi.org/10.1109%2FTEVC.2008.919004)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Biogeography-based%20optimization&journal=Evolutionary%20Computation%2C%20IEEE%20Transactions%20on&doi=10.1109%2FTEVC.2008.919004&volume=12&pages=702-713&publication_year=2008&author=Simon%2CD)

12.   Yang, X. S. & Deb, S. Cuckoo search via Lévy flights. A. Proceedings of World Congress on Nature & Biologically Inspired Computing. C. IEEE Publications. USA, 210–214 (2009).

13.   Mirjalili, S., Wang, G.-G., dos, L. & Coelho, S. Binary optimization using hybrid particle swarm optimization and gravitational search algorithm. _J. Neural Computing and Applications._**25**, 1423–1435 (2014).

[Article](https://link.springer.com/doi/10.1007/s00521-014-1629-6)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Binary%20optimization%20using%20hybrid%20particle%20swarm%20optimization%20and%20gravitational%20search%20algorithm&journal=J.%20Neural%20Computing%20and%20Applications.&doi=10.1007%2Fs00521-014-1629-6&volume=25&pages=1423-1435&publication_year=2014&author=Mirjalili%2CS&author=Wang%2CG-G&author=dos%2CL&author=Coelho%2CS)

14.   Črepinšek, M., Liu, S. H. & Marjan, M. Exploration and exploitation in evolutionary algorithms: a survey. _ACM Comput. Surv._**45**, 1–33 (2013).

[Article](https://doi.org/10.1145%2F2480741.2480752)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Exploration%20and%20exploitation%20in%20evolutionary%20algorithms%3A%20a%20survey&journal=ACM%20Comput.%20Surv.&doi=10.1145%2F2480741.2480752&volume=45&pages=1-33&publication_year=2013&author=%C4%8Crepin%C5%A1ek%2CM&author=Liu%2CSH&author=Marjan%2CM)

15.   Mirjalili, S., Mirjalili, S. M. & Lewis, A. Grey wolf optimizer. _J. Advances in Engineering Software._**69**, 46–61 (2014).

[Article](https://doi.org/10.1016%2Fj.advengsoft.2013.12.007)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Grey%20wolf%20optimizer&journal=J.%20Advances%20in%20Engineering%20Software.&doi=10.1016%2Fj.advengsoft.2013.12.007&volume=69&pages=46-61&publication_year=2014&author=Mirjalili%2CS&author=Mirjalili%2CSM&author=Lewis%2CA)

16.   Brambilla, M. _et al_. Swarm robotics: a review from the swarm engineering perspective. _J. Swarm Intelligence._**7**, 1–41 (2013).

[Article](https://link.springer.com/doi/10.1007/s11721-012-0075-2)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Swarm%20robotics%3A%20a%20review%20from%20the%20swarm%20engineering%20perspective&journal=J.%20Swarm%20Intelligence.&doi=10.1007%2Fs11721-012-0075-2&volume=7&pages=1-41&publication_year=2013&author=Brambilla%2CM)

17.   Liao, J. _et al_. A neighbor decay cellular automata approach for simulating urban expansion based on particle swarm intelligence. _J. International Journal of Geographical Information Science._**28**, 720–738 (2014).

[Article](https://doi.org/10.1080%2F13658816.2013.869820)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20neighbor%20decay%20cellular%20automata%20approach%20for%20simulating%20urban%20expansion%20based%20on%20particle%20swarm%20intelligence&journal=J.%20International%20Journal%20of%20Geographical%20Information%20Science.&doi=10.1080%2F13658816.2013.869820&volume=28&pages=720-738&publication_year=2014&author=Liao%2CJ)

18.   Das, S. & Suganthan, P. N. Differential evolution: a survey of the state-of-the-art. _J_. _Evolutionary Computation, IEEE Transactions on._**15**, 4–31 (2011).

[Article](https://doi.org/10.1109%2FTEVC.2010.2059031)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Differential%20evolution%3A%20a%20survey%20of%20the%20state-of-the-art.%20J&journal=Evolutionary%20Computation%2C%20IEEE%20Transactions%20on.&doi=10.1109%2FTEVC.2010.2059031&volume=15&pages=4-31&publication_year=2011&author=Das%2CS&author=Suganthan%2CPN)

19.   Palmer, Katie _et al_. Differential Evolution of Cognitive Impairment in Nondemented Older Persons: Results From the Kungsholmen Project. _J. Psychiatry._**159**, 436–442 (2014).

[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Differential%20Evolution%20of%20Cognitive%20Impairment%20in%20Nondemented%20Older%20Persons%3A%20Results%20From%20the%20Kungsholmen%20Project&journal=J.%20Psychiatry.&volume=159&pages=436-442&publication_year=2014&author=Palmer%2CKatie)

20.   Agrawal, R. _et al_. Parallelization of industrial process control program based on the technique of differential evolution using multi-threading[C]//Industrial Engineering and Engineering Management (IEEM), 2014 IEEE International Conference on. IEEE, 546–550 (2014).

21.   Islam, S. M. _et al_. An adaptive differential evolution algorithm with novel mutation and crossover strategies for global numerical optimization. _J. Systems, Man, and Cybernetics, Part B: Cybernetics, IEEE Transactions on._**42**, 482–500 (2012).

[Article](https://doi.org/10.1109%2FTSMCB.2011.2167966)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=An%20adaptive%20differential%20evolution%20algorithm%20with%20novel%20mutation%20and%20crossover%20strategies%20for%20global%20numerical%20optimization&journal=J.%20Systems%2C%20Man%2C%20and%20Cybernetics%2C%20Part%20B%3A%20Cybernetics%2C%20IEEE%20Transactions%20on.&doi=10.1109%2FTSMCB.2011.2167966&volume=42&pages=482-500&publication_year=2012&author=Islam%2CSM)

22.   Zheng, Y. J. _et al_. A hybrid fireworks optimization method with differential evolution operators. _J. Neurocomputing._**148**, 75–82 (2015).

[Article](https://doi.org/10.1016%2Fj.neucom.2012.08.075)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20hybrid%20fireworks%20optimization%20method%20with%20differential%20evolution%20operators&journal=J.%20Neurocomputing.&doi=10.1016%2Fj.neucom.2012.08.075&volume=148&pages=75-82&publication_year=2015&author=Zheng%2CYJ)

23.   Zhang, P., Wei, Y. X. & Xue, H. Q. Heterogeneous Multiple Colonies Ant Colony Algorithm Based on Survival of Fittest Rules. _J. Computer Engineering._**38**, 182–185 (2012).

[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Heterogeneous%20Multiple%20Colonies%20Ant%20Colony%20Algorithm%20Based%20on%20Survival%20of%20Fittest%20Rules&journal=J.%20Computer%20Engineering.&volume=38&pages=182-185&publication_year=2012&author=Zhang%2CP&author=Wei%2CYX&author=Xue%2CHQ)

24.   Eyler, C. E. & Rich, J. N. Survival of the fittest: cancer stem cells in therapeutic resistance and angiogenesis. _J. Journal of Clinical Oncology._**26**, 2839–2845 (2008).

[Article](https://doi.org/10.1200%2FJCO.2007.15.1829)[CAS](https://www.nature.com/articles/cas-redirect/1:CAS:528:DC%2BD1cXotlCmsr4%3D)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Survival%20of%20the%20fittest%3A%20cancer%20stem%20cells%20in%20therapeutic%20resistance%20and%20angiogenesis&journal=J.%20Journal%20of%20Clinical%20Oncology.&doi=10.1200%2FJCO.2007.15.1829&volume=26&pages=2839-2845&publication_year=2008&author=Eyler%2CCE&author=Rich%2CJN)

25.   Whitley, D. An executable model of a simple genetic algorithm. _J. Foundations of genetic algorithms._**2**, 45–62 (2014).

[Google Scholar](http://scholar.google.com/scholar_lookup?&title=An%20executable%20model%20of%20a%20simple%20genetic%20algorithm&journal=J.%20Foundations%20of%20genetic%20algorithms.&volume=2&pages=45-62&publication_year=2014&author=Whitley%2CD)

26.   Vidal, T. _et al_. A hybrid genetic algorithm with adaptive diversity management for a large class of vehicle routing problems with time-windows. _J. Computers & Operations Research._**40**, 475–489 (2013).

[Article](https://doi.org/10.1016%2Fj.cor.2012.07.018)[MathSciNet](http://www.ams.org/mathscinet-getitem?mr=2979129)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=A%20hybrid%20genetic%20algorithm%20with%20adaptive%20diversity%20management%20for%20a%20large%20class%20of%20vehicle%20routing%20problems%20with%20time-windows&journal=J.%20Computers%20%26%20Operations%20Research.&doi=10.1016%2Fj.cor.2012.07.018&volume=40&pages=475-489&publication_year=2013&author=Vidal%2CT)

27.   Kristian, B. & Frédéric, R. N. Survival of the Fittest in Cities: Urbanisation and Inequality. _J. The Economic Journal._**124**, 1371–1400 (2014).

[Article](https://doi.org/10.1111%2Fecoj.12099)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Survival%20of%20the%20Fittest%20in%20Cities%3A%20Urbanisation%20and%20Inequality&journal=J.%20The%20Economic%20Journal.&doi=10.1111%2Fecoj.12099&volume=124&pages=1371-1400&publication_year=2014&author=Kristian%2CB&author=Fr%C3%A9d%C3%A9ric%2CRN)

28.   Bak, P. & Sneppen, K. Punctuated equilibrium and criticality in a simple model of evolution. _Physical Review Letters._**24**, 4083–4086 (1993).

[Article](https://doi.org/10.1103%2FPhysRevLett.71.4083)[ADS](http://adsabs.harvard.edu/cgi-bin/nph-data_query?link_type=ABSTRACT&bibcode=1993PhRvL..71.4083B)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Punctuated%20equilibrium%20and%20criticality%20in%20a%20simple%20model%20of%20evolution&journal=Physical%20Review%20Letters.&doi=10.1103%2FPhysRevLett.71.4083&volume=24&pages=4083-4086&publication_year=1993&author=Bak%2CP&author=Sneppen%2CK)

29.   Boettcher, S. & Percus, A. Nature’s way of optimizing. _Artificial Intelligence._**1–2**, 275–286 (2000).

[Article](https://doi.org/10.1016%2FS0004-3702%2800%2900007-2)[Google Scholar](http://scholar.google.com/scholar_lookup?&title=Nature%E2%80%99s%20way%20of%20optimizing&journal=Artificial%20Intelligence.&doi=10.1016%2FS0004-3702%2800%2900007-2&volume=1%E2%80%932&pages=275-286&publication_year=2000&author=Boettcher%2CS&author=Percus%2CA)

[Download references](https://citation-needed.springer.com/v2/references/10.1038/s41598-019-43546-3?format=refman&flavour=references)

## Acknowledgements

This work was supported by the Project by National Natural Science Foundation of China (Grant No. 21576127), the Basic Scientific Research Project of Institution of Higher Learning of Liaoning Province (Grant No. 2017FWDF10), and the Project by Liaoning Provincial Natural Science Foundation of China (Grant No. 20180550700).

## Author information

### Authors and Affiliations

1.   School of Electronic and Information Engineering, University of Science & Technology Liaoning, Anshan, 114044, China

Jie-Sheng Wang&Shu-Xia Li

2.   National Financial Security and System Equipment Engineering Research Center, University of Science & Technology Liaoning, Anshan, 114044, China

Jie-Sheng Wang

Authors

1.   Jie-Sheng Wang
2.   Shu-Xia Li

### Contributions

Jie-Sheng Wang participated in the concept, design, interpretation and commented on the manuscript. A substantial amount of Shu-Xia Li’s contribution to the data collection, analysis and algorithm simulation, draft writing, and critical revision of this paper was undertaken.

### Corresponding author

Correspondence to [Jie-Sheng Wang](mailto:wang_jiesheng@126.com).

## Ethics declarations

### Competing Interests

The authors declare no competing interests.

## Additional information

**Publisher’s note:** Springer Nature remains neutral with regard to jurisdictional claims in published maps and institutional affiliations.

## Rights and permissions

**Open Access** This article is licensed under a Creative Commons Attribution 4.0 International License, which permits use, sharing, adaptation, distribution and reproduction in any medium or format, as long as you give appropriate credit to the original author(s) and the source, provide a link to the Creative Commons license, and indicate if changes were made. The images or other third party material in this article are included in the article’s Creative Commons license, unless indicated otherwise in a credit line to the material. If material is not included in the article’s Creative Commons license and your intended use is not permitted by statutory regulation or exceeds the permitted use, you will need to obtain permission directly from the copyright holder. To view a copy of this license, visit [http://creativecommons.org/licenses/by/4.0/](http://creativecommons.org/licenses/by/4.0/).

[Reprints and permissions](https://s100.copyright.com/AppDispatchServlet?title=An%20Improved%20Grey%20Wolf%20Optimizer%20Based%20on%20Differential%20Evolution%20and%20Elimination%20Mechanism&author=Jie-Sheng%20Wang%20et%20al&contentID=10.1038%2Fs41598-019-43546-3&copyright=The%20Author%28s%29&publication=2045-2322&publicationDate=2019-05-09&publisherName=SpringerNature&orderBeanReset=true&oa=CC%20BY)

## About this article

[![Image 1: Check for updates. Verify currency and authenticity via CrossMark](blob:http://localhost/df43c82f6cb6dcd2a87db38f317bf9f2)](https://crossmark.crossref.org/dialog/?doi=10.1038/s41598-019-43546-3)

### Cite this article

Wang, JS., Li, SX. An Improved Grey Wolf Optimizer Based on Differential Evolution and Elimination Mechanism. _Sci Rep_**9**, 7181 (2019). https://doi.org/10.1038/s41598-019-43546-3

[Download citation](https://citation-needed.springer.com/v2/references/10.1038/s41598-019-43546-3?format=refman&flavour=citation)

*   Received: 20 August 2015

*   Accepted: 27 April 2019

*   Published: 09 May 2019

*   Version of record: 09 May 2019

*   DOI: https://doi.org/10.1038/s41598-019-43546-3

