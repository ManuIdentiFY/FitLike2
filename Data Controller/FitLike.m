classdef FitLike < handle
    %
    % Presenter for the FitLike software. See MVP model.
    %
    
    properties (Access = public)
        RelaxData % Model for the Presenter
        FitLikeView % Main view for the Presenter
        FileManager % Other view for the Presenter (subView)
        DisplayManager % Other view for the Presenter (subView)
        ProcessingManager % Other view for the Presenter  (subView)
        ModelManager % Other view for the Presenter (subView)
%         AcquisitionManager % Other view for the Presenter (subView)
    end
    
    events
        ThrowMessage
    end
    
    methods (Access = public)
        % Constructor
        function this = FitLike()
            % create subView
            this.FileManager = FileManager(this);
            this.DisplayManager = DisplayManager(this);
            this.ProcessingManager = ProcessingManager(this);
            this.ModelManager = ModelManager(this);
            % this.AcquisitionManager = AcquisitionManager(this);
            
            % Add the main View
            this.FitLikeView = FitLikeView(this);
            
            % Set the main callbacks
            addlistener(this.FileManager, 'DataSelected',...
                            @(src, event) selectData(this, src, event));
            addlistener(this.FileManager, 'FileEdited',...
                            @(src, event) editFile(this, src, event));
            addlistener(this.FileManager.SelectedTree, 'TreeHasChanged',...
                            @(src, event) updateTree(this, src));
             
            addlistener(this.DisplayManager, 'SelectTab',...
                            @(src, event) selectTab(this, src));
            addlistener(this.DisplayManager, 'PlotError',...
                            @(src, event) plotError(this, src, event));             
                        
            addlistener(this, 'ThrowMessage',...
                            @(src, event) throwMessage(this, src, event));
                        
            % Set visible the main windows
            this.FileManager.gui.fig.Visible = 'on';
            this.DisplayManager.gui.fig.Visible = 'on';
            this.ModelManager.gui.fig.Visible = 'on';
        end %FitLike
        
        % Destructor             
        function closeWindowPressed(this)
           % Delete everything
           this.FitLikeView.deleteWindow();
           this.FileManager.deleteWindow();
           this.DisplayManager.deleteWindow();
           this.ProcessingManager.deleteWindow();
           this.ModelManager.deleteWindow();
