function sig=sssa_source_sigma(hist,span,D,opt)
%SSSA_SOURCE_SIGMA  Source-specific shell scale using the frozen shellSigma rule.
if numel(hist)>=opt.sssaMin
    L=median(hist);
else
    L=opt.sssaInitFrac*span;
end
sig=max(opt.sssaFloorFrac*span,L)*sqrt(3/D);
end
