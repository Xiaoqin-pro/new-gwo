function result = demoRun(job)
%DEMORUN Toy sphere random sampling for 4-worker infrastructure ONLY.
% Do not use as GWO performance or a scientific benchmark.
rng(job.seed,'twister');
D=job.D; budget=job.maxFE;
best=inf;
for i=1:budget
    x=-5+10*rand(1,D);
    f=sum(x.^2);
    if f<best, best=f; end
end
result=struct('BestCost',best,'Evaluations',budget, ...
    'Note','synthetic parallel infrastructure check ONLY');
end
