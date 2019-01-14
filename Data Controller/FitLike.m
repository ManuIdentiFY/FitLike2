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
                    elseif isempty(this.RelaxData)
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
                            dispMsg(this, ['Error while importing file ' filename '. File not loaded.\n']) % simple error handling for file import
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
            dispMsg(this, [sprintf('%d files have been imported!', numel(relaxObj)),'\n']);
            %%-----------------------------------------------------------%%
            % Check if duplicates are imported
            function relaxObj = checkDuplicates(this, relaxObj)
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
                    msg = sprintf(['The following files '...
                        'are already stored in FitLike:\n\n%s'],...
                        sprintf('%s \n',listDuplicate{:}));
                    dispMsg(this, [msg, '\n']);
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
            [~,idx,~] = intersect({this.RelaxData.fileID}, {relaxObj.fileID});
            delete(this.RelaxData(idx)); this.RelaxData(idx) = [];
            % update FileManager
            deleteFile(this.FileManager);
            % throw message
            dispMsg(this, [num2str(numel(idx)),' files have been removed \n']);
        end %remove
        
        % Export function: allow to export data (dispersion, model)
        function export(this, src)
            % get selected data
            fileID = getSelectedFile(this.FileManager);
            % check input
            if strcmp(src.Tag,'Export_Dispersion')
                % get save folder
                path = uigetdir(pwd, 'Export Dispersion data');
                % loop over the files
                for k = 1:numel(fileID)
                    % get dispersion data
                    tf = strcmp({this.RelaxData.fileID}, fileID{k});
                    % check if dispersion
                    if ~isa(this.RelaxData(tf), 'Dispersion')
                        dispMsg(this, [sprintf('Error: Cannot export this file...%d/%d',k,numel(fileID)),'\n']);
                    else
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Need to modify export_data to handle array of
                        % DataUnit object [Manu] --> maybe set this
                        % function in Dispersion??
                        hData = getData(this.RelaxData(tf),'Dispersion');
                        export_data(hData, path);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                    end
                    dispMsg(this, [sprintf('Files exported...%d/%d',k,numel(fileID)),'\n']);
                end
            else
                
            end
        end %export
        
        % Save function: allow to save all data in .mat dataset
        function save(this)
            relaxData = this.RelaxData; %#ok<NASGU>
            uisave('relaxData','data');
            dispMsg(this, 'Files saved succesfully!\n');
        end %save

        %%% Edit Menu
        % Add label
        function this = addLabel(this, src)
            % check if files are selected
            relaxObj = getSelectedFile(this.FileManager);
            if isempty(relaxObj)
                dispMsg(this,'Error: You need to select files to define labels!\n');
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
                            dispMsg(this,'Error: This label already exists!\n');
                            return
                        end
                    end
                    label = answer{1};
                end

                % add this label to the list
                [~, icon] = addLabelItem(this.FitLikeView, label);
                
                if isempty(icon)
                    dispMsg(this, 'Error: You have reached the maximal number of label!\n');
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
                dispMsg(this, 'Error: No label to delete!')
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % To remove [Manu]
%         % Get datafile info: WILL CHANGED SOON! DUMMY FUNCTION
%         function datainfo = getFileInfo(this, fileID)
%             % get the corresponding data(s)
%             tf = strcmp({this.RelaxData.fileID}, fileID);
%             hData = this.RelaxData(tf);
%             % form the output structure
%             while ~isempty(hData(1).parent)
%                 hData = hData(1).parent;
%             end
%             % get the info
%             while numel(hData) > 0
%                 % get the number of zone
%                 nZone = numel(hData(1).parameter.paramList.ZONE);
%                 % switch
%                 switch class(hData)
%                     case 'Dispersion'
%                         dispersion = {hData.displayName};
%                         datainfo.dispersion = {dispersion};
%                     case 'Zone'
%                         zone = {hData.displayName};
%                         zonelist = strcat('Zone',...
%                             cellfun(@num2str, num2cell(1:nZone),'Uniform',0));
%                         datainfo.zone = {zone, zonelist};
%                     case 'Bloc'
%                         bloc = {hData.displayName};
%                         bloclist = strcat('Bloc',...
%                             cellfun(@num2str, num2cell(1:nZone),'Uniform',0));
%                         datainfo.bloc = {bloc, bloclist};
%                 end
%                 % get the children
%                 hData = [hData.children];
%             end
%         end %getFileInfo
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Event: data is selected. Add or remove data from current plot
        function this = selectData(this, ~, event)
            % check if data are selected or deselected
            if strcmp(event.Action, 'Select')
                % loop over the input
                for k = 1:numel(event.Data)
                    % add data from current plot
                    [~, plotFlag, ~] = addPlot(this.DisplayManager,...
                                        event.Data(k), event.idxZone(k));
                    if ~plotFlag
                        % uncheck this node
                        dispMsg(this, ['Cannot plot ', getRelaxProp(event.Data(k), 'filename'),...
                            ': the data type doesnt fit with the current tab!\n']);
                        %hNode(k).Checked = 0;
                    end
                    pause(0.005) %EDT
                end
            elseif strcmp(event.Action, 'Deselect')
                 % loop over the input
                for k = 1:numel(event.Data)
                    % remove data from current plot
                    removePlot(this.DisplayManager,...
                               event.Data(k), event.idxZone(k));
                    pause(0.005)
                end               
            end
            drawnow; %EDT
        end %selectData
