function test_screening_arms()
% Verify the three screening policies produce valid, distinct, deterministic runs.
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'),fullfile(sqRoot,'src','ablation'));
cd(fullfile(root,'data','cec2017'));
fid=4; seed=3471; budget=20000;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
    'upperBound',100*ones(1,50),'maxEvaluations',budget,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
cfgs={ {'screening','rand'}
       {'screening','geo'}
       {'screening','arc'}
       {'screening','arc','nG2',25,'nE',25}
       {'screening','arc','nG2',50,'nE',50} };
for k=1:numel(cfgs)
    o=cfgs{k};
    args={}; for q=1:numel(o), args{end+1}=o{q}; end
    [B,T,i]=SVADGWO2_cfg(f,st,seed+1000000,args{:});
    assert(i.Evaluations==budget,sprintf('cfg%d FE',k));
    assert(all(diff(T)<=0),sprintf('cfg%d monotone',k));
    [B2,~,~]=SVADGWO2_cfg(f,st,seed+1000000,args{:});
    assert(abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)),sprintf('cfg%d det',k));
    fprintf('cfg%d %-28s best=%12.6g  M=%3d  scr=%-4s\n',k, ...
        strjoin(cellfun(@(x)num2str(x),o,'UniformOutput',false),','), ...
        B.Cost, 50+i.Parameters.nG2+i.Parameters.nE, i.Ablation.screening);
end
% default must be unchanged from SVADGWO2
[B1,~,~]=SVADGWO2(f,st,[],50,seed+1000000);
[B2,~,~]=SVADGWO2_cfg(f,st,seed+1000000);
d=abs(B1.Cost-B2.Cost)/max(1,abs(B1.Cost));
assert(d==0,'default cfg changed the algorithm');
fprintf('\ndefault cfg == SVADGWO2 : rel=%.3g\nTEST_SCREENING_ARMS PASS\n',d);
end