%          this.AcquisitionManager.deleteWindow();

           % Delete this and clear to avoid memory leak
           delete(this);
           clear this
        end %closeWindowPressed
    end
    
    %% ----------------------- Menu Callback --------------------------- %%
    methods (Access = public)
        %%% File Menu
        % Open function: allow to open new files or dataset (.sdf, .sef, .mat)
        function this = open(this, file, path, indx, dataset)
            if nargin==1
                % open interface to select files
                [file, path, indx] = uigetfile({'*.sdf','Stelar Raw Files (*.sdf)';...
                                         '*.sef','Stelar Processed Files (*.sef)';...
                                         '*.mat','FitLike Dataset (*.mat)'},...
                                         'Select One or More Files', ...
                                         'MultiSelect', 'on');    
            end
            % check output
            if isequal(file,0)
                % user canceled
                return
            elseif ischar(file)
                file = {file};
            end
            % initialisation
            relaxObj = [];
            % switch depending on the type of file
            switch indx
                case 1 %sdf
                    if nargin >= 5
                        % case when the dataset is loaded from a various
                        % folders.
                        % the value should be provided in the input.
                        
                    % enter dataset
                    elseif isempty(this.RelaxData)||sum(~ishandle(this.RelaxData))
                        %%%-------------%%%
                        dataset = inputdlg({'Enter a dataset name:'},...
                            'Create dataset',[1 70],{'myDataset'});
                        
                        %dataset = 'myDataset';
                        %%%-------------%%%
                    elseif nargin < 5
                        % ask user in which dataset we need to put files
                        res = questdlg('Where do you want to import your data?',...
                            'Importation','Existing dataset','New dataset',...
                            'Existing dataset');
                        switch res
                            case 'Existing dataset'
                                list = unique({this.RelaxData.dataset});
                                [indx,~] = listdlg('PromptString','Select a dataset',...
                                    'SelectionMode','single',...
                                    'ListString',list);
                                dataset = list(indx);
                            case 'New dataset'
                                dataset = inputdlg({'Enter a dataset name:'},...
                              'Create dataset',[1 70],{'myDataset'});
                            otherwise 
                                return
                        end
                    end
                    % check dataset output
                    if isempty(dataset)
                        return
                    elseif ischar(dataset)
                        dataset = {dataset};
                    end
                        
                    % loop over the files
                    for i = 1:length(file)
                        filename = [path file{i}];
                        % check version and select the correct reader
                        try
                            ver = checkversion(filename);
                            if isequal(ver,1)
                                [data, parameter] = readsdfv1(filename);
                            else
                                [data, parameter] = readsdfv2(filename);
                            end
                        catch
                            event.txt = ['Error while importing file ' filename '. File not loaded.\n'];
                            throwMessage(this, [], event);
                            continue
                        end   
                        % get the data
                        y = cellfun(@(x,y) complex(x,y), data.real, data.imag,...
                            'UniformOutput',0);
                        name = getfield(parameter,'FILE','ForceCellOutput','True');
                        sequence = getfield(parameter,'EXP','ForceCellOutput','True');
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                       
                        % format the output
                        new_relaxObj = RelaxObj('filename',name,'sequence',sequence,...
                                                'dataset',repmat(dataset,1,length(name)),...
                                                'parameter',num2cell(parameter),...
                                                'data',num2cell(Bloc('x',data.time,'y',y)));
                        new_relaxObj = check(new_relaxObj);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        % check duplicates
                        if ~isempty(this.RelaxData)
                            new_relaxObj = checkDuplicates(this, new_relaxObj);
                        end
                        % append them to the current data
                        relaxObj = [relaxObj new_relaxObj]; %#ok<AGROW>
                    end
                case 2 %sef
                    % enter dataset
                    if nargin >= 5
                        % dataset already provided
                    elseif isempty(this.RelaxData)
                        dataset = inputdlg({'Enter a dataset name:'},...
                            'Create dataset',[1 70],{'myDataset'});
                    else
                        % ask user in which dataset we need to put files
                        res = questdlg('Where do you want to import your data?',...
                            'Importation','Existing dataset','New dataset',...
                            'Existing dataset');
                        switch res
                            case 'Existing dataset'
                                list = unique({this.RelaxData.dataset});
                                [indx,~] = listdlg('PromptString','Select a dataset',...
                                    'SelectionMode','single',...
                                    'ListString',list);
                                dataset = list(indx);
                            case 'New dataset'
                                dataset = inputdlg({'Enter a dataset name:'},...
                              'Create dataset',[1 70],{'myDataset'});
                            otherwise 
                                return
                        end
                    end
                    % check dataset output
                    if isempty(dataset)
                        return
                    elseif ischar(dataset)
                        dataset = {dataset};
                    end
                    % loop over the files
                    for i = 1:length(file)
                        filename = [path file{i}];
                        % read the file
                        [x,y,dy] = readsef(filename);
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        data = Dispersion('x',x,'xLabel','Magnetic Field (MHz)',...
                            'y',y,'dy',dy,'yLabel','Relaxation Rate R_1 (s^{-1})');
                        new_relaxObj = RelaxObj('filename',file{i},'sequence','Unknown',...
                                                'dataset',dataset,...
                                                'data', data);
                        new_relaxObj = check(new_relaxObj);                       
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        % check duplicates
                        if ~isempty(this.RelaxData)
                            new_relaxObj = checkDuplicates(this, new_relaxObj);
                        end
                        % append them to the current data
                        relaxObj = [relaxObj new_relaxObj]; %#ok<AGROW>
                    end
                case 3 %mat
                    for i = 1:length(file)
                        filename = [path file{i}];
                        % read the .mat file
                        obj = load(filename);
                        var = fieldnames(obj);
                        % check duplicates
                        new_relaxObj = obj.(var{1});
                        if ~isempty(this.RelaxData)
                            new_relaxObj = checkDuplicates(this, new_relaxObj);
                        end
                        % append them to the current data
                        relaxObj = [relaxObj new_relaxObj]; %#ok<AGROW>
                    end
            end
            % check ID integrity
            relaxObj = checkID(this, relaxObj);
            % append data to RelaxData
            this.RelaxData = [this.RelaxData relaxObj];
            % update FileManager
            addFile(this.FileManager, relaxObj);
            % throw message
            event.txt = [sprintf('%d files have been imported!', numel(relaxObj)),'\n'];
            throwMessage(this, [], event);
            %%-----------------------------------------------------------%%
            % Check if duplicates are imported
            function relaxObj = checkDuplicates(this, relaxObj)
                % remove invalid handles from the list if any 
                this.RelaxData = this.RelaxData(arrayfun(@(r) isvalid(r),this.RelaxData));
                % check if duplicates have been imported
                [~,idx,~] = intersect(strcat({relaxObj.dataset},{relaxObj.sequence},...
                    {relaxObj.filename}),strcat({this.RelaxData.dataset},{this.RelaxData.sequence},...
                    {this.RelaxData.filename}));
                if ~isempty(idx)
                    % create a cell array of string with:
                    % 'filename' (Sequence: 'sequence')
                    listDuplicate = arrayfun(@(x) sprintf(['%s\t'...
                        '(Sequence: %s)'], x.filename, x.sequence),...
                        relaxObj(idx),'UniformOutput',0);
                    % display message
                    eventdata.txt = [sprintf(['The following files '...
                        'are already stored in FitLike:\n\n%s'],...
                        sprintf('%s \n',listDuplicate{:})),'\n'];
                    throwMessage(this, [], eventdata);
                    % delete duplicated
                    relaxObj(idx) = [];
                end
            end %checkDuplicated
            %%-----------------------------------------------------------%%
        end %open
        
        % load the entire content of one folder
        function this = loadfolder(this,folder,dataset,options)
            % read the content of the folder and decide which file type to
            % process
            content = dir(folder);
            for indfile = length(content):-1:1
                [~,~,ext{indfile}] = fileparts(content(indfile).name);
            end
            datalist = {};
            if sum(strcmp(ext,'.sdf'))  % if at least one sdf file if found, load all of them only
                datalist = {content(strcmp(ext,'.sdf')).name};
                ind = 1;
            elseif sum(strcmp(ext,'.sef'))
                datalist = {content(strcmp(ext,'.sef')).name};
                ind = 2;
