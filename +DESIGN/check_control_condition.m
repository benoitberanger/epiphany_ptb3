function varargout = check_control_condition()
% Run the function (F5) to check if everything is ok !

need_plot = false;
if nargout < 1
    need_plot = true;
end

cfg = struct;
cfg.name = mfilename;


%% General parameters

cfg.TR           = 0.300;                                                  % second
cfg.contrast     = 1;                                                      % ratio, from 0 to 1
cfg.frequency    = 6;                                                      % Hz !!! must be a multiple of the framerate
cfg.nSquareWidth = 8;                                                      % number of square in the horizontal direction


%% onset vector
%  0 -> rest
% +1 -> stim, flickering checkerboard
% -1 -> control condition
% please make your own randomization here

rest_dur = 02; % seconds
ctrl_dur = 04; % seconds

nvol_rest = round(rest_dur/cfg.TR);
nvol_ctrl = round(ctrl_dur/cfg.TR);

vect = [];
vect = [vect zeros(1,nvol_rest)];
vect = [vect  ones(1,nvol_ctrl)*-1];
vect = [vect zeros(1,nvol_rest)];

cfg.onset = vect;


%% Perform the checks

if need_plot
    fig = findall(0,'Tag',mfilename);
    if ~isempty(fig)
        figure(fig)
        clf(fig)
    else
        figure('NumberTitle','off', 'Name',mfilename, 'Tag',mfilename);
    end
    x = (0:length(cfg.onset)-1)*cfg.TR;
    plot(x, cfg.onset);
    xlabel('time (s)')
    ylabel('condition')
    yticks([-1 0 +1])
    UTILS.ScaleAxisLimits()
end

UTILS.CheckDesign(cfg);

if nargout
    varargout{1} = cfg;
end


end % fcn
