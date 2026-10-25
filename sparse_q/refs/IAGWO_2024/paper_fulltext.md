
===== PAGE 1 =====
Vol.:(0123456789)
Artificial Intelligence Review (2024) 57:277
https://doi.org/10.1007/s10462-024-10821-3
Improved multi‑strategy adaptive Grey Wolf Optimization 
for practical engineering applications and high‑dimensional 
problem solving
Mingyang Yu1 · Jing Xu1 · Weiyun Liang1 · Yu Qiu1 · Sixu Bao1 · Lin Tang2
Accepted: 28 May 2024 / Published online: 5 September 2024 
© The Author(s), under exclusive licence to Springer Nature B.V. 2024
Abstract
The Grey Wolf Optimization (GWO) is a highly effective meta-heuristic algorithm lev-
eraging swarm intelligence to tackle real-world optimization problems. However, when 
confronted with large-scale problems, GWO encounters hurdles in convergence speed and 
problem-solving capabilities. To address this, we propose an Improved Adaptive Grey 
Wolf Optimization (IAGWO), which significantly enhances exploration of the search space 
through refined search mechanisms and adaptive strategy. Primarily, we introduce the 
incorporation of velocity and the Inverse Multiquadratic Function (IMF) into the search 
mechanism. This integration not only accelerates convergence speed but also maintains 
accuracy. Secondly, we implement an adaptive strategy for population updates, enhanc-
ing the algorithm’s search and optimization capabilities dynamically. The efficacy of our 
proposed IAGWO is demonstrated through comparative experiments conducted on bench-
mark test sets, including CEC 2017, CEC 2020, CEC 2022, and CEC 2013 large-scale 
global optimization suites. At CEC2017, CEC 2020 (10/20 dimensions), CEC 2022 (10/20 
dimensions), and CEC 2013, respectively, it outperformed other comparative algorithms 
by 88.2%, 91.5%, 85.4%, 96.2%, 97.4%, and 97.2%. Results affirm that our algorithm sur-
passes state-of-the-art approaches in addressing large-scale problems. Moreover, we show-
case the broad application potential of the algorithm by successfully solving 19 real-world 
engineering challenges.
Keywords  Grey Wolf Optimization algorithm · Search mechanism · Inverse multiquadratic 
function · Adaptive strategy · Engineering design challenges
1  Introduction
The rapid advancement of science, technology, and industry has given rise to a multitude 
of intricate optimization problems. These problems frequently entail numerous variables, 
constraints, and objectives. Their solution spaces are huge and complex, and it is diffi-
cult for traditional deterministic optimization methods to obtain satisfactory solutions in 
acceptable time (Deng et al. 2022; Guo et al. 2023; Zhou et al. 2022). To cope with these 
challenges, researchers in the field of computational intelligence have started to search for 
Extended author information available on the last page of the article

===== PAGE 2 =====
	
M. Yu et al.
277 
Page 2 of 51
new approaches. Among them, metaheuristic algorithms have attracted much attention 
due to their high efficiency, universal applicability and powerful global search capability 
(Aldosari et al. 2022; Chauhan et al., 2024; Chen et al. 2023).
When dealing with engineering problems, constraints are a crucial consideration. Con-
straints may be physical limitations or requirements and restrictions of the project. In the 
field of engineering, there are various techniques available for handling these constraints 
to ensure that projects proceed as expected and achieve their intended goals. One com-
mon technique for constraint handling is optimization algorithms. Optimization algorithms 
assist engineers in finding the best solution given certain constraints. These algorithms can 
be mathematical optimization methods such as linear programming, integer programming, 
or nonlinear programming, or they can be heuristic algorithms such as genetic algorithms, 
simulated annealing, or particle swarm optimization. By leveraging these algorithms, engi-
neers can find the optimal design or decision solution while taking into account various 
constraints (Fu et al. 2024b; Li et al. 2023).
MH algorithms are inspired by certain phenomena in nature, such as PSO (Kennedy and 
Eberhart 1995b), Firefly Algorithm (FA) (Yang 2009), Sine Cosine Algorithm (SCA) (Mir-
jalili 2016), Wind Driven Optimization (WDO) (Bayraktar et al. 2010), Fruit Fly Optimi-
zation Algorithm (FOA) (Pan 2012), Competitive Swarm Optimizer (Chauhan et al. 2024), 
Fox optimizer(FOX) (Mohammed and Rashid 2023), Fitness Dependent Optimizer(FDO) 
(Abdullah and Ahmed 2019) and so on. These algorithms often do not rely on the specific 
nature of the problem, but instead draw on nature’s strategies for stochastic search, which 
can effectively avoid falling into local optima (Abdel-Basset et al. 2023). With the develop-
ment of deep learning, neural networks and other machine learning techniques, researchers 
have begun to try to combine these techniques with metaheuristic algorithms to further 
improve the efficiency of solving complex optimization problems (Garg et al. 2023). In 
recent years, with the wide application of heuristic intelligent optimization algorithms in 
numerical optimization solving, various swarm intelligence algorithms have been proposed 
(Fu et al. 2022).
The popularity of MH algorithms has four distinct advantages: practicality, generaliz-
ability, non-leading properties and avoidance of local optima (Fu et al. 2023a). First, based 
on their natural theoretical framework, these strategies are relatively intuitive to construct 
and deploy, thus allowing engineers and researchers to rapidly integrate them into concrete 
applications (Havaei & Sandidzadeh 2023). Next, since these algorithms treat the problem 
as an unknown mechanism, they can be applied to a wide range of different tasks such as 
selection (Said, Elarbi, Bechikh, Coello Coello, & Said, 2023), shop visit balancing (Xia 
et al. 2023) and engineering problems (Nadimi-Shahraki et al. 2022). Further, these meth-
ods do not rely on derivative information and are particularly good for dealing with non-
linear problems (Aldosari et al. 2022). Ultimately, with the help of a global search strat-
egy and a stochastic strategy for updating the location, they can efficiently jump out of the 
local optimum, which is particularly effective for those scenarios where there are multiple 
locally optimal solutions.
The existing MH algorithm mainly include: Physics-based algorithms (PhA), Swarm 
Intelligence Algorithms (SI), Natural Evolutionary Algorithms (EA), and Human-
based algorithms (Abualigah et al. 2021). In the course of evolution, cooperative behav-
ior between individuals has been gradually formed through natural selection over a long 
period of time. For example, Trojovský and Dehghani, 2022 proposed a pelican optimi-
zation algorithm (POA) inspired by pelican predation. The Genetic Algorithm (GA) is a 
method of optimization based on the principles of natural evolution. It was proposed by 
John Holland and his colleagues. is a typical example inspired by Darwinian evolution 

===== PAGE 3 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 3 of 51 
277
(Bäck & Schwefel 1993). Differential Evolution (DE), based on the concepts of natural 
selection and reproduction in Darwinian evolution(Storn and Price 1997); Genetic Pro-
gramming (GP), inspired by biological evolution processes; and Evolution Strategies (ES) 
(Wei 2012). Among these, Genetic Algorithms (GA) and Differential Evolution (DE) are 
widely considered to be the most popular evolutionary algorithms, having garnered sig-
nificant attention and being applied in numerous applications. Physical method is the result 
of the interaction of physical law and chemical variation. For example, the Chernobyl 
Disaster Optimizer (CDO) is an optimization algorithm inspired by the core explosion at 
the Chernobyl nuclear power plant. (Shehadeh 2023). The Galaxy Swarm Optimization 
(GSO) (Muthiah-Nakarajan and Noel 2016) algorithm, inspired by the motion of galaxies; 
the Firefly Algorithm (FFA), drawing inspiration from soil fertility in agriculture (Shay-
anfar and Gharehchopogh 2018); the Firefly Algorithm (FFA), drawing inspiration from 
soil fertility in agriculture (Eskandar et al. 2012); and the Gravitational Search Algorithm 
(GSA), derived from Newton’s law of universal gravitation and kinematic laws (Rashedi 
et al. 2009).In sharp contrast, a variety of human behaviors are simulated based on human 
behavior patterns, such as the "Alpine skiing Optimization (ASO)" proposed by Professor 
Yuan, a new idea influenced by the competitive behavior of athletes. Each of these different 
Metaheuristic algorithms has its own characteristics. According to different problems and 
requirements, appropriate algorithms can be selected to solve the optimal problems (Yuan 
et al. 2022). Particle Swarm Optimization (PSO) (Kennedy and Eberhart 1995a) is inspired 
by the foraging behavior of bird flocks and fish schools. The Ant Colony Optimization 
(ACO) algorithm (Dorigo et al. 2006) is inspired by the social behavior of ant colonies 
during foraging. The Pathfinder Algorithm (PFA) (Yapici & Cetinkaya 2019) is inspired 
by the collective action of animal populations in finding optimal food areas or prey. The 
Harris Hawk Optimization algorithm (HHO)(Heidari et al. 2019) is based on the predatory 
process of Harris hawks hunting rabbits. The Sparrow Search Algorithm (SSA) (Xue and 
Shen 2020) is inspired by the foraging and anti-predatory behavior of sparrows. The Dung 
Beetle Optimization algorithm (DBO) (Xue and Shen 2022) is inspired by the rolling, 
dancing, foraging, stealing, and reproductive behaviors of dung beetles. The Remora Opti-
mization Algorithm (ROA) (Jia et al. 2021) is inspired by the behavior of remoras adhering 
to different-sized hosts to facilitate foraging. The Black Widow Optimization algorithm 
(BWO) (Hayyolalam and Kazem 2020) is inspired by the unique reproductive behavior of 
black widow spiders. Dikshit Chauhan et al. proposed the Artificial Electric Field Algo-
rithm (AFFEA) based on a series of learning strategies (Chauhan and Yadav 2024a, b). 
Additionally, the Secretary Bird Optimization Algorithm (SBOA) was introduced based 
on the survival behavior of secretary birds in their natural environment (Fu et al. 2024b), 
while the Red-Billed Blue Magpie Optimizer (RBMO) was proposed by simulating the 
search, chase, prey attack, and food storage behaviors of red-billed blue magpies (Fu et al. 
2024a).
Generally, the optimization process of the MH algorithm can be divided into two main 
steps (Saka et al. 2016): exploration and exploitation. In the exploration phase, the algo-
rithm mainly focuses on searching all corners of the solution space to ensure that no pos-
sible optimal solution area is missed; while in the exploitation phase, the algorithm will 
focus on known high-quality solutions and further deepen the search in order to find the 
real the optimal solution. These two phases complement each other and ensure that the 
algorithm has both breadth and depth. GWO is inspired by the hunting behavior of grey 
wolves (Mirjalili et al. 2014). GWO effectively balances the two stages of exploration and 
exploitation by combining the social behavior of grey wolves with a dynamically adjusted 
location update strategy, thereby ensuring good global and local search capabilities.

===== PAGE 4 =====
	
M. Yu et al.
277 
Page 4 of 51
Since its introduction in 2014, GWO has received widespread attention from schol-
ars at home and abroad for its simplicity and efficiency, and has become an important 
tool for solving complex optimization problems (Fan and Yu 2022). However, similar to 
other optimization algorithms, the GWO algorithm does have some limitations although 
it has shown quite good performance in many optimization problems. In particularly, 
it is prone to suffer from prematurity and local optimality when dealing with multi-
modal function problems. As the iterative process of the GWO progresses, the inherent 
social hierarchy mechanism within the wolf population leads to a decrease in diversity. 
This mechanism prioritizes the positions and decisions of the leading wolves (Alpha, 
Beta, and Delta), influencing the entire pack’s movement. As a result, the population 
tends to converge towards the leaders’ positions. However, this strong convergence 
driven by the social hierarchy can also lead to a drawback. The population may start 
to aggregate too closely or blindly around the leaders’ current positions. This phenom-
enon, often referred to as premature convergence, limits the algorithm’s ability to thor-
oughly explore the solution space. Consequently, the algorithm might struggle to escape 
local optima, as the current best solutions (guided by the leading wolves) might not 
always represent the global optimum. The pack, following the leaders too closely, can 
get trapped in these local optima, lacking the diversity or exploratory behavior needed 
to venture out and discover better solutions elsewhere in the search space. (Wang et al. 
2018). In addition, when global exploration transitions to local mining, the algorithm 
may lose the ability to explore a wider solution space and overly concentrate on a spe-
cific region for detailed search. Such a centralized strategy, although helpful in finding 
the optimal solution in the local region accurately, may also lead the algorithm to ignore 
other promising regions (Wolpert and Macready 1997). Despite there has been various 
GWO variants, such as Advanced Grey Wolf Optimizer (AGWO) (Meng et al. 2021), 
Exponential Neighborhood Grey Wolf Optimization (EN-GWO) (Mohakud and Dash 
2022), Hybrid Grey Wolf Optimizer with Mutation Operator (DE-GWO) (Gupta and 
Deep 2017), and others (Ambika et al. 2022; Biabani et al. 2022). These improved ver-
sions do not break through in solving the large-scale global optimization problems of 
CEC 2022 and CEC 2013. Moreover, their performance in dealing with complex prob-
lems remains unsatisfactory.
To improve the performance of the GWO, this study incorporates several key enhance-
ments. Firstly, the search mechanism from PSO is employed to increase population diver-
sity. This addition helps in broadening the search scope of the algorithm. Secondly, the 
IMF is used to adjust inertia weights, a strategy that aids in fine-tuning the balance between 
exploration and exploitation. Lastly, an adaptive mechanism based on the Sigmoid function 
is introduced for updating the positions of individuals within the population. This adaptive 
update strategy strengthens the group’s ability to escape local optima, enhancing the over-
all effectiveness of the GWO algorithm in finding optimal solutions.
An improved adaptive grey wolf optimization (IAGWO) is proposed to address the 
shortcomings of the GWO algorithm. The main contributions are as follows.
1)	 The PSO search mechanism is introduced to enhances the algorithm’s search efficiency 
and robustness by updating grey wolf positions early in each iteration. Additionally, the 
dynamic adjustment of inertia weights through the IMF boosts global search capability 
initially and local search effectiveness later.
2)	 Adaptive position updating strategy based on Sigmoid function to balance the explora-
tion and exploitation of IAGWO.

===== PAGE 5 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 5 of 51 
277
3)	 To evaluate the exploration and exploitation capabilities of IAGWO, extensive experi-
mentation is conducted using a suite of 67 test functions, which includes benchmarks 
from the CEC 2014, CEC 2017, CEC 2020, CEC 2022, and CEC 2013 for large-scale 
global optimization problems.
4)	 The effectiveness and accuracy of IAGWO in solving practical engineering design chal-
lenges are thoroughly assessed through its application to 19 diverse engineering design 
challenges.
The paper is organized as follows: Sect.  2 provides a brief review of the previous 
enhancements and potential application directions of the GWO. Section 3 details the origi-
nal GWO algorithm and the proposed improvement strategy. Section 4 evaluates IAGWO 
performance through relevant experiments and in-depth analysis. Finally, Sect. 5 concludes 
this paper with a summary of the results and an outlook on future research directions.
2  Related work
In recent years, there has been a significant focus among researchers on enhancing the 
GWO. These improvements are aimed at boosting the algorithm’s search performance and 
effectiveness. Scholars have explored various approaches to achieve this, including aspects 
such as adjusting the algorithm parameters, improving the speed and position equations, 
and combining it with other algorithms.
Yu et al. (2023) adopted a new update search mechanism, improved control param-
eters, mutation driven strategy and greedy selection strategy to improve GWO in the 
search process. (Singh and Bansal 2022a) proposed a hybrid GWO and Differential Evo-
lution (HGWODE) algorithm and applied it to UAV path planning. (Cuong-Le et  al. 
2022) introduced an equation to control the moving strategy of the algorithm in each 
iteration and proposed New Balance Grey Wolf Optimizer (NB-GWO), which was used 
to optimize the hyperparameters of the deep neural network for damage detection of 
two-dimensional concrete frames. Liu et al. (2023) proposed a hybrid differential evolu-
tion GWO (DE-GWO) algorithm and applied it to gas emission identification and locali-
zation. Luo et  al. (2023) introduced butterfly optimization algorithm and opposition-
based learning method based on elite strategy, adaptive nonlinear inertia weight strategy 
and random walk law to improve the shortcomings of slow convergence speed and low 
accuracy of GWO algorithm when dealing with high-dimensional complex problem. 
To address the issue of premature convergence encountered by the classic GWO in 
some situations due to the stagnation of sub-optimal solutions, Gupta et al. introduced 
an enhanced leadership-inspired grey wolf optimizer for global optimization problems 
(GLF-GWO)(Gupta and Deep 2020), Addressing the issues of slow convergence speed 
and insufficient global exploration in GWO, which can lead to settling in local opti-
mal states and failure to achieve global optimal solutions, Singh et al. proposed a novel 
mutation-driven modified grey wolf optimizer (MDM-GWO) (Singh and Bansal 2022b). 
MDM-GWO integrates new update search mechanisms, modified control parame-
ters, mutation-driven schemes, and greedy selection methods into the search process 
of GWO. Addressing the issues of slow convergence speed and susceptibility to local 
optima in the Grey Wolf Optimizer (GWO) algorithm, Zhang et al. proposed a nonlinear 

===== PAGE 6 =====
	
M. Yu et al.
277 
Page 6 of 51
control parameter strategy based on a sinusoidal function (GWO-SIN) and a nonlinear 
control parameter combination strategy (GWO-COM) (Zhang et al. 2019).
Soliman et  al. (2022) proposed a novel hybrid African vultures–grey wolf optimizer 
(AV–GWO) approach to precisely estimate the electrical parameters of such TDM. 
Nadimi-Shahraki et al. (2021) introduced an enhanced variant of the Grey Wolf Optimiza-
tion algorithm, termed I-GWO. The algorithm, based on a dimensionally learned hunting 
and searching (DLH) strategy, uniquely constructs hunting domains for each Wolf and ena-
bles them to share information about neighboring domains with each other. This enhances 
the algorithm’s local and global search capabilities for more balanced performance, while 
also helping to maintain population diversity. A. Abushawish and A. Jarndal (Abushawish 
and Jarndal 2021) jointly proposed a new hybrid algorithm named GWO-CS that combines 
the advantages of Cuckoo Search (CS) algorithm and GWO algorithm. This algorithm pri-
marily incorporates the position update equation from the CS to further refine the global 
search process of the GWO. Aimed at solving the problems of poor stability and easily 
falling into the local optimal solution in the grey wolf optimizer (GWO) algorithm, Liu 
et al. proposed an improved GWO algorithm based on the differential evolution (DE) algo-
rithm and the OTSU algorithm is proposed (DE-OTSU-GWO) (Liu, Sun, Yu, Wang, & 
Zhou, 2020). The multithreshold OTSU, Tsallis entropy, and DE algorithm are combined 
with the GWO algorithm. The multithreshold OTSU algorithm is used to calculate the fit-
ness of the initial population. The population is updated using the GWO algorithm and 
the DE algorithm through the Tsallis entropy algorithm for crossover steps. Multithreshold 
OTSU calculates the fitness in the initial population and makes the initial stage basically 
stable. Tsallis entropy calculates the fitness quickly. The DE algorithm can solve the local 
optimal solution of GWO. To address the issues of GWO’s susceptibility to local optima 
and its low exploration capabilities, Hardi Mohammed et al. proposed the Enhanced GWO 
(EGWO) (Mohammed et al. 2024). EGWO employs diverse methods to improve the per-
formance of GWO, utilizing gamma, z-position, and the golden ratio.
Liu et  al. (2022) introduced a novel improvement strategy for the GWO algorithm, 
known as the exponential convergence factor improvement strategy. This strategy is 
designed to more accurately simulate the actual search process of grey wolves. It incorpo-
rates dynamic weighting factors and enhances control parameters to reduce the likelihood 
of the GWO algorithm getting stuck in local optima. However, despite these improvements, 
experimental findings indicate that GWO still faces challenges in accurately handling 
high-dimensional functions. Şenel et al. (2019) integrated a differential disturbance oper-
ator into the GWO algorithm. This addition brought an element of exploration into the 
exploitation phase, thereby enhancing the GWO algorithm’s overall optimization capabili-
ties. Jangir and Jangir (2018) proposed a multi-objective version of the GWO algorithm, 
named NSGWO. This algorithm utilizes a crowding distance mechanism to select the opti-
mal solution from a set of Pareto optimal solutions. This approach helps guide the search 
towards the dominant region in multi-objective search spaces. NSGWO was tested on a 
variety of standard unconstrained, constrained, and engineering design challenges, demon-
strating its efficiency and effectiveness in diverse optimization scenarios.
To improve the performance of the GWO, this study incorporates several key enhance-
ments. Firstly, the search mechanism from PSO is employed to increase population diver-
sity. This addition helps in broadening the search scope of the algorithm. Secondly, the 
IMF is used to adjust inertia weights, a strategy that aids in fine-tuning the balance between 
exploration and exploitation. Lastly, an adaptive mechanism based on the Sigmoid function 
is introduced for updating the positions of individuals within the population. This adaptive 