%             elseif sum(strcmp(ext,'.mat'))
%                 datalist = {content(strcmp(ext,'.mat')).name};
%                 ind = 3;
            end
            if ~isempty(datalist)
                this = open(this,datalist,[folder filesep],ind,dataset);
            end
            % then search for further directory and load their content
            % recursively
            for indfolder = 3:length(content)
                foldername = fullfile(folder,content(indfolder).name);
                if exist(foldername,'dir') == 7
                    if options.splitFolders
                        subdataset = [dataset filesep content(indfolder).name];
                    else
                        subdataset = dataset;
                    end
                    this = loadfolder(this,foldername,subdataset,options);
                else
                   % throw error to the log console 
                end
            end
        end
        
        % recursively loads the content of a directory
        function this = opendir(this)
            folder = uigetdir(cd,'Recursively load folder:');
            if exist(folder,'dir') == 7
                dataset = inputdlg('Name of the new dataset:','New data set',1,{'NewSet'});
                ans = questdlg('Load each folder in a new dataset?','Import','Yes','No','No');
                options.splitFolders = strcmp(ans,'Yes'); 
                if ~isempty(dataset)
                    this = loadfolder(this,folder,dataset{1},options); 
                end
            else
               % throw error to the log console 
            end
        end
        
        % Remove funcion: allow to remove files, sequence, dataset
        function this = remove(this)
            % check the selected files in FileManager
            relaxObj = getSelectedFile(this.FileManager);
            % remove files in RelaxData 
            idx = intersect(this.RelaxData, relaxObj);
            remove(this.RelaxData, idx);
            % removes invalid objects
            this.RelaxData = this.RelaxData(arrayfun(@(r) isvalid(r),this.RelaxData));
            % update FileManager
            deleteFile(this.FileManager);
            % throw message
            event.txt = [num2str(numel(idx)),' files have been removed \n'];
            throwMessage(this, [], event);
        end %remove
        
        % Export function: allow to export data (dispersion, model)
        function export(this, src)
            % get selected data
            relaxObj = getSelectedFile(this.FileManager);
            % check input
            if strcmp(src.Tag,'Export_Dispersion')
                % get save folder
                path = uigetdir(pwd, 'Export Dispersion data');
                % loop over the files
                for k = 1:numel(relaxObj)
                    % get dispersion data
                    tf = isequal(relaxObj(k), this.RelaxData);
                    hData = getData(this.RelaxData(tf),'Dispersion');
                    % check if dispersion
                    if ~isa(this.RelaxData(tf), 'Dispersion')
                        event.txt = [sprintf('Error: Cannot export this file...%d/%d',k,numel(relaxObj)),'\n'];
                        throwMessage(this, [], event);
                    else
                        export_data(hData, path);
                    end
                    event.txt = [sprintf('Files exported...%d/%d',k,numel(relaxObj)),'\n'];
                    throwMessage(this, [], event);
                end
            else
                
            end
        end %export
        
        % Save function: allow to save all data in .mat dataset
        function save(this)
            relaxData = this.RelaxData; %#ok<NASGU>
            uisave('relaxData','data');
            event.txt = 'Files saved succesfully!\n';
            throwMessage(this, [], event);
        end %save

        %%% Edit Menu
        % Add label
        function this = addLabel(this, src)
            % check if files are selected
            relaxObj = getSelectedFile(this.FileManager);
            if isempty(relaxObj)
                event.txt = 'Error: You need to select files to define labels!\n';
                throwMessage(this, [], event);
                return
            end
            
            % check if new label or not
            if strcmp(src.Label,'Add Label')
                % ask user
                answer = inputdlg({'Enter a label:'},'Label',[1 40],{'0'});
                if isempty(answer{1})
                    return
                else
                    % check if duplicate
                    hLabel = src.Parent.Children;
                    
                    if numel(hLabel) > 2
                        tf = strcmp({hLabel(1:end-2).Label}, answer{1});
                        
                        if ~all(tf == 0)
                            event.txt = 'Error: This label already exists!\n';
                            throwMessage(this, [], event);
                            return
                        end
                    end
                    label = answer{1};
                end

                % add this label to the list
                [~, icon] = addLabelItem(this.FitLikeView, label);
                
                if isempty(icon)
                    event.txt = 'Error: You have reached the maximal number of label!\n';
                    throwMessage(this, [], event);
                    return
                end
            else
                label = src.Label;
                icon = src.UserData;
            end
            
            % update selected files
            [~,indx,~] = intersect({this.RelaxData.fileID}, {relaxObj.fileID});
            [this.RelaxData(indx).label] = deal(label);
            
            % update FileManager
            addLabel(this.FileManager, icon);
        end %addLabel
        
        % Remove label
        function this = removeLabel(this, src)
            % get the list of label
            hLabel = src.Parent.Children;
            
            if numel(hLabel) < 3
                event.txt = 'Error: No label to delete!';
                throwMessage(this, [], event);
            end
            
            % ask user which item to delete
            indx = listdlg('PromptString','Select a label to delete:',...
                           'SelectionMode','single',...
                           'ListString',{hLabel(1:end-2).Label});
                       
            if isempty(indx); return; end
            
            % check if files are labeled
            tf = strcmp({this.RelaxData.label}, hLabel(indx).Label);
            
            if ~all(tf == 0)
                % reset their label
                [this.RelaxData(tf).label] = deal('');
                
                % update FileManager
                removeLabel(this.FileManager, this.RelaxData(tf));
            end
                        
            % delete the label
            removeLabel(this.FitLikeView, hLabel(indx).Label);
        end %removeLabel
        
        % Merge function: allow to merge/unmerge files
        function this = merge(this)
