function out=screen268b_diffwhiten_dev10_resume(refDir)
% 只重跑 Q-DiffWhiten 失败的 job，其余臂复用
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',2,'opDiffMode','whiten','opF',0.5);
algs={'SGWO_STEER3'};
labels={'C-DiffWhiten'};
opt=struct('states',{ {base} },'labels',{labels},'resume',refDir);
out=run_batch_sq('diffwhiten_dev10_resume',algs,[1 3 4 5 6 7 8 9 10 11 13 14 18 20 24 26 30],4319:4328,50,100000,opt);
end