%         
%         % Event: data is selected. NEED TO MODIFY RELAXOBJ ACCESS
%         function addData(this, hNode, type, fileID, name, idx)
%                 % loop over the input
%                 for k = 1:numel(fileID)
%                     
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     % get the corresponding dataobj
%                     tf = strcmp({this.RelaxData.fileID}, fileID{k});
%                     hData = getData(this.RelaxData(tf), type, name);
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     
%                     % add data from current plot
%                     [~, plotFlag, ~] = addPlot(this.DisplayManager, hData, idx(k));
%                     if ~plotFlag
%                         % uncheck this node
%                         dispMsg(this, ['Cannot plot ',getRelaxProp(hData,'filename'),...
%                             ': the data type doesnt fit with the current tab!\n']);
%                         hNode(k).Checked = 0;
%                     end
%                     pause(0.005)
%                 end
%                 drawnow;
%         end %addData
%         
%         % Event: data is selected. NEED TO MODIFY RELAXOBJ ACCESS
%         function removeData(this, type, fileID, name, idx)
%                 % loop over the input
%                 for k = 1:numel(fileID)                   
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     % get the corresponding dataobj
%                     tf = strcmp({this.RelaxData.fileID}, fileID{k});
%                     hData = getData(this.RelaxData(tf), type, name);
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     
%                     % remove data from current plot
%                     removePlot(this.DisplayManager, hData, idx(k));
%                     pause(0.005)
%                 end
%                 drawnow;
%         end %addData
        
