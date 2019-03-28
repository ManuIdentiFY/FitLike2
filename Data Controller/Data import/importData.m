function [filelist, sequence, data, parameter] = importData(varargin)
%
% [DATA, PARAMETERS] = IMPORTDATA(FILENAME) is a function dedicated to the
% data importation for FitLike software. It helps user to select the imported
% files as well as selecting particular sequences contained inside these files.
%
% IMPORTDATA can be initialise with filenames but this is not required. 
% Right now, only .sdf and .sef files are accepted as valid input (use 
% file pathway) and only these type of data can be imported (Stelar data 
% type). See examples for uses. 
%
% IMPORTDATA returns parameters as 1xN cell array of structure where N
% corresponds to the number of experiment. Similarely, data are returned as a
% structure where each field is a 1xN cell array of 3D matrix (double).
% File list and sequence are also returned where sequence contains cell
% array of string of selected sequences.
%
% An experiment is defined by the succession (or not) of "ZONE" with
% identical data size, identical parameter structure and identical 
% sequence name.
%
% Thus, the number of output is not always equal to the number of files
% selected if multiple sequences are selected for each files.
%
% See also readsdfv1, readsdfv2, readsef functions
% 
% Warning: this function requires the following functions:
% - checkversion(filename)
% - readsdfv1(filename)
% - readsdfv2(filename)
% - readsef(filename)
% - make_gui_settings(filename)
% - getformatdlg(filename, sequence, ncol, data, colname)
% 
% Examples:
% 1. Start with no input (will be done inside the window)
% [filelist, sequence, data, parameter] = importData();
% 
% 2. Start with one .sdf or .sef file
% [filelist, sequence, data, parameter] = importData('mydata.sdf');
% [filelist, sequence, data, parameter] = importData('mydata.sef');
%
% 3. Start with a cell array of .sdf files (same with .sef files)
% [filelist, sequence, data, parameter] = importData({'mydata1.sdf','mydata2.sdf'});
% 
%
% M.Petit - 02/2019
% manuel.petit@inserm.fr

% check input
if nargin > 1
    error('importData: too many input arguments')
elseif nargin == 1
    % check that input is string or cell array of string of .sdf or .sef
    % files
    filelist = varargin{1};
    % check
    if ~iscell(filelist)
        % convert in cell array for further treatment
        filelist = {filelist};
    end
    
    % check that all files are char
    tf_char = cellfun(@ischar, filelist);
    
    if any(tf_char == 0)
        warning('importData: some files are not string and have been ignored')
        filelist = filelist(tf_char);
    end
end

% init data and parameter
data = [];
parameter = [];
sequence = [];
tf_sequence = [];

% read filename if any
if exist('filelist','var')
    % loop over the file
    for k = numel(filelist):-1:1
        % check extension
        [~, ~, ext] = fileparts(filelist{k});
        
        switch ext
            case '.sdf'
                ext = 'sdf';
            case '.sef'
                ext = 'sef';
            otherwise
        end
        
        % read file
        [rawdata{k}, param{k}, nExp{k}] = readFile(filelist{k}, ext);
        % get sequence
        [seq{k},~] = getParam(filelist{k});
    end
    
    % check empty data
    tf_empty = cellfun(@isempty, rawdata);
        
    % add data
    if ~isempty(rawdata(~tf_empty))
        data = [data, rawdata(~tf_empty)];
        parameter = [parameter, param(~tf_empty)];
        sequence = [sequence, seq(~tf_empty)];
        tf_sequence = [tf_sequence cellfun(@(x) true(1,x), nExp, 'Uniform', 0)];
    end
else
    filelist = 'Add files!';
end

%% Create GUI
fig = figure('Name','FitLike Importation','NumberTitle','off',...
             'MenuBar','none','ToolBar','none','DockControls','off',...
             'Units','normalized','Position',[0.2 0.25 0.6 0.5],...
             'CloseRequestFcn',@exit);

