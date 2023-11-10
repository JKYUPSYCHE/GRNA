% Name          : GRNA same/diff task
% Author        : Jinkook Yu
% Environment   : Windows 10 64bit (resolution : 1920 * 1080), Matlab R2022b
% last edited   : 23.10.18
% Note          : check blcokN & hidecursor before start
% todo          : 

%% ---------- Initialize ----------
clear all; % clear all pre-exist variables (interference prevention)
try % error handling start (error -> automatically close all screen)
clc; % clear command-window 
fclose('all'); % close all pre-opened files (interference prevention)
ClockRandSeed; % reset random seed % use clock to set random number generator
GetSecs; WaitSecs(0); % pre-load timing function for precision timing
Screen('Preference', 'SkipSyncTests', 1);

% ---------- Configuration ----------
expName      = 'GRNA';    % experiment name for data files
expData      = 'results'; % experiment data folder name
bgColor      = 192;       % gray
fixlen       = 15;        % fixation length
fixwidth     = 5;         % fixation width 

% stimsize
stimwidth    = 640;       % monitor_resolution / 3 
stimheight   = 360;
stimdist     = stimwidth / 1.5; 

inputDelay   = 0.5;
ITI          = 0.5;
fixTime      = 1;
max_respTime = 1.5;

% ---------- Participant Information ----------
Ptag = input('P: ');                % participant number 
Stag = input('S(1=m, 2=f): ', 's'); % sex
Atag = input('age: ', 's');         % age

% key response counterbalancing
if mod(Ptag, 2) == 0 % Ptag is even
    Ctag = 2;
    noticeExp = imread('resources\instC2.png','png');
else                 % Ptag is odd
    Ctag = 1;
    noticeExp = imread('resources\instC1.png','png');
end

% ---------- Stimuli Condition Setup ----------
condMat = readtable('resources\env_condition.csv'); % read stimuli condition csv
env1 = imread('resources\stimuli\env1.png','png');  % import envirnment images and tranfer to texture
env2 = imread('resources\stimuli\env2.png','png');
env3 = imread('resources\stimuli\env3.png','png');
env4 = imread('resources\stimuli\env4.png','png');

practice1 = imread('resources\stimuli\practice1.png','png');
practice2 = imread('resources\stimuli\practice2.png','png');
practice3 = imread('resources\stimuli\practice3.png','png');

env1_bias = condMat{Ptag, 7}{1};
env2_bias = condMat{Ptag, 8}{1};
env3_bias = condMat{Ptag, 9}{1};
env4_bias = condMat{Ptag, 10}{1};

% ---------- Key Setup ----------
goKey       = KbName('space'); % response key to proceed
finKey      = KbName('q');     % administrative key to end experiment

if Ctag == 1
    expKeyList  = {'c','m'}; % keys for tasks
elseif Ctag == 2
    expKeyList  = {'m','c'};
end

for keyP = 1:numel(expKeyList)
    useKeys(keyP) = KbName(expKeyList{keyP});  % useKeys(1) = same / useKeys(2) = diff
end

% ---------- Display Setup ----------
ListenChar(2);
screenNumber = max(Screen('Screens'));
[w, rect] = Screen('OpenWindow', screenNumber, bgColor, [0 0 1920 1080]); % open main screen full screen 1920 1080
[cx, cy] = RectCenter(rect); % get screen center coordinate
stimrect1 = [cx-stimwidth/2-stimdist cy-stimheight/2 cx+stimwidth/2-stimdist cy+stimheight/2]; % stimuli window
stimrect2 = [cx-stimwidth/2+stimdist cy-stimheight/2 cx+stimwidth/2+stimdist cy+stimheight/2];

noticePrac  = imread('resources\instPrac.png','png');
noticeBreak = imread('resources\instBreak.png','png'); % make image to texture
noticeEnd   = imread('resources\instEnd.png','png');

% ---------- Data, Trials, Stimuli Setup ---------- 
date = clock; D = '_';
Dtag = [num2str(date(1)) D num2str(date(2)) D num2str(date(3)) D num2str(date(4)) D num2str(date(5))];
fileName = [expData, '/', expName, D, int2str(Ctag), D, Stag, D, Dtag, D, int2str(Ptag)];