%             % get the selected files
%             fileID = nodes2fileID(this.FileManager.gui.tree);
%             [~,indx,~] = intersect({this.RelaxData.fileID}, fileID);
%             % check if files are already merged or not
%             if all(cellfun(@isempty,  {this.RelaxData(indx).subUnitList}) == 1)
%                 % check if their dataset/sequence are the same
%                 if ~all(strcmp({this.RelaxData(indx).dataset},...
%                                this.RelaxData(indx(1)).dataset) == 1) ||... 
%                    ~all(strcmp({this.RelaxData(indx).sequence},...
%                                this.RelaxData(indx(1)).sequence) == 1)
%                     % ask user
%                     warning('Not done yet!')
%                     return                      
%                 end
%                 % merge files
%                 mergedFile = merge(this.RelaxData(indx));
%                 % update tree
%                 fileID = [this.RelaxData(indx(1)).dataset,'@',...
%                           this.RelaxData(indx(1)).sequence,'@',...
%                           this.RelaxData(indx(1)).filename];
%                 fileID2modify(this.FileManager.gui.tree,...
%                     {fileID}, {mergedFile.filename}, {[]}, 0);
%                 fileID2delete(this.FileManager.gui.tree, {this.RelaxData(indx(2:end)).fileID});
%                 % update model
%                 this.RelaxData = remove(this.RelaxData, indx);
%                 this.RelaxData = [this.RelaxData mergedFile];
%                 selectFile(this, [], struct('Action','NodeChecked',...
%                     'Nodes',this.FileManager.gui.tree.CheckedNodes));
%             elseif all(cellfun(@isempty,  {this.RelaxData(indx).subUnitList}) == 0)
%                 % unmerged files
%                 for k = 1:numel(indx)
%                     relaxList = unMerge(this.RelaxData(indx(k)));
%                     % update tree
%                     fileID = [this.RelaxData(indx(k)).dataset,'@',...
%                           this.RelaxData(indx(k)).sequence,'@',...
%                           this.RelaxData(indx(k)).filename];
%                     % check if label
%                     if ~isempty(relaxList(1).label)
%                         name = ['[',relaxList(1).label,'] ',relaxList(1).filename];
%                     else
%                         name = relaxList(1).filename;
%                     end
%                     fileID2modify(this.FileManager.gui.tree,...
%                         {fileID}, {name}, {[]}, 0);
%                     add(this.FileManager.gui.tree, relaxList(2:end), 0);
%                     % update model
%                     this.RelaxData = remove(this.RelaxData, indx(k));
%                     this.RelaxData = [this.RelaxData, relaxList];
%                     selectFile(this, [], struct('Action','NodeChecked',...
%                         'Nodes',this.FileManager.gui.tree.CheckedNodes));
%                 end
%             else
%                warning('Not done yet!') 
%                return
%             end
        end %merge       
        
        %%% View Menu      
        % CreateFig function: allow to export current axis in new figure
        function this = createFig(this)
            % get the handle of the selected tab
            h = this.DisplayManager.gui.tab.SelectedTab;
            % call createFig() in the concerned tab
            createFig(h.Children);
        end %createFig          
        
        %%% Display Menu
        % Show/Hide FileManager, DisplayManager, Processing Manager,...
        function showWindow(this, src)
            % according to the current visibility, change it
            if strcmp(src.Checked,'on')
                src.Checked = 'off';
                this.(src.Tag).gui.fig.Visible = 'off';
            else
                src.Checked = 'on';
                this.(src.Tag).gui.fig.Visible = 'on';
            end
        end %showWindow

        
        %%% Help Menu
        % Documentation function: allow to open the user documentation
        function help(this)
            
        end %help
    end      
    %% --------------------- FileManager Callback ---------------------- %%  
    methods (Access = public)               
        % Event: data is selected. Add or remove data from current plot
        function selectData(this, ~, event)
            % check if data are selected or deselected
            if strcmp(event.Action, 'Select')
                % add data to the current plot
                for k = 1:numel(event.Data)
                    addPlot(this.DisplayManager, event.Data(k), event.idxZone(k));
                    pause(0.005) %EDT
                end
            elseif strcmp(event.Action, 'Deselect')
                 % remove data from current plot
                for k = 1:numel(event.Data)
                    removePlot(this.DisplayManager, event.Data(k), event.idxZone(k));
                    pause(0.005) %EDT
                end               
            end
            drawnow; %EDT
        end %selectData
        
        % Event: error during plot. Need to uncheck the concerning
        % nodes.
        function plotError(this, ~, event)
            checkData(this.FileManager, event.Data, event.idxZone, 0);
        end %plotError
        
        % edit files callback       
        function editFile(~, ~, event)
            % update the data
            [event.Data.(event.Prop)] = deal(event.Value); 
        end %editFile

        % Update the current data tree in case where data are plot and need
        % to be checked
        function updateTree(this, src, ~)
            % get the tab information
            [dataObj, idxZone] = getData(this.DisplayManager);
            
            % check the corresponding data            
            if ~isempty(dataObj) && strcmp(class(dataObj), src.Tag)
                checkData(this.FileManager, dataObj, idxZone, 1);
            end
        end
        
        % Wrapper to throw message
        function throwMessage(this, ~, event)
            this.FileManager = throwMessage(this.FileManager, event.txt);
        end %disp
    end   
    %% -------------------- DisplayManager Callback -------------------- %% 
    methods (Access = public)
        % Tab selection callback
        function selectTab(this, src)
            % reset all tree in FileManager
            reset(this.FileManager);
            
            % get data from the current tab
            [dataObj, idxZone] = getData(src);
            
            if ~isempty(dataObj)          
                % update FileManager
                setTree(this.FileManager, class(dataObj));
                checkFile(this.FileManager, unique([dataObj.relaxObj]));
                checkData(this.FileManager, dataObj, idxZone, 1);
                drawnow;
            end
        end %selectTab

        % Mask data
        function setMask(~, ~, event)
            if strcmp(event.Action,'SetMask')
                % get boundaries
                xmin = event.XRange(1); xmax = event.XRange(2);
                ymin = event.YRange(1); ymax = event.YRange(2);
                % define mask
                for k = 1:numel(event.Data)
                    event.Data(k) = setMask(event.Data(k), event.idxZone(k),...
                        [xmin xmax], [ymin ymax]);
                    % notify
                    %notify(event.Data(k), 'DataHasChanged', EventData(event.idxZone(k)))
                end
            elseif strcmp(event.Action,'ResetMask')
                % reset mask
                for k = 1:numel(event.Data)
                    event.Data(k) = setMask(event.Data(k), event.idxZone(k));
                    % notify
                    %notify(event.Data(k), 'DataHasChanged', EventData(event.idxZone(k)))
                end
            end
        end % setMask
    end
    %% ------------------ ProcessingManager Callback ------------------- %%
    methods (Access = public)
        % Run process
        function runProcess(this)
            % check if data are selected
            relaxObj = getSelectedFile(this.FileManager);
            % according to the mode process, run it
            if isempty(relaxObj)
                event.txt = 'Warning: You need to select data to run process!\n';
                throwMessage(this, [], event);
                return
            elseif this.ProcessingManager.gui.BatchRadioButton.Value
                % Batch mode
                tab = this.ProcessingManager.gui.tab.SelectedTab.Children;
                % check the selected pipeline
                if ~ProcessTab.checkProcess(tab)
                    return
                end
                % get the process array
                ProcessArray = flip(tab.ProcessArray);
                event.txt = 'Starting to process file...\n';
                throwMessage(this, [], event);
                
                % apply the processes
                warning off
                for nProc = 1:length(ProcessArray)          
                    if ~ProcessArray(nProc).globalProcess % case when the process is applied independently to each data acquisition
                        % loop over the file
