function test_pcss_active_contract()
%TEST_PCSS_ACTIVE_CONTRACT  Active/control PCSS screening contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'pcssK',5,'pcssCap',256,'pcssGuide',2);
fc=@(x)CEC2017Function(x,fid);
out=struct();
for mode={'active','control'}
    s=base; s.pcssMode=mode{1};
    [B,T,inf1]=SGWO_PCSS(fc,s,[],N,seed+1000000);
    assert(inf1.Evaluations==budget,sprintf('%s FE mismatch',mode{1}));
    assert(all(diff(T)<=0),sprintf('%s trace not monotone',mode{1}));
    genComplete=floor((budget-N)/10);
    assert(inf1.PcssGuideEval>=2*(genComplete-1) && inf1.PcssGuideEval<=2*genComplete, ...
        sprintf('%s guided-slot evaluation count off: %d',mode{1},inf1.PcssGuideEval));
    assert(inf1.PcssGuideEval+inf1.PcssRandEval==budget-N, ...
        sprintf('%s guided+random evaluations != main-loop evaluations',mode{1}));
    out.(mode{1})=struct('Best',B.Cost,'Trace',T,'Info',inf1);
    fprintf('  %-7s ok FE=%d rounds=%d guidedEval=%d(gRate=%.3f) randEval=%d(rRate=%.3f) fallbackGens=%d\n', ...
        mode{1},inf1.Evaluations,inf1.Rounds,inf1.PcssGuideEval,inf1.PcssGuideRate, ...
        inf1.PcssRandEval,inf1.PcssRandRate,inf1.PcssFallbackGens);
end
% paired design: identical generation count, different selections
assert(out.active.Info.Rounds==out.control.Info.Rounds,'active/control rounds differ');
assert(~isequal(out.active.Trace,out.control.Trace),'active and control traces are identical');
% active mode must fall back exactly once (first generation, buffer below k+1)
assert(out.active.Info.PcssFallbackGens==1,'expected exactly one warm-up fallback generation');
assert(out.control.Info.PcssFallbackGens==0,'control must not report fallbacks');
% both skip the frozen random screen (no distance ops claimed)
assert(out.active.Info.NDistanceOps==out.control.Info.NDistanceOps,'distance-op accounting differs');
fprintf('test_pcss_active_contract PASS: active/control exact FE, paired generations, guided slot counts ok.\n');
end