if ~exist(expData, 'dir') % if there's no folder called 'expData', make one
	mkdir(expData);
end

trialTable = readtable('resources\trialMat.csv');        % trial setup
trialMat = [trialTable{:,1} trialTable{:,2}];
trialMat = trialMat(randperm(size(trialMat, 1)), :);     % randomizing trial
trialN   = size(trialMat,1);                             % number of trials

practiceTable = readtable('resources\practiceMat.csv');
practiceMat   = [practiceTable{:,1} practiceTable{:,2}];
practiceMat   = practiceMat(randperm(6), :);

% trial condition
for i = 1:trialN
    trialBias1 = eval(['env',int2str(trialMat(i, 1)),'_bias']);
    trialBias2 = eval(['env',int2str(trialMat(i, 2)),'_bias']);
    if trialMat(i, 1) == trialMat(i, 2) 
        trialMat(i, 3) = 2;         % same / control
    else 
        if trialBias1 == trialBias2
            trialMat(i, 3) = 1;     % diff / congruent
        else
            trialMat(i, 3) = 0;     % diff / incongruent
        end
    end
end

blockN    = 3;                      %  64 trials per blcok
blockSize = trialN / blockN;

% instruction
noticeExp   = Screen('MakeTexture', w, noticeExp);
noticePrac  = Screen('MakeTexture', w, noticePrac);
noticeBreak = Screen('MakeTexture', w, noticeBreak);
noticeEnd   = Screen('MakeTexture', w, noticeEnd);

% exp stimuli
env1 = Screen('MakeTexture', w, env1);
env2 = Screen('MakeTexture', w, env2);
env3 = Screen('MakeTexture', w, env3);
env4 = Screen('MakeTexture', w, env4);

% practice stimuli
practice1 = Screen('MakeTexture', w, practice1);
practice2 = Screen('MakeTexture', w, practice2);
practice3 = Screen('MakeTexture', w, practice3);

RAWDATA     = [];
BLOCKTIME   = zeros(blockN); % blocktime preallocation
expTimer    = GetSecs;

%% ---------- experiment start  ----------
HideCursor;

Screen('DrawTexture', w, noticeExp, [], rect);
Screen('Flip', w);
WaitSecs(inputDelay); % notice force-viewing

RestrictKeysForKbCheck(goKey);
FlushEvents('keyDown'); % flush pre-pressed key events
while 1
    [keyIsDown, secs, keyCode] = KbCheck();
    if keyIsDown
        break
    end
end
Screen('Flip', w); % clear screen
WaitSecs(inputDelay);

% -------- Practice trials ----------
for p = 1:6
    
    % fixation
    Screen('DrawLine', w, 0, cx-fixlen, cy, cx+fixlen, cy, fixwidth);
    Screen('DrawLine', w, 0, cx, cy-fixlen, cx, cy+fixlen, fixwidth);
    Screen('Flip', w);
    WaitSecs(fixTime);
    
    % stimuli
    Screen('DrawLine', w, 0, cx-fixlen, cy, cx+fixlen, cy, fixwidth);
    Screen('DrawLine', w, 0, cx, cy-fixlen, cx, cy+fixlen, fixwidth);
    Screen('DrawTexture', w, eval(['practice',int2str(practiceMat(p, 1))]), [], stimrect1);
    Screen('DrawTexture', w, eval(['practice',int2str(practiceMat(p, 2))]), [], stimrect2);
    Screen('Flip', w);
    
    pstim_onset = GetSecs;

    RestrictKeysForKbCheck([useKeys(1) useKeys(2)]);
    FlushEvents('KeyDown');
    while GetSecs - pstim_onset <= max_respTime
        [keyIsDown, secs, keyCode] = KbCheck();
        if keyIsDown
            break
        end
    end
    Screen('DrawLine', w, 0, cx-fixlen, cy, cx+fixlen, cy, fixwidth);
    Screen('DrawLine', w, 0, cx, cy-fixlen, cx, cy+fixlen, fixwidth);
    Screen('Flip', w);
    WaitSecs(ITI);
end

Screen('DrawTexture', w, noticePrac, [], rect);
Screen('Flip', w);
WaitSecs(inputDelay); % notice force-viewing

