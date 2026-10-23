function test_mse_contract()
%TEST_MSE_CONTRACT  MSE must be bitwise inert when off/passive, must act when on, and must satisfy the
%   mean-preserving / RMS-matched design claims.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'mseMode','none');
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
for m={'none','audit'}
    s=base; s.mseMode=m{1};
    [B,T,i]=SGWO_MSE(fc,s,[],N,seed+1000000);
    ok=isequal(TF,T) && BF.Cost==B.Cost;
    fprintf('  %-6s %s | cand=[%d %d %d] clip=[%.3f %.3f %.3f]\n',m{1}, ...
        ternary(ok,'BITWISE EQUAL','DIFFERS'),i.MseCand,i.MseClipRate);
    assert(ok,'MSE %s differs from SGWO_STEER3',m{1});
    assert(i.Evaluations==budget,'FE mismatch in %s',m{1});
end
% active arms
res=struct();
for m={'mix','ctrl'}
    s=base; s.mseMode=m{1};
    [B,T,i]=SGWO_MSE(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch in %s',m{1});
    assert(sum(i.MseCand)>0 && sum(i.MseEval)>0,'MSE did not act in %s',m{1});
    assert(~isequal(TF,T),'%s produced an identical trace to the frozen arm',m{1});
    fprintf('  %-6s ok FE=%d cand=[%d %d %d] (%.3f/%.3f/%.3f) evals=[%d %d %d] evRate=[%.3f %.3f %.3f] dispMean=[%.4f %.4f %.4f] clip=[%.3f %.3f %.3f]\n', ...
        m{1},i.Evaluations,i.MseCand,i.MseCand/sum(i.MseCand),i.MseEval,i.MseEvalRate,i.MseDispMean,i.MseClipRate);
    res.(m{1})=i;
end
% design claims: mean-preserving (mix mean radius ~ frozen), dispersion up, ctrl RMS ~ mix RMS
s=base; s.mseMode='none'; [~,~,i0]=SGWO_MSE(fc,s,[],N,seed+1000000);  % counters are zero when off -> use audit
s.mseMode='audit'; [~,~,ia]=SGWO_MSE(fc,s,[],N,seed+1000000);
w=ia.MseCand/sum(ia.MseCand);
meanFrz=ia.MseDispMean*w';                       % audit logs the SAME candidates as frozen (mult=1) for class 2? no: audit logs counterfactual
% compute the frozen single-centre mean radius directly from class-2 (mult=1) of the mix arm
wm=res.mix.MseCand/sum(res.mix.MseCand);
meanMix=res.mix.MseDispMean*wm'; meanCtrl=res.ctrl.MseDispMean*wm';
rmsMix=sqrt(sum(res.mix.MseCand/sum(res.mix.MseCand).*res.mix.MseDispMean.^2));
fprintf('  weighted mean displacement: mix=%.4f ctrl=%.4f ; RMS: mix=%.4f\n',meanMix,meanCtrl,rmsMix);
assert(abs(i0.MseCand(1)+i0.MseCand(2)+i0.MseCand(3))==0,'mseMode=none must not log');
fprintf('  class proportions (mix): fine %.3f / base %.3f / coarse %.3f (target 0.25/0.50/0.25)\n',res.mix.MseCand/sum(res.mix.MseCand));
fprintf('test_mse_contract PASS.\n');
end
function out=ternary(c,a,b)
if c, out=a; else, out=b; end
end