%         % edit files callback
%         function editFile(this, fileID, prop, val)
%             % get the file to modify
%             [~,indx,~] = intersect({this.RelaxData.fileID}, fileID);
%             % update them
%             [this.RelaxData(indx).(prop)] = deal(val);
%         end %editFile

        % edit files callback       
        function editFile(~, ~, event)
            % update the data
            [event.Data.(event.Prop)] = deal(event.Value); 
        end %editFile

        % Update the current data tree in case where data are plot and need
        % to be checked
        function updateTree(this, src, ~)
            % get the tab information
            [dataObj, idxZone] = getTabData(this.DisplayManager);
            
            % check the corresponding data            
            if ~isempty(dataObj) && strcmp(class(dataObj), src.Tag)
                checkData(this.FileManager, dataObj, idxZone, 1);
            end
        end
        
        % Wrapper to throw message
        function dispMsg(this, msg)
            this.FileManager = throwMessage(this.FileManager, msg);
        end %disp
    end   
    %% -------------------- DisplayManager Callback -------------------- %% 
    methods (Access = public)
        % Tab selection callback
        function selectTab(this, src)
            % get the selected tab
            hTab = src.SelectedTab.Children;
            resetFileTree(this.FileManager);
            if isa(hTab,'EmptyPlusTab')
                % add new tab
                addTab(this.DisplayManager);
            else 
                [~, fileID, displayName, idx] = getTabData(this);
                % update FileManager
                setSelectedTree(this.FileManager, hTab.inputType);
                checkFile(this.FileManager, fileID);
                checkData(this.FileManager, fileID, displayName, idx, 1);
                drawnow;
            end
        end %selectTab
        
        % Wrapper to get plot data
        function [c, fileID, displayName, idx] = getTabData(this)
            [c, fileID, displayName, idx] = getDataID(this.DisplayManager.gui.tab.SelectedTab.Children);
        end
        
        % Wrapper to get legend (avoid fit)
        function [leg, fileID] = getLegend(this)
             [leg, fileID] = getLegend(this.DisplayManager.gui.tab.SelectedTab.Children);
        end
        
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
                    notify(event.Data(k), 'DataHasChanged', EventData(event.idxZone(k)))                 
                end
            elseif strcmp(event.Action,'ResetMask')
                % reset mask
                for k = 1:numel(event.Data)
                   event.Data(k) = setMask(event.Data(k), event.idxZone(k));
                   % notify
                   notify(event.Data(k), 'DataHasChanged', EventData(event.idxZone(k))) 
                end
            end
        end % setMask
    end
    %% ------------------ ProcessingManager Callback ------------------- %%
    methods (Access = public)
        % Run process
        function this = runProcess(this)
            % check if data are selected
            fileID = getSelectedFile(this.FileManager);
            % according to the mode process, run it
            if isempty(fileID)
                dispMsg(this, 'Warning: You need to select data to run process!\n');
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
                dispMsg(this, 'Starting to process file...\n');
                % loop over the file
                for k = 1:numel(fileID)
                    dispMsg(this, 'Processing...');
                    % get data
                    tf = strcmp({this.RelaxData.fileID}, fileID{k});
                    data = getData(this.RelaxData(tf), 'Bloc');
 
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Could be replace by getData('Bloc')[Manu]
                    % Need to think about a smart way to avoid delete data
                    % unecessary. Maybe just keep both data until the end:
                    % 1. If bad processing: destroy relaxObj
                    % 2. If good processing: destroy bloc [Manu] 
                    
                    % create copy to avoid processing error
                    data_copy = copy(data);
%                     % get the ancestor
%                     bloc = this.RelaxData(indx(1)); %take the first one
%                     while ~isempty(bloc.parent)
%                         bloc = bloc.parent;
%                     end
%                     % create a copy of the object, for the process
%                     relaxObj = copy(bloc);
%                     if ~isempty(relaxObj.children)
%                         remove(relaxObj.children); % remove children
%                     end

                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % apply the pipeline
                    for j = 1:numel(ProcessArray) 
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % check if new process or not
                        if strcmp(data_copy(1).processingMethod, ProcessArray(j))
                            data_copy = [data_copy.children]; continue;
                        end
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % assign the process
                        assignProcessingFunction(data_copy, ProcessArray(j));
                        % apply the process
                        warning off
                        data_copy = processData(data_copy);
                        warning on
                    end   
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % No need to destroy RelaxObj. Choose between delete
                    % relaxobj or bloc and replace data in RelaxObj [Manu]
                    delete(data); this.RelaxData(tf).data_copy;
                    % replace the new relaxObj in the main array
%                     delete(this.RelaxData(indx)); this.RelaxData(indx) = [];
%                     this.RelaxData = [this.RelaxData, relaxObj];
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        
                    drawnow; %EDT
                    % replace the new relaxObj in the main array
                    setSelectedTree(this.FileManager, class(data_copy));
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Take filename from RelaxObj, not DataUnit
                    updateData(this.FileManager, this.RelaxData(tf).filename, fileID{k});
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    drawnow;
                    if isa(relaxObj, 'Dispersion')
                        idxZone = repelem(NaN, numel(data_copy));
                    else
                        idxZone = repelem(1,numel(data_copy));
                    end
                    pause(0.005);
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Same as before, take info from RelaxObj
                    checkData(this.FileManager, repmat(fileID(k),1,numel(data_copy)),...
                        {data_copy.displayName}, idxZone, 1);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    drawnow; %EDT
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Should be changed if DataUnit class do not fit with
                    % the current tab in DisplayManager: open another one?
                    % [Manu]
                    % In this case, how to deal with FileManager update...
                    
                    % try to plot
                    [~, plotFlag, ~] = addPlot(this.DisplayManager, data_copy, idxZone);
                    % check if everything have been plotted 
                    if ~plotFlag