RestrictKeysForKbCheck(goKey);
FlushEvents('keyDown'); % flush pre-pressed key events
while 1
    [keyIsDown, secs, keyCode] = KbCheck();
    if keyIsDown
        break
    end
end
Screen('Flip', w); % clear screen
WaitSecs(inputDelay);

% ---------- Main trials ----------
blockTimer  = GetSecs;

for T = 1:trialN

    % trial information
    tflip  = [];
    blockT = ceil(T/blockSize);
    cong  = trialMat(T, 3); % trial congruency (0: incon, 1: con, 2: same)

    % fixation
    Screen('DrawLine', w, 0, cx-fixlen, cy, cx+fixlen, cy, fixwidth);
    Screen('DrawLine', w, 0, cx, cy-fixlen, cx, cy+fixlen, fixwidth);
    Screen('Flip', w);
    WaitSecs(fixTime);
    Screen('Flip', w);
    
    % stimuli
    Screen('DrawLine', w, 0, cx-fixlen, cy, cx+fixlen, cy, fixwidth);
    Screen('DrawLine', w, 0, cx, cy-fixlen, cx, cy+fixlen, fixwidth);
    Screen('DrawTexture', w, eval(['env',int2str(trialMat(T, 1))]), [], stimrect1);
    Screen('DrawTexture', w, eval(['env',int2str(trialMat(T, 2))]), [], stimrect2);
    tflip = Screen('Flip', w, tflip);

    % get response
    stim_onset = tflip;
    respT      = 99;   % 99 if no response
    RT         = 99;   % 99 if no response
    
    RestrictKeysForKbCheck([useKeys(1) useKeys(2)]);
    FlushEvents('KeyDown');
    while GetSecs - stim_onset <= max_respTime
        [keyIsDown, secs, keyCode] = KbCheck();
        if keyIsDown
            RT = secs - stim_onset;             % get RT
            pressedKeyList = find(keyCode);     % pressed key List
            pressedKeyList = pressedKeyList(1); % record first pressed key

            if pressedKeyList == useKeys(1)     % same
                respT = 1;
            elseif pressedKeyList == useKeys(2) % different
                respT = 2;
            end
            break
        end
    end

    % corr
    if cong == 2                   % same trial
        if respT == 1
            corr = 1;
        else
            corr = 0;
        end
    elseif cong == 1 || cong == 0 % different trial
        if respT == 2
            corr = 1;
        else
            corr = 0;
        end
    end

    % write data
    RAWDATA(T, :) = [Ptag, T, cong, respT, RT, corr];
    save([fileName, '.mat'])
    csvwrite([fileName, '.csv'], RAWDATA);

    % blcok break
    if mod(T, blockSize) == 0 && T ~= trialN
        BLOCKTIME(blockT) = GetSecs - blockTimer;
        blockTimer = GetSecs;
        Screen('DrawTexture', w, noticeBreak, [], rect);
        Screen('Flip', w);

        RestrictKeysForKbCheck(goKey);
        FlushEvents('keyDown'); % flush pre-pressed key events
        while 1
            [keyIsDown, secs, keyCode] = KbCheck();
            if keyIsDown
                break
            end
        end
        WaitSecs(1);
    else
        Screen('DrawLine', w, 0, cx-fixlen, cy, cx+fixlen, cy, fixwidth);
        Screen('DrawLine', w, 0, cx, cy-fixlen, cx, cy+fixlen, fixwidth);
        Screen('Flip', w);
        WaitSecs(ITI);
    end
end

Screen('Flip', w);
WaitSecs(ITI);

%% ---------- End of Experiment ----------
EXPTIME = GetSecs - expTimer;
save([fileName, '.mat']);

Screen('DrawTexture', w, noticeEnd, [], rect);
Screen('Flip', w);
RestrictKeysForKbCheck(finKey);
FlushEvents('keyDown'); % flush pre-pressed key events
while 1
    [keyIsDown, secs, keyCode] = KbCheck();
    if keyIsDown
        break
    end
end
RestrictKeysForKbCheck([]);

Screen('CloseAll');
ShowCursor;
ListenChar(0); % now listen to my command
catch ERROR % if an error occured, run following script and end the experiment
Screen('CloseAll');
ShowCursor;
ListenChar(0);
rethrow(ERROR); % show me the error
end % error handling end