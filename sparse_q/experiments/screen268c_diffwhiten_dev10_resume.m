function out=screen268c_diffwhiten_dev10_resume(refDir)
% 与 screen268 完全相同的 4 臂 + resume 到原目录；runBatch4 自动跳过 ok 的 job，只重跑 failed（C 臂 170 次）
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5);
a=base;
b=base; b.opFixed=2; b.opDiffMode='nowarc';
c=base; c.opFixed=2; c.opDiffMode='whiten';
d=base; d.opFixed=2; d.opDiffMode='shuffle';
algs=repmat({'SGWO_STEER3'},1,4);
labels={'A-Standard','B-DiffPlain','C-DiffWhiten','D-DiffShuffle'};
opt=struct('states',{ {a,b,c,d} },'labels',{labels},'resume',refDir);
out=run_batch_sq('diffwhiten_dev10',algs,[1 3 4 5 6 7 8 9 10 11 13 14 18 20 24 26 30],4319:4328,50,100000,opt);
end