===== PAGE 7 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 7 of 51 
277
update strategy strengthens the group’s ability to escape local optima, enhancing the over-
all effectiveness of the GWO algorithm in finding optimal solutions.
3  Methodology Overview: Standardized GWO and Proposed 
Enhancements
This section offers an overview of the hunting behavior and the mathematical model that 
forms the foundation of the original GWO. Additionally, we introduce the IAGWO, our 
proposed enhancement to GWO. IAGWO integrates the PSO search mechanism, the IMF 
strategy for inertia weighting, and an adaptive strategy for updating positions. These addi-
tions aim to refine and boost the efficiency of the original GWO algorithm.
3.1  The standardized GWO
3.1.1  Inspiration of grey wolf packs’ hunting activity behavior
The GWO algorithm draws inspiration from the hunting behavior of grey wolf packs. It 
mathematically simulates the way a group of grey wolves hunts, encircles, and targets their 
prey while adhering to a well-defined social hierarchy. In this hierarchy, the pack is led by 
three primary wolves: the Alphas (α), Betas (β), and Deltas (δ), each playing a crucial role 
in guiding the pack’s movements and decisions. These wolves are considered the leaders, 
showcasing significant leadership abilities. Below them are the Omega (w) wolves, who 
occupy a subordinate role and follow the directives of the leading wolves. This hierarchical 
structure, integral to the functioning of the GWO algorithm, is depicted in Fig. 1.
3.1.2  Mathematical model: GWO
GWO simulates grey wolf leadership and hunting mechanisms by dividing grey wolves based 
on their characteristics into a leader, α, who rules over the entire grey wolf; a facilitator, β, 
who helps α to make decisions and replaces α when α dies; and an enforcer, δ, who follows α’s 
Fig. 1   Hierarchy of the grey 
Wolf Pack

===== PAGE 8 =====
	
M. Yu et al.
277 
Page 8 of 51
and β’s orders (Fan and Yu 2022). GWO searches for excellence by modeling the wolf hunt-
ing process. In addition to the social hierarchy of wolves, group hunting is another interesting 
social behavior of grey wolves. The main phases of grey wolf hunting are as follows: The Grey 
Wolf Optimizer algorithm mimics the hunting behavior of grey wolf packs. Initially, in the 
"tracking, chasing, and approaching prey" phase, each wolf searches for potential solutions 
in the solution space and adjusts its position through certain search strategies to get closer to 
possible candidate solutions. Subsequently, in the "chasing, surrounding, and harassing prey 
until it stops moving" phase, the wolf pack collaborates to try to corner the prey into a smaller 
area and prevent its escape, involving behaviors such as encircling and harassing the prey to 
prevent its escape. Finally, in the "attacking prey" phase, once the prey is cornered and unable 
to escape, the wolves concentrate their attack on the prey, gradually optimizing the position 
of candidate solutions through strategies such as linear or leap searches until finding the opti-
mal solution or meeting specific optimization criteria. These three phases represent the Grey 
Wolf Optimization algorithm’s process of searching, chasing, and optimizing in the solution 
space, analogous to the behavior of a grey wolf pack during hunting, progressing from search 
to attack, gradually optimizing and approaching the optimal solution.
Now, this paper shows the calculation steps of the basic grey Wolf Optimization algorithm 
and the pseudo-code as follows (Algorithm 1). The GWO algorithm process is as follows:
1) Each member is initialized using Eq. (1), determine the population size N, the maximum 
number of iterations M, the single grey wolf dimension dim, and ɑ, A and C;
where, LB and UB are the lower and upper boundaries of the solution space, respectively. X 
represent the positions of the current solution. phi is a random number between [0,1].
2) Calculate the fitness value of each individual using the test function. Then, based on the 
magnitude of the fitness values, select the best-fit individual as the α-wolf, the second-best 
individual as the β-wolf, and the third-best individual as the δ-wolf;
3) The mathematical model of Wolf pack leader tracking prey is shown in Eq. (2), which 
calculates the traction direction of the entire pack according to the distance difference between 
the Wolf leader and the pack, that is, the movement direction information of the pack, can be 
calculated as shown in Eqs. (3) and (4). Update the current grey wolf position according to 
Eqs. (2)– (4).
where Dα, Dβ, and Dδ denote the distance difference between α-wolf, β-wolf, and δ-wolf 
and other individuals, respectively. ­Xα, ­Xβ, and ­Xδ indicate the current positions of α-wolf, 
(1)
X = (UB −LB) × phi + lb
(2)
⎧
⎪
⎨
⎪⎩
D훼= C1X훼−X
D훽= C2X훽−X
D훿= C3X훿−X
(3)
⎧
⎪
⎨
⎪⎩
X1 = X훼−A1D훼
X2 = X훽−A2D훽
X3 = X훿−A3D훿
(4)
X(t + 1) = X1 + X2 + X3
3

===== PAGE 9 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 9 of 51 
277
β-wolf, and δ-wolf respectively, X indicate the current positions C1, C2, and C3 satisfy the 
constraints of Eq. (6). A1, A2, and A3 are random vectors satisfying the constrain of Eq. (5); 
X1, X2 and X3 are the traction directions of the three leading wolves; and X(t + 1) represents 
the next collective movement position of the wolf pack. As shown in Fig. 2, the final orien-
tation of the wolves in the search space will be randomly positioned within a circle defined 
by the locations of the α, β, and δ in the search space. This graphical representation illus-
trates how the wolves’ positions influence the movement and direction of the entire pack in 
the pursuit of their prey.
4) Update ɑ, A and C according to Eqs. (5)–(7);
where, the parameter ɑ plays a crucial role in balancing global search and local explora-
tion. Its value is set to decrease linearly from 2 to 0 over the course of the algorithm’s itera-
tions. Initially, a higher value of ɑ aids in the global convergence of the algorithm, guiding 
the wolf pack swiftly towards the region where the optimal solution might be found. As 
the algorithm progresses through its later iterations, the gradual decrease in the value of ɑ 
facilitates more refined exploration in the area of the optimal solution. This helps improve 
(5)
A = 2a ⋅r1 −a
(6)
C = 2r2
(7)
a = 2 −2t
M
Fig. 2   Position update of wolf groups in GWO algorithm

===== PAGE 10 =====
	
M. Yu et al.
277 
Page 10 of 51
the convergence accuracy of the GWO algorithm, ensuring a more precise final result. r1 
and r2 are random vectors and r1, r2 ∈ [0, 1].
5) Update the positions of other individuals, calculate the updated fitness value based 
on the new position, and update the α-wolf, β-wolf, δ-wolf and global optimal solution, R 
represents the position vector of the optimization target;
6) Judge whether the specified stopping condition is reached (e.g., the maximum num-
ber of iterations is reached), if not, repeat steps 2 to 5. Otherwise, output the optimal result: 
the position of the α-wolf obtained at the end is the optimal solution, and the correspond-
ing fitness value is the degree of superiority or inferiority of the optimal solution. 
Algorithm 1:    GWO
3.2  Improved grey wolf optimization algorithm
3.2.1  PSO search mechanism
The GWO (Grey Wolf Optimizer) exhibits a weak exploratory capability in its early 
stages and lacks diversity within the population, consequently resulting in subopti-
mal solution quality. In order to enhance exploration capabilities, improve population 
diversity (Hu et al. 2022), and increase the quality of solutions (Hakli and Kiran 2020), 
this study integrates the PSO, introducing a velocity concept to provide a new search 
mechanism for the GWO. The individual grey wolves are updated in terms of posi-
tion during the early iterations, and the application in the velocity update introduces 
additional randomness. This prevents the algorithm from converging prematurely 
and encourages exploration of new areas, thereby increasing population diversity. By 
dynamically adjusting the velocity and position of each individual, this method may 