% information panel
hp1 = uipanel('Title','Information','Parent',fig,...
    'Units','normalized','Position',[0.01 0.68 0.98,0.32],'FontSize',9);
uicontrol('Parent',hp1,'Style','text','String',...
    sprintf(['This importation window will help you to select your ',...
    'imported files and data. You can access some details about the imported ',...
    'files concerning sequences, size, or type by selecting one.\nStart by importing files with "Add Files". ',...
    'You can select the wanted sequences for each file. Click on a file to see the sequences ',...
    'and select or unselect the wanted sequences. You can also use the "For all files" panel ',...
    'to apply the selection to all files. A "Remove Files" button allows to remove the selected ',...
    'files.\n\nSome files (ex: .sdf ver1) require help during important. A window opens automaticaly ',...
    'to allow you the selection of the wanted data. Settings are automaticaly saved to avoid selection',...
    'of the data each time. You can access settings with "Change Settings". Keep the checkbox activated ',...
    'to save the settings.']),...
    'Units','normalized','Position',[0 -0.05 1 1],'HorizontalAlignment','left');

% file panel
hp2 = uipanel('Title','Files','Parent',fig,...
              'Units','normalized','Position',[0.01 0.15 0.98 ,0.51],'FontSize',9);
          
listfile = uicontrol('Parent',hp2,'Style','listbox','String',filelist,'Value',1,...
              'Units','normalized','Position',[0.01 0.02 0.2 ,0.96],...
              'Callback',@selectFile);
          
bg = uipanel('Parent',hp2,...
            'Title','Sequences:',...
            'Visible','on','Units','normalized',...
            'Position',[0.23 0.02 0.23 ,0.96]);

textp = uibuttongroup('Title','Details:','Parent',hp2,...% 'Scrollable', 'on',...
                'Units','normalized','Position',[0.48 0.02 0.26 ,0.96]);
hdetail = uicontrol('Parent',textp,'Style','edit','Enable','inactive',...
                    'String','','FontSize',7,'Max',3,'Min',1,...
                    'Units','normalized','Position',[0.01 0.01 0.99, 0.99],...
                    'HorizontalAlignment','left');

bg2 = uipanel('Parent',hp2,...
            'Title','For all files:',...
            'Visible','on','Units','normalized',...
            'Position',[0.76 0.02 0.23 ,0.96]);    

% options panel          
hp3 = uipanel('Title','Options','Parent',fig,...
              'Units','normalized','Position',[0.01 0.01 0.98 ,0.15],'FontSize',9);
uicontrol('Parent',hp3,'Style','pushbutton','String','Add Files',...
          'Units','normalized','Position',[0.01 0.2 0.15 0.6],...
          'Callback',@addFile);
uicontrol('Parent',hp3,'Style','pushbutton','String','Remove Files',...
          'Units','normalized','Position',[0.18 0.2 0.15 0.6],...
          'Callback',@removeFile);
uicontrol('Parent',hp3,'Style','pushbutton','String','Settings',...
          'Units','normalized','Position',[0.35 0.2 0.15 0.6],...
          'Callback',@changeSettings);
uicontrol('Parent',hp3,'Style','pushbutton','String','Import',...
          'Units','normalized','Position',[0.83 0.2 0.15 0.6],...
          'Callback',@import);

        
selectFile(); %initialise the button group
if ~strcmp(filelist, 'Add files!')
    updateGlobalSequence();
end      

waitfor(fig); %wait the deletion of the figure to return

