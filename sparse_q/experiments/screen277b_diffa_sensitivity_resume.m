function out=screen277b_diffa_sensitivity_resume(refDir)
ba=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','diffa','g2F',1.0,'g2Pool','pool','g2Anchor','best');
a=ba; b=ba; b.g2F=0.75; c=ba; c.g2F=1.25;
d=ba; d.nG2=6; d.nE=44; e=ba; e.nG2=18; e.nE=32; f=ba; f.nG2=24; f.nE=26;
g=ba; g.g2Pool='wolves'; h=ba; h.g2Anchor='any'; i=ba; i.g2MaxStep=0.5;
algs=repmat({'SGWO_STEER3'},1,9);
labels={'A-AncBest-F10','B-F075','C-F125','D-G2-06','E-G2-18','F-G2-24','G-Wolves','H-AnchAny','I-Step05'};
opt=struct('states',{ {a,b,c,d,e,f,g,h,i} },'labels',{labels},'resume',refDir);
out=run_batch_sq('diffa_sensitivity',algs,[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30],4389:4393,50,100000,opt);
end
