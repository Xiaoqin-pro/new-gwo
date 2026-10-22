function test_timing_final(reps)
%TEST_TIMING_FINAL  Quiet-machine timing of the whole algorithm: original vs optimised, bitwise-checked.
if nargin<1 || isempty(reps), reps=3; end
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=50; N=50; budget=100000; seed=3986;
% --- preliminary: bitwise equality on the STEER confirmation's own cells ---
cells={ {1,3071}, {13,3072}, {30,3073} };
for k=1:numel(cells)
    fidC=cells{k}{1}; seedC=cells{k}{2}; fcC=@(x)CEC2017Function(x,fidC);
    rng(261013000+fidC*10000+seedC,'twister'); poolC=-100+200*rand(50,D);
    bC=struct('initialPopulation',poolC,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
        'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
        'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
    [Bc1,Tc1]=SGWO_STEER(fcC,bC,[],N,seedC+1000000);
    [Bc2,Tc2]=SGWO_STEER3(fcC,bC,[],N,seedC+1000000);
    ok=isequal(Tc1,Tc2)&&Bc1.Cost==Bc2.Cost;
    fprintf('  confirmation cell F%-3d s%d: %s (cost %.10g)\n',fidC,seedC,ternary(ok,'BITWISE EQUAL','DIFFERS'),Bc1.Cost);
    assert(ok,'optimised implementation differs on a confirmation cell');
end
funcs=[1 13 30];
res=zeros(numel(funcs),3,reps);  % 1=frozen orig, 2=frozen opt, 3=steer opt
for k=1:numel(funcs)
    fid=funcs(k); fc=@(x)CEC2017Function(x,fid);
    for r=1:reps
        rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
        b=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
            'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
            'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','steerLambda',0.5,'succSteer',0);
        t=tic; [B0,T0]=SGWO_STEER(fc,b,[],N,seed+1000000); res(k,1,r)=toc(t);
        t=tic; [B1,T1]=SGWO_STEER3(fc,b,[],N,seed+1000000); res(k,2,r)=toc(t);
        assert(isequal(T0,T1)&&B0.Cost==B1.Cost,'frozen opt not bitwise equal (F%d)',fid);
        b2=b; b2.succSteer=0.5;
        t=tic; [B2,T2]=SGWO_STEER3(fc,b2,[],N,seed+1000000); res(k,3,r)=toc(t);
        assert(~isempty(T2),'steer run failed');
    end
end
fprintf('%-5s %-14s %-14s %-14s %-10s %-10s\n','F','frozen(orig)','frozen(opt)','steer(opt)','impl ratio','mech cost');
mi=zeros(numel(funcs),3);
for k=1:numel(funcs)
    mi(k,:)=min(res(k,:,:),[],3);
    fprintf('F%-4d %8.2f s     %8.2f s     %8.2f s     %6.3f     %6.3f\n', ...
        funcs(k),mi(k,1),mi(k,2),mi(k,3),mi(k,2)/mi(k,1),mi(k,3)/mi(k,2));
end
fprintf('median over functions: impl ratio %.3f  |  mechanism cost (same implementation) %.3f\n', ...
    median(mi(:,2)./mi(:,1)), median(mi(:,3)./mi(:,2)));
end

function out=ternary(cond,a,b)
if cond, out=a; else, out=b; end
end