===== PAGE 11 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 11 of 51 
277
help in more effectively balancing global exploration and local exploitation. Leading 
to a wider search in the early stage of the iteration, this assists in identifying potential 
high-quality solutions. The computation Eq. (8) is as follows:
where t represents the current number of iterations, X and Xbest represent the positions of 
the current solution and the best-performing solution, respectively. vrand(t) is the velocity 
vector of the current solution at time t of iteration. phi is a random number between [0,1]. 
Xselfbest is the best position vector in the history of the current solution.
In this study, at the start of each iteration, a PSO updating strategy is employed, 
along with the addition of extra randomness to stimulate a more extensive global 
search. This approach helps avoid local optimization and increases population diver-
sity. This approach not only accumulates a more diverse and high-quality search expe-
rience for the GWO but also more effectively balances global exploration and local 
exploitation by dynamically adjusting the search behavior.
3.2.2  IMF inertia weighting strategy
Inverse Multiquadric Function is a decreasing function based on the principle of 
inverse multiple squares. It is often used as a regularization method in neural net-
works, such as a kernel function in support vector machines (Hu et al. 1998; Rathan 
et al. 2023). In accordance with the characteristics of the IMF, this paper incorporates 
it into the population position update mechanism within the framework of the GWO as 
delineated in Eq. (3). The IMF inertia weight ω, along with the revised formulae for 
the wolf pack updating process, are elucidated in Eqs. (9)–(10).
where, the parameter groups [a, b, c, d] are taken as [0.6, 0.02, 0.05, 0.3] and the graph of 
ω is shown in Fig. 3. As indicated by Fig. 3, during the early to mid-phases of the algo-
rithm’s iteration, the inertia weight ω is set to a higher value. This larger influence of the 
α-wolf, β-wolf, and δ-wolf on the updated positions is beneficial for the pack to quickly 
converge towards the optimal solution, effectively preventing the waste of search resources 
due to blind searching and thus enhancing the quality of the pack. As the development 
progresses to the mid and late stages and the pack becomes densely concentrated, if the 
higher-ranking wolves get trapped in a local optimum, the lower-ranking wolves led by 
them are also unable to escape this local optimum. At this juncture, the value of ω should 
be reduced to a lower level, thereby enlarging the pack’s autonomous search capability and 
avoiding premature convergence.
(8)
{ vrand(t) = vrand(t) + phi ∗(
Xbest −X
)
+ phi ∗
(
Xselfbest −X
)
X = X + vrand(t)
(9)
휔= a ⋅e(−b⋅e(−c⋅t)) + d
(10)
⎧
⎪
⎨
⎪⎩
X1 = X훼−휔A1D훼
X2 = X훽−휔A2D훽
X3 = X훿−휔A3D훿

===== PAGE 12 =====
	
M. Yu et al.
277 
Page 12 of 51
3.2.3  Adaptive updating mechanism
The population updating mechanism based on IMF inertia weight effectively reduces the 
density of population clustering to a certain extent. However, due to the intrinsic dynamics 
of the GWO, the newly generated wolf packs are still inevitably concentrated and migrate 
towards the positions directed by the α-wolf, β-wolf, and δ-wolf during the iterative pro-
cess. In response to this, the present study defines the aggregation coefficient as the ratio 
of an individual’s fitness value to the average population fitness value, which serves to 
quantify the degree of divergence between the current solution and the optimal solution. 
In minimization problems, the smaller the fitness value, the better the solution. A smaller 
aggregation coefficient indicates a more favorable current solution, thus allowing for minor 
updates in the vicinity of the individual’s current position. Conversely, a larger aggregation 
coefficient suggests a poor location of the individual, warranting a significant perturbation 
to facilitate a jump to other positions. Based on this analysis, this paper introduces a Sig-
moid function to construct the adaptive updating amplitude of the population under differ-
ent aggregation coefficients, as depicted in Eqs. (11)-(12).
where fi represents the fitness value of the ith individual, and fave denotes the average fitness 
value of the population. θ is the exponential coefficient, which is taken as 0.5 in this paper.
In comparison to the standard GWO, the IAGWO brings several significant advance-
ments. Firstly, it introduces a novel search mechanism by incorporating velocity con-
cepts. This addition helps in preventing premature convergence and allows for a more 
thorough exploration of the search space. The integration of velocity updates also adds 
(11)
휙=
1
1 + (e−fi∕fave)휃
(12)
Yi = Yi ⋅휙
Fig. 3   IMF Inertia Weight Graph

===== PAGE 13 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 13 of 51 
277
an element of randomness, which in turn increases the diversity within the population of 
solutions. Moreover, the implementation of the IMF inertia weight strategy in IAGWO 
improves the balance between exploring the global search space and exploiting local 
solutions. This strategic enhancement significantly boosts the convergence speed of the 
algorithm. Furthermore, IAGWO differentiates itself from the standard GWO through 
its adaptive updating mechanism. This mechanism combines the aggregation coeffi-
cient with the Sigmoid function, enhancing the algorithm’s ability to switch between 
broad search patterns and detailed solution refinement. This results in improved perfor-
mance in maintaining diversity and achieving faster convergence rates. This adaptive 
approach enables IAGWO to search and optimize more efficiently within the solution 
space of the problem. For an in-depth comprehension of the workings of IAGWO, the 
Fig. 4   Implementation Process for IAGWO
Fig. 5   Working procedure of the proposed IAGWO algorithm

===== PAGE 14 =====
	
M. Yu et al.
277 
Page 14 of 51
procedural flow is visually depicted in Fig. 4, its pseudocode is meticulously detailed in 
Algorithm 2, and the proposed IAGWO workflow(Chauhan & Yadav 2023b) is shown 
in Fig. 5.
Algorithm 2:   IAGWO
3.3  Time complexity analysis
CEC17 (Competition on Evolutionary Computation) defines algorithm complexity as a 
measure of the computational resources required by an algorithm to solve a given problem 
instance. This section explains the computational complexity of IAGWO. The complex-
ity of IAGWO is primarily influenced by two main factors: the initialization of solutions 
and the execution of the algorithm’s core functions. These core functions involve calculat-
ing fitness functions and updating solutions. The computational complexity is determined 
by considering several variables: the count of solutions (N) , the upper limit of iterations 
(T) , and the problem’s dimension (D) being tackled. Specifically, the complexity of ini-
tializing solutions in the IAGWO algorithm can be represented as O(N) , indicating the 
order of complexity in relation to the number of solutions. This gives an understanding 

===== PAGE 15 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 15 of 51 
277
of the computational resources required for the initial setup phase of the algorithm. This 
means that as the number of solutions N increases, the computational complexity of the 
initial solution of the algorithm will also increase accordingly. This represents the order 
of complexity for the initial setup phase of the algorithm. The time complexity of the 
original GWO algorithm is O(T × N × D) . IAGWO modifies this with Eqs. (8), (9), and 
(10)–(11), including enhancements to population diversity using the PSO position updat-
ing strategy, integration of IMF weights to reduce the excessive influence of higher-level 
wolves on lower-level ones, and the introduction of a population adaptive update based 
on the sigmoid function. The PSO position updating strategy requires calculations for 
each individual and each dimension, with a complexity of O(T × N × D) . The update from 
Eq. (10) is independent of population size and search dimensions, correlating only with 
the maximum number of iterations, resulting in a time complexity of O(T) . The time com-
plexity for Eq. (11) is O(N × D) . Consequently, the overall time complexity of IAGWO 
is O(IAGWO) = O(T × N × D) + O(T) + O(N × D) = O(T × N × D) , consistent with the 
original algorithm.
4  Results and comprehensive analysis
The simulation for this study was carried out on a Windows 11 platform, operating on a 
64-bit system. The analysis was performed using MATLAB 2023b, running on a machine 
equipped with an AMD Ryzen 7 4800H CPU at 2.30 GHz and 16 GB of RAM.
4.1  Test functions and parameter settings
In this paper, the CEC 2017 (Dim = 30) (Mallipeddi and Suganthan 2010), CEC 2020 
(Dim = 10 and 20) (Liang et al. 2019), and CEC 2022 (Dim = 10 and 20) (Ahrari et al. 
2022) test suites were employed to evaluate the performance of the proposed IAGWO algo-
rithm. The test suite for evaluating algorithms covers four different functional types: single-
modal, multimodal, mixed, and combined. These different types of test suites are designed 
to comprehensively evaluate the performance and applicability of algorithms. Addition-
ally, for assessing the scalability of the IAGWO algorithm, we employed the CEC 2013 
Large-scale Global Optimization suite (800-dimensional) for simulation analysis (Li et al. 
2013). The suite contains 15 highly complex reference functions that are grouped into four 
groups: fully separable, partially additively separable, overlapping, and completely indivis-
ible. These different types of benchmark functions provide a comprehensive experimental 
framework for evaluating the scalability of optimization algorithms, so that we can more 
accurately evaluate the performance of IAGWO algorithm on different types of problems.

===== PAGE 16 =====
	
M. Yu et al.
277 
Page 16 of 51
4.2  Comparison with other algorithms and parameter settings
The performance of the Improved Adaptive Grey Wolf Optimization (IAGWO) is 
benchmarked against 12 well-known algorithms, grouped into three categories for 
comparison:
High-citation algorithms: These include the Gravitational Search Algorithm (GSA) 
(Rashedi et al. 2009), Dolphin Echolocation Optimization (DMO) (Kaveh and Farhoudi 
2013), Whale Optimization Algorithm (WOA) (Mirjalili and Lewis 2016), and Harris 
Hawks Optimization (HHO) (Tripathy et al. 2022).
Advanced algorithms: This category includes Combined Particle Swarm Optimiza-
tion and Gravitational Search Algorithm (CPSOGSA), Crow Optimization Algorithm 
(COA) (Jia et al. 2023), African Vulture Optimization Algorithm (AVOA) (Abdollahza-
deh et al. 2021), Optical Microscope Algorithm (OMA) (Cheng and Sholeh 2023), and 
Adaptive Artificial Electric Field Algorithm (iAEFA) (Chauhan and Yadav 2023a).
GWO and its variants: This includes the original Grey Wolf Optimization (GWO), 
the Adaptive GWO (AGWO) (Meidani et  al. 2022), the Enhanced GWO (ENGWO)
(Mohammed et al. 2024)and the Revised GWO (RGWO) (Banaie-Dezfouli et al. 2021).
Table 1 offers a comprehensive summary of the parameters for 14 different MH algo-
rithms. For each of these algorithms, 30 independent runs were conducted, with each 
run limited to a maximum of 500 iterations and population size is set to 30 and a maxi-
mum of 30,000 evaluations. The outcomes of these runs were meticulously recorded, 
capturing the average values (denoted as Ave) and the standard deviations (Std) for each 
algorithm. To facilitate an easy comparison of their performance, the table highlights 
the best results among these 14 algorithms by formatting them in bold text. This high-
lighting method provides a clear visual indicator of which algorithms performed most 
effectively under the given testing conditions.
Table 1   Parameter configurations 
for competing algorithms
Algorithms
Parameter
Value
GSA
α, G0
20, 100
DMO
peep
2
WOA
a, a2, b
[0,2], [− 1,−2], 1
HHO
E0, E1
[− 1,1], [0,2]
CPSOGSA
φ 1, φ2
2.05, 2.05
COA
C1, C2, μ, σ
0.2, 3, 25, 3
AVOA
L1, L2, w, p1, p2, p3
0.8, 0.2, 2.5, 0.6, 0.4, 0.6
OMA
mr
[0,1]
GWO
a
[0,2]
AGWO
a
[0,2]
ENGWO
a
[0,2]
iAEFA
Rpower, ­FCheck, ­Rnorm
1, 1, 2
RGWO
σinitial, σfinal, Exponent
1, 0, 2
IAGWO
vrand(t), a, ω,θ
[− 20,20],[0,2], [0.3,0.9], 0.5

===== PAGE 17 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 17 of 51 
277
4.3  Qualitative assessment of IAGWO
4.3.1  Exploring convergence patterns
To verify the convergence performance of IAGWO, we plotted its convergence perfor-
mance evaluation on the 30-dimensional CEC2017 test functions, as shown in Fig. 6. It 
presents the corresponding results of different test functions in the form of nine images 
involving three instances selected from the same suite. In the presentation of images, 
the first column distinctly illustrates the two-dimensional profiles of the reference func-
tions being analyzed. The visuals presented in the first column accurately depict the 
characteristics and contours of each function being optimized. These graphical repre-
sentations offer a clear understanding of the challenges and intricacies of each function. 
In the second column, images depict the final positions of the search agents at the end 
of the optimization process. Within these visuals, the optimal solution’s location is dis-
tinctly marked with a red dot. This not only illustrates the end point of the search agents’ 
Fig. 6   The convergence behavior of IAGWO

===== PAGE 18 =====
	
M. Yu et al.
277 
Page 18 of 51
journey but also visually highlights the spot where they successfully identified the most 
favorable solution. This layout effectively communicates the results of the optimization 
process, making it easier to comprehend the behavior and efficacy of the search agents 
in navigating the solution space. This layout offers a clear and informative view of both 
the nature of the functions and the outcomes of the optimization process. By observ-
ing the second column of images, we can clearly find that the search agent is close to 
the optimal solution in most cases, which fully reflects the powerful ability of IAGWO 
algorithm in the process of exploration and development. In addition, the third column 
image accurately tracks the change of the average fitness value during the iteration. Ini-
tially high, these values decrease and stabilize after 100 iterations, albeit with minor 
fluctuations. These fluctuations are normal in complex optimization problems, indicate 
ongoing detailed searches for improvement and the maintenance of population diversity 
to prevent premature convergence to local optima. The fourth column reveals the search 
agents’ trajectories in the first dimension, there were marked fluctuations in the early 
iterations, which then leveled off, and then fluctuations again at intervals, which leveled 
off again, signifying a balance between exploration and exploitation. Finally, the con-
vergence curve, smooth for unimodal functions, suggests optimal values are achievable 
through iteration. For multimodal functions, however, the step-like curve reflects the 
need for continual avoidance of local optima to reach global optima. These four metrics 
collectively affirm IAGWO’s robust convergence.
Fig. 6   (continued)

===== PAGE 19 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 19 of 51 
277
4.3.2  Analyzing the diversity of population
In optimization algorithms, the importance of population diversity is a matter of balance. 
Moderate population diversity can help the algorithm avoid falling into local optima, 
thereby increasing search space coverage and global search capability, improving conver-
gence speed, and the quality of optimization results. However, excessive population diver-
sity may lead to overly dispersed search, making it difficult for the algorithm to explore 
local regions deeply, thereby reducing convergence speed and the quality of final solutions. 
Therefore, when designing optimization algorithms, it is necessary to consider a balance 
between population diversity and search efficiency. This can be achieved through appropri-
ate parameter settings or suitable strategies to maintain population diversity, thus effec-
tively solving optimization problems. A population with high diversity indicates significant 
differences among individuals, allowing for broader exploration in the search space and 
avoiding premature convergence to local optima. Hence, maintaining good population 
diversity is a crucial objective in metaheuristic algorithms. Typically, we use Eq. (13) and 
Eq. (14) to measure the population diversity of the algorithm. This calculation method was 
proposed by Morrison in 2004. Where,  IC represents the moment of inertia, xid denotes the 
ith search agent’s value in the dth dimension at iteration t. Furthermore, cd represents the 
spread of the population from its center of mass, denoted by ’c’, in every iteration, as illus-
trated in Eq. (14) (Fu et al. 2023a, b).
Figure 7 displays the comparative experimental outcomes regarding population diver-
sity for both IAGWO and GWO. The measurement of population diversity is conducted 
through IC . Observations from Fig. 7 reveal that IAGWO demonstrates an initial marked 
increase in diversity during the early phases of iteration, which then transitions to a state of 
relative stability at an elevated level. This indicates an increase in the variance among indi-
viduals within the IAGWO population during the early iterations, effectively exploring a 
vast search space. As iterations progress, the population diversity tends to stabilize, which 
aids in averting premature convergence to local optima. The minor fluctuation are normal 
and beneficial for the algorithm to adapt to dynamically changing search spaces and pre-
vent premature convergence. In contrast, GWO shows insufficient population diversity, 
highlighting IAGWO’s effectiveness in maintaining diversity, crucial for exploring com-
plex search spaces and avoiding local optima. These experimental outcomes demonstrate 
IAGWO’s substantial potential in optimization.
4.3.3  Exploration and exploitation analysis
In optimization algorithms, managing the balance between exploration and exploitation is 
key for optimal performance (Saka et al. 2016). Exploration involves searching through the 
solution space, while exploitation focuses on refining known good solutions. This section 
(13)
IC(t) =
√
√
√
√
n
∑
i=1
dim
∑
d=1
(xid(t) −cd(t)
)2
(14)
cd(t) =
1
dim
n
∑
i=1
xid(t)

===== PAGE 20 =====
	
M. Yu et al.
277 
Page 20 of 51
deals with quantifying the extent of exploration and exploitation in the algorithm. To do 
this, we use Eq. (15) to calculate the percentage of exploration and Eq. (16) for the per-
centage of exploitation. Additionally, the parameter Div(t) used for measuring dimension 
diversity is calculated using Eq.  (17). The parameter Divmax reflects the peak diversity 
noted throughout the entire course of iterations,, which is essential for understanding how 
broadly and effectively the algorithm explores the solution space(Li et al. 2023) (Nadimi-
Shahraki et al. 2023).
Figure 8 depicts the results of the experiments conducted. It shows that for various func-
tion types, as the number of iterations progresses, GWO consistently demonstrates a higher 
rate of exploration and a comparatively lower rate of exploitation. In contrast, IAGWO 
shows a changing pattern, with exploration decreasing and exploitation increasing as itera-
tions progress. This observation suggests that GWO tends towards a broad search across 
(15)
Exploration(%) = Div(t)
Divmax
× 100
(16)
Exploitation(%) =
||Div(t) −Divmax||
Divmax
× 100
(17)
Div(t) =
1
dim
dim
∑
d=1
1
n
n
∑
i=1
||median(xd(t)) −xid(t)||
Fig. 7   The population diversity of IAGWO and GWO

===== PAGE 21 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 21 of 51 
277
the entire space, with less focus on local search and weaker performance in thoroughly 
exploiting the optimal regions found. In comparison, IAGWO demonstrates the ability to 
dynamically adjust its search strategy. This implies that the algorithm initially identifies 
potential good solution areas through extensive exploration and then finely tunes these 
solutions in the later stages through focused exploitation, potentially enhancing both the 
efficiency of the algorithm and the quality of solutions. Overall, while GWO shows com-
mendable exploration capabilities, it lacks effective exploitation. In contrast, IAGWO 
effectively strikes a balance between exploration and exploitation. This balance is well-
maintained across a variety of benchmark functions, showcasing IAGWO’s adaptability 
and efficiency in different optimization scenarios. This attribute is particularly important as 
it ensures the algorithm can thoroughly search the solution space while also honing in on 
the most promising solutions.
4.3.4  Ablation experiments
In this section, a detailed analysis is conducted on the impact of three proposed improve-
ment strategies on the GWO. These strategies include the PSO position updating mecha-
nism, the introduction of IMF inertia weight strategy, and the adoption of a Sigmoid adap-
tive updating strategy. Based on these improvements, three new algorithm variants are 
named: PGWO for the PSO search mechanism, IGWO for the IMF inertia weight, and 
SGWO for the Sigmoid adaptive updating strategy. According to the experimental results 
Fig. 8   The exploration and exploitation of IAGWO and GWO

===== PAGE 22 =====
	
M. Yu et al.
277 
Page 22 of 51
in Fig. 9, all three strategies significantly enhance the convergence accuracy and speed of 
GWO, with IAGWO showing particularly notable performance.
Specifically, when dealing with unimodal and multimodal functions, the results of 
PGWO and IAGWO are relatively consistent, showing a more significant improvement 
over GWO compared to SGWO and IGWO. However, when dealing with more com-
plex hybrid modal functions, the enhancement of PGWO on GWO diminishes, while the 
IAGWO algorithm, integrating all three strategies, continues to exhibit exceptional opti-
mization performance. Overall, the IAGWO algorithm successfully overcomes challenges 
of local optima and premature convergence, significantly boosting the algorithm’s conver-
gence speed and accuracy. These findings provide valuable insights for the further develop-
ment and application of the GWO.
4.4  Quantitative evaluation
In this section, the efficacy of IAGWO is scrutinized using a series of test suites: CEC 
2017, CEC 2020, and CEC 2022. Moreover, its proficiency in handling large-scale prob-
lems is assessed with the CEC 2013 suite. To clearly compare performance, the best results 
among the algorithms are highlighted in bold in the tables. The parameters are standard-
ized with a population size of 100, a maximum iteration limit of 500, and a total of 30 
independent runs. The performance outcomes are systematically presented in Tables 2 to 
7, which illustrate the average values (Ave) and the standard deviations (Std) for each com-
peting algorithm. A thorough statistical analysis is conducted to highlight the superiority 
Fig. 9   Comparison of different improvement strategies

===== PAGE 23 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 23 of 51 
277
Table 2   Comparison of results on CEC 2017 (Dim = 30)
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
CEC2017-F1
Ave
1.51E + 10 2.76E + 07
1.18E + 10 8.66E + 09 3.92E + 09
3.61E + 09 7.21E + 07
3.54E + 09
3.88E + 09
7.98E + 09 5.38E + 09
1.36E + 10 6.00E + 06 2.36E + 05
Std
4.47E + 09 1.65E + 07
3.39E + 09 2.59E + 09 2.67E + 09
3.15E + 09 1.21E + 08
1.70E + 09
2.37E + 09
5.03E + 09 3.18E + 09
3.83E + 09 3.27E + 06 8.39E + 04
CEC2017-F2
Ave
6.57E + 45 9.16E + 34
2.06E + 37 1.75E + 40 3.70E + 42
8.46E + 31 4.75E + 29 3.91E + 31
1.44E + 35
3.21E + 34 7.36E + 34
1.80E + 46 1.74E + 34 1.97E + 33
Std
3.06E + 46 1.94E + 35
6.20E + 37 9.51E + 40 1.51E + 43
4.49E + 32 2.54E + 30 1.53E + 32
5.49E + 35
1.75E + 35 3.95E + 35
7.72E + 46 7.58E + 34 1.08E + 34
CEC2017-F3
Ave
1.74E + 10 1.38E + 05
1.27E + 05 2.10E + 05 1.37E + 05
1.57E + 05 1.11E + 05
5.58E + 04
7.19E + 04
6.82E + 04 6.87E + 04
7.71E + 04 9.84E + 04 2.12E + 04
Std
9.50E + 10 2.17E + 04
3.16E + 04 8.97E + 04 3.84E + 04
5.23E + 04 3.72E + 04
1.02E + 04 1.46E + 04
2.04E + 04 1.46E + 04
1.38E + 04 5.80E + 04 1.05E + 04
CEC2017-F4
Ave
5.05E + 03 5.95E + 02 2.91E + 03 3.25E + 03 1.27E + 03
8.33E + 02 6.40E + 02
1.02E + 03
7.45E + 02
1.22E + 03 9.81E + 02
5.33E + 03 9.47E + 02 6.99E + 02
Std
1.51E + 03 3.28E + 01 1.09E + 03 1.32E + 03 6.20E + 02
1.86E + 02 5.06E + 01
2.56E + 02
1.57E + 02
7.74E + 02 4.35E + 02
2.56E + 03 5.30E + 02 2.34E + 02
CEC2017-F5
Ave
7.18E + 02 7.44E + 02
8.48E + 02 7.60E + 02 7.85E + 02
7.35E + 02 7.07E + 02
7.19E + 02
6.50E + 02
6.72E + 02 6.36E + 02 6.92E + 02 6.64E + 02 6.37E + 02
Std
2.71E + 01 1.28E + 01 4.30E + 01 2.11E + 01 5.18E + 01
2.49E + 01 3.09E + 01
3.47E + 01
4.17E + 01
3.66E + 01 4.20E + 01
3.72E + 01 3.00E + 01 2.09E + 01
CEC2017-F6
Ave
6.63E + 02 6.05E + 02 6.86E + 02 6.75E + 02 6.77E + 02
6.57E + 02 6.56E + 02
6.38E + 02
6.16E + 02
6.32E + 02 6.23E + 02
6.58E + 02 6.29E + 02 6.08E + 02
Std
5.86E + 00 1.34E + 00 1.26E + 01 8.17E + 00 9.89E + 00
1.11E + 01 8.62E + 00
1.03E + 01
5.22E + 00
1.01E + 01 8.22E + 00
6.90E + 00 7.79E + 00 6.15E + 00
CEC2017-F7
Ave
1.16E + 03 1.00E + 03
1.35E + 03 1.36E + 03 1.78E + 03
1.26E + 03 1.14E + 03
1.31E + 03
9.24E + 02
9.83E + 02 9.26E + 02
9.69E + 02 9.41E + 02 8.78E + 02
Std
9.27E + 01 1.79E + 01 7.73E + 01 5.90E + 01 2.14E + 02
7.14E + 01 7.87E + 01
1.30E + 02
8.40E + 01
5.10E + 01 5.80E + 01
6.10E + 01 5.26E + 01 3.01E + 01
CEC2017-F8
Ave
9.60E + 02 1.05E + 03
1.08E + 03 9.91E + 02 1.05E + 03
9.65E + 02 9.63E + 02
1.00E + 03
9.30E + 02
9.48E + 02 9.18E + 02
9.46E + 02 9.36E + 02 9.00E + 02
Std
2.46E + 01 1.78E + 01 3.82E + 01 2.06E + 01 3.97E + 01
1.82E + 01 2.78E + 01
3.37E + 01
4.64E + 01
2.80E + 01 2.67E + 01
2.63E + 01 2.63E + 01 1.97E + 01
CEC2017-F9
Ave
5.26E + 03 2.95E + 03 1.43E + 04 1.12E + 04 8.50E + 03
8.82E + 03 6.16E + 03
6.71E + 03
3.55E + 03
5.40E + 03 4.06E + 03
4.85E + 03 6.42E + 03 3.18E + 03
Std
8.40E + 02 7.94E + 02
4.29E + 03 1.63E + 03 2.10E + 03
1.80E + 03 9.63E + 02
1.33E + 03
1.36E + 03
1.53E + 03 1.54E + 03
1.03E + 03 1.80E + 03 7.41E + 02
CEC2017-F10 Ave
4.87E + 03 8.49E + 03
7.24E + 03 6.05E + 03 5.25E + 03
7.54E + 03 5.19E + 03
8.27E + 03
4.90E + 03
4.64E + 03 4.74E + 03
5.09E + 03 4.07E + 03 3.52E + 03
Std
6.38E + 02 2.99E + 02 7.69E + 02 9.26E + 02 8.30E + 02
4.70E + 02 7.04E + 02
3.05E + 02
1.46E + 03
1.15E + 03 1.59E + 03
7.29E + 02 7.47E + 02 6.20E + 02
CEC2017-F11 Ave
2.55E + 04 3.30E + 03
8.81E + 03 1.08E + 04 4.31E + 03
3.48E + 03 2.53E + 03
2.20E + 03
6.68E + 03
8.37E + 03 1.19E + 04
4.81E + 04 4.31E + 03 1.31E + 03
Std
7.22E + 03 7.61E + 02
3.42E + 03 4.81E + 03 3.70E + 03
1.35E + 03 1.10E + 03
9.02E + 02
4.18E + 03
4.34E + 03 6.41E + 03
1.58E + 04 4.69E + 03 1.88E + 02
CEC2017-F12 Ave
1.80E + 09 7.55E + 07
1.62E + 09 1.16E + 09 5.92E + 08
5.87E + 07 6.77E + 07
2.03E + 08
4.95E + 08
7.17E + 08 6.66E + 08
2.33E + 09 7.65E + 07 5.39E + 06
Std
9.48E + 08 3.90E + 07
9.40E + 08 6.26E + 08 1.96E + 09
8.65E + 07 5.88E + 07
2.70E + 08
6.14E + 08
8.25E + 08 7.56E + 08
1.48E + 09 1.47E + 08 2.66E + 07
CEC2017-F13 Ave
7.05E + 07 2.18E + 04
1.15E + 08 8.35E + 07 4.58E + 04
8.45E + 04 7.63E + 04
1.53E + 05
6.51E + 07
1.03E + 08 8.63E + 07
3.40E + 08 1.18E + 07 3.18E + 03
Std
1.39E + 08 2.43E + 04
1.36E + 08 2.11E + 08 4.80E + 04
6.59E + 04 7.05E + 04
2.49E + 05
1.51E + 08
1.74E + 08 1.96E + 08
5.88E + 08 4.81E + 07 1.86E + 03
CEC2017-F14 Ave
3.06E + 06 3.07E + 05
1.10E + 06 1.04E + 06 4.25E + 05
5.37E + 05 3.55E + 05
7.45E + 03 1.73E + 06
2.12E + 06 2.20E + 06
1.80E + 07 1.55E + 06 1.68E + 05
Std
4.63E + 06 3.06E + 05
1.07E + 06 1.07E + 06 5.26E + 05
5.94E + 05 3.42E + 05
1.27E + 04 2.99E + 06
2.68E + 06 2.81E + 06
1.08E + 07 4.01E + 06 8.52E + 05

===== PAGE 24 =====
	
M. Yu et al.
277 
Page 24 of 51
Table 2   (continued)
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
CEC2017-F15 Ave
8.43E + 03 2.81E + 05
1.05E + 06 2.28E + 05 2.96E + 04
4.87E + 04 5.04E + 04
1.62E + 04
3.23E + 04
2.63E + 07 3.21E + 04
1.43E + 05 2.71E + 03 1.98E + 03
Std
3.08E + 03 1.57E + 05
1.10E + 06 1.29E + 05 2.27E + 04
4.26E + 04 5.56E + 04
2.19E + 04
1.86E + 04
1.44E + 08 3.15E + 04
6.96E + 05 1.74E + 03 6.00E + 02
CEC2017-F16 Ave
3.60E + 03 3.56E + 03
4.12E + 03 3.86E + 03 3.02E + 03
3.05E + 03 3.19E + 03
3.13E + 03
2.50E + 03 2.69E + 03 2.66E + 03
3.62E + 03 2.96E + 03 2.64E + 03
Std
4.40E + 02 1.90E + 02 8.26E + 02 5.61E + 02 4.96E + 02
4.26E + 02 4.50E + 02
3.53E + 02
3.91E + 02
3.09E + 02 3.52E + 02
4.94E + 02 5.44E + 02 3.12E + 02
CEC2017-F17 Ave
2.82E + 03 2.58E + 03
2.90E + 03 3.04E + 03 2.79E + 03
2.34E + 03 2.67E + 03
2.32E + 03
2.06E + 03 2.09E + 03 2.19E + 03
2.87E + 03 2.42E + 03 2.19E + 03
Std
2.71E + 02 1.65E + 02
3.62E + 02 3.13E + 02 3.04E + 02
1.97E + 02 3.08E + 02
1.93E + 02
1.33E + 02 1.41E + 02 1.89E + 02
2.40E + 02 2.59E + 02 1.73E + 02
CEC2017-F18 Ave
4.28E + 06 4.65E + 06
3.70E + 07 1.15E + 07 1.61E + 06
1.84E + 06 1.83E + 06
3.82E + 05
1.56E + 06
1.52E + 06 2.04E + 06
9.30E + 06 2.97E + 06 2.23E + 05
Std
3.92E + 06 2.52E + 06
4.64E + 07 8.25E + 06 1.44E + 06
1.40E + 06 1.56E + 06
2.84E + 05
1.32E + 06
1.12E + 06 1.92E + 06
7.62E + 06 5.42E + 06 2.64E + 05
CEC2017-F19 Ave
9.03E + 05 3.77E + 03
2.12E + 07 7.52E + 06 3.31E + 05
1.30E + 05 4.71E + 05
3.02E + 04
2.04E + 06
1.56E + 06 4.72E + 06
1.19E + 07 4.46E + 03 3.74E + 03
Std
1.08E + 06 2.05E + 03 1.84E + 07 5.42E + 06 9.21E + 05
2.12E + 05 5.42E + 05
7.60E + 04
1.46E + 06
9.91E + 05 1.72E + 07
2.79E + 07 2.71E + 03 2.28E + 03
CEC2017-F20 Ave
3.26E + 03 2.99E + 03
2.94E + 03 2.96E + 03 3.00E + 03
2.85E + 03 2.79E + 03
2.91E + 03
2.53E + 03
2.55E + 03 2.54E + 03
3.03E + 03 2.59E + 03 2.43E + 03
Std
2.52E + 02 1.10E + 02 2.03E + 02 1.99E + 02 2.47E + 02
2.11E + 02 1.86E + 02
1.38E + 02
2.06E + 02
2.26E + 02 2.26E + 02
2.21E + 02 1.39E + 02 1.13E + 02
CEC2017-F21 Ave
2.20E + 03 2.20E + 03 2.20E + 03 2.20E + 03 2.20E + 03
2.20E + 03 2.20E + 03
2.20E + 03
2.20E + 03
2.20E + 03 2.20E + 03
2.20E + 03 2.20E + 03 2.20E + 03
Std
1.60E + 00 3.25E-06
2.98E-02
1.15E + 00 1.49E-01
5.43E-03
1.26E-03
5.77E-02
7.85E-02
2.13E-01
1.41E-01
1.91E + 00 4.73E-01
1.93E-01
CEC2017-F22 Ave
2.31E + 03 2.30E + 03 2.30E + 03 2.30E + 03 2.30E + 03
2.30E + 03 2.30E + 03
2.30E + 03
2.30E + 03
2.30E + 03 2.30E + 03
2.30E + 03 2.30E + 03 2.30E + 03
Std
2.47E + 00 4.94E-04
1.02E-01
1.28E + 00 3.94E-01
6.09E-02
3.57E-03
1.29E-01
1.08E-01
1.55E-01
2.36E-01
2.19E + 00 5.11E-01
2.42E-01
CEC2017-F23 Ave
3.94E + 03 2.88E + 03
3.17E + 03 3.47E + 03 3.12E + 03
2.93E + 03 2.97E + 03
2.94E + 03
2.79E + 03 2.80E + 03 2.83E + 03
3.44E + 03 3.13E + 03 3.03E + 03
Std
1.97E + 02 1.27E + 01 1.02E + 02 2.09E + 02 1.11E + 02
8.78E + 01 9.32E + 01
6.47E + 01
3.45E + 01
5.66E + 01 5.42E + 01
2.10E + 02 1.58E + 02 1.12E + 02
CEC2017-F24 Ave
4.33E + 03 3.10E + 03
3.37E + 03 3.98E + 03 3.51E + 03
3.10E + 03 3.18E + 03
3.18E + 03
3.04E + 03 3.06E + 03 3.08E + 03
4.06E + 03 3.43E + 03 3.23E + 03
Std
3.13E + 02 1.63E + 01 9.71E + 01 4.00E + 02 1.54E + 02
6.90E + 01 8.54E + 01
5.73E + 01
6.62E + 01
6.57E + 01 7.91E + 01
3.93E + 02 2.71E + 02 2.05E + 02
CEC2017-F25 Ave
4.60E + 03 3.79E + 03
5.03E + 03 4.46E + 03 4.13E + 03
4.04E + 03 3.77E + 03
4.42E + 03
4.11E + 03
4.48E + 03 4.28E + 03
4.91E + 03 3.64E + 03 3.37E + 03
Std
3.46E + 02 1.29E + 02 4.41E + 02 2.29E + 02 4.12E + 02
3.26E + 02 2.05E + 02
3.66E + 02
2.41E + 02
3.84E + 02 4.43E + 02
3.45E + 02 3.97E + 02 3.17E + 02
CEC2017-F26 Ave
1.06E + 04 6.91E + 03
9.60E + 03 1.26E + 04 8.53E + 03
7.47E + 03 7.48E + 03
7.72E + 03
6.12E + 03
6.30E + 03 6.74E + 03
1.03E + 04 5.61E + 03 5.25E + 03
Std
1.12E + 03 1.84E + 02 1.03E + 03 2.30E + 03 7.02E + 02
1.32E + 03 1.22E + 03
7.98E + 02
5.38E + 02
9.98E + 02 8.89E + 02
1.24E + 03 2.22E + 03 2.01E + 03
CEC2017-F27 Ave
6.14E + 03 3.32E + 03 3.86E + 03 4.52E + 03 4.12E + 03
3.46E + 03 3.51E + 03
3.50E + 03
3.44E + 03
3.44E + 03 3.56E + 03
5.15E + 03 3.61E + 03 3.44E + 03
Std
6.39E + 02 1.84E + 01 3.05E + 02 4.93E + 02 4.44E + 02
1.20E + 02 1.12E + 02
8.92E + 01
8.50E + 01
7.92E + 01 1.21E + 02
4.92E + 02 3.71E + 02 2.31E + 02
CEC2017-F28 Ave
5.63E + 03 3.49E + 03
4.67E + 03 4.89E + 03 3.61E + 03
3.66E + 03 3.47E + 03 3.99E + 03
3.71E + 03
3.87E + 03 4.22E + 03
5.91E + 03 3.73E + 03 3.55E + 03

===== PAGE 25 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 25 of 51 
277
Table 2   (continued)
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
Std
5.72E + 02 8.39E + 01
6.69E + 02 5.79E + 02 3.24E + 02
3.38E + 02 7.92E + 01 2.74E + 02
2.89E + 02
3.28E + 02 6.50E + 02
5.98E + 02 3.33E + 02 2.29E + 02
CEC2017-F29 Ave
4.94E + 03 4.59E + 03
5.16E + 03 4.97E + 03 4.64E + 03
4.33E + 03 4.43E + 03
4.38E + 03
3.87E + 03
4.00E + 03 3.94E + 03
5.11E + 03 3.92E + 03 3.74E + 03
Std
4.04E + 02 1.70E + 02
4.35E + 02 5.93E + 02 3.65E + 02
3.12E + 02 3.27E + 02
2.76E + 02
1.68E + 02 1.96E + 02 2.69E + 02
5.27E + 02 2.27E + 02 2.27E + 02
CEC2017-F30 Ave
1.35E + 07 2.31E + 05
8.73E + 07 6.28E + 07 1.66E + 06
1.94E + 06 2.28E + 06
5.71E + 05
7.78E + 06
1.92E + 07 7.73E + 06
8.03E + 07 2.28E + 05 1.21E + 05
Std
2.96E + 07 2.10E + 05 9.32E + 07 7.28E + 07 1.57E + 06
2.90E + 06 1.61E + 06
6.64E + 05
6.67E + 06
6.11E + 07 6.73E + 06
9.08E + 07 3.46E + 05 2.61E + 05
(W|T|L)
(0|16|14)
(6|23|1)
(0|19|11)
(0|28|2)
(0|29|1)
(0|30|0)
(2|28|0)
(1|29|0)
(4|26|0)
(0|29|1)
(1|29|0)
(0|30|0)
(0|30|0)
(16|14|0)
Mean
10.73
5.97
11.93
12.07
8.40
6.83
6.13
6.83
4.97
6.30
6.40
11.13
4.83
2.47
Ranking
11
4
13
14
10
8.5
5
8.5
3
6
7
12
2
1

===== PAGE 26 =====
	
M. Yu et al.
277 
Page 26 of 51
of IAGWO. This includes an initial evaluation represented by three indicators (W|T|L) in 
the first line of the results, denoting the algorithms’ performance as best (win), comparable 
(tie), or least effective (loss) for specific functions. The second row compiles the mean 
performance of all algorithms, while the third row offers insights into the overall standings 
through the final Friedman ranking. The tables distinctly highlight the top results, empha-
sizing their significance. Furthermore, the comparative analysis of the convergence curves 
for each algorithm is depicted in Fig. 10. This visual representation aids in understand-
ing the progression and efficiency of each algorithm in finding optimal solutions over the 
course of iterations. This detailed evaluation underscores the robustness and adaptability of 
IAGWO in varied optimization contexts.
4.4.1  Assessing performance with CEC 2017 test suite
This section examines the efficacy of IAGWO using the CEC 2017 test suite with a dimen-
sionality of 30, as detailed in Table 2. The results are quite telling: IAGWO recorded the 
highest number of best performances, leading in 16 out of the 30 functions tested. Nota-
bly, it did not register as the least effective in any of the functions. In terms of statistical 
standing, IAGWO’s Friedman mean ranking is 3.00, earning it the top position. Further, a 
diverse range of functions from CEC 2017 (Dim = 30) were chosen for a more comprehen-
sive evaluation. The comparative analysis of the convergence trends, depicted in Fig. 10, 
reveals that IAGWO consistently achieved the quickest convergence rate and maintained 
the highest level of accuracy in convergence. These results underscore IAGWO’s excep-
tional proficiency in both global exploration and local exploitation. Collectively, these find-
ings solidify the effectiveness and superiority of IAGWO as an optimization tool.
4.4.2  Assessing performance with CEC 2020 test suite
This section is dedicated to evaluating 13 algorithms with the utilization of the CEC 2020 
test suite, which includes tests with dimensions of 10 and 20. The outcomes of this evalu-
ation are systematically presented in Table 3 and Table 4. On the CEC 2020 tests, IAGWO 
mirrors the impressive results observed in the CEC 2017 suite, achieving the highest num-
ber of best performances while not being the least effective in any function. To provide a 
visual representation of these results, representative functions are chosen to illustrate the 
convergence curves, as depicted in Fig. 10. IAGWO consistently shows the quickest con-
vergence speed and the highest accuracy in convergence, reaffirming its efficiency. Addi-
tionally, it’s important to note the contrasting performance of GWO on the CEC 2020 
suite. Despite its lower ranking in the Friedman rankings, indicating a comparatively poor 
performance, its improved variants, namely AGWO, ENGWO, and RGWO, show marked 
improvements. Remarkably, RGWO secures the second-highest ranking, closely following 
IAGWO, underscoring the substantial research value in enhancing the GWO algorithm. A 
comprehensive statistical analysis among the 13 algorithms tested places IAGWO at the 
forefront in the Friedman rankings. This achievement highlights its superiority not only 
over the original GWO but also over other well-regarded algorithms. These results collec-
tively demonstrate the robustness and effectiveness of IAGWO in a competitive algorith-
mic landscape.

===== PAGE 27 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 27 of 51 
277
Fig. 10   Convergence curves of different algorithms

===== PAGE 28 =====
	
M. Yu et al.
277 
Page 28 of 51
Table 3   Comparison of results on CEC2020 (Dim = 10)
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
CEC2020-F1
Ave
9.07E + 02 2.45E + 04
2.35E + 08 1.61E + 08 2.36E + 04
1.46E + 04 3.44E + 03 4.75E + 05
8.78E + 07
1.72E + 08 2.60E + 08 2.48E + 06
1.25E + 06
2.43E + 04
Std
1.28E + 03 5.49E + 04
3.14E + 08 2.06E + 08 8.97E + 04
2.08E + 04 3.55E + 03 9.01E + 05
1.69E + 08
2.61E + 08 5.26E + 08 9.51E + 06
6.28E + 06
8.76E + 04
CEC2020-F2
Ave
2.55E + 03
2.40E + 03
2.37E + 03 2.23E + 03 2.17E + 03
2.16E + 03 1.97E + 03 2.36E + 03
1.62E + 03
1.86E + 03 1.97E + 03 2.25E + 03
1.62E + 03
1.46E + 03
Std
3.38E + 02
2.18E + 02
3.86E + 02 3.14E + 02 4.15E + 02
3.14E + 02 3.08E + 02 1.88E + 02
2.31E + 02
4.01E + 02 5.24E + 02 3.28E + 02
3.00E + 02
1.82E + 02
CEC2020-F3
Ave
7.28E + 02
7.48E + 02
7.97E + 02 8.03E + 02 8.16E + 02
7.92E + 02 7.73E + 02 7.68E + 02
7.43E + 02
7.44E + 02 7.41E + 02 7.18E + 02 7.34E + 02
7.23E + 02
Std
7.71E + 00
5.53E + 00
2.20E + 01 2.10E + 01 4.15E + 01
2.04E + 01 2.35E + 01 1.83E + 01
1.54E + 01
1.44E + 01 1.92E + 01 4.32E + 00 1.06E + 01
4.52E + 00
CEC2020-F4
Ave
1.95E + 03
1.90E + 03
1.91E + 03 1.92E + 03 2.06E + 03
1.91E + 03 1.90E + 03 1.91E + 03
2.02E + 03
6.42E + 03 4.44E + 03 2.56E + 03
1.90E + 03
1.90E + 03
Std
6.24E + 01
4.83E-01
2.17E + 01 1.23E + 01 4.42E + 02
2.85E + 00 2.65E + 00 4.07E + 00
6.10E + 02
1.91E + 04 1.38E + 04 1.36E + 03
2.04E + 00
1.14E + 00
CEC2020-F5
Ave
5.85E + 05
2.86E + 04
2.92E + 05 2.64E + 05 4.70E + 05
5.27E + 04 1.52E + 05 4.53E + 03 1.75E + 05
2.09E + 05 2.05E + 05 1.00E + 06
2.23E + 05
4.65E + 03
Std
3.01E + 05
2.52E + 04
3.36E + 05 2.19E + 05 5.64E + 05
7.51E + 04 1.89E + 05 2.02E + 03 2.45E + 05
2.37E + 05 2.84E + 05 1.32E + 06
2.73E + 05
3.19E + 03
CEC2020-F6
Ave
1.66E + 03
1.60E + 03
1.62E + 03 1.63E + 03 1.68E + 03
1.60E + 03 1.61E + 03 1.60E + 03 1.61E + 03
1.62E + 03 1.61E + 03 1.64E + 03
1.61E + 03
1.60E + 03
Std
3.86E + 01
2.77E-01
2.05E + 01 1.17E + 01 8.47E + 01
1.06E + 01 7.53E + 00 2.35E-01
1.62E + 01
1.68E + 01 1.74E + 01 2.68E + 01
7.35E + 00
5.71E + 00
CEC2020-F7
Ave
9.85E + 05
4.20E + 03
1.08E + 06 9.23E + 05 6.59E + 04
8.77E + 03 1.19E + 04 3.55E + 03
1.63E + 04
2.44E + 04 4.21E + 04 8.29E + 05
1.21E + 04
3.00E + 03
Std
8.45E + 05
1.59E + 03
2.14E + 06 9.17E + 05 1.27E + 05
7.05E + 03 9.80E + 03 1.14E + 03
3.64E + 04
4.87E + 04 7.83E + 04 1.00E + 06
1.53E + 04
9.34E + 02
CEC2020-F8
Ave
2.31E + 03
2.30E + 03
2.32E + 03 2.64E + 03 2.38E + 03
2.42E + 03 2.33E + 03 2.30E + 03
2.36E + 03
2.36E + 03 2.35E + 03 2.31E + 03
2.33E + 03
2.30E + 03
Std
5.31E + 01
2.16E + 00 2.04E + 01 5.80E + 02 2.93E + 02
4.41E + 02 1.40E + 02 1.20E + 01
2.68E + 02
1.60E + 02 1.39E + 02 5.72E + 00
1.32E + 02
2.05E + 01
CEC2020-F9
Ave
2.66E + 03 2.75E + 03
2.80E + 03 2.89E + 03 2.81E + 03
2.75E + 03 2.74E + 03 2.74E + 03
2.75E + 03
2.74E + 03 2.74E + 03 2.73E + 03
2.70E + 03
2.70E + 03
Std
1.83E + 02
3.19E + 01
4.58E + 01 1.03E + 02 6.69E + 01
4.71E + 01 1.10E + 02 4.42E + 01
1.26E + 01 6.11E + 01 6.14E + 01 8.28E + 01
1.43E + 02
1.20E + 02
CEC2020-F10 Ave
2.93E + 03
2.93E + 03
2.96E + 03 2.95E + 03 2.93E + 03
2.93E + 03 2.94E + 03 2.93E + 03
2.93E + 03
2.95E + 03 2.95E + 03 2.95E + 03
2.94E + 03
2.93E + 03
Std
2.28E + 01
1.98E + 01
7.39E + 01 3.12E + 01 2.53E + 01
2.42E + 01 2.38E + 01 2.40E + 01
5.09E + 01
2.53E + 01 3.31E + 01 1.60E + 01
1.48E + 01 2.34E + 01
(W|T|L)
(1|8|1)
(1|9|0)
(0|8|2)
(0|8|2)
(0|5|5)
(0|10|0)
(2|8|0)
(0|10|0)
(0|10|0)
(0|10|0)
(0|10|0)
(0|10|0)
(0|8|2)
(6|4|0)
Mean
8.30
4.80
11.70
12.20
9.40
5.60
7.40
5.90
6.10
8.20
7.30
9.20
6.30
2.60
Ranking
10
2
13
14
12
3
8
4
5
9
7
11
6
1

===== PAGE 29 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 29 of 51 
277
Table 4   Comparison of results on CEC2020 (Dim = 20)
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
CEC2020-F1
Ave
3.98E + 09 8.90E + 05
8.82E + 09 9.84E + 09 1.19E + 10
6.02E + 09 2.05E + 08 3.67E + 09
8.11E + 09 6.62E + 09 5.72E + 09 1.17E + 06 2.22E + 06 2.70E + 04
Std
2.91E + 09 1.30E + 06
2.95E + 09 2.79E + 09 9.83E + 09
4.45E + 09 3.21E + 08 2.54E + 09
4.14E + 09 3.91E + 09 3.80E + 09 1.49E + 06 1.25E + 06 1.58E + 04
CEC2020-F2
Ave
4.12E + 03 4.95E + 03
5.01E + 03 4.31E + 03 4.12E + 03
4.29E + 03 3.31E + 03 5.18E + 03
3.63E + 03 3.38E + 03 3.21E + 03 2.28E + 03 2.25E + 03 1.72E + 03
Std
5.85E + 02 5.76E + 02
5.11E + 02 6.01E + 02 6.33E + 02
6.81E + 02 6.17E + 02 3.38E + 02
6.23E + 02 7.82E + 02 4.70E + 02 3.87E + 02 4.21E + 02 2.21E + 02
CEC2020-F3
Ave
9.05E + 02 8.47E + 02
1.01E + 03 9.91E + 02 1.51E + 03
9.39E + 02 9.02E + 02 1.02E + 03
8.70E + 02 8.66E + 02 8.36E + 02 7.88E + 02 8.07E + 02 7.53E + 02
Std
7.19E + 01 3.25E + 01
3.82E + 01 2.63E + 01 2.02E + 02
4.50E + 01 3.24E + 01 6.95E + 01
3.96E + 01 4.32E + 01 2.73E + 01 1.86E + 01 2.26E + 01 1.15E + 01
CEC2020-F4
Ave
2.52E + 04 1.92E + 03
2.14E + 04 5.00E + 04 1.89E + 06
4.07E + 03 1.94E + 03 1.14E + 04
2.47E + 04 8.10E + 03 4.72E + 03 1.91E + 03 1.91E + 03 1.91E + 03
Std
7.37E + 04 8.88E + 00
2.83E + 04 7.48E + 04 4.88E + 06
4.14E + 03 4.19E + 01 1.34E + 04
5.21E + 04 1.04E + 04 3.95E + 03 2.82E + 00 3.04E + 00 2.45E + 00
CEC2020-F5
Ave
1.74E + 06 2.18E + 06
5.38E + 06 1.73E + 06 1.18E + 07
1.37E + 06 1.28E + 06 6.69E + 05
1.77E + 06 1.66E + 06 1.28E + 06 1.11E + 06 1.06E + 06 2.32E + 05
Std
1.16E + 06 1.57E + 06
4.62E + 06 1.14E + 06 1.86E + 07
1.03E + 06 9.41E + 05 6.60E + 05
1.14E + 06 1.34E + 06 1.17E + 06 9.39E + 05 9.10E + 05 1.67E + 05
CEC2020-F6
Ave
1.84E + 03 1.84E + 03
1.84E + 03 1.84E + 03 1.84E + 03
1.84E + 03 1.84E + 03 1.84E + 03
1.84E + 03 1.84E + 03 1.84E + 03 1.85E + 03 1.84E + 03 1.84E + 03
Std
1.96E + 02 1.96E + 02
1.96E + 02 1.96E + 02 1.96E + 02
1.96E + 02 1.96E + 02 1.96E + 02
1.96E + 02 1.96E + 02 1.96E + 02 2.28E + 02 1.96E + 02 1.96E + 02
CEC2020-F7
Ave
1.48E + 06 6.41E + 05
3.99E + 06 2.19E + 06 2.60E + 06
9.00E + 05 1.29E + 06 6.28E + 04 2.03E + 06 5.85E + 05 6.00E + 05 5.49E + 05 1.11E + 06 1.04E + 05
Std
1.22E + 06 6.07E + 05
5.05E + 06 1.95E + 06 3.78E + 06
1.05E + 06 1.80E + 06 5.70E + 04 3.85E + 06 9.88E + 05 9.57E + 05 1.53E + 04 1.31E + 06 9.57E + 04
CEC2020-F8
Ave
5.09E + 03 4.61E + 03
5.79E + 03 5.71E + 03 5.62E + 03
3.34E + 03 3.09E + 03 2.75E + 03
4.57E + 03 3.73E + 03 4.32E + 03 3.22E + 03 3.34E + 03 2.46E + 03
Std
1.43E + 03 1.65E + 03
1.52E + 03 8.61E + 02 6.86E + 02
1.42E + 03 1.21E + 03 3.59E + 02 1.44E + 03 1.11E + 03 1.05E + 03 1.33E + 03 1.54E + 03 6.07E + 02
CEC2020-F9
Ave
3.21E + 03 2.93E + 03 3.10E + 03 3.53E + 03 3.32E + 03
3.02E + 03 2.98E + 03 3.02E + 03
3.01E + 03 2.95E + 03 2.95E + 03 3.05E + 03 3.03E + 03 3.01E + 03
Std
2.32E + 02 1.30E + 01 7.95E + 01 2.66E + 02 1.49E + 02
1.51E + 02 1.16E + 02 6.63E + 01
6.92E + 01 6.69E + 01 6.32E + 01 1.35E + 02 1.59E + 02 6.83E + 01
CEC2020-F10 Ave
3.21E + 03 2.97E + 03 3.61E + 03 3.46E + 03 4.02E + 03
3.25E + 03 3.02E + 03 3.18E + 03
3.49E + 03 3.25E + 03 3.16E + 03 3.00E + 03 3.00E + 03 2.99E + 03
Std
1.54E + 02 3.78E + 01
2.83E + 02 2.09E + 02 9.47E + 02
3.38E + 02 3.14E + 01 1.74E + 02
3.66E + 02 2.85E + 02 1.80E + 02 2.85E + 02 2.43E + 01 2.09E + 01
(W|T|L)
(0|10|0)
(2|8|0)
(0|8|2)
(0|9|1)
(0|5|5)
(0|10|0)
(0|10|0)
(1|8|1)
(0|9|1)
(0|10|0)
(0|10|0)
(0|10|0)
(0|10|0)
(7|3|0)
Mean
10.10
5.40
11.60
10.50
8.60
6.00
5.20
7.10
5.80
7.00
7.40
11.00
5.80
3.50
Ranking
11
3
14
12
10
6
2
8
4.5
7
9
13
4.5
1

===== PAGE 30 =====
	
M. Yu et al.
277 
Page 30 of 51
4.4.3  Assessing performance with CEC 2022 test suite
This section is dedicated to a thorough evaluation of the proposed IAGWO and 12 
other comparative algorithms, utilizing the CEC 2022 test suite. The primary objec-
tive of this evaluation is to gauge the exploration and exploitation capabilities of these 
algorithms and assess their proficiency in avoiding local optima traps. The experiments 
are conducted under 10-dimensional and 20-dimensional scenarios, with corresponding 
results displayed in Tables 5 and 6, respectively. IAGWO ranks first in Friedman mean 
ranking in both dimensional settings, with ranking values of 1.75 and 2.25 respectively. 
Similarly, while GWO shows subpar performance, its variants enhance GWO’s perfor-
mance, emphasizing the research significance of GWO. The analysis of results depicted 
in Fig. 10 leads to a conclusive observation that IAGWO successfully evades getting 
stuck in local optima and avoids premature convergence. These findings serve not just as 
a testament to the excellence and robustness of IAGWO, but they also highlight its sub-
stantial performance benefits and the capability to yield enhanced solutions. This analy-
sis underscores IAGWO’s effectiveness in navigating complex optimization landscapes, 
further establishing its potential as a superior tool in optimization tasks.
4.4.4  Scalability evaluation using the CEC 2013 test suite
In real-world scenarios, solving optimization problems often requires adjusting multiple 
parameters at once. To test the scalability of the IAGWO for high-dimensional prob-
lems, we utilized the CEC 2013 suite for large-scale global optimization. The results of 
this testing are detailed in Table 7. This suite includes 15 highly complex test functions, 
each with up to 1000 dimensions, providing a robust challenge for assessing algorithmic 
performance. In our experiments, IAGWO was compared with 12 other algorithms. The 
population size was fixed at 100, and we limited the maximum number of iterations 
to 10 for each run. After conducting 30 independent runs for each algorithm, IAGWO 
achieved a Friedman mean rank value of 2.63. This score signifies a higher level of 
performance relative to the other algorithms in the competition. The findings from these 
experiments demonstrate that the IAGWO algorithm has significant scalability, effec-
tively handling complex, high-dimensional optimization challenges. This capability 
distinguishes IAGWO from other algorithms, highlighting its suitability for practical, 
large-scale optimization applications.
4.5  Wilcoxon rank sum test
This study utilizes the non-parametric Wilcoxon rank sum test (Wilcoxon 1945) to 
conduct comparative performance assessments of various algorithms, setting the sig-
nificance level at 0.05. To succinctly represent the performance of IAGWO relative to 
its competitors, the symbols “ + / = /-” are used to denote whether IAGWO is superior 
to, equivalent to, or inferior to the competing algorithms. As shown in Table 8, these 
statistical results clearly indicate significant performance differences between IAGWO 
and other competing algorithms in most cases. Specifically, the statistical data show 
the following comparative results: 344/0/46、119/0/11、111/13/6、150/0/6、152/0/4 
and 175/0/5. The analysis presented above demonstrates that the IAGWO method, 
as introduced in this study, shows exceptional overall performance when compared 

===== PAGE 31 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 31 of 51 
277
Table 5   Comparison of results on CEC2022 (Dim = 10)
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
CEC2022-F1
Ave
1.21E + 04 5.31E + 03
3.64E + 04 7.64E + 03 2.11E + 04
1.07E + 04
4.13E + 03 1.11E + 03
8.06E + 03 5.57E + 03 6.55E + 03 1.15E + 04 1.69E + 03
3.00E + 02
Std
3.13E + 03 2.73E + 03
1.38E + 04 1.60E + 03 9.55E + 03
7.41E + 03
1.90E + 03 5.96E + 02
3.79E + 03 3.01E + 03 3.96E + 03 3.65E + 03 1.47E + 03
1.85E-01
CEC2022-F2
Ave
5.80E + 02 4.28E + 02
5.71E + 02 6.22E + 02 5.69E + 02
4.38E + 02
4.48E + 02 4.38E + 02
5.10E + 02 4.61E + 02 4.73E + 02 4.52E + 02 4.39E + 02
4.08E + 02
Std
2.26E + 02 2.89E + 01
1.37E + 02 1.83E + 02 1.75E + 02
3.43E + 01
7.47E + 01 3.05E + 01
1.22E + 02 5.26E + 01 7.49E + 01 2.88E + 01 3.79E + 01
2.15E + 01
CEC2022-F3
Ave
6.33E + 02 6.00E + 02
6.49E + 02 6.54E + 02 6.66E + 02
6.29E + 02
6.34E + 02 6.09E + 02
6.16E + 02 6.11E + 02 6.13E + 02 6.09E + 02 6.02E + 02
6.00E + 02
Std
1.57E + 01 7.50E-01
1.25E + 01 1.29E + 01 1.90E + 01
2.13E + 01
1.41E + 01 6.48E + 00
1.05E + 01 8.42E + 00 1.04E + 01 6.86E + 00 1.71E + 00
2.63E-02
CEC2022-F4
Ave
8.27E + 02 8.46E + 02
8.52E + 02 8.30E + 02 8.52E + 02
8.33E + 02
8.30E + 02 8.31E + 02
8.25E + 02 8.24E + 02 8.22E + 02 8.12E + 02 8.25E + 02
8.18E + 02
Std
8.43E + 00 6.06E + 00
1.37E + 01 6.82E + 00 1.65E + 01
4.97E + 00 1.03E + 01 8.04E + 00
1.00E + 01 7.55E + 00 9.45E + 00 5.25E + 00 1.07E + 01
7.22E + 00
CEC2022-F5
Ave
1.20E + 03 9.15E + 02
1.61E + 03 1.58E + 03 2.30E + 03
1.27E + 03
1.32E + 03 1.10E + 03
1.14E + 03 1.13E + 03 1.08E + 03 9.11E + 02 9.58E + 02
9.01E + 02
Std
2.37E + 02 1.48E + 01
4.65E + 02 1.80E + 02 7.10E + 02
2.22E + 02
1.72E + 02 1.53E + 02
2.40E + 02 2.18E + 02 2.40E + 02 2.13E + 01 7.60E + 01
2.25E + 00
CEC2022-F6
Ave
9.11E + 05 4.32E + 04
9.52E + 04 3.48E + 04 3.89E + 07
4.77E + 03
4.06E + 03 2.49E + 03 1.07E + 04 9.78E + 05 1.64E + 06 3.09E + 03 1.05E + 04
2.78E + 03
Std
3.06E + 06 5.67E + 04
1.31E + 05 3.07E + 04 2.13E + 08
2.08E + 03
2.22E + 03 8.01E + 02 5.80E + 03 5.32E + 06 8.95E + 06 1.49E + 03 2.91E + 04
1.38E + 03
CEC2022-F7
Ave
2.16E + 03 2.03E + 03
2.11E + 03 2.13E + 03 2.14E + 03
2.04E + 03
2.07E + 03 2.04E + 03
2.08E + 03 2.05E + 03 2.07E + 03 2.09E + 03 2.02E + 03
2.01E + 03
Std
1.02E + 02 1.15E + 01
3.99E + 01 4.06E + 01 6.61E + 01
3.90E + 01
2.71E + 01 1.18E + 01
4.10E + 01 2.73E + 01 4.14E + 01 4.49E + 01 7.82E + 00 9.03E + 00
CEC2022-F8
Ave
2.42E + 03 2.23E + 03
2.24E + 03 2.26E + 03 2.32E + 03
2.24E + 03
2.23E + 03 2.23E + 03
2.40E + 03 2.26E + 03 2.26E + 03 2.33E + 03 2.22E + 03
2.22E + 03
Std
1.44E + 02 3.93E + 00
1.58E + 01 4.86E + 01 8.89E + 01
3.02E + 01
1.20E + 01 6.22E + 00
7.52E + 02 6.68E + 01 5.22E + 01 8.64E + 01 1.18E + 00 4.63E + 00
CEC2022-F9
Ave
2.62E + 03 2.53E + 03
2.66E + 03 2.71E + 03 2.65E + 03
2.57E + 03
2.59E + 03 2.56E + 03
2.66E + 03 2.62E + 03 2.62E + 03 2.67E + 03 2.54E + 03
2.51E + 03
Std
2.61E + 01 1.92E-01
4.76E + 01 2.77E + 01 6.46E + 01
4.12E + 01
3.52E + 01 2.11E + 01
4.19E + 01 3.46E + 01 4.21E + 01 2.82E + 01 3.01E + 01
1.13E + 01
CEC2022-F10 Ave
2.91E + 03 2.51E + 03 2.90E + 03 2.83E + 03 3.61E + 03
2.65E + 03
2.62E + 03 2.52E + 03
2.64E + 03 2.63E + 03 2.76E + 03 2.66E + 03 2.58E + 03
2.57E + 03
Std
4.87E + 02 1.45E + 01 4.97E + 02 3.18E + 02 5.66E + 02
1.92E + 02
9.41E + 01 4.77E + 01
1.32E + 02 1.43E + 02 4.43E + 02 3.21E + 02 7.60E + 01
5.76E + 01
CEC2022-F11 Ave
2.83E + 03 2.79E + 03
2.98E + 03 3.13E + 03 3.08E + 03
3.10E + 03
2.79E + 03 2.93E + 03
3.04E + 03 3.06E + 03 3.04E + 03 2.83E + 03 2.78E + 03
2.67E + 03
Std
1.11E + 02 1.12E + 02
2.83E + 02 3.29E + 02 3.78E + 02
4.37E + 02
1.51E + 02 1.64E + 02
3.43E + 02 3.19E + 02 1.97E + 02 1.65E + 02 1.50E + 02
1.10E + 02
CEC2022-F12 Ave
3.04E + 03 2.86E + 03
2.95E + 03 3.10E + 03 3.03E + 03
2.88E + 03
2.88E + 03 2.88E + 03
2.91E + 03 2.90E + 03 2.92E + 03 2.93E + 03 2.89E + 03
2.86E + 03
Std
8.60E + 01 1.46E + 00 8.01E + 01 1.09E + 02 1.59E + 02
2.35E + 01
1.66E + 01 1.66E + 01
3.10E + 01 3.47E + 01 4.89E + 01 3.39E + 01 2.02E + 01
1.56E + 01
(W|T|L)
(0|10|2)
(1|11|0)
(0|9|2)
(0|8|4)
(0|8|4)
(0|12|0)
(0|12|0)
(1|11|0)
(0|12|0)
(0|12|0)
(0|12|0)
(0|10|2)
(0|12|0)
(11|1|0)
Mean
9.50
4.33
11.83
12.58
10.08
7.08
6.83
4.50
6.33
7.83
7.75
9.25
5.33
1.75
Ranking
11
2
13
14
12
7
6
3
5
9
8
10
4
1

===== PAGE 32 =====
	
M. Yu et al.
277 
Page 32 of 51
Table 6   Comparison of results on CEC2022 (Dim = 20)
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
CEC2022-F1
Ave
4.20E + 04
4.35E + 04
6.35E + 04 8.21E + 04 8.17E + 04
6.06E + 04 5.27E + 04 3.18E + 04 3.58E + 04 2.48E + 04 2.81E + 04 3.55E + 04 3.03E + 04 1.27E + 03
Std
1.15E + 04
1.10E + 04
3.19E + 04 3.03E + 04 2.38E + 04
2.10E + 04 2.43E + 04 1.21E + 04 1.02E + 04 6.61E + 03 8.90E + 03 7.82E + 03 1.85E + 04 1.04E + 03
CEC2022-F2
Ave
6.54E + 02
4.80E + 02 9.11E + 02 8.81E + 02 1.22E + 03
7.82E + 02 5.60E + 02 6.40E + 02 7.42E + 02 6.48E + 02 6.49E + 02 6.69E + 02 5.28E + 02 4.82E + 02
Std
8.00E + 01
3.59E + 01
1.91E + 02 1.21E + 02 7.14E + 02
3.29E + 02 6.01E + 01 8.27E + 01 1.60E + 02 1.13E + 02 1.48E + 02 8.81E + 01 4.76E + 01 1.86E + 01
CEC2022-F3
Ave
6.65E + 02
6.04E + 02
6.79E + 02 6.75E + 02 6.86E + 02
6.48E + 02 6.57E + 02 6.37E + 02 6.30E + 02 6.34E + 02 6.29E + 02 6.48E + 02 6.25E + 02 6.03E + 02
Std
9.46E + 00
3.11E + 00 1.32E + 01 1.03E + 01 1.75E + 01
1.88E + 01 8.90E + 00 8.94E + 00 1.09E + 01 1.15E + 01 1.57E + 01 9.96E + 00 1.24E + 01 3.18E + 00
CEC2022-F4
Ave
8.84E + 02
9.47E + 02
9.82E + 02 9.02E + 02 9.62E + 02
9.02E + 02 8.94E + 02 9.23E + 02 9.00E + 02 8.86E + 02 8.81E + 02 8.58E + 02 8.89E + 02 8.57E + 02
Std
2.19E + 01
1.11E + 01 4.27E + 01 1.33E + 01 3.90E + 01
1.47E + 01 1.90E + 01 1.78E + 01 3.40E + 01 2.48E + 01 4.00E + 01 1.45E + 01 2.37E + 01 1.30E + 01
CEC2022-F5
Ave
2.44E + 03
1.76E + 03
4.87E + 03 3.46E + 03 4.50E + 03
2.93E + 03 2.48E + 03 2.51E + 03 2.45E + 03 2.52E + 03 2.02E + 03 1.53E + 03 2.67E + 03 1.68E + 03
Std
5.09E + 02
6.89E + 02
2.01E + 03 4.50E + 02 9.99E + 02
4.47E + 02 3.97E + 02 5.86E + 02 6.92E + 02 5.79E + 02 5.50E + 02 3.07E + 02 8.73E + 02 3.19E + 02
CEC2022-F6
Ave
2.95E + 03 2.70E + 06
1.19E + 08 6.00E + 07 3.48E + 08
9.69E + 06 6.21E + 03 4.63E + 06 2.55E + 07 1.59E + 07 2.64E + 07 2.54E + 05 3.29E + 05 4.26E + 03
Std
1.20E + 03 3.91E + 06
1.15E + 08 1.73E + 08 8.24E + 08
1.84E + 07 5.31E + 03 1.82E + 07 6.51E + 07 3.84E + 07 6.83E + 07 1.37E + 06 1.77E + 06 2.66E + 03
CEC2022-F7
Ave
2.34E + 03
2.14E + 03
2.28E + 03 2.28E + 03 2.35E + 03
2.35E + 03 2.20E + 03 2.14E + 03 2.19E + 03 2.16E + 03 2.19E + 03 2.27E + 03 2.11E + 03 2.06E + 03
Std
1.30E + 02
4.20E + 01
6.83E + 01 1.02E + 02 1.64E + 02
1.78E + 02 6.44E + 01 4.26E + 01 8.10E + 01 7.89E + 01 8.28E + 01 1.23E + 02 6.15E + 01 3.34E + 01
CEC2022-F8
Ave
2.58E + 03
2.26E + 03
2.36E + 03 2.39E + 03 2.55E + 03
2.32E + 03 2.25E + 03 2.26E + 03 2.34E + 03 2.28E + 03 2.29E + 03 2.58E + 03 2.27E + 03 2.23E + 03
Std
2.11E + 02
1.03E + 01 1.31E + 02 1.46E + 02 1.65E + 02
9.76E + 01 2.29E + 01 4.15E + 01 9.70E + 01 7.76E + 01 8.17E + 01 1.99E + 02 6.69E + 01 2.18E + 01
CEC2022-F9
Ave
2.86E + 03
2.48E + 03 2.71E + 03 2.81E + 03 2.71E + 03
2.52E + 03 2.53E + 03 2.53E + 03 2.62E + 03 2.60E + 03 2.64E + 03 2.79E + 03 2.52E + 03 2.49E + 03
Std
2.86E + 02
3.31E + 00 8.01E + 01 1.75E + 02 1.18E + 02
3.07E + 01 3.39E + 01 2.09E + 01 9.08E + 01 4.80E + 01 7.02E + 01 1.05E + 02 5.83E + 01 8.14E + 00
CEC2022-F10 Ave
5.32E + 03
3.74E + 03
6.11E + 03 5.32E + 03 5.42E + 03
4.86E + 03 4.09E + 03 3.17E + 03 4.61E + 03 4.21E + 03 4.31E + 03 4.95E + 03 3.07E + 03 2.55E + 03
Std
7.83E + 02
1.35E + 03
1.36E + 03 5.95E + 02 5.13E + 02
1.19E + 03 8.61E + 02 1.31E + 03 1.23E + 03 9.15E + 02 1.07E + 03 9.90E + 02 3.07E + 02 9.54E + 01
CEC2022-F11 Ave
5.00E + 03
3.09E + 03
5.33E + 03 6.05E + 03 5.79E + 03
5.85E + 03 3.54E + 03 4.44E + 03 5.60E + 03 5.46E + 03 4.50E + 03 5.18E + 03 3.20E + 03 2.93E + 03
Std
8.14E + 02
2.66E + 02
9.18E + 02 9.37E + 02 1.67E + 03
1.01E + 03 4.35E + 02 7.38E + 02 1.06E + 03 1.06E + 03 8.67E + 02 7.25E + 02 9.37E + 02 7.60E + 01
CEC2022-F12 Ave
4.50E + 03
2.96E + 03
3.21E + 03 3.80E + 03 3.67E + 03
3.05E + 03 3.02E + 03 3.14E + 03 3.15E + 03 3.04E + 03 3.09E + 03 3.57E + 03 3.00E + 03 2.91E + 03
Std
4.90E + 02
1.33E + 01 1.73E + 02 5.42E + 02 4.79E + 02
4.99E + 01 5.06E + 01 8.16E + 01 1.01E + 02 7.01E + 01 5.21E + 01 2.29E + 02 2.02E + 02 3.89E + 01
(W|T|L)
(1|8|3)
(2|10|0)
(0|9|3)
(0|10|2)
(0|8|4)
(0|12|0)
(0|12|0)
(0|12|0)
(0|12|0)
(0|12|0)
(0|12|0)
(0|10|2)
(0|12|0)
(9|3|0)
Mean
10.67
5.00
12.00
11.67
9.92
8.08
6.50
6.33
5.00
7.00
6.67
9.42
4.50
2.25
Ranking
12
3.5
14
13
11
9
6
5
3.5
8
7
10
2
1

===== PAGE 33 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 33 of 51 
277
Table 7   Experimental results of 13 algorithms on the CEC 2013 large-scale global optimization suite
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
CEC2013-F1 Ave
3.35E + 11 3.08E + 11 1.97E + 11 1.93E + 11 2.28E + 11 1.93E + 11 1.76E + 11 1.89E + 11 1.54E + 11 1.42E + 11 1.55E + 11 3.25E + 11 1.67E + 11 1.36E + 11
Std
3.73E + 11 3.23E + 11 2.07E + 11 1.99E + 11 2.56E + 11 2.02E + 11 1.89E + 11 2.2E + 11
1.73E + 11 1.57E + 11 1.75E + 11 3.59E + 11 1.79E + 11 1.44E + 11
CEC2013-F2 Ave
93,255.72
112,064.4
43,080.84
42,250.92
50,647.46
47,037.74
42,058.73
55,940.77
58,323.92
42,841.87
56,303.07
97,556.85
47,402.46
43,840.7
Std
102,011.1
117,277.8
44,186.55
42,898.96
53,211.28
47,380.09
43,717.04
60,134.27
61,880.87
44,034.83
61,083.19
108,779.5
49,317.96
45,430.29
CEC2013-F3 Ave
21.49376
21.50212
21.06985
21.02136
21.41458
21.00417
21.02704
21.13752
21.37364
21.01368
21.33498
21.48408
21.1016
21.04118
Std
21.51888
21.52571
21.17079
21.04775
21.45068
21.03428
21.04392
21.22419
21.39918
21.04472
21.37094
21.51878
21.13504
21.0767
CEC2013-F4 Ave
2.92E + 13 7.29E + 12 6.69E + 12 6.42E + 12 3.87E + 12 4.81E + 12 4.18E + 12 5.29E + 12 3.03E + 12 2.05E + 12 3.08E + 12 2.41E + 13 3.12E + 12 1.96E + 12
Std
3.89E + 13 1.11E + 13 1.33E + 13 1.51E + 13 8.18E + 12 1.45E + 13 7.8E + 12
8.38E + 12 4.73E + 12 3.08E + 12 4.58E + 12 3.42E + 13 4.41E + 12 2.99E + 12
CEC2013-F5 Ave
51,481,894 52,483,004 34,809,401 38,752,599 40,402,847 36,183,366 33,211,821 35,920,575 24,936,656 24,810,859 24,258,271 55,346,326 34,073,257 24,161,959
Std
65,449,636 55,517,964 43,186,695 42,177,103 46,118,435 43,343,088 36,983,477 40,290,831 27,850,243 28,121,226 28,503,267 67,634,604 37,069,143 26,967,202
CEC2013-F6 Ave
1,054,645
1,057,992
1,028,368
1,020,788
1,051,115
1,026,690
1,023,386
1,030,458
1,012,733
998,839.5
1,010,587
1,056,845
1,011,897
998,155.6
Std
1,060,636
1,060,651
1,051,240
1,028,236
1,056,882
1,031,790
1,028,811
1,041,863
1,032,055
1,013,403
1,029,268
1,061,368
1,027,296
1,013,764
CEC2013-F7 Ave
3.8E + 15
8.33E + 14 1.23E + 14 1.23E + 14 7.65E + 13 7.67E + 13 2.8E + 13
4.2E + 13
5.42E + 12 7.98E + 12 6.41E + 12 6.12E + 15 2.28E + 13 5.06E + 12
Std
1.91E + 16 2.25E + 15 4.17E + 14 2.75E + 14 3.73E + 14 3.76E + 14 9.35E + 13 2.11E + 14 2.54E + 13 1.46E + 13 2.76E + 13 1.36E + 16 4.56E + 13 9.16E + 12
CEC2013-F8 Ave
8.71E + 17 3.63E + 17 2.58E + 17 2.86E + 17 2.91E + 17 3.58E + 17 1.87E + 17 4.74E + 17 5.88E + 16 1.06E + 17 6.99E + 16 1.07E + 18 9.37E + 16 6.2E + 16
Std
2.35E + 18 5.82E + 17 6.18E + 17 5.69E + 17 6.01E + 17 9.16E + 17 4.13E + 17 7.55E + 17 1.28E + 17 2.27E + 17 2.1E + 17
1.71E + 18 2.97E + 17 1.25E + 17
CEC2013-F9 Ave
3.87E + 09 3.32E + 09 2.81E + 09 2.95E + 09 2.79E + 09 2.74E + 09 2.71E + 09 2.51E + 09 1.83E + 09 1.94E + 09 1.69E + 09 4.26E + 09 2.46E + 09 1.86E + 09
Std
5.67E + 09 4E + 09
3.66E + 09 3.49E + 09 3.2E + 09
3.33E + 09 3.06E + 09 2.86E + 09 2.1E + 09
2.09E + 09 2.18E + 09 5.25E + 09 2.85E + 09 2.1E + 09
CEC2013-F10 Ave
93,611,977 90,686,116 89,098,217 92,312,148 86,096,968 91,007,160 86,426,155 86,439,680 72,158,168 73,808,964 78,093,845 92,087,389 87,644,234 70,930,145
Std
95,102,068 92,974,345 93,465,721 93,235,436 92,157,822 93,329,179 91,920,790 92,546,080 84,432,720 85,554,070 84,494,675 95,221,734 91,391,514 81,586,156
CEC2013-F11 Ave
9E + 16
5.7E + 16
3.39E + 15 4.8E + 15
8.88E + 15 7E + 15
2.85E + 15 3.46E + 15 7.3E + 14
3.94E + 14 2.2E + 15
1.51E + 17 1.31E + 15 3.88E + 14
Std
1.03E + 18 1.45E + 17 1.04E + 16 1.01E + 16 2.72E + 16 2.17E + 16 5.54E + 15 1.1E + 16
3.1E + 15
8.5E + 14
4.12E + 15 5.42E + 17 2.85E + 15 5.32E + 14
CEC2013-F12 Ave
8.07E + 12 8.15E + 12 1.71E + 12 1.69E + 12 5.03E + 12 1.68E + 12 1.66E + 12 2.33E + 12 3.13E + 12 1.59E + 12 3.17E + 12 7.86E + 12 1.86E + 12 1.54E + 12
Std
8.42E + 12 8.55E + 12 1.81E + 12 1.69E + 12 5.27E + 12 1.7E + 12
1.68E + 12 2.71E + 12 3.75E + 12 1.61E + 12 3.56E + 12 8.29E + 12 1.95E + 12 1.62E + 12
CEC2013-F13 Ave
4.13E + 17 4.23E + 16 4.75E + 15 2.98E + 15 3.94E + 15 1.15E + 16 1.02E + 15 2.23E + 15 5.9E + 14
4.69E + 14 9.84E + 14 3.73E + 17 1.23E + 15 2.83E + 14
Std
1.46E + 18 1.33E + 17 1.11E + 16 8.48E + 15 8.84E + 15 2.29E + 16 5.54E + 15 8.7E + 15
1.79E + 15 7.01E + 14 2.4E + 15
1.28E + 18 2.27E + 15 5.56E + 14
CEC2013-F14 Ave
2.4E + 17
1.35E + 17 2.18E + 16 9.65E + 15 2.04E + 16 2.84E + 16 6.8E + 15
7.11E + 15 2.06E + 15 4.76E + 14 1.13E + 15 2.3E + 17
3.27E + 15 5.12E + 14
Std
1.54E + 18 3.57E + 17 6.61E + 16 5.4E + 16
8.81E + 16 2.67E + 17 3.67E + 16 1.66E + 16 3.88E + 15 1.25E + 15 4.77E + 15 1.54E + 18 7.54E + 15 1.13E + 15

===== PAGE 34 =====
	
M. Yu et al.
277 
Page 34 of 51
Table 7   (continued)
ID
Metric GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
CEC2013-F15 Ave
3.33E + 17 1.58E + 17 2.62E + 11 1.94E + 11 8.3E + 12
2.17E + 15 8.79E + 10 1.89E + 11 2.74E + 15 8.37E + 14 2.69E + 15 2.68E + 17 1.26E + 15 4.74E + 14
Std
9.19E + 17 3.63E + 17 4.25E + 11 3.17E + 11 2.56E + 13 4.22E + 15 2.28E + 11 2.82E + 11 5.88E + 15 1E + 15
5.9E + 15
9.12E + 17 1.78E + 15 6.61E + 14
(W|T|L)
(0|3|12)
(0|12|3)
(0|15|0)
(1|14|0)
(0|15|0)
(0|15|0)
(1|14|0)
(0|15|0)
(2|13|0)
(5|10|0)
(0|15|0)
(0|15|0)
(0|15|0)
(6|9|0)
Mean
13.33
11.73
8.33
6.93
9.40
8.60
4.93
7.60
5.13
2.60
5.47
13.27
5.47
2.20
Ranking
14
12
9
7
11
10
3
8
4
2
5.5
13
5.5
1

===== PAGE 35 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 35 of 51 
277
to the traditional GWO and other rival algorithms, thereby underscoring its distinct 
advantages.
4.6  Time comparison analysis of IAGWO and GWO
Building on the findings from previous chapters, it’s clear that IAGWO significantly sur-
passes the original GWO in terms of overall performance. In this section, we focus on a 
more detailed comparison, specifically looking at the computational costs of both algo-
rithms, with a particular emphasis on the differences in computational time. To facilitate 
this comparison, we standardized the settings for both IAGWO and GWO. For this evalu-
ation, the population size was configured to 50, the maximum iterations were limited to 
1000, and each algorithm underwent 30 independent runs. Table 9 presents the total time 
(in seconds) each algorithm took to complete all 30 runs. This data provides a clear basis 
for comparing the efficiency of the two algorithms in terms of how long they take to exe-
cute, offering insights into their time-based performance efficiency.
Analysis of the experimental data on the CEC 2017 test suit (Dim = 30) indicates that 
under the same experimental parameters, IAGWO and GWO perform almost equally in 
terms of execution time on unimodal functions and some simpler multimodal functions, 
but when dealing with more complex multimodal and hybrid functions, IAGWO gener-
ally consumes significantly less computational time than GWO. This suggests that in han-
dling highly complex problems, IAGWO demonstrates greater computational efficiency. 
Compared to the original GWO, IAGWO’s improved search strategies are more efficient, 
possessing better global search capabilities or faster local convergence speeds. Overall, 
IAGWO not only excels in benchmark tests but also exhibits higher computational effi-
ciency and better adaptability when addressing more complex optimization problems that 
may arise in practical applications.
Table 8   Statistical findings from Wilcoxon rank sum test
IAGWO VS
CEC2017
(Dim = 30)
CEC2020
(Dim = 10)
CEC2020
(Dim = 20)
CEC2022
(Dim = 10)
CEC2022
(Dim = 20)
CEC2013
(Dim = 100)
GSA
30/0/0
8/0/2
9/1/0
11/0/1
12/0/0
15/0/0
DMO
24/0/6
9/0/1
8/1/1
11/0/1
9/0/3
15/0/0
WOA
29/0/1
10/0/0
9/1/0
12/0/0
12/0/0
15/0/0
HHO
30/0/0
10/0/0
9/1/0
12/0/0
12/0/0
15/0/0
CPSOGSA
21/0/2
10/0/0
9/1/0
12/0/0
12/0/0
15/0/0
COA
21/0/2
9/0/1
8/1/1
12/0/0
12/0/0
15/0/0
AVOA
26/0/4
9/0/1
8/1/1
12/0/0
11/0/1
14/0/1
OMA
26/0/4
8/0/2
8/1/1
13/0/2
12/0/0
15/0/0
GWO
23/0/7
10/0/0
8/1/1
12/0/0
12/0/0
14/0/1
AGWO
25/0/5
9/0/1
9/1/0
12/0/0
12/0/0
14/0/1
ENGWO
24/0/6
9/0/1
9/1/0
12/0/0
12/0/0
14/0/1
iAEFA
25/0/5
9|0|1
9|1|0
10|0|2
12|0|0
14|0|1
RGWO
26/0/4
9/0/1
8/1/1
10/0/2
12/0/0
15/0/0
Overall (+ / = /-)
344/0/46
119/0/11
111/13/6
150/0/6
152/0/4
175/0/5

===== PAGE 36 =====
	
M. Yu et al.
277 
Page 36 of 51
However, on the CEC 2020 test suite (Dim = 10 and 20) and CEC 2022 test suite 
(Dim = 10 and 20), IAGWO generally exhibits higher computational times compared to 
GWO. This may indicate that the types of problems or characteristics included in CEC 
2020 are not entirely compatible with the strategies of IAGWO, leading to a higher compu-
tational load.
4.7  Evaluating performance against CEC 2014 and CEC 2017 competition‑winners
This section evaluates the performance of the proposed IAGWO using the CEC 2014 test 
suite with a dimensionality of 30 (Liang et al. 2013) and CEC 2017 (Dim = 30) test suites. 
Additionally, we compare the performance of IAGWO with the competition-winners of 
these two suites in previous CEC competitions, including L-SHADE (Tanabe & Fuku-
naga 2014) and AL-SHADE (Li et al. 2022) from CEC 2014, and LSHADE-SPACMA 
(Mohamed, Hadi, Fattouh, & Jambi, 2017) and LSHADE-cnEpSin (Awad, Ali, & Sug-
anthan, 2017) from CEC 2017. In the experimental setup, the population size is fixed 
at 30, the maximum iterations are limited to 500, and a total of 30 independent runs are 
performed.
Table 9   Execution time comparison: IAGWO vs. GWO
CEC2017 (Dim = 30)
F1
F2
F3
F4
F5
F6
F7
F8
F9
F10
GWO
21.51
24.22
23.25
25.07
24.96
33.76
26.44
25.93
25.79
27.64
IAGWO
22.48
21.20
23.64
23.76
22.61
33.30
24.40
24.50
24.76
29.51
CEC2017 (Dim = 30)
F11
F12
F13
F14
F15
F16
F17
F18
F19
F20
GWO
24.57
25.63
24.19
29.49
24.76
25.55
33.40
26.09
72.19
33.64
IAGWO
23.96
26.19
27.29
29.72
27.81
25.53
34.16
29.45
56.34
31.65
CEC2017 (Dim = 30)
F21
F22
F23
F24
F25
F26
F27
F28
F29
F30
GWO
38.05
41.22
45.36
49.38
42.21
52.42
58.37
49.39
44.44
85.41
IAGWO
34.95
38.22
38.75
37.49
34.20
38.65
40.13
37.85
37.26
57.68
CEC2020 (Dim = 10)
F1
F2
F3
F4
F5
F6
F7
F8
F9
F10
GWO
12.20
14.00
13.63
13.20
13.82
28.62
27.24
27.95
28.40
28.37
IAGWO
26.52
30.53
30.65
29.82
30.22
29.38
30.02
37.92
39.78
36.73
CEC2020 (Dim = 20)
F1
F2
F3
F4
F5
F6
F7
F8
F9
F10
GWO
16.52
20.30
18.62
19.31
20.54
17.06
19.96
27.69
31.51
26.97
IAGWO
27.66
33.89
32.01
31.57
32.88
28.33
31.92
45.24
50.49
42.19
CEC2022 (Dim = 10)
F1
F2
F3
F4
F5
F6
F7
F8
F9
F10
GWO
12.46
12.34
16.75
14.23
14.61
12.89
18.76
21.10
18.66
17.84
IAGWO
26.07
25.88
33.70
30.08
31.12
26.85
36.52
41.58
35.04
33.47
CEC2022 (Dim = 10)
F11
F12
GWO
21.27
22.83
IAGWO
41.59
39.59
CEC2022 (Dim = 20)
F1
F2
F3
F4
F5
F6
F7
F8
F9
F10
GWO
16.91
17.92
24.75
18.87
18.95
16.97
29.04
31.16
29.28
24.85
IAGWO
27.70
27.19
38.86
30.75
31.34
28.21
45.42
49.24
44.92
40.01
CEC2022 (Dim = 20)
F11
F12
GWO
IAGWO
33.25
53.87
37.83
58.70

===== PAGE 37 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 37 of 51 
277
Table 10   Comparison with the 2014 CEC winner results
ID
L-SHADE
AL-SHADE
IAGWO
ID
L-SHADE
AL-SHADE
IAGWO
CEC2014-F1
Ave
5.98E + 06
1.03E + 08
1.40E + 07
CEC2014-F16
Ave
1.61E + 03
1.61E + 03
1.61E + 03
Std
7.23E + 06
4.86E + 07
3.22E + 07
Std
5.11E-01
2.34E-01
2.87E-01
CEC2014-F2
Ave
1.62E + 07
1.62E + 10
1.90E + 08
CEC2014-F17
Ave
1.43E + 05
6.43E + 06
2.92E + 06
Std
5.04E + 07
4.96E + 09
6.42E + 08
Std
1.88E + 05
4.64E + 06
4.66E + 06
CEC2014-F3
Ave
9.66E + 03
1.16E + 05
1.50E + 04
CEC2014-F18
Ave
1.53E + 04
7.86E + 07
1.89E + 06
Std
5.04E + 03
2.79E + 04
7.80E + 03
Std
1.70E + 04
7.13E + 07
9.39E + 06
CEC2014-F4
Ave
5.11E + 02
2.57E + 03
7.05E + 02
CEC2014-F19
Ave
1.92E + 03
2.05E + 03
1.93E + 03
Std
2.03E + 01
1.28E + 03
5.45E + 02
Std
1.82E + 01
9.23E + 01
2.68E + 01
CEC2014-F5
Ave
5.21E + 02
5.21E + 02
5.21E + 02
CEC2014-F20
Ave
6.20E + 03
3.75E + 04
1.82E + 04
Std
1.50E-01
5.50E-02
1.08E-01
Std
4.79E + 03
2.32E + 04
7.94E + 03
CEC2014-F6
Ave
6.19E + 02
6.35E + 02
6.24E + 02
CEC2014-F21
Ave
1.91E + 04
1.25E + 06
3.41E + 05
Std
2.67E + 00
3.33E + 00
3.84E + 00
Std
2.44E + 04
1.34E + 06
3.22E + 05
CEC2014-F7
Ave
7.01E + 02
8.51E + 02
7.01E + 02
CEC2014-F22
Ave
2.51E + 03
3.12E + 03
2.72E + 03
Std
5.12E-01
6.71E + 01
4.61E-02
Std
1.51E + 02
2.49E + 02
1.93E + 02
CEC2014-F8
Ave
8.11E + 02
1.05E + 03
8.46E + 02
CEC2014-F23
Ave
2.64E + 03
2.77E + 03
2.65E + 03
Std
7.26E + 00
2.59E + 01
9.69E + 00
Std
3.69E + 00
7.39E + 01
1.19E + 01
CEC2014-F9
Ave
9.93E + 02
1.18E + 03
1.01E + 03
CEC2014-F24
Ave
2.60E + 03
2.65E + 03
2.61E + 03
Std
1.70E + 01
2.37E + 01
2.16E + 01
Std
7.73E-01
3.61E + 01
1.99E + 01
CEC2014-F10
Ave
1.28E + 03
8.12E + 03
2.32E + 03
CEC2014-F25
Ave
2.71E + 03
2.75E + 03
2.72E + 03
Std
1.60E + 02
7.48E + 02
5.31E + 02
Std
3.85E + 00
2.00E + 01
2.16E + 01
CEC2014-F11
Ave
4.90E + 03
9.39E + 03
4.83E + 03
CEC2014-F26
Ave
2.70E + 03
2.70E + 03
2.71E + 03
Std
5.86E + 02
5.36E + 02
7.14E + 02
Std
1.50E-01
7.85E-01
4.82E + 01
CEC2014-F12
Ave
1.20E + 03
1.20E + 03
1.20E + 03
CEC2014-F27
Ave
3.49E + 03
3.82E + 03
3.60E + 03
Std
7.34E-01
7.21E-01
3.37E-01
Std
7.39E + 01
7.25E + 01
1.71E + 02
CEC2014-F13
Ave
1.30E + 03
1.30E + 03
1.30E + 03
CEC2014-F28
Ave
3.32E + 03
3.74E + 03
3.49E + 03
Std
9.82E-02
8.09E-01
1.23E-01
Std
4.97E + 01
1.71E + 02
1.71E + 02

===== PAGE 38 =====
	
M. Yu et al.
277 
Page 38 of 51
Table 10   (continued)
ID
L-SHADE
AL-SHADE
IAGWO
ID
L-SHADE
AL-SHADE
IAGWO
CEC2014-F14
Ave
1.40E + 03
1.43E + 03
1.40E + 03
CEC2014-F29
Ave
1.46E + 06
1.18E + 07
2.29E + 04
Std
1.43E-01
1.41E + 01
5.51E-02
Std
4.47E + 06
1.70E + 07
8.24E + 04
CEC2014-F15
Ave
1.54E + 03
2.51E + 05
1.54E + 03
CEC2014-F30
Ave
5.26E + 03
5.52E + 04
7.46E + 03
Std
2.99E + 01
2.76E + 05
1.29E + 01
Std
1.02E + 03
3.67E + 04
1.10E + 04
Statistical results
Mean
1.34
2.95
1.71
(W|T|L)
(24|6|0)
(0|1|29)
(6|23|1)
Ranking
1
3
2

===== PAGE 39 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 39 of 51 
277
Table 11   Comparison with the 2017 CEC winner results
ID
LSHADE-cnEpSin
LSHADE-SPACMA
IAGWO
ID
LSHADE-cnEpSin
LSHADE-SPACMA
IAGWO
CEC2017-F1
Ave
3.66E + 06
1.27E + 07
3.39E + 05
CEC2017-F16
Ave
2.33E + 03
3.06E + 03
2.65E + 03
Std
3.20E + 06
4.32E + 07
1.27E + 05
Std
2.07E + 02
6.93E + 02
3.14E + 02
CEC2017-F2
Ave
8.30E + 24
4.01E + 29
1.53E + 29
CEC2017-F17
Ave
2.12E + 03
2.73E + 03
2.18E + 03
Std
4.54E + 25
4.97E + 29
6.03E + 29
Std
1.28E + 02
6.64E + 02
2.00E + 02
CEC2017-F3
Ave
4.30E + 04
6.30E + 07
2.65E + 04
CEC2017-F18
Ave
4.07E + 04
5.16E + 04
6.61E + 05
Std
2.20E + 04
3.39E + 08
1.06E + 04
Std
1.68E + 04
4.56E + 04
1.88E + 06
CEC2017-F4
Ave
5.53E + 02
5.48E + 02
7.75E + 02
CEC2017-F19
Ave
5.24E + 03
5.98E + 03
3.55E + 03
Std
4.11E + 01
5.14E + 01
4.44E + 02
Std
4.69E + 03
5.93E + 03
1.63E + 03
CEC2017-F5
Ave
6.09E + 02
6.09E + 02
6.26E + 02
CEC2017-F20
Ave
2.44E + 03
2.85E + 03
2.46E + 03
Std
3.08E + 01
2.33E + 01
2.24E + 01
Std
1.15E + 02
3.43E + 02
1.25E + 02
CEC2017-F6
Ave
6.12E + 02
6.07E + 02
6.11E + 02
CEC2017-F21
Ave
2.20E + 03
2.20E + 03
2.20E + 03
Std
5.30E + 00
2.80E + 00
6.91E + 00
Std
5.04E-03
9.32E-03
1.79E-01
CEC2017-F7
Ave
8.90E + 02
8.74E + 02
8.85E + 02
CEC2017-F22
Ave
2.30E + 03
2.30E + 03
2.30E + 03
Std
4.79E + 01
3.13E + 01
3.20E + 01
Std
2.72E-03
1.22E-02
3.07E-01
CEC2017-F8
Ave
9.04E + 02
9.04E + 02
8.97E + 02
CEC2017-F23
Ave
2.79E + 03
2.85E + 03
3.01E + 03
Std
2.71E + 01
2.12E + 01
1.50E + 01
Std
3.51E + 01
8.73E + 01
1.07E + 02
CEC2017-F9
Ave
2.53E + 03
2.61E + 03
3.56E + 03
CEC2017-F24
Ave
3.02E + 03
3.29E + 03
3.22E + 03
Std
7.19E + 02
1.25E + 03
8.15E + 02
Std
4.36E + 01
5.76E + 02
1.89E + 02
CEC2017-F10
Ave
4.54E + 03
4.91E + 03
3.43E + 03
CEC2017-F25
Ave
3.45E + 03
3.51E + 03
3.34E + 03
Std
6.41E + 02
6.01E + 02
5.35E + 02
Std
2.30E + 02
2.08E + 02
3.71E + 02
CEC2017-F11
Ave
1.48E + 03
2.96E + 03
1.86E + 03
CEC2017-F26
Ave
6.23E + 03
7.56E + 03
5.12E + 03
Std
1.32E + 02
4.26E + 03
1.41E + 03
Std
4.00E + 02
3.58E + 03
2.27E + 03
CEC2017-F12
Ave
2.12E + 06
7.61E + 06
7.42E + 06
CEC2017-F27
Ave
3.34E + 03
4.60E + 03
3.41E + 03
Std
2.00E + 06
1.42E + 07
2.22E + 07
Std
4.78E + 01
1.26E + 03
2.57E + 02
CEC2017-F13
Ave
1.23E + 04
7.34E + 03
5.34E + 06
CEC2017-F28
Ave
3.31E + 03
9.11E + 03
3.57E + 03
Std
6.20E + 03
3.47E + 03
2.23E + 07
Std
5.70E + 01
4.91E + 03
1.57E + 02

===== PAGE 40 =====
	
M. Yu et al.
277 
Page 40 of 51
Table 11   (continued)
ID
LSHADE-cnEpSin
LSHADE-SPACMA
IAGWO
ID
LSHADE-cnEpSin
LSHADE-SPACMA
IAGWO
CEC2017-F14
Ave
2.19E + 03
1.79E + 03
1.25E + 04
CEC2017-F29
Ave
3.74E + 03
4.14E + 03
3.83E + 03
Std
2.06E + 03
1.17E + 02
1.79E + 04
Std
171.51
4.32E + 02
233.94
CEC2017-F15
Ave
3.88E + 03
4.34E + 03
2.20E + 03
CEC2017-F30
Ave
76,239.75
71,778.12
4.85E + 05
Std
2.59E + 03
3.24E + 03
8.16E + 02
Std
7.14E + 04
1.14E + 05
2.35E + 06
Statistical results
Mean
1.83
2.17
1.99
(W|T|L)
(15|13|2)
(7|15|8)
(8|12|10)
Ranking
1
3
2

===== PAGE 41 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 41 of 51 
277
Table 10 presents the results from testing IAGWO using the CEC 2014 suite. In these 
tests, IAGWO surpassed other algorithms in six different scenarios, though it showed 
slightly weaker performance in one. Notably, IAGWO achieved a Friedman mean ranking 
value of 1.71, which places it second after L-SHADE but ahead of AL-SHADE. Table 11 
focuses on the performance of IAGWO in the CEC 2017 suite. Here, IAGWO showed 
strong results in 8 of the test cases, but its performance was less impressive in 10 others. 
In terms of the Friedman mean ranking, IAGWO scored 1.99, which is slightly better than 
LSHADE-SPACMA, but not quite as good as LSHADE-cnEpSin. These results provide a 
detailed comparison of IAGWO’s performance relative to other algorithms in these spe-
cific test environments.
Combining experimental outcomes, IAGWO can be positioned as a high-performing 
optimizer in test functions. These results not only demonstrate IAGWO’s strong capability 
in handling different types of optimization problems but also indicate its competitive stand-
ing against existing top-tier algorithms. These findings emphasize the potential application 
value of IAGWO in the field of evolutionary computing and optimization. This simultane-
ously demonstrates the effectiveness of the three improvement strategies we introduced: 
the PSO Search Mechanism, the IMF Inertia Weighting Strategy, and the Adaptive Updat-
ing Mechanism, enhancing the optimization performance of the algorithm.
4.8  IAGWO for 19 engineering design challenges
The specific constrained handling technique used in engineering design challenges is called 
"constraint relaxation." Constraint relaxation involves temporarily easing or loosening 
certain constraints within the design problem to explore alternative solutions. This allows 
designers to generate a wider range of potential solutions without being overly restricted 
by strict constraints. Once various solutions have been identified, designers can then 
reintroduce and refine the constraints to ensure that the final design meets all necessary 
requirements. Intelligent optimization algorithms can efficiently explore the design space 
and uncover potential solutions. By integrating constraint relaxation techniques, these 
algorithms can dynamically handle constraints during the search process, allowing for a 
broader exploration of the design space and enhancing the efficiency of finding optimal 
solutions.
In this section, the proficiency of IAGWO is meticulously evaluated through a set of 
19 engineering design challenges (EDC) sourced from the CEC 2020 real-world optimiza-
tion benchmarks, as outlined by Kumar et al., 2020., 2020. A concise summary of these 
engineering challenges is presented in Table 12, which includes key details such as their 
dimensions (D), the count of inequality constraints (g), equality constraints (h), and the 
known optimal cost (fmin). The evaluation parameters are defined as follows: a population 
size of 50, a maximum of 1000 iterations, and 30 independent runs for each challenge.
Table 13 is dedicated to enumerating the performance metrics of IAGWO. This table 
encompasses various metrics including the best cost achieved (Best), the average cost 
(Ave), the cost’s standard deviation (Std), and performance symbols (W|T|L), representing 
the number of wins, ties, and losses, respectively. Additionally, the evaluation includes a 
comprehensive analysis of the mean performance of all the algorithms involved in the test-
ing. It also presents a ranking of these methods, providing a clear and structured compari-
son of their overall effectiveness and highlights instances where IAGWO achieves optimal 
results.

===== PAGE 42 =====
	
M. Yu et al.
277 
Page 42 of 51
The statistical analysis drawn from these results clearly demonstrates IAGWO’s supe-
rior ability in solving these real-world engineering design challenges, effectively outshin-
ing other methods. In terms of overall effectiveness, other algorithms like OMA, DMO, 
RGWO, and ENGWO trail behind IAGWO. This comprehensive analysis accentuates the 
robustness and efficacy of IAGWO.
5  Summary and future directions
In this study, we introduced an enhanced version of the GWO, aiming to tackle its inher-
ent limitations and elevate its efficacy for addressing contemporary optimization chal-
lenges. The original GWO, while promising, exhibited deficiencies, notably in its con-
vergence speed and its adaptability to intricate, high-dimensional problem landscapes. 
To fortify its capabilities, we embarked on an innovative path, culminating in the birth 
of an enhanced variant dubbed the Improved Adaptive Grey Wolf Optimizer (IAGWO). 
Central to our enhancement strategy was the infusion of concepts borrowed from Par-
ticle Swarm Optimization (PSO), introducing a velocity component to expedite conver-
gence. This integration of velocity mechanics injected dynamism into the algorithm, 
enabling it to traverse solution spaces with greater agility. Moreover, a novel search 
mechanism was devised, augmenting the algorithm’s exploration and exploitation capa-
bilities to navigate complex problem domains more efficiently. In addition to these fun-
damental alterations, we devised novel strategies for Inertia Weighting and Position 
Updating, leveraging Nonlinear Inertia Weighting for Intermediary Fitness (IMF) and 
Table 12   Overview of 19 EDC from CEC 2020
Problems
Name
D
g
h
fmin
EDC01
Weight Minimization of a Speed Reducer
7
11
0
2.9944E + 03
EDC02
Optimal Design of Industrial refrigeration System
14
15
0
3.2213E-02
EDC03
Tension/compression spring design (case 1)
3
3
0
1.2665E-02
EDC04
Pressure vessel design
4
4
0
5.8853E + 03
EDC05
Welded beam design
4
5
0
1.6702E + 00
EDC06
Three-bar truss design problem
2
3
0
2.6389E + 02
EDC07
Multiple disk clutch brake design problem
5
7
0
2.3524E-01
EDC08
Planetary gear train design optimization problem
9
10
1
5.2576E-01
EDC09
Step-cone pulley problem
5
8
3
1.6069E + 01
EDC10
Robot gripper problem
7
7
0
2.5287E + 00
EDC11
Hydro-static thrust bearing design problem
4
7
0
1.6161E + 03
EDC12
Four-stage gearbox problem
22
86
0
3.5359E + 01
EDC13
10-bar truss design
10
3
0
5.2445E + 02
EDC14
Rolling element bearing
10
9
0
1.4614E + 04
EDC15
Gas Transmission Compressor Design (GTCD)
4
1
0
2.9648 + 06
EDC16
Tension/compression spring design (case 2)
3
8
0
2.6138E + 00
EDC17
Gear train design Problem
4
1
1
0.0000E + 00
EDC18
Himmelblau’s Function
5
6
0
-3.0665E + 04
EDC19
Topology Optimization
30
30
0
2.6393E + 00

===== PAGE 43 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 43 of 51 
277
Table 13   Comparison of 14 algorithms in EDC
ID
GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
EDC01
Best
Ave
Std
3.05E + 03
2.99E + 03
3.03E + 03
3.02E + 03
3.13E + 03
2.99E + 03
2.99E + 03
2.99E + 03
3.00E + 03
3.00E + 03
3.00E + 03
3.22E + 03
2.99E + 03
2.99E + 03
3.16E + 03
2.99E + 03
3.47E + 03
3.05E + 03
3.95E + 03
3.00E + 03
3.00E + 03
3.01E + 03
3.01E + 03
3.01E + 03
3.00E + 03
3.33E + 03
2.99E + 03
2.99E + 03
9.53E + 01
2.15E-04
8.14E + 02
2.58E + 01
5.29E + 02
3.25E-01
8.11E + 00
4.64E + 01
4.07E + 00
4.24E + 00
2.42E + 00
4.49E + 01
1.24E-03
4.79E-13
EDC02
Best
Ave
Std
1.99E + 05
3.22E-02
7.27E-01
2.48E + 00
2.22E-01
3.25E-02
9.04E-02
5.18E-02
3.97E-02
3.92E-02
4.15E-02
9.15E + 06
5.79E-02
3.53E-02
3.05E + 15
8.68E-02
6.42E + 15
1.99E + 14
1.49E + 00
6.19E-02
8.43E + 14
7.69E-02
2.81E + 14
9.36E + 13
9.36E + 13
2.95E + 15
1.87E + 14
5.44E-02
4.06E + 15
5.95E-02
1.23E + 16
4.20E + 14
8.60E-01
5.03E-02
2.96E + 14
3.81E-02
4.53E + 14
2.96E + 14
2.96E + 14
6.34E + 15
3.95E + 14
9.25E-03
EDC03
Best
Ave
Std
1.59E-02
1.27E-02
1.27E-02
1.27E-02
1.27E-02
1.27E-02
1.27E-02
1.27E-02
1.27E-02
1.27E-02
1.27E-02
6.19E-02
1.27E-02
1.27E-02
1.86E-02
1.32E-02
1.35E-02
1.31E-02
2.52E + 07
1.32E-02
1.33E-02
1.27E-02
1.27E-02
1.27E-02
1.28E-02
5.28E + 13
1.40E-02
1.28E-02
2.16E-03
7.07E-04
1.28E-03
4.59E-04
5.90E + 07
7.37E-04
8.15E-04
6.16E-05
8.16E-05
4.85E-05
1.10E-04
9.29E + 13
1.24E-03
9.57E-05
EDC04
Best
Ave
Std
9.08E + 03
6.37E + 03
6.69E + 03
6.11E + 03
6.09E + 03
6.09E + 03
6.06E + 03
6.06E + 03
6.06E + 03
6.06E + 03
6.06E + 03
6.39E + 03
6.09E + 03
6.06E + 03
1.48E + 04
6.39E + 03
9.20E + 03
6.78E + 03
6.81E + 03
6.56E + 03
6.52E + 03
6.28E + 03
6.14E + 03
6.19E + 03
6.21E + 03
6.75E + 03
6.46E + 03
6.22E + 03
3.69E + 03
2.16E + 01
3.03E + 03
3.75E + 02
4.12E + 02
4.68E + 02
4.11E + 02
3.89E + 02
2.40E + 02
4.08E + 02
2.46E + 02
2.37E + 02
3.59E + 02
2.09E + 02
EDC05
Best
Ave
Std
2.11E + 00
1.67E + 00
1.84E + 00
1.83E + 00
1.75E + 00
1.67E + 00
1.68E + 00
1.67E + 00
1.67E + 00
1.67E + 00
1.67E + 00
2.04E + 00
1.67E + 00
1.67E + 00
3.35E + 00
1.74E + 00
2.50E + 00
1.97E + 00
1.92E + 00
1.67E + 00
1.78E + 00
1.67E + 00
1.67E + 00
1.67E + 00
1.67E + 00
2.73E + 00
2.01E + 00
1.67E + 00
8.69E-01
9.03E-02
7.15E-01
1.83E-01
1.16E-01
1.41E-03
4.26E-02
2.22E-16
1.83E-03
2.26E-03
5.72E-04
1.25E + 00
2.62E-01
9.17E-04
EDC06
Best
Ave
Std
2.64E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.73E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.68E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.65E + 02
2.64E + 02
2.91E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.64E + 02
2.66E + 02
2.64E + 02
2.76E + 02
2.64E + 02
2.64E + 02
6.01E-03
2.65E-04
8.28E-01
9.10E-02
1.91E + 01
1.21E-03
2.02E-02
5.29E-05
7.90E-03
5.99E + 00
6.26E-04
5.24E + 00
6.86E-04
1.29E-04
EDC07
Best
Ave
Std
2.77E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
4.63E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.35E-01
2.37E-01
2.35E-01
2.35E-01
1.35E-01
2.93E-17
6.28E-08
2.37E-07
4.21E-14
2.31E-06
7.96E-07
1.58E-15
3.53E-05
2.14E-05
9.37E-06
4.75E-03
1.51E-16
2.93E-17
EDC08
Best
Ave
Std
5.26E-01
5.24E-01
5.23E-01
5.23E-01
5.26E-01
5.23E-01
5.23E-01
5.23E-01
5.23E-01
5.23E-01
5.25E-01
6.34E-01
5.26E-01
5.24E-01
1.26E + 00
5.28E-01
5.28E-01
5.27E-01
5.32E-01
1.11E + 15
5.26E-01
5.25E-01
5.31E-01
5.40E-01
5.31E-01
1.08E + 00
5.31E-01
5.27E-01
1.20E + 00
3.18E-03
4.25E-03
4.03E-03
4.91E-03
3.50E + 15
1.74E-03
3.11E-03
4.84E-03
2.41E-02
5.19E-03
4.30E-01
4.63E-03
1.80E-03
EDC09
Best 8.51E + 00
8.18E + 00
8.82E + 00
8.21E + 00
8.18E + 00
8.18E + 00
8.18E + 00
8.18E + 00
8.19E + 00
8.19E + 00
8.18E + 00
8.34E + 00
8.18E + 00
8.18E + 00
Ave
1.15E + 01
8.18E + 00
1.01E + 01
8.25E + 00
8.18E + 00
8.18E + 00
8.22E + 00
8.18E + 00
8.20E + 00
8.20E + 00
8.19E + 00
8.61E + 00
8.18E + 00
8.18E + 00
Ave
1.80E + 00
1.42E-04
1.16E + 00
3.41E-02
9.16E-12
8.93E-04
9.02E-02
9.07E-08
7.48E-03
5.64E-03
1.96E-03
3.19E-01
5.94E-04
5.12E-13

===== PAGE 44 =====
	
M. Yu et al.
277 
Page 44 of 51
Table 13   (continued)
ID
GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
EDC10
Best
Ave
Std
5.59E + 00
2.62E + 00
3.66E + 00
3.53E + 00
8.99E + 00
3.06E + 00
2.57E + 00
2.83E + 00
3.24E + 00
3.03E + 00
2.87E + 00
6.46E + 00
3.07E + 00
3.43E + 00
4.01E + 01
3.07E + 00
5.45E + 00
5.28E + 00
1.50E + 17
3.66E + 00
3.73E + 00
3.23E + 00
3.50E + 00
2.93E + 18
3.22E + 00
8.19E + 00
3.93E + 00
3.78E + 00
3.45E + 01
3.24E-01
1.18E + 00
1.14E + 00
4.73E + 17
7.59E-01
6.36E-01
4.20E-01
2.54E-01
9.27E + 18
4.25E-01
1.21E + 00
7.12E-01
2.40E-01
EDC11
Best
Ave
Std
2.67E + 03
1.74E + 03
2.23E + 03
3.17E + 03
5.67E + 03
2.06E + 03
1.86E + 03
1.63E + 03
1.79E + 03
1.78E + 03
1.78E + 03
4.70E + 16
1.83E + 03
1.91E + 03
4.41E + 03
2.05E + 03
1.16E + 08
2.27E + 17
6.96E + 17
2.55E + 03
2.50E + 03
1.67E + 03
2.08E + 03
2.01E + 03
2.08E + 03
1.65E + 22
2.54E + 03
2.25E + 03
9.89E + 02
3.17E + 02
3.67E + 08
4.71E + 17
9.27E + 17
2.70E + 02
5.84E + 02
3.92E + 01
2.92E + 02
1.63E + 02
2.35E + 02
3.56E + 22
4.32E + 02
2.04E + 02
EDC12
Best
Ave
Std
1.02E + 17
3.96E + 01
1.15E + 17
1.06E + 17
1.11E + 16
1.95E + 16
4.13E + 01
5.14E + 01
1.41E + 15
2.32E + 16
5.52E + 01
9.03E + 17
5.72E + 01
2.48E + 17
8.13E + 19
4.78E + 16
9.26E + 17
3.35E + 17
5.64E + 17
8.52E + 17
1.78E + 17
8.43E + 16
1.89E + 17
2.47E + 17
2.16E + 17
4.61E + 19
2.34E + 17
6.63E + 17
1.48E + 20
1.38E + 17
8.91E + 17
1.32E + 17
4.33E + 17
1.06E + 18
1.74E + 17
1.48E + 17
1.55E + 17
1.96E + 17
3.08E + 17
9.72E + 19
7.25E + 17
6.26E + 17
EDC13
Best
Ave
Std
5.28E + 02
5.26E + 02
5.97E + 02
5.85E + 02
5.25E + 02
5.25E + 02
5.27E + 02
5.25E + 02
5.25E + 02
5.25E + 02
5.26E + 02
7.29E + 02
5.27E + 02
5.25E + 02
5.35E + 02
5.32E + 02
6.78E + 02
6.95E + 02
5.28E + 02
5.29E + 02
5.34E + 02
5.30E + 02
5.27E + 02
5.30E + 02
5.29E + 02
8.35E + 02
5.33E + 02
5.26E + 02
3.61E + 00
2.86E + 00
7.16E + 01
5.97E + 01
3.18E + 00
3.88E + 00
4.21E + 00
3.66E + 00
2.49E + 00
2.44E + 00
2.14E + 00
7.74E + 01
3.01E + 00
7.87E-01
EDC14
Best
Ave
Std
1.73E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.83E + 04
1.70E + 04
1.83E + 04
1.70E + 04
1.78E + 04
-9.77E + 03 1.70E + 04
1.78E + 04
1.70E + 04
1.70E + 04
1.70E + 04
1.76E + 04
1.70E + 04
1.70E + 04
1.19E + 03
4.54E-12
1.94E + 03
3.69E + 01
2.59E + 03
1.02E + 05
2.44E + 01
2.57E + 03
2.76E + 01
2.15E + 01
1.99E + 01
5.47E + 02
1.77E-08
3.83E-12
EDC15
Best
Ave
Std
2.97E + 06
2.96E + 06
2.97E + 06
2.97E + 06
2.99E + 06
2.96E + 06
2.96E + 06
2.96E + 06
2.97E + 06
2.96E + 06
2.96E + 06
3.21E + 06
2.96E + 06
2.96E + 06
3.06E + 06
2.96E + 06
3.02E + 06
3.03E + 06
3.05E + 06
2.97E + 06
2.97E + 06
2.96E + 06
2.97E + 06
2.97E + 06
2.97E + 06
3.81E + 06
2.97E + 06
2.96E + 06
1.08E + 05
1.71E + 02
3.35E + 04
2.88E + 04
6.64E + 04
2.78E + 02
9.26E + 03
1.04E + 01
4.53E + 02
3.22E + 02
6.04E + 01
6.22E + 05
3.34E + 03
1.04E + 01
EDC16
Best
Ave
Std
3.21E + 00
2.66E + 00
2.66E + 00
2.66E + 00
2.66E + 00
2.66E + 00
2.66E + 00
2.66E + 00
2.66E + 00
2.66E + 00
2.66E + 00
3.10E + 00
2.66E + 00
2.66E + 00
4.24E + 00
2.67E + 00
3.38E + 00
3.07E + 00
3.45E + 00
2.93E + 00
2.72E + 00
2.66E + 00
2.67E + 00
2.69E + 00
2.78E + 00
3.79E + 00
2.67E + 00
2.66E + 00
8.05E-01
1.73E-02
5.23E-01
4.85E-01
4.21E-01
4.45E-01
9.43E-02
2.93E-03
1.98E-02
1.73E-02
3.43E-01
4.49E-01
1.98E-02
8.95E-08
EDC17
Best
Ave
Std
1.63E-30
8.74E-20
0.00E + 00
0.00E + 00
1.23E-32
1.14E-16
0.00E + 00
2.19E-17
5.76E-16
1.60E-14
5.86E-16
0.00E + 00
2.47E-17
3.12E-15
3.10E-24
2.85E-15
1.93E-26
0.00E + 00
4.93E-29
3.58E-14
9.78E-33
5.66E-14
1.60E-12
1.21E-10
2.02E-13
0.00E + 00
5.43E-14
1.84E-12
4.61E-24
5.06E-15
6.09E-26
0.00E + 00
1.00E-28
4.59E-14
2.93E-32
5.95E-14
3.92E-12
2.57E-10
4.27E-13
0.00E + 00
1.01E-13
3.93E-12
EDC18
Best
Ave
Std
-3.06E + 04 -3.07E + 04 -3.04E + 04 -3.07E + 04 -3.07E + 04 -3.07E + 04 -3.07E + 04 -3.07E + 04 -3.07E + 04 -3.07E + 04 -3.07E + 04 -3.04E + 04 -3.07E + 04 -3.07E + 04
-3.05E + 04 -3.07E + 04 -2.98E + 04 -3.06E + 04 -3.06E + 04 -3.07E + 04 -3.06E + 04 -3.07E + 04 -3.07E + 04 -3.07E + 04 -3.07E + 04 -2.99E + 04 -3.07E + 04 -3.07E + 04
1.19E + 02
2.02E-05
4.01E + 02
1.60E + 02
7.02E + 01
4.17E-01
1.47E + 02
4.88E-06
2.31E + 00
1.46E + 00
6.28E-01
1.99E + 02
6.54E-03
3.03E-08

===== PAGE 45 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 45 of 51 
277
Table 13   (continued)
ID
GSA
DMO
WOA
HHO
CPSOGSA COA
AVOA
OMA
GWO
AGWO
ENGWO
iAEFA
RGWO
IAGWO
EDC19
Best
Ave
Std
3.48E + 00
2.64E + 00
2.64E + 00
2.64E + 00
2.65E + 00
2.66E + 00
2.64E + 00
2.65E + 00
2.79E + 00
2.72E + 00
2.76E + 00
2.64E + 00
2.64E + 00
2.64E + 00
4.01E + 00
2.64E + 00
2.64E + 00
2.64E + 00
2.73E + 00
2.73E + 00
2.64E + 00
2.66E + 00
2.97E + 00
2.90E + 00
2.88E + 00
2.64E + 00
2.64E + 00
2.64E + 00
3.37E-01
8.50E-16
4.68E-16
4.68E-16
7.23E-02
7.11E-02
3.63E-16
9.77E-03
1.29E-01
1.33E-01
1.10E-01
3.16E-05
1.45E-15
4.68E-16
(W|T|L)
(0|10|9)
(3|16|0)
(0|17|2)
(1|17|1)
(0|15|4)
(1|17|1)
(0|19|0)
(4|15|0)
(5|14|0)
(1|18|0)
(1|16|2)
(3|14|2)
(0|19|0)
(9|10|0)
Mean
11.32
4.45
9.67
8.63
8.72
6.59
6.76
4.02
7.05
7.37
6.32
12.00
6.27
3.86
Ranking
14
3
12
10
11
6
7
2
8
9
5
13
4
1

===== PAGE 46 =====
	
M. Yu et al.
277 
Page 46 of 51
employing Sigmoid adaptive techniques. These refinements were meticulously crafted 
to synergize with the core algorithm, amplifying its prowess in navigating diverse opti-
mization landscapes with finesse.
To validate the prowess of IAGWO, rigorous experimentation ensued, wherein 52 
test functions sourced from prestigious benchmark suites were scrutinized. Comparative 
analysis against eight prominent Metaheuristic (MH) algorithms, including the origi-
nal GWO and three of its variants, underscored IAGWO’s supremacy in terms of con-
vergence speed and solution precision. Furthermore, the algorithm’s mettle was tested 
against 15 formidable large-scale global optimization challenges, affirming its adeptness 
in grappling with high-dimensional complexities. The litmus test for IAGWO’s efficacy 
extended to competitive arenas, where it stood toe-to-toe against previous champions of 
the renowned CEC competitions across various iterations. Notably, IAGWO’s perfor-
mance surpassed expectations, firmly establishing its dominance and resilience in the 
face of formidable adversaries. Beyond the realm of academia, the real-world applica-
bility of IAGWO was validated through its deployment in 19 diverse engineering design 
challenges. Here, its versatility and competitive edge shone brightly, outperforming 
established algorithms and offering tangible solutions to practical problems.
Despite its commendable achievements, the journey of IAGWO is far from over. 
While it has emerged as a potent force in the optimization landscape, ongoing efforts 
are directed towards fine-tuning its computational efficiency. Time comparison analyses 
have revealed areas for optimization, particularly concerning computational overhead 
in certain test suites. Future endeavors will thus focus on streamlining computational 
complexity without compromising search efficacy, ensuring that IAGWO remains at 
the forefront of optimization methodologies. Looking ahead, the horizon for IAGWO is 
brimming with promise. Beyond academic benchmarks, its utility extends to a myriad of 
real-world applications, ranging from feature extraction to operations research, classifi-
cation, and logistical challenges. As we embark on this journey, our aim is clear: to har-
ness the full potential of IAGWO in unraveling the complexities of the modern world, 
one optimization problem at a time.
Acknowledgements  There is no acknowledgement involved in this work.
Author contributions  MY: conceptualization, methodology, writing—original draft, formal analysis, data 
curation, writing—review & editing, software. WL: visualization, formal analysis, writing—review & edit-
ing. JX: conceptualization, resources, supervision, formal analysis. YQ: software, writing—review & edit-
ing, resources. SB: methodology, visualization resources, software. LT: visualization resources.
Funding  This work was supported by Natural Science Foundation of Tianjin Municipality (21JCY-
BJC00110) and China Postdoctoral Science Foundation (2023M731803).
Availability of data and materials  Enquiries about data availability should be directed to the authors.
Declarations 
Competing interests  The authors have no relevant financial or non-financial interests to disclose.
Ethical approval  His article does not contain any studies with human participants or animals performed by 
any of the authors.
Informed consent  This article does not contain any studies with human participants. So informed consent is 
not applicable here.

===== PAGE 47 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 47 of 51 
277
Open Access  This article is licensed under a Creative Commons Attribution 4.0 International License, 
which permits use, sharing, adaptation, distribution and reproduction in any medium or format, as long 
as you give appropriate credit to the original author(s) and the source, provide a link to the Creative Com-
mons licence, and indicate if changes were made. The images or other third party material in this article 
are included in the article’s Creative Commons licence, unless indicated otherwise in a credit line to the 
material. If material is not included in the article’s Creative Commons licence and your intended use is not 
permitted by statutory regulation or exceeds the permitted use, you will need to obtain permission directly 
from the copyright holder. To view a copy of this licence, visit http://​creat​iveco​mmons.​org/​licen​ses/​by/4.​0/.
References
Abdel-Basset M, Mohamed R, Jameel M, Abouhawwash M (2023) Nutcracker optimizer: A novel nature-
inspired metaheuristic algorithm for global optimization and engineering design problems. Knowl 
Based Syst 262:110248
Abdollahzadeh B, Gharehchopogh FS, Mirjalili S (2021) African vultures optimization algorithm: A 
new nature-inspired metaheuristic algorithm for global optimization problems. Comput Ind Eng 
158:107408
Abdullah JM, Ahmed T (2019) Fitness dependent optimizer: inspired by the bee swarming reproductive 
process. IEEE Access 7:43473–43486
Abualigah L, Yousri D, Abd Elaziz M, Ewees AA, Al-qaness MAA, Gandomi AH (2021) Aquila Opti-
mizer: A novel meta-heuristic optimization algorithm. Comput Ind Eng 157:107250
Abushawish, A., & Jarndal, A. 2021. Hybrid GWOCS optimization based parameter extraction method 
applied to GaN devices. Paper presented at the 2021 IEEE International Midwest Symposium on Cir-
cuits and Systems (MWSCAS).
Ahrari, A., Elsayed, S., Sarker, R., Essam, D., & Coello, C. A. C. 2022. Problem Definition and Evaluation 
Criteria for the CEC’2022 Competition on Dynamic Multimodal Optimization. Paper presented at the 
Proceedings of the IEEE World Congress on Computational Intelligence (IEEE WCCI 2022), Padua, 
Italy.
Aldosari F, Abualigah L, Almotairi KH (2022) A normal distributed dwarf Mongoose Optimization Algo-
rithm for global optimization and data clustering applications. Symmetry 14(5):1021
Ambika V, Lim S-J (2022) Hybrid image embedding technique using Steganographic Signcryption and 
IWT-GWO methods. Microprocess Microsyst 95:104688
Awad, N. H., Ali, M. Z., & Suganthan, P. N. 2017. Ensemble sinusoidal differential covariance matrix adap-
tation with Euclidean neighborhood for solving CEC2017 benchmark problems. In: Paper presented at 
the 2017 IEEE congress on evolutionary computation (CEC).
Bäck T, Schwefel H-P (1993) An overview of evolutionary algorithms for parameter optimization. Evol 
Comput 1(1):1–23
Banaie-Dezfouli M, Nadimi-Shahraki MH, Beheshti Z (2021) R-GWO: Representative-based grey wolf 
optimizer for solving engineering problems. Appl Soft Comput 106:107328
Bayraktar, Z., Komurcu, M., & Werner, D. H. 2010. Wind Driven Optimization (WDO): A novel nature-
inspired optimization algorithm and its application to electromagnetics. Paper presented at the 2010 
IEEE antennas and propagation society international symposium.
Biabani F, Shojaee S, Hamzehei-Javaran S (2022) A new insight into metaheuristic optimization method 
using a hybrid of PSO, GSA, and GWO. Structures 44:1168–1189
Chauhan, D., & Yadav, A. 2024b. A Comprehensive Survey on Artificial Electric Field Algorithm: Theories 
and Applications. Archives of Computational Methods in Engineering.
Chauhan D, Shivani, & Cheng, R. (2024) Competitive Swarm Optimizer: a decade survey. Swarm Evol 
Comput 87:101543
Chauhan D, Yadav A (2023a) An Adaptive Artificial Electric Field Algorithm for Continuous Optimization 
Problems 40(9):e13380
Chauhan D, Yadav A (2023b) Optimizing the parameters of hybrid active power filters through a compre-
hensive and dynamic multi-swarm gravitational search algorithm. Eng Appl Artif Intell 123:106469
Chauhan D, Yadav A (2024a) An archive-based self-adaptive artificial electric field algorithm with orthogo-
nal initialization for real-parameter optimization problems. Appl Soft Comput 150:111109
Chen W, Wang H, Liu Z, Jiang K (2023) Time-energy-jerk optimal trajectory planning for high-speed 
parallel manipulator based on quantum-behaved particle swarm optimization algorithm and quintic 
B-spline. Eng Appl Artif Intell 126:107223

===== PAGE 48 =====
	
M. Yu et al.
277 
Page 48 of 51
Cheng M-Y, Sholeh MN (2023) Optical microscope algorithm: A new metaheuristic inspired by micro-
scope magnification for solving engineering optimization problems. Knowl-Based Syst 279:110939
Cuong-Le T, Minh H-L, Sang-To T, Khatir S, Mirjalili S, Abdel Wahab M (2022) A novel version of 
grey wolf optimizer based on a balance function and its application for hyperparameters optimiza-
tion in deep neural network (DNN) for structural damage identification. Eng Fail Anal 142:106829
Deng W, Xu J, Gao X-Z, Zhao H (2022) An enhanced MSIQDE algorithm with novel multiple strategies 
for global optimization problems. IEEE Trans Syst Man Cybern Syst 52(3):1578–1587
Dorigo M, Birattari M, Stützle T (2006) Ant colony optimization. Computational Intelligence Magazine, 
IEEE 1:28–39
Eskandar H, Sadollah A, Bahreininejad A, Hamdi M (2012) Water cycle algorithm—a novel metaheuris-
tic optimization method for solving constrained engineering optimization problems. Comput Struct 
110:151–166
Fan X, Yu M (2022) Coverage optimization of WSN based on improved grey wolf optimizer. Comput 
Sci 49:628–631
Fu H, Shi H, Xu Y, Shao J (2022) Research on gas outburst prediction model based on multiple strategy 
fusion improved snake optimization algorithm with temporal convolutional network. IEEE Access 
10:117973–117984
Fu S, Huang H, Ma C, Wei J, Li Y, Fu Y (2023a) Improved dwarf mongoose optimization algorithm 
using novel nonlinear control and exploration strategies. Expert Syst Appl 233:120904
Fu S, Li K, Huang H, Ma C, Fan Q, Zhu Y (2024a) Red-billed blue magpie optimizer: a novel metaheuristic 
algorithm for 2D/3D UAV path planning and engineering design problems. Artif Intell Rev 57(6):134
Fu Y, Liu D, Chen J, He L (2024b) Secretary bird optimization algorithm: a new metaheuristic for solv-
ing global optimization problems. Artif Intell Rev 57(5):123
Garg V, Deep K, Bansal S (2023) Improved Teaching Learning Algorithm with Laplacian operator for 
solving nonlinear engineering optimization problems. Eng Appl Artif Intell 124:106549
Guo H-W, Sang H-Y, Zhang X-J, Duan P, Li J-Q, Han Y-Y (2023) An effective fruit fly optimization 
algorithm for the distributed permutation flowshop scheduling problem with total flowtime. Eng 
Appl Artif Intell 123:106347
Gupta, S., & Deep, K. 2017. Hybrid Grey Wolf Optimizer with Mutation Operator. Paper presented at 
the International Conference on Soft Computing for Problem Solving (SocProS), Indian Inst Tech-
nol Bhubaneswar, Bhubaneswar, INDIA.
Gupta S, Deep K (2020) Enhanced leadership-inspired grey wolf optimizer for global optimization prob-
lems. Engineering with Computers 36(4):1777–1800
Hakli H, Kiran MS (2020) An improved artificial bee colony algorithm for balancing local and global 
search behaviors in continuous optimization. Int J Mach Learn Cybern 11(9):2051–2076
Havaei P, Sandidzadeh MA (2023) Multi-objective train speed profile determination for automatic train 
operation with conscious search: a new optimization algorithm, a comprehensive study. Eng Appl 
Artif Intell 119:105756
Hayyolalam V, Kazem AAP (2020) Black widow optimization algorithm: a novel meta-heuristic 
approach for solving engineering optimization problems. Eng Appl Artif Intell 87:103249
Heidari AA, Mirjalili S, Faris H, Aljarah I, Mafarja M, Chen H (2019) Harris hawks optimization: Algo-
rithm and applications. Futur Gener Comput Syst 97:849–872
Hu X-G, Ho T-S, Rabitz H (1998) The collocation method based on a generalized inverse multiquadric 
basis for bound-state problems. Comput Phys Commun 113(2–3):168–179
Hu G, Du B, Wang X, Wei G (2022) An enhanced black widow optimization algorithm for feature selec-
tion. Knowl Based Syst 235:107638
Jangir P, Jangir N (2018) A new Non-Dominated Sorting Grey Wolf Optimizer (NS-GWO) algorithm: 
Development and application to solve engineering designs and economic constrained emission dis-
patch problem with integration of wind power. Eng Appl Artif Intell 72:449–467
Jia H, Peng X, Lang C (2021) Remora optimization algorithm. Expert Syst Appl 185:115665
Jia H, Rao H, Wen C, Mirjalili S (2023) Crayfish optimization algorithm. Artif Intell Rev 56(Suppl 
2):1919–1979
Kaveh A, Farhoudi N (2013) A new optimization method: Dolphin echolocation. Adv Eng Softw 59:53–70
Kennedy, J., & Eberhart, R. 1995a. Particle swarm optimization. Paper presented at the Proceedings of 
ICNN’95 - International Conference on Neural Networks.
Kennedy, J., & Eberhart, R. 1995b. Particle swarm optimization (PSO). Paper presented at the Proc. 
IEEE international conference on neural networks, Perth, Australia.
Li X, Tang K, Omidvar MN, Yang Z, Qin K, China H (2013) Benchmark functions for the CEC 2013 
special session and competition on large-scale global optimization. Gene 7(33):8

===== PAGE 49 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 49 of 51 
277
Li Y, Han T, Zhou H, Tang S, Zhao H (2022) A novel adaptive L-SHADE algorithm and its application in 
UAV swarm resource configuration problem. Inf Sci 606:350–367
Li K, Huang H, Fu S, Ma C, Fan Q, Zhu Y (2023) A multi-strategy enhanced northern goshawk optimiza-
tion algorithm for global optimization and engineering design problems. Comput Methods Appl Mech 
Eng 415:116199
Liang JJ, Qu BY, Suganthan PN (2013) Problem definitions and evaluation criteria for the CEC 2014 special 
session and competition on single objective real-parameter numerical optimization. Comput Intell Lab 
635(2):1–32
Liang J-J, Qu B, Gong D, Yue C (2019) Problem definitions and evaluation criteria for the CEC 2019 spe-
cial session on multimodal multiobjective optimization. Zhengzhou University, Computational Intel-
ligence Laboratory, pp 1–26
Liu Z, He L, Yuan L, Zhang H (2022) Path Planning of Mobile Robot Based on TGWO Algorithm. Hsi-
Chiao Tung Ta Hsueh/J. Xi’an Jiaotong Univ 56:49–60
Liu Y, Jiang Y, Zhang X, Pan Y, Wang J (2023) An improved grey wolf optimizer algorithm for identifica-
tion and location of gas emission. J Loss Prev Process Ind 82:105003
Liu, Y. Y., Sun, J. H., Yu, H. Y., Wang, Y. Y., & Zhou, X. K. 2020. An Improved Grey Wolf Optimizer 
Based on Differential Evolution and OTSU Algorithm. Applied Sciences-Basel, 10(18).
Luo Y, Qin Q, Hu Z, Zhang Y (2023) Path planning for unmanned delivery robots based on EWB-GWO 
algorithm. Sensors 23(4):1867
Mallipeddi R, Suganthan PN (2010) Problem definitions and evaluation criteria for the CEC 2010 com-
petition on constrained real-parameter optimization. Nanyang Technological University, Singapore 
24:1–17
Meidani K, Hemmasian A, Mirjalili S, Barati Farimani A (2022) Adaptive grey wolf optimizer. Neural 
Comput Appl 34(10):7711–7731
Meng X, Jiang J, Wang H (2021) AGWO: Advanced GWO in multi-layer perception optimization. Expert 
Syst Appl 173:114676
Mirjalili S (2016) SCA: a sine cosine algorithm for solving optimization problems. Knowl Based Syst 
96:120–133
Mirjalili S, Lewis A (2016) The whale optimization algorithm. Adv Eng Softw 95:51–67
Mirjalili S, Mirjalili SM, Lewis A (2014) Grey wolf optimizer. Adv Eng Softw 69:46–61
Mohakud, R., & Dash, R. 2022. Skin cancer image segmentation utilizing a novel EN-GWO based hyper-
parameter optimized FCEDN. J. King Saud Univ. - Comput. Inf. Sci., 34(10): 9889–9904.
Mohamed, A. W., Hadi, A. A., Fattouh, A. M., & Jambi, K. M. 2017. LSHADE with semi-parameter adap-
tation hybrid with CMA-ES for solving CEC 2017 benchmark problems. Paper presented at the 2017 
IEEE Congress on evolutionary computation (CEC).
Mohammed H, Rashid T (2023) FOX: a FOX-inspired optimization algorithm. Appl Intell 53(1):1030–1050
Mohammed H, Abdul Z, Hamad Z (2024) Enhancement of GWO for solving numerical functions and engi-
neering problems. Neural Comput Appl 36(7):3405–3413
Muthiah-Nakarajan V, Noel MM (2016) Galactic Swarm Optimization: a new global optimization 
metaheuristic inspired by galactic motion. Appl Soft Comput 38:771–787
Nadimi-Shahraki MH, Taghian S, Mirjalili S (2021) An improved grey wolf optimizer for solving engineer-
ing problems. Expert Syst Appl 166:113917
Nadimi-Shahraki MH, Taghian S, Mirjalili S, Zamani H, Bahreininejad A (2022) GGWO: Gaze cues learn-
ing-based grey wolf optimizer and its applications for solving engineering problems. J Comput Sci 
61:101636
Nadimi-Shahraki MH, Taghian S, Zamani H, Mirjalili S, Elaziz MA (2023) MMKE: Multi-trial vector-
based monkey king evolution algorithm and its applications for engineering optimization problems. 
PLoS ONE 18(1):e0280006
Pan W-T (2012) A new Fruit Fly Optimization Algorithm: Taking the financial distress model as an exam-
ple. Knowl Based Syst 26:69–74
Rashedi E, Nezamabadi-Pour H, Saryazdi S (2009) GSA: A Gravitational Search Algorithm. Inf Sci 
179(13):2232–2248
Rathan, S., Shah, D., Kumar, T. H., & Charan, K. S. 2023. Adaptive IQ and IMQ-RBFs for solving Initial 
Value Problems: Adam-Bashforth and Adam-Moulton methods. arXiv preprint arXiv:2302.06113.
Said R, Elarbi M, Bechikh S, Coello Coello CA, Said LB (2023) Discretization-based feature selection as a 
bilevel optimization problem. IEEE Trans Evol Comput 27(4):893–907
Saka MP, Hasançebi O, Geem ZW (2016) Metaheuristics in structural optimization and discussions on har-
mony search algorithm. Swarm Evol Comput 28:88–97
Şenel FA, Gökçe F, Yüksel AS, Yiğit T (2019) A novel hybrid PSO–GWO algorithm for optimization prob-
lems. Eng Comput 35(4):1359–1373

===== PAGE 50 =====
	
M. Yu et al.
277 
Page 50 of 51
Shayanfar H, Gharehchopogh FS (2018) Farmland fertility: A new metaheuristic algorithm for solving con-
tinuous optimization problems. Appl Soft Comput 71:728–746
Shehadeh HA (2023) Chernobyl disaster optimizer (CDO): a novel meta-heuristic method for global optimi-
zation. Neural Comput Appl 35(15):10733–10749
Singh, S., & Bansal, J. C. 2022b. Mutation-driven grey wolf optimizer with modified search mechanism. 
Expert Systems with Applications, 194.
Singh S, Bansal JC (2022a) Mutation-driven grey wolf optimizer with modified search mechanism. Expert 
Syst Appl 194:116450
Soliman MA, Hasanien HM, Turky RA, Muyeen SM (2022) Hybrid African vultures–grey wolf optimizer 
approach for electrical parameters extraction of solar panel models. Energy Rep 8:14888–14900
Storn R, Price K (1997) Differential evolution–a simple and efficient heuristic for global optimization over 
continuous spaces. J Global Optim 11(4):341–359
Tanabe, R., & Fukunaga, A. S. 2014. Improving the search performance of SHADE using linear population 
size reduction. Paper presented at the 2014 IEEE congress on evolutionary computation (CEC).
Tripathy, B., Reddy Maddikunta, P. K., Pham, Q.-V., Gadekallu, T. R., Dev, K., Pandya, S., & ElHalawany, 
B. M. 2022. Harris hawk optimization: a survey onvariants and applications. Computational Intelli-
gence and Neuroscience, 2022.
Wang, Q., Xu, J., Zhang, W., Mao, M., Wei, Z., Wang, L., Cui, C., Zhu, Y., & Ma, J. 2018. Research pro-
gress on vanadium-based cathode materials for sodium ion batteries. J. Mater. Chem. A Mater. Energy 
Sustain., 6(19): 8815–8838.
Wei, G. 2012. Study on Genetic Algorithm and Evolutionary Programming. Paper presented at the 2nd 
IEEE International Conference on Parallel, Distributed and Grid Computing (PDGC), Jaypee Univ 
Informat Technol (JUIT), Waknaghat, INDIA.
Wilcoxon F (1945) Individual comparisons by ranking methods. Biom Bull 1(6):80–83
Wolpert DH, Macready WG (1997) No free lunch theorems for optimization. IEEE Trans Evol Comput 
1(1):67–82
Xia X, Fu X, Zhong S, Bai Z, Wang Y (2023) Gravity particle swarm optimization algorithm for solving 
shop visit balancing problem for repairable equipment. Eng Appl Artif Intell 117:105543
Xue, J., & Shen, B. 2022. Dung beetle optimizer: a new meta-heuristic algorithm for global optimization. 
Journal of Supercomputing.
Xue J, Shen B (2020) A novel swarm intelligence optimization approach: sparrow search algorithm. Sys-
tems Science & Control Engineering 8:22–34
Yang, X.-S. 2009. Firefly algorithms for multimodal optimization. Paper presented at the International sym-
posium on stochastic algorithms.
Yapici H, Cetinkaya N (2019) A new meta-heuristic optimizer: Pathfinder algorithm. Appl Soft Comput 
78:545–568
Yu X, Jiang N, Wang X, Li M (2023) A hybrid algorithm based on grey wolf optimizer and differential evo-
lution for UAV path planning. Expert Syst Appl 215:119327
Yuan Y, Ren J, Wang S, Wang Z, Mu X, Zhao W (2022) Alpine skiing optimization: A new bio-inspired 
optimization algorithm. Adv Eng Softw 170:103158
Zhang, M. J., Long, D. Y., Wang, X., Yu, L. Z., Wu, J. W., Li, D. H., Yang, J., & Ieee. 2019. Improved Grey 
Wolf Algorithm Based on Nonlinear Control Parameter Strategy. Paper presented at the Chinese Auto-
mation Congress (CAC), Hangzhou, PEOPLES R CHINA.
Zhou Y, He X, Chen Z, Jiang S (2022) A neighborhood regression optimization algorithm for computation-
ally expensive optimization problems. IEEE Trans Cybern 52(5):3018–3031
Publisher’s Note  Springer Nature remains neutral with regard to jurisdictional claims in published maps and 
institutional affiliations.

===== PAGE 51 =====
Improved multi‑strategy adaptive Grey Wolf Optimization for…
Page 51 of 51 
277
Authors and Affiliations
Mingyang Yu1 · Jing Xu1 · Weiyun Liang1 · Yu Qiu1 · Sixu Bao1 · Lin Tang2
 *	 Jing Xu 
	
xujing@nankai.edu.cn
	
Mingyang Yu 
	
2120220567@mail.nankai.edu.cn
	
Weiyun Liang 
	
weiyunliang@mail.nankai.edu.cn
	
Yu Qiu 
	
yqiu@nankai.edu.cn
	
Sixu Bao 
	
2120220492@mail.nankai.edu.cn
	
Lin Tang 
	
ltang12@nyit.edu
1	
College of Artificial Intelligence, Nankai University, Tianjin 300350, China
2	
Department of Biological and Chemical Sciences, New York Institute of Technology, 
New York 11568‑8000, USA
