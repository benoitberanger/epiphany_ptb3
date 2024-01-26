function Run()
global S

%% Parse the onset vector from the design to create blocks

S.recPlanning = UTILS.RECORDER.Planning();
S.recPlanning.AddStart();

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
S.recPlanning.AddEnd(S.recPlanning.GetNextOnset());

switch S.guiACQmode
    case 'Acquisition'
        % pass
    case {'Debug', 'FastDebug'}
        debug_rest_duration = 2; % seconds

        dur = cell2mat(S.recPlanning.data(:,S.recPlanning.icol_duration));
        rest_idx = strcmp(S.recPlanning.data(:,S.recPlanning.icol_name), 'rest');
        dur(rest_idx) = debug_rest_duration;
        ons = zeros(size(dur));
        for o = 1 : length(dur)
            if o > 1
                ons(o) = ons(o-1) + dur(o-1);
            end
        end
        S.recPlanning.data(:,S.recPlanning.icol_onset   ) = num2cell(ons);
        S.recPlanning.data(:,S.recPlanning.icol_duration) = num2cell(dur);
end

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

delta_time_flicflac = 1 / S.Design.frequency;


%% run the events

EXIT = false;
secs = GetSecs();

% main loop
for evt = 1 : S.recPlanning.count

    evt_name     = S.recPlanning.data{evt,S.recPlanning.icol_name    };
    evt_onset    = S.recPlanning.data{evt,S.recPlanning.icol_onset   };
    evt_duration = S.recPlanning.data{evt,S.recPlanning.icol_duration};

    if evt < S.recPlanning.count
        next_evt_onset = S.recPlanning.data{evt+1,S.recPlanning.icol_onset};
    end

    switch evt_name

        case 'START'

            FixationCross.Draw();
            Window.Flip();
            S.STARTtime = PTB_ENGINE.START(S.cfgKeybinds.Start, S.cfgKeybinds.Abort);
            S.recEvent.AddStart();
            S.Window.AddFrameToMovie();

        case 'END'

            S.ENDtime = WaitSecs('UntilTime', S.STARTtime + evt_onset );
            S.recEvent.AddEnd(S.ENDtime - S.STARTtime );
            S.Window.AddFrameToMovie();
            PTB_ENGINE.END();


        case 'rest'

            FixationCross.Draw();
            real_onset = Window.Flip(S.STARTtime + evt_onset - Window.slack);
            S.recEvent.AddStim(evt_name, real_onset-S.STARTtime, []);

            fprintf('rest : %gs \n', evt_duration)
            S.Window.AddFrameToMovie(evt_duration);

            next_onset = S.STARTtime + next_evt_onset - Window.slack;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end
                end
            end


        case 'stim'

            Checkerboard.DrawFlic();
            real_onset = Window.Flip(S.STARTtime + evt_onset - Window.slack);
            S.recEvent.AddStim(evt_name, real_onset-S.STARTtime, []);

            fprintf('stim : %gs \n', evt_duration)
            S.Window.AddFrameToMovie(evt_duration);

            next_onset = S.STARTtime + next_evt_onset - Window.slack - delta_time_flicflac*2;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end
                end

                Checkerboard.DrawFlac();
                real_onset = Window.Flip(real_onset + delta_time_flicflac);
                Checkerboard.DrawFlic();
                real_onset = Window.Flip(real_onset + delta_time_flicflac);
            end

        case 'ctrl'

            % draw : TODO
            Screen('FillRect', Window.ptr, [255 0 0 255], [0 0 100 100])
            real_onset = Window.Flip(S.STARTtime + evt_onset - Window.slack);
            S.recEvent.AddStim(evt_name, real_onset-S.STARTtime, []);

            fprintf('ctrl : %gs \n', evt_duration)
            S.Window.AddFrameToMovie(evt_duration);

            next_onset = S.STARTtime + next_evt_onset - Window.slack;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end
                end
            end

        otherwise
            error('unknown event : %s', evt_name)

    end % switch

    % if Abort is pressed
    if EXIT

        S.ENDtime = GetSecs();
        S.recEvent.AddEnd(S.ENDtime - S.STARTtime);
        S.recEvent.ClearEmptyLines();

        if S.WriteFiles
            save([S.OutFilepath '_ABORT_at_runtime.mat'], 'S')
        end

        fprintf('!!! @%s : Abort key received !!!\n', mfilename)
        break % stop the forloop:evt

    end

end % forloop:evt


%% End of task routine

S.Window.Close();

S.recEvent.ComputeDurations();
S.recKeylogger.GetQueue();
S.recKeylogger.Stop();
S.recKeylogger.kb2data();
switch S.guiACQmode
    case 'Acquisition'
    case {'Debug', 'FastDebug'}
        TR = S.Design.TR;
        n_volume = ceil((S.ENDtime-S.STARTtime)/TR);
        S.recKeylogger.GenerateMRITrigger(TR, n_volume, S.STARTtime)
end
S.recKeylogger.ScaleTime(S.STARTtime);
assignin('base', 'S', S)

switch S.guiACQmode
    case 'Acquisition'
    case {'Debug', 'FastDebug'}
        UTILS.plotDelay(S.recPlanning, S.recEvent);
        UTILS.plotStim(S.recPlanning, S.recEvent, S.recKeylogger);
end


end % fcn