%                         for indFile = 1:numel(relaxObj)
%                             % collect the data (selection may have changed if data
%                             % merge operations are included)
%                             tf = isequal(relaxObj(indFile), this.RelaxData);
%                             if indFile == 1
%                                 data = getData(this.RelaxData(tf), ProcessArray(nProc).InputChildClass);
%                             else
%                                 data = [data getData(this.RelaxData(tf), ProcessArray(nProc).InputChildClass)];
%                             end
%                         end
                        data = getData(relaxObj, ProcessArray(nProc).InputChildClass);
                        data = arrayfun(@(d) processData(d, ProcessArray(nProc)),data); % perform the process
                    else % case when the process needs to be applied to the entire selection.
                        data = getData(relaxObj, ProcessArray(nProc).InputChildClass);
                        data = processDataGroup(ProcessArray(nProc),data);
                        % find the list of relaxobj corresponding to the
                        % data objects returned
                        oldRelaxObj = relaxObj;
                        relaxObj = unique([data.relaxObj]);
                        
                        % find if the new objects are the same as the
                        % previous ones
                        changeflag = 1;
                        if numel(oldRelaxObj)==numel(relaxObj)
                            testcell = arrayfun(@(old,new) isequal(old,new),oldRelaxObj,relaxObj,'UniformOutput', false);
                            if all([testcell{:}])
                                changeflag = 0;
                            end
                        end
                                
                        if changeflag

                            % add new relax objects to the windows manager (if
                            % any)
                            addFile(this.FileManager, relaxObj);

                            % find the old relaxObj and unselect them (if any)
                            % TO DO

                            % update the selection
                            % TO DO
                        end                        
                        
                    end
                    
                end % process array loop
                warning on
                
                % finalise the data units
                % Check if data has children and delete them if true.
                % Avoid to keep old children from previous process
                for j = 1:numel(data)
                    if ~isempty(data(j).children)
                        data(j).children = remove(data(j).children);
                    end
                end

                % replace the highest object created in relaxObj
                for indFile = 1:numel(relaxObj)
                    relaxObj(indFile).data(~arrayfun(@(x) isempty(x.processingMethod), relaxObj(indFile).data)) = [];
                end
                for indData = 1:numel(data)
                    data(indData).relaxObj.data(end+1) = data(indData);
                end
                pause(0.005); % avoids some bugs with Java delays
                % update FileManager
                setTree(this.FileManager, class(data));
                drawnow; pause(0.005);
                updateData(this.FileManager, relaxObj);                  
                drawnow; pause(0.005);

                if isa(data, 'Dispersion')
                    idxZone = repelem(NaN, numel(data));
                else
                    idxZone = repelem(1,numel(data));
                end                   
                checkData(this.FileManager, data, idxZone, 1);                    
                drawnow; pause(0.005);
                
