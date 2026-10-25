function test_svad_equiv()
% Check whether SVADGWO.m is bitwise identical to the frozen SGWO_STEER3 config
% used by the existing 29x30 ablation batch (final_ablation_confirm30).
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'),fullfile(sqRoot,'src','ablation'));
cd(fullfile(root,'data','cec2017'));
cfg=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','diffa','g2F',1.0,'g2Fend',0.3,'g2FendFrac',0.7,'g2Pool','pool','g2Anchor','any');
ok=0; bad=0;
for fid=[1 4 13]
  for seed=[3459 3460]
    rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
    st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
        'upperBound',100*ones(1,50),'maxEvaluations',20000,'functionID',fid);
    fn=fieldnames(cfg); for k=1:numel(fn), st.(fn{k})=cfg.(fn{k}); end
    f=@(x)CEC2017Function(x,fid);
    [B1,T1,i1]=SVADGWO(f,st,[],50,seed+1000000);
    [B2,T2,i2]=SGWO_STEER3(f,st,[],50,seed+1000000);
    d=abs(B1.Cost-B2.Cost)/max(1,abs(B2.Cost));
    tag='DIFF';
    if d==0, tag='SAME'; ok=ok+1; else bad=bad+1; end
    fprintf('F%-2d seed %d: SVAD=%.10g  STEER3=%.10g  rel=%.3g  %s\n',fid,seed,B1.Cost,B2.Cost,d,tag);
  end
end
fprintf('\n%d identical, %d different\n',ok,bad);
end
