function [realcol, imagcol, timecol] = getformatdlg(filename, sequence, ncol, data, colname)
%
% GETFORMATDLG(FILENAME, SEQUENCE, NCOL, DATA, COLNAME)
% helps the user to select the columns in Stelar .sdf files corresponding
% to the following properties:
% * real: the real part of the signal
% * imag: the imaginary part of the signal
% * time (optional): the time-series associated
%
% GETFORMATDLG opens a new window where the beginning of the
% data file is displayed. The user enters the column index. 
% 
% GETFORMATDLG allows to save the setting (specific sequence
% associated with specific number of column) in a matlab file
% 'formatsettings.mat' (folder 'format')
% This file is a table with 5 columns organized as:
%   Sequence | nCol | realIdx | imagIdx | timeIdx
%   IRCPMG   |  2   |    1    |    2    |   []
%     NP     |  4   |    2    |    3    |   1 
%    ...     | ...  |   ...   |   ...   |  ...
% 
% This function uses the inputsdlg function from FEX, written by Takeshi
% Ikuma.
%
% See also INPUTSDLG
%
% Manuel Petit, June 2018
% manuel.petit@inserm.fr

NUMBER_LINE_TO_DISPLAYED = 15;

% locate the function and check if the folder format exists. Create it if
% false.
path = [fileparts(which('getformatdlg')),'\format\'];
if exist(path,'dir') ~= 7
    mkdir(path)
    addpath(path);
end

% check input
validateattributes(filename,{'char'},{});
validateattributes(sequence,{'char'},{});
validateattributes(ncol,{'numeric'},{'>',1}); %need at least two columns
validateattributes(data,{'numeric'},{'size',[NaN ncol]}); %need the same number of columns as ncol

% limit the size of data to display if needed
if size(data,1) > NUMBER_LINE_TO_DISPLAYED
    data = data(1:NUMBER_LINE_TO_DISPLAYED,:);
end

% check if some column names match with one of the properties
if ~isempty(colname)
    % +real
    isReal = strcmpi(colname,'real');
    if ~isempty(isReal)
        defAnsReal = num2str(find(isReal));
    else
        defAnsReal = '';
    end
    % +imag
    isImag = strcmpi(colname,'imag');
    if ~isempty(isImag)
        defAnsImag = num2str(find(isImag));
    else
        defAnsImag = '';
    end
    % +time
    isTime = strcmpi(colname,'time');
    if ~isempty(isTime)
        defAnsTime = num2str(find(isTime));
    else
        defAnsTime = '';
    end
else
    defAnsReal = '';
    defAnsImag = '';
    defAnsTime = '';
end

% set the title window
Title = 'FitLike Data Importation Helper';

% set options
Options.Resize = 'on';
Options.CancelButton = 'off';
Options.ApplyButton = 'off';
Options.ButtonNames = {'Continue'};

Prompt = {};
Formats = {};
DefAns = struct([]);

% +add explanation about the window
Prompt(1,:) = {sprintf(['FitLike has detected an unknown sequence and/or an unknown data formating for the following file: %s\n'...
                '\n'...
                'You need to help him to define the following properties:\n'...
                '- real: the real part of the signal\n'...
                '- imag: the imaginary part of the signal\n'...
                '- time(optional): the time-series associated with the measurement\n'...
                '\n'...
                'Sequence: %s\n'...
                'Number of column detected: %d\n'...
                '\n'...
                'To help you, the beginning of the text file will be displayed below!'],...
                filename,sequence, ncol),[],[]};
Formats(1,1).type = 'text';
Formats(1,1).span = [1 3]; 

% +add data
Prompt(2,:) = {[],'Table',[]};
Formats(2,2).type = 'table';
Formats(2,2).style = 'table';
Formats(2,2).enable = 'inactive';
Formats(2,2).format = repmat({'numeric'},1,ncol);
if isempty(colname)
    Formats(2,2).items = cellfun(@(x) ['Var' num2str(x)],num2cell(1:ncol),'UniformOutput',0);
else
    Formats(2,2).items = colname;
end
Formats(2,2).size = [85*ncol 202];
DefAns(1).Table = data;

% +add explanation about what to do
Prompt(3,:) = {'Indicate below the column corresponding to the properties:',[],[]};
Formats(3,1).type = 'text';
Formats(3,1).span = [1 3]; 

% +add fields to fill by user
Prompt(4,:) = {'Real:','real',[]};
Formats(4,1).type = 'edit';
Formats(4,1).format = 'text';
Formats(4,1).required = 'on';
Formats(4,1).size = [-1 0];
DefAns.real = defAnsReal;
Formats(4,1).callback = @(hObj,~,~,~) checkInput(hObj, ncol);

Prompt(5,:) = {'Imag:','imag',[]};
Formats(4,2).type = 'edit';
Formats(4,2).format = 'text';
Formats(4,2).required = 'on';
Formats(4,2).size = [-1 0];
Formats(4,2).callback = @(hObj,~,~,~) checkInput(hObj, ncol);
DefAns.imag = defAnsImag;

Prompt(6,:) = {'Time(optional):','time',[]};
Formats(4,3).type = 'edit';
Formats(4,3).format = 'text';
Formats(4,3).size = [-1 0];
Formats(4,3).callback = @(hObj,~,~,~) checkInput(hObj, ncol);
DefAns.time = defAnsTime;

% +add save option
Prompt(7,:) = {'Save settings for next time' 'EnableSaveMode',[]};
Formats(5,1).type = 'check';
DefAns.EnableSaveMode = true;

% display window
[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);

% check answers and set output
if Cancelled
    realcol = [];
    imagcol = [];
    timecol = [];
    return
elseif isempty(Answer.time)
    realcol = str2double(Answer.real);
    imagcol = str2double(Answer.imag);
    timecol = NaN;
else
    realcol = str2double(Answer.real);
    imagcol = str2double(Answer.imag);
    timecol = str2double(Answer.time);
end

% if save options true, get the saveFile and fill it
if Answer.EnableSaveMode
    % load the saveFile: it is a table with five columns as:
    % Sequence | nCol | realIdx | imagIdx | timeIdx
    % IRCPMG   |  2   |    1    |    2    |   []
    %   NP     |  4   |    2    |    3    |   1 
    %  ...     | ...  |   ...   |   ...   |  ...
    if exist([path 'formatsettings.mat'],'file') ~= 2
        % create the .mat file 
        Sequence = {sequence};
        nCol = ncol;
        realIdx = realcol;
        imagIdx = imagcol;
        timeIdx = timecol;
        
        T = table(Sequence, nCol, realIdx, imagIdx, timeIdx); %#ok<NASGU>
        
        save([path 'formatsettings.mat'], 'T')
    else        
        % update the .mat file
        try 
            % load the table 
            saveObj = load([path 'formatsettings.mat']);
            var = fieldnames(saveObj);
            T = saveObj.(var{1});
            % check if this setting is already in the table
            if sum(strcmp(T.Sequence, sequence) & T.nCol == ncol) > 0
                return
            end
            % add the new settings
            newSettings = {sequence,ncol,realcol,imagcol,timecol};
            T = [T; newSettings]; %#ok<NASGU>
            % save the settings
            save([path 'formatsettings.mat'], 'T')        
        catch ME
            rethrow(ME);
        end   
    end
end

    function checkInput(hObj, ncol)
        % Some check need to be perform on the input to avoid further
        % errors:
        % - no doublons are allowed (same column index)
        % - input must be integer between 1 and ncol
        
        % check if input is integer between 1 and ncol
        val = str2double(hObj.String);
        if isnan(val)
            hObj.String = '';
            % input is not a number
            errordlg('Input must be a number!')
        elseif floor(val) ~= val
            hObj.String = '';
            % input is not a number
            errordlg('Input must be an integer!')
        elseif val < 1 || val > ncol
            hObj.String = '';
            % input is not a number
            errordlg(sprintf('Input must be between 1 and %d!',ncol))
        end
        
        % check if the value assigned to the source is not already assigned
        % to another editbox (not possible because column index need to be
        % unique)
        % get all the values set in the editbox (3)
        val = get(findobj(hObj.Parent.Parent.Children,'Style','edit'),'String');
        % if the new value is a doublon then the length of the unique values 
        % is different from the length of the values
        val = val(~cellfun(@isempty,val)); %remove empty 
        if length(unique(val)) ~= length(val)
            hObj.String = '';
            % throw an error
            errordlg('You cannot set the same column index for two properties!')
        end   
    end

end