%                 
%                 
%                 
%                 
%                 ndata = numel(relaxObj); % store the initial number of data sets for information
%                 % loop over the file
% %                 for k = 1:numel(relaxObj)
%                 while numel(relaxObj) > 0
%                     event.txt = 'Processing...'; throwMessage(this, [], event);
%                     
%                     % get data
%                     tf = isequal(relaxObj(1), this.RelaxData);
%                     data = getData(this.RelaxData(tf), 'Bloc');
%                     
%                     % apply the pipeline
%                     for j = 1:numel(ProcessArray) 
%                         % check if new process or not
% %                         if ~isempty(data(1).processingMethod)
% %                             if isequal(data.processingMethod, ProcessArray(j))
% %                                 data = [data.children]; continue;
% %                             end                
% %                         end
%                      
%                         % apply the process
%                         warning off
%                         % Check if the process to be applied must be
%                         % dispatched to each acquisition separately
%                         if ~ProcessArray(j).globalProcess
%                             data = processData(data, ProcessArray(j));
%                         else
%                             % otherwise, this is an operation on the data that
%                             % requires multiple RelaxObj
%                             data = processDataGroup(ProcessArray(j),data);
%                             % add new relax objects to the list, select
%                             % them and unselect old ones
%                             % TO DO
%                         end
%                         
%                         pause(0.005);
%                         warning on
%                     end   
%                     
%                     % Check if data has children and delete them if true.
%                     % Avoid to keep old children from previous process
%                     for j = 1:numel(data)
%                         if ~isempty(data(j).children)
%                         data(j).children = remove(data(j).children);
%                         end
%                     end
%                     
%                     % Check if data has processingMethod and delete if true
%                     tf_oldprocess = ~arrayfun(@(x) isempty(x.processingMethod), data);
%                     if any(tf_oldprocess ~= 0)
%                         [data(tf_oldprocess).processingMethod] = deal([]);
%                     end
%                     
%                     % replace the highest object created in relaxObj
%                     this.RelaxData(tf).data = data;
%                     pause(0.005);
%                     % update FileManager
%                     setTree(this.FileManager, class(data));
%                     drawnow; pause(0.005);
%                     updateData(this.FileManager, this.RelaxData(tf));                  
%                     drawnow; pause(0.005);
%                     
%                     if isa(data, 'Dispersion')
%                         idxZone = repelem(NaN, numel(data));
%                     else
%                         idxZone = repelem(1,numel(data));
%                     end                   
%                     checkData(this.FileManager, data, idxZone, 1);                    
%                     drawnow; pause(0.005);
%                     % try to plot
% %                     addPlot(this.DisplayManager, data, idxZone);                                       
% %                     drawnow % EDT
%                     
%                     event.txt = [sprintf('%d/%d',numel(relaxObj)),ndata,'\n'];
%                     throwMessage(this, [], event);
%                 end %for
            else
                % Simulation mode
                % TO DO
            end
        end %runProcess
    end
    %% --------------------- ModelManager Callback --------------------- %%
    methods (Access = public)
        % Run Fit
        function runFit(this) %%%%% WARNINNNNG %%%%
            % check if data are selected
            [dataObj, ~] = getSelectedData(this.FileManager); %%%%% WARNINNNNG %%%%
            % according to the mode process, run it
            if isempty(dataObj)
                event.txt = 'Warning: You need to select dispersion data to run fit\n!';
                throwMessage(this, [], event);
                return
            end
            
            if this.ModelManager.gui.BatchRadioButton.Value
                event.txt = 'Starting to fit file...\n';
                throwMessage(this, [], event);
                % Batch mode
                tab = this.ModelManager.gui.tab.SelectedTab.Children;
                % get the process array
                ModelArray = tab.ModelArray;
                % make the sum of all the models
                ModelSum = MergedModels;
                ModelSum = addModel(ModelSum,ModelArray);
                
                if isempty(ModelArray); return; end
                
                % loop over the file
                for k = 1:numel(dataObj)
                    event.txt = 'Fitting...'; throwMessage(this, [], event);
                    % apply the process
                    dataObj(k) = processData(dataObj(k), ModelSum);
                    % throw message
                    event.txt = [sprintf('%d/%d',k,numel(dataObj)),'\n'];
                    throwMessage(this, [], event);
                end
                drawnow; %EDT
                %updateResultTable(this.ModelManager);
            else % simulation mode
                
            end
            
            
            
