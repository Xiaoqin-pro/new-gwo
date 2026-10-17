function dbg_rlgwo()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
D=5; N=10; budget=4000;
rng(3,'twister'); X0=-10+20*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-10*ones(1,D),'upperBound',10*ones(1,D),'maxEvaluations',budget);
f=@(x)sum(x.^2);
[B,T,i]=RLGWO_CEC(f,st,[],N,7);
bad=find(diff(T)>0); nanidx=find(isnan(T));
fprintf('FE=%d best=%.4g | nonmonotone at %s | NaN at %s\n',i.Evaluations,B.Cost,mat2str(bad(1:min(5,numel(bad)))),mat2str(nanidx(1:min(5,numel(nanidx)))));
if ~isempty(bad), fprintf('T around bad: %s\n', mat2str(T(max(1,bad(1)-2):bad(1)+2)')); end
end
