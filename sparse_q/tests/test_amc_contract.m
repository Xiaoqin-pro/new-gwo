function test_amc_contract()
%TEST_AMC_CONTRACT  Frozen equivalence and AMC factorial contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3987;
rng(261013000+1*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
fc=@(x)CEC2017Function(x,1);
off=base; off.enacOn=0; off.amcOn=0;
[BA,TA]=SGWO(fc,base,[],N,seed+1000000);
[BO,TO,io]=SGWO_AMC(fc,off,[],N,seed+1000000);
assert(isequal(TA,TO),'AMC off-state trace differs from frozen SGWO');
assert(BA.Cost==BO.Cost && isequal(BA.Vector,BO.Vector),'AMC off-state Best differs');
assert(io.Evaluations==budget,'AMC off-state FE mismatch');
armA=base; armA.enacOn=1; armA.enacMode='identity'; armA.amcOn=0; armA.amcWindow=10; armA.amcSuccessThresh=0.2; armA.amcExpand=1.10; armA.amcShrink=0.90; armA.amcGammaMax=2.0; armA.amcGammaMin=1.0;
armB=base; armB.enacOn=1; armB.enacMode='enac';     armB.amcOn=0; armB.amcWindow=10; armB.amcSuccessThresh=0.2; armB.amcExpand=1.10; armB.amcShrink=0.90; armB.amcGammaMax=2.0; armB.amcGammaMin=1.0;
armC=armA; armC.amcOn=1;
armD=armB; armD.amcOn=1;
arms={armA,armB,armC,armD}; names={'A-Identity','B-ENAC','C-Identity-AMC','D-ENAC-AMC'};
for k=1:4
    [Bk,Tk,ik]=SGWO_AMC(fc,arms{k},[],N,seed+1000000);
    assert(ik.Evaluations==budget && all(diff(Tk)<=0),sprintf('%s run broken',names{k}));
    assert(ik.EnacCenterEvalTotal>0 && ik.EnacCenterSuccTotal>0,sprintf('%s centre stats missing',names{k}));
    if k>=3
        assert(ik.AMCOn==1,'AMC flag missing');
        assert(ik.AMCEndGamma>=1 && ik.AMCEndGamma<=2,'gamma outside [1,2]');
        assert(ik.AMCValidFeedbackRounds>0,'no valid AMC feedback rounds');
        assert(ik.G1EvalCount>0,'no G1 evaluations recorded');
        assert(ik.AMCExpandCount>=0 && ik.AMCShrinkCount>=0,'negative AMC event count');
    end
    fprintf('  %-16s ok FE=%d gammaEnd=%.4g expand=%d shrink=%d\n',names{k},ik.Evaluations,ik.AMCEndGamma,ik.AMCExpandCount,ik.AMCShrinkCount);
end
fprintf('test_amc_contract PASS: off bitwise; four factorial arms run.\n');
end