%             
%             % according to the mode process, run it
%             if isempty(fileID)
%                 event.txt = 'Warning: You need to select dispersion data to run fit\n!';
%                 throwMessage(this, [], event);
%                 return
%             elseif this.ModelManager.gui.BatchRadioButton.Value
%                 event.txt = 'Starting to fit file...\n';
%                 throwMessage(this, [], event);
%                 % Batch mode
%                 tab = this.ModelManager.gui.tab.SelectedTab.Children;
%                 % get the process array
%                 ModelArray = tab.ModelArray;
%                  % loop over the file
%                 for k = 1:numel(fileID)
%                     event.txt = 'Fitting...'; throwMessage(this, [], event);
%                     
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     tf = isequal({this.RelaxData.fileID}, fileID{k});
%                     dispersion = getData(this.RelaxData(tf), 'Dispersion', legendTag{k});
%                     % Replace by getData('Dispersion') [Manu]
%                     % check for correspondance (same data file)
% %                     tf = strcmp(strcat({this.RelaxData.fileID},...
% %                         {this.RelaxData.displayName}), strcat(fileID{k},...
% %                         legendTag{k}));
%                     % check if dispersion
%                     if isempty(dispersion); continue; end
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     
%                     % apply the fit to the file
%                     procObj = DispersionLsqCurveFit;
%                     procObj = addModel(procObj,ModelArray);
%                     assignProcessingFunction(dispersion, procObj);
%                     % apply the process
%                     processData(dispersion); 
%                     
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     % Use Wrapper? [Manu]
%                     % update model name
%                     dispersion.processingMethod.model.modelName = tab.Parent.Title;
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     
%                     % notify
%                     notify(dispersion, 'DataHasChanged', EventData(NaN)) 
%                     event.txt = [sprintf('%d/%d',k,numel(fileID)),'\n'];
%                     throwMessage(this, [], event);
%                 end
%                 drawnow;
%                 updateResultTable(this.ModelManager);
%                 drawnow;
%             else
%                 % Simualation mode
%             end
        end %runFit
        
        % send model to the ModelManager
        function dataObj = getData(this, fileID, displayName)
            % check input
            if isempty(fileID); dataObj = []; return; end
            
            % get the corresponding relaxObj
            tf = strcmp(fileID, {this.RelaxData.fileID});
            
            if all(tf ==0); dataObj = []; return; end
            
            dataObj = getData(this.RelaxData(tf), 'Dispersion', displayName);
        end %getModel
    end
    %% ------------------ AcquisitionManager Callback ------------------ %%
    methods (Access = public)
        
    end
    %% ------------------------ Others Callback ------------------------ %%
    methods (Access = public)     
        % Close subView callback: hide figure
        function hideWindowPressed(this, src)
            % determine the figure concerned and call showWindow() to close
            % it
            tag = strrep(src.Name,' ',''); %just remove space
            src = this.FitLikeView.gui.(tag);
            showWindow(this, src);
        end %hideWindowPressed  
        
        % Check ID integrity of the new bloc. Change ID if needed.
        function relaxObj = checkID(this, relaxObj)
            % check if data
            if isempty(this.RelaxData)
                return
            end
            
            % intersect
            [~,~,idx] = intersect({this.RelaxData.fileID},{relaxObj.fileID});
            if ~isempty(idx)
                % generate new ID
                for k = 1:numel(idx)
                    relaxObj(idx).fileID = char(java.util.UUID.randomUUID);
                end
                relaxObj = checkID(this, relaxObj);
            end    
        end %checkID
    end
end

