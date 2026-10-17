function dbg2()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
disp(which('SGWO'));
w=dir(which('SGWO'));
fprintf('SGWO file datenum: %s size %d\n', datestr(w.datenum), w.bytes);
state=struct('farE',4,'farReserve',4,'screenPolicy','random');
opt=struct('screenPolicy','directed','farE',0,'farReserve',0,'farMinDist',0.15);
fn=fieldnames(state);
for k=1:numel(fn)
    if isfield(opt,fn{k}) && ~isempty(state.(fn{k}))
        opt.(fn{k})=state.(fn{k});
    end
end
fprintf('merged: farE=%d farReserve=%d screen=%s\n',opt.farE,opt.farReserve,opt.screenPolicy);
end
