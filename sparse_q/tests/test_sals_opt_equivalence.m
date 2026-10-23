function test_sals_opt_equivalence()
%TEST_SALS_OPT_EQUIVALENCE  The batched/vectorised SALS hot path must reproduce the pre-optimisation
%   implementation BITWISE in every SALS mode.  Reference copy: tests/ref/SGWO_SALS_preopt.m
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'),fullfile(root,'tests','ref'));
cd(cfg.cecDir);
D=30; N=50; budget=12000;
base=@(fid,seed,pool) struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
cells=[1 3986; 7 3987; 14 3986];
modes={'none','audit','iid','lhs'};
totP=0; totN=0;
for c=1:size(cells,1)
    fid=cells(c,1); seed=cells(c,2);
    rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
    fc=@(x)CEC2017Function(x,fid);
    for m=1:numel(modes)
        s=base(fid,seed,pool); s.salsMode=modes{m};
        t0=tic; [Bp,Tp,ip]=SGWO_SALS_preopt(fc,s,[],N,seed+1000000); tp=toc(t0);
        t0=tic; [Bn,Tn,in]=SGWO_SALS(fc,s,[],N,seed+1000000);        tn=toc(t0);
        totP=totP+tp; totN=totN+tn;
        assert(isequal(Tp,Tn),'F%d seed%d %s: Trace differs',fid,seed,modes{m});
        assert(isequal(Bp.Vector,Bn.Vector) && Bp.Cost==Bn.Cost,'F%d seed%d %s: Best differs',fid,seed,modes{m});
        assert(ip.Evaluations==in.Evaluations,'F%d seed%d %s: FE differs',fid,seed,modes{m});
        assert(isequal(ip.SalsGens,in.SalsGens) && ip.SalsNMean==in.SalsNMean,'F%d seed%d %s: SALS counters differ',fid,seed,modes{m});
        if strcmp(modes{m},'audit')   % geometry diagnostics are recorded in audit mode only
            assert(isequal(ip.SalsStratFrac,in.SalsStratFrac) && ip.SalsDispBMean==in.SalsDispBMean && ...
                   ip.SalsDispCMean==in.SalsDispCMean && ip.SalsShiftBMean==in.SalsShiftBMean && ...
                   ip.SalsShiftCMean==in.SalsShiftCMean,'F%d seed%d %s: SALS diagnostics differ',fid,seed,modes{m});
            assert(in.SalsStratFrac==1,'F%d seed%d audit: stratification not realised (%.4f)',fid,seed,in.SalsStratFrac);
        end
        fprintf('  F%-3d seed%d %-6s BITWISE EQUAL  (pre %.2fs -> opt %.2fs, strat=%.3f)\n', ...
            fid,seed,modes{m},tp,tn,ternary(strcmp(modes{m},'none'),1,in.SalsStratFrac));
    end
end
fprintf('test_sals_opt_equivalence PASS: %d cells x %d modes bitwise identical (pre %.1fs vs opt %.1fs, speedup %.2fx)\n', ...
    size(cells,1),numel(modes),totP,totN,totP/totN);
end

function out=ternary(cond,a,b)
if cond, out=a; else, out=b; end
end
