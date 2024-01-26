function Run()
global S

%% Parse the onset vector from the design to create blocks

S.recPlanning = UTILS.RECORDER.Planning();

block_name     = '';
block_onset    = 0;
block_duration = 0;
prev_name      = '';

for o = 1 : length(S.Design.onset)

    cond = S.Design.onset(o);
    switch cond
        case 0
            block_name = 'rest';
        case +1
            block_name = 'stim';
        case -1
            block_name = 'ctrl';
        otherwise
            error('unknown cond')
    end

    if ~strcmp(prev_name, block_name)
        if o>1 % new block ? register previous one
            S.recPlanning.AddStim(prev_name, block_onset, block_duration)
        end
        block_onset    = S.Design.TR * (o-1);
        block_duration = S.Design.TR;
    else % same  block ? just add duration
        block_duration = block_duration + S.Design.TR;
    end

    prev_name = block_name;
end

S.recPlanning.AddStim(block_name, block_onset, block_duration) % finish last block
S.recEvent = UTILS.RECORDER.Event(S.recPlanning);


%% Keymap

KbName('UnifyKeyNames') % make keybinds cross-platform compatible

S.cfgKeybinds.Start = KbName('t');
S.cfgKeybinds.Abort = KbName('escape');
switch S.guiKeybind
    case 'fORP (MRI)'
        S.cfgKeybinds.Catch = KbName('b');
    case 'Keyboard'
        S.cfgKeybinds.Catch = KbName('DownArrow');
    otherwise
        error('unknown S.guiKeybind : %s', S.guiKeybind)
end

S.recKeylogger = UTILS.RECORDER.Keylogger(S.cfgKeybinds);
S.recKeylogger.Start();


%% start PTB engine

% get object
Window = PTB_ENGINE.VIDEO.Window();
S.Window = Window; % also save it in the global structure for diagnostic

% task specific paramters
S.Window.bg_color       = [0 0 0];
S.Window.movie_filepath = [S.OutFilepath '.mov'];

% set parameters from the GUI
S.Window.screen_id      = S.guiScreenID; % mandatory
S.Window.is_transparent = S.guiTransparent;
S.Window.is_windowed    = S.guiWindowed;
S.Window.is_recorded    = S.guiRecordMovie;

S.Window.Open();


%% prepare rendering object

FixationCross          = PTB_OBJECT.VIDEO.FixationCross();
FixationCross.window   = Window;
FixationCross.dim      = 0.10;              %  Size_px = ScreenY_px * Size
FixationCross.width    = 0.05;              % Width_px =    Size_px * Width
FixationCross.color    = [128 128 128 255]; % [R G B a], from 0 to 255
FixationCross.center_x = 0.50;              %   Pos_px = center_x * ScreenX_px
FixationCross.center_y = 0.50;              %   Pos_px = center_y * ScreenY_px
FixationCross.GenerateCoords();

Checkerboard                 = PTB_OBJECT.VIDEO.Checkerboard();
Checkerboard.window          = Window;
Checkerboard.n_square_width  = S.Design.nSquareWidth;
Checkerboard.color_flic(1:3) = [255 255 255] *  S.Design.contrast;
Checkerboard.color_flac(1:3) = [255 255 255] *  S.Design.contrast;
Checkerboard.GenerateRects();

%%


%% End of task routine

S.Window.Close();

S.recEvent.ComputeDurations();
S.recKeylogger.GetQueue();
S.recKeylogger.Stop();
switch S.guiACQmode
    case 'Acquisition'
    case {'Debug', 'FastDebug'}
        TR = S.Design.TR;
        n_volume = ceil((S.ENDtime-S.STARTtime)/TR);
        S.recKeylogger.GenerateMRITrigger(TR, n_volume, S.STARTtime)

        UTILS.plotDelay(S.recPlanning, S.recEvent);
        UTILS.plotStim(S.recPlanning, S.recEvent, S.recKeylogger);
end
S.recKeylogger.kb2data();
S.recKeylogger.ScaleTime(S.STARTtime);
assignin('base', 'S', S)


end % fcn
