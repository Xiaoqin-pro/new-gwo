function diag_calibrate_weights()
% 蒙特卡洛标定：对 (nE=38,nO=62,K=50) 求权重 wE 使 E 期望份额≈目标 {0.25,0.5,0.75}
nE=38; nO=62; K=50; M=nE+nO;
rng(20261016,'twister');
targets=[0.25 0.50 0.75];
for t=targets
    lo=1e-3; hi=1e3;
    for it=1:25
        wE=sqrt(lo*hi);
        w=ones(M,1); w(1:nE)=wE;
        nsel=0; N=20000;
        for i=1:N
            keys=rand(M,1).^(1./w);
            [~,ord]=sort(keys,'descend');
            nsel=nsel+sum(ord(1:K)<=nE);
        end
        share=nsel/(N*K);
        if share<t, lo=wE; else, hi=wE; end
    end
    fprintf('target %.2f -> wE=%.6f (realized %.4f)\n',t,sqrt(lo*hi),share);
end
end