%% Nested functions
    function selectFile(~, ~)
        % check if files
        if ~strcmp(listfile.String, 'Add files!')
            % get the first selected file
            idx = listfile.Value;
            % check the sequences contained in this file
            if ~isempty(sequence{idx})
                % remove previous sequences
                delete(bg.Children);
   
                % calculate position and height
                n = numel(sequence{idx});
                h = (0.98-0.01*(n-1))/n;
                pos = 0.99-h:-h-0.01:0;

                % add sequences and set state according to the selection
                for i = 1:n
                    % create radiobutton
                    hbt = uicontrol('Parent',bg,'Style','radiobutton',...
                        'String', sequence{idx}{i},...
                        'Units','normalized',...
                        'FontSize',7,...
                        'Position', [0.01 pos(i) 0.98 h],...
                        'Callback',@selectSequence);
                    
                    % set state
                    set(hbt, 'Value', tf_sequence{idx}(i));
                end
            end
            
            % update detail
            updateDetail()
        end
    end %selectFile

    function selectSequence(src, ~)
        % get selected file
        idx_file = listfile.Value;
        % check the source
        if strcmp(src.Parent.Title,'Sequences:')
            % check the selected sequence and file
            idx_seq = flip(src.Parent.Children == src);

            % update selection
            tf_sequence{idx_file}(idx_seq) = logical(src.Value);  
        else
            % global sequence selection
            % get the selected sequence
            seqq = src.String;
            % change all the state corresponding to this sequence
            if src.Value
                tf_sequence = cellfun(@(x, y) x | strcmp(y, seqq), tf_sequence, sequence, 'Uniform', 0);
            else
                tf_sequence = cellfun(@(x, y) x & ~strcmp(y, seqq), tf_sequence, sequence, 'Uniform', 0);
            end
            % reset state in the current sequence display
            set(findobj(bg.Children,'String',seqq),'Value',src.Value);
        end
    end %selectSequence

    function changeSettings(~, ~)
        % check if the settings figure exists
        if exist('figure_settings','var') == 1
            return
        end
        % get the pathname for the format file
        pathname = which('formatsettings.mat');
        % if empty throw warning
        if isempty(pathname)
            warning('Format folder was not found!')
            return 
        else
            try
                % create new small GUI to display settings
                figure_settings = make_gui_settings(pathname);
            catch
                warning('File could not be loaded!')
                return 
            end
            
            % prevent other callback by desable all uicontrol components
            % as long as the setting's figure exists
            if exist('figure_settings','var') == 1
                h = findobj(fig.Children,'Type','uicontrol');
                [h.Enable] = deal('off');
                waitfor(figure_settings)
                [h.Enable] = deal('on');
            end
        end
    end %changeSettings

    function addFile(~, ~)
        % open interface to select files
        [file, path, indx] = uigetfile({'*.sdf','Stelar Raw Files (*.sdf)';...
            '*.sef','Stelar Processed Files (*.sef)'},...
            'Select One or More Files', ...
            'MultiSelect', 'on');
        % check output
        if isequal(file,0); return; elseif ischar(file); file = {file}; end

        switch indx
            case 1 %sdf
                extt = 'sdf';
            case 2 %sef
                extt = 'sef';
        end
        
        file = strcat(path, file);
        % loop over the files
        for i = length(file):-1:1
            [rawwdata{i}, paramm{i}, nExpp{i}] = readFile(file{i}, extt);
            [seqq{i},~] = getParam(file{i}, paramm{i}); 
        end
        
        % check empty data
        tf = cellfun(@isempty, rawwdata);
        
        % add data and update listbox
        if ~isempty(rawwdata(~tf))   
            % check if global sequences need to be update
            seqqq = seqq(~tf);
            if ~isempty(sequence)
                new_seq = setdiff([seqqq{:}], unique([sequence{:}]));
                if ~isempty(new_seq)
                    updateGlobalSequence('add',new_seq);
                end
            else
                updateGlobalSequence('add',unique([seqqq{:}]));
            end
            
            data = [data, rawwdata(~tf)];
            parameter = [parameter, paramm(~tf)];
            tf_sequence = [tf_sequence cellfun(@(x) true(1,x), nExpp, 'Uniform', 0)];
            sequence = [sequence, seqq(~tf)];
            
            [~,name,~] = cellfun(@(x) fileparts(x), file(~tf), 'Uniform', 0);
            
            if strcmp(listfile.String, 'Add files!')
                filelist = file(~tf);
                listfile.String = name;
            else
                filelist = [filelist, file(~tf)];
                listfile.String = [listfile.String; name'];
            end   
            
            % update file selection, sequences and detail
            selectFile();
        end
    end %addFile

    function removeFile(~, ~)
        % check the selected file in the file panel
        idx = setdiff(1:numel(listfile.String), listfile.Value);
        
        old_idx = setdiff(1:numel(listfile.String), idx);
        old_seq = sequence(old_idx); new_seq = sequence(idx);     
        old_seq = setdiff([old_seq{:}],[new_seq{:}]);
        
        if ~isempty(idx)  
           set(listfile,'String',listfile.String(idx),'Value', 1);
           filelist = filelist(idx);
           data = data(idx); parameter = parameter(idx);
           tf_sequence = tf_sequence(idx); sequence = sequence(idx);
        else
           set(listfile,'String','Add files!','Value', 1);
           filelist = []; data = []; parameter = [];
           tf_sequence = []; sequence = [];
        end     
        
        % update file selection, sequences and detail
        selectFile();  
        
        % check if global sequences need to be update
        if ~isempty(old_seq)
            updateGlobalSequence('remove',old_seq);
        end
    end %removeFile
    
    % function invokes when user pushes the 'import' pushbutton. Return the
    % selected data (sequences) and delete figure.
    function import(~, ~)
        % check file list state
        if strcmp(filelist, 'Add Files!')
            filelist = []; % case if user imports no files
        end
        % select the sequences to import for each file
        flag = 0;
        for j = 1:numel(data)
            fld = fieldnames(data{j}); %get fieldnames
            % check sequences
            if all(tf_sequence{j} == 0)
                data{j} = []; flag = 1; continue
            end
            % select parameter and sequence
            if ~isempty(parameter{j})
                parameter{j} = parameter{j}(tf_sequence{j});
            end
            sequence{j} = sequence{j}(tf_sequence{j});
            % update filelist to have filename
            [~,filelist{j},~] = fileparts(filelist{j});
            % select data
            for i = 1:numel(fld)
                data{j}.(fld{i}) = data{j}.(fld{i})(tf_sequence{j});
            end
        end
        % remove empty cells
        if flag
            tf = ~cellfun(@isempty, data);
            filelist = filelist(tf); sequence = sequence(tf);
            data = data(tf); parameter = parameter(tf);
        end
        % delete figure
        delete(fig);
    end %import
    
    % function invokes when the figure is closed. Delete all saved data.
    function exit(~, ~)
        % remove all data
        data = []; parameter = []; filelist = [];
        % check the existence of the figure settings
        if exist('figure_settings','var') == 1
            delete(figure_settings)
        end
        closereq
    end
    
    function updateGlobalSequence(action, data)
        % check action
        if strcmp(action,'add')
            n = numel(data);
            % need to reset position of the current buttons
            if ~isempty(bg2.Children)
                n = n + numel(bg2.Children);
                % calculate new height and position
                h = (0.98-0.01*(n-1))/n;
                pos = 0.99-h:-h-0.01:0;
                % set new position
                for i = 1:numel(bg2.Children)
                    bg2.Children(i).Position(2) = pos(i);
                    bg2.Children(i).Position(4) = h;
                end
                pos = pos(i+1:end);
            else
                h = (0.98-0.01*(n-1))/n;
                pos = 0.99-h:-h-0.01:0;
            end
            
            % add new buttons
            for i = 1:numel(data)
                % create radiobutton
                uicontrol('Parent',bg2,'Style','radiobutton',...
                    'String', data{i},...
                    'Units','normalized',...
                    'FontSize',7,...
                    'Value',1,...
                    'Position', [0.01 pos(i) 0.98 h],...
                    'Callback',@selectSequence);
            end
        elseif strcmp(action,'remove')
            % remove old sequences
            hbt = bg2.Children;
            [~,idx] = setdiff({hbt.String}, unique([sequence{:}]));
            % remove buttons
            delete(bg2.Children(idx));
            % reset position
            n = numel(bg2.Children);
            
            h = (0.98-0.01*(n-1))/n;
            pos = 0.99-h:-h-0.01:0;
            % set new position
            for i = 1:numel(bg2.Children)
                bg2.Children(i).Position(2) = pos(i);
                bg2.Children(i).Position(4) = h;
            end
        else %update state
            
        end
    end %updateGlobalSequence

    function updateDetail()
        % get the selected file
        idx_file = listfile.Value;
        
        % check extension of file
        [~,~,extt] = fileparts(filelist{idx_file});
        
        switch extt
            case '.sef'
                fmt = '.sef (Processed Stelar file)';
                info = struct('date','?','BR',data{idx_file}.x,'NBLK',NaN,'BS',NaN);
            case '.sdf'
                v = checkversion(filelist{idx_file});
                fmt = sprintf('.sdf v%d (Raw Stelar file)', v);
                
                [~, info] = getParam(filelist{idx_file},...
                                       parameter{idx_file});
            otherwise
                hdetail.String = 'Extension of file not recognized...';
                return
        end
        
        % get detail and update the text
        if iscell(info(1).date)
            date = strsplit(info(1).date{1},' ');
        else
            date = strsplit(info(1).date,' ');
        end
            
        txt{1} = sprintf('Format of file: %s\nDate: %s\n\n', fmt, date{1});
        for i = 1:numel(sequence{idx_file})
            warning off
            txt{i+1} = sprintf(['%s:\nNumber of BR: %d (min:%.1e, max:%.1e)\n',...
                             'Number of tau: %d\nBloc length: %d\n\n'],...
                                 sequence{idx_file}{i}, numel(info(i).BR),...
                                 min(info(i).BR), max(info(i).BR),...
                                 info(i).NBLK, info(i).BS);
            warning on
        end
        
        set(hdetail,'String',txt);            
    end %updateDetail

    %%%%%%%%%%%%%%%%%%%%%%%%% Other nested functions %%%%%%%%%%%%%%%%%%%%%%
    % Can be custom according to the extension.
    function [seq, info] = getParam(filename, parameter)
        % check extension
        [~,~,extt] = fileparts(filename);
        
        switch extt
            case '.sdf'
                % check version
                v = checkversion(filename);
                for i = numel(parameter):-1:1
                    if v == 1
                        seq{i} = parameter(i).paramList.EXP;
                        info(i).date = parameter(i).paramList.TIME;
                        info(i).BR = parameter(i).paramList.BRLX;
                        info(i).NBLK = parameter(i).paramList.NBLK;
                        info(i).BS = parameter(i).paramList.BS;
                    else
                        seq{i} = parameter(i).paramList.EXP;
                        info(i).date = '?';
                        info(i).BR = parameter(i).paramList.BR;
                        info(i).NBLK = parameter(i).paramList.NBLK;
                        info(i).BS = parameter(i).paramList.BS;
                    end
                end
            case '.sef'
                seq{1} = 'SEF File'; info = [];
            otherwise               
                seq{1} = 'Unknown sequence'; info = [];
        end
    end %getSequence

    function [rawdata, param, nExp] = readFile(pathname, ext)
        % check the extension and choose the importer
        if strcmp(ext,'sdf')
            % check version and select the correct reader
            try
                v = checkversion(pathname);
                if isequal(v,1)
                    [rawdata, param] = readsdfv1(pathname);
                else
                    [rawdata, param] = readsdfv2(pathname);
                end
                
                fld = fieldnames(rawdata);
                nExp = numel(rawdata.(fld{1}));
            catch
                [~,name,~] = fileparts(pathname);
                warning('Error while importing file %s. File not loaded.', name);
                rawdata = []; param = []; nExp = [];
            end
        elseif strcmp(ext,'sef')
            try
                rawdata = readsef(pathname);
                param = []; nExp = 1;
            catch
                [~,name,~] = fileparts(pathname);
                warning('Error while importing file %s. File not loaded.', name);
                rawdata = []; param = []; nExp = [];
            end
        else
            rawdata = []; param = [];
            warning('extension not recognized')
        end           
    end %readFile
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end