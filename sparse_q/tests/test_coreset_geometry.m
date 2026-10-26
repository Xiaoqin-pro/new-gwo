function test_coreset_geometry()
% Does maximin screening select boundary points in 50-D?  If yes, the rule is
% structurally unsuitable at this dimension and no tuning will save it.
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
D=50; N=50; M=100; K=10;
rng(11,'twister');
% representative candidate pool: 50 GWO-like (clustered) + 12 diff (spread) + 38 shell
lb=-100*ones(1,D); ub=100*ones(1,D);
Y=[ -20+40*randn(N,D); -60+120*rand(M-50,D) ];
Y=min(max(Y,lb),ub);
alpha=mean(Y(1:N,:),1);
% maximin selection (as in 'core')
dA=sqrt(sum((Y-alpha).^2,2)); [~,first]=min(dA);
sel=first; dmin=sqrt(sum((Y-Y(first,:)).^2,2));
for q=2:K
    dmin(sel)=-inf; [~,nx]=max(dmin); sel(end+1)=nx;
    dmin=min(dmin,sqrt(sum((Y-Y(nx,:)).^2,2)));
end
% random selection
rsel=randperm(M,K);
% measure: mean absolute coordinate magnitude relative to the domain half-width
bw=100;
fprintf('maximin set : mean |x|/bw = %.3f   frac coords beyond 0.8*bw = %.3f\n', ...
    mean(vecnorm(Y(sel,:),2,2))/sqrt(D)/bw, mean(abs(Y(sel,:))>0.8*bw,'all'));
fprintf('random  set : mean |x|/bw = %.3f   frac coords beyond 0.8*bw = %.3f\n', ...
    mean(vecnorm(Y(rsel,:),2,2))/sqrt(D)/bw, mean(abs(Y(rsel,:))>0.8*bw,'all'));
fprintf('whole pool  : mean |x|/bw = %.3f   frac coords beyond 0.8*bw = %.3f\n', ...
    mean(vecnorm(Y,2,2))/sqrt(D)/bw, mean(abs(Y)>0.8*bw,'all'));
fprintf('\nselection bias of maximin toward the boundary: %.2fx vs pool\n', ...
    mean(vecnorm(Y(sel,:),2,2))/mean(vecnorm(Y,2,2)));
end