%                         str = cellfun(@(x,y) sprintf('%s (Sequence: %s)',x,y),...
%                                 {relaxObj.filename},...
%                                 {relaxObj.sequence},'Uniform',0);
%                         warndlg(sprintf(['The following data have not been '...
%                             'displayed because their type do not fit with '...
%                             'the graph type: \n\n%s.'], sprintf('%s \n',str{:})))
                        drawnow; pause(0.05);
                        % uncheck these nodes
                        checkData(this.FileManager, repmat(fileID(k),1,numel(data_copy)),...
                            {data_copy.displayName}, idxZone, 0);
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    
                    drawnow % EDT
                    dispMsg(this, [sprintf('%d/%d',k,numel(fileID)),'\n']);
                end %for
                % notify
                notify(this.FileManager.SelectedTree, 'TreeHasChanged');
            else
                % Simulation mode
                % TO DO
            end
        end %runProcess
    end
    %% --------------------- ModelManager Callback --------------------- %%
    methods (Access = public)
        % Run Fit
        function this = runFit(this) %%%%% WARNINNNNG %%%%
            % check if data are selected
            [~, fileID, legendTag, ~] = getSelectedData(this.FileManager,[]); %%%%% WARNINNNNG %%%%
            % according to the mode process, run it
            if isempty(fileID)
                dispMsg(this, 'Warning: You need to select dispersion data to run fit\n!');
                return
            elseif this.ModelManager.gui.BatchRadioButton.Value
                dispMsg(this, 'Starting to fit file...\n');
                % Batch mode
                tab = this.ModelManager.gui.tab.SelectedTab.Children;
                % get the process array
                ModelArray = tab.ModelArray;
                 % loop over the file
                for k = 1:numel(fileID)
                    dispMsg(this, 'Fitting...');
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    tf = strcmp({this.RelaxData.fileID}, fileID{k});
                    dispersion = getData(this.RelaxData(tf), 'Dispersion', legendTag{k});
                    % Replace by getData('Dispersion') [Manu]
                    % check for correspondance (same data file)
%                     tf = strcmp(strcat({this.RelaxData.fileID},...
%                         {this.RelaxData.displayName}), strcat(fileID{k},...
%                         legendTag{k}));
                    % check if dispersion
                    if isempty(dispersion); continue; end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % apply the fit to the file
                    procObj = DispersionLsqCurveFit;
                    procObj = addModel(procObj,ModelArray);
                    assignProcessingFunction(dispersion, procObj);
                    % apply the process
                    processData(dispersion); 
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Use Wrapper? [Manu]
                    % update model name
                    dispersion.processingMethod.model.modelName = tab.Parent.Title;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % notify
                    notify(dispersion, 'DataHasChanged', EventData(NaN)) 
                    dispMsg(this, [sprintf('%d/%d',k,numel(fileID)),'\n']);
                end
                drawnow;
                updateResultTable(this.ModelManager);
                drawnow;
            else
                % Simualation mode
            end
        end %runFit
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
%             % check if UUID
%             relaxObj = checkUUID(relaxObj);
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
            
            %%% ------------------ Nested Function -------------------- %%%
%             % check if UUID is used (old fileID contains '@' and length is
%             % variable).
%             % UUID format is 32 hexadecimal digits, displayed in five
%             % groups separated by hyphens, in the form 8-4-4-4-12.
%             function relaxObj = checkUUID(relaxObj)           
%                 % loop over the input
%                 for i = 1:numel(relaxObj)
%                     % check format and size
%                     s = strsplit(relaxObj(i).fileID,'-');
%                     n = cellfun(@numel,s);
% 
%                     % generate UUID if needed
%                     if numel(n) ~= 5 || ~isequal(n, [8 4 4 4 12])
%                         relaxObj(i).fileID = char(java.util.UUID.randomUUID);
%                     end
%                 end
%             end %checkUUID
            %%% ------------------------------------------------------- %%%
        end %checkID
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % To remove [Manu]
%         % Get data from fileID: TO CHANGE
%         function data = getData(this, fileID, type)
%             % get the fileID list
%             tf = strcmp({this.RelaxData.fileID}, fileID);
%             % check if type is correct
%             data = this.RelaxData(tf);
%             while ~strcmp(class(data), type)
%                 if isempty(data(1).parent)
%                     data = []; return
%                 else
%                     data = [data.parent];
%                 end
%             end
%         end %getData
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

