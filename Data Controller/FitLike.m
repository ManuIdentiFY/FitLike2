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
            
            % Set visible the main windows
            this.FileManager.gui.fig.Visible = 'on';
            this.DisplayManager.gui.fig.Visible = 'on';
            this.ModelManager.gui.fig.Visible = 'on';
            %%%-----------%%%
            % call open
%             open(this);
%             loadPipeline(this.ProcessingManager);
%             this.ProcessingManager.gui.tree.UserData.Root.Children.Children(3).Checked = 1;
%             runProcess(this);
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
        function this = open(this)
            % open interface to select files
            %%%%---------------------%%%%
            [file, path, indx] = uigetfile({'*.sdf','Stelar Raw Files (*.sdf)';...
                                     '*.sef','Stelar Processed Files (*.sef)';...
                                     '*.mat','FitLike Dataset (*.mat)'},...
                                     'Select One or More Files', ...
                                     'MultiSelect', 'on');
            
%             path = 'C:/Users/Manu/Desktop/FFC-NMR/FFC-NMR DATA/PIGS/SAIN/2/';
%             file = {'20170728_cochonsain2_corpscalleux2_ML.sdf',...
%                     '20170728_cochonsain2_corpscalleux4_ML.sdf',...
%                     '20170728_cochonsain2_corpscalleux2_QP_ML.sdf'};
%             indx = 1;
            %%%%---------------------%%%%
            % check output
            if isequal(file,0)
                % user canceled
                return
            elseif ischar(file)
                file = {file};
            end
            % initialisation
            bloc = [];
            % switch depending on the type of file
            switch indx
                case 1 %sdf
                    % enter dataset
                    if isempty(this.RelaxData)
                        %%%-------------%%%
%                         dataset = inputdlg({'Enter a dataset name:'},...
%                             'Create dataset',[1 70],{'myDataset'});
                        
                        dataset = 'myDataset';
                        %%%-------------%%%
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
                        % check version and select the correct reader
                        ver = checkversion(filename);
                        if isequal(ver,1)
                            [data, parameter] = readsdfv1(filename);
                        else
                            [data, parameter] = readsdfv2(filename);
                        end
                        % get the data
                        y = cellfun(@(x,y) complex(x,y), data.real, data.imag,...
                            'UniformOutput',0);
                        name = getfield(parameter,'FILE','ForceCellOutput','True');
                        sequence = getfield(parameter,'EXP','ForceCellOutput','True');
                        % format the output
                        new_bloc = Bloc('x',data.time,'y',y,...
                            'xLabel',repmat({'Time'},1,length(name)),...
                            'yLabel',repmat({'Signal'},1,length(name)),...
                            'parameter',num2cell(parameter),...
                            'filename',name,'sequence',sequence,...
                            'dataset',repmat(dataset,1,length(name)));
                        % check duplicates
                        if ~isempty(this.RelaxData)
                            new_bloc = checkDuplicates(this, new_bloc);
                        end
                        % append them to the current data
                        bloc = [bloc new_bloc]; %#ok<AGROW>
                    end
                case 2 %sef
                    % enter dataset
                    if isempty(this.RelaxData)
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
                        % format the output
                        new_bloc = Dispersion('x',x,'xLabel','Magnetic Field (MHz)',...
                            'y',y,'dy',dy,'yLabel','Relaxation Rate R_1 (s^{-1})',...
                            'filename',file{i},'sequence','Unknown','dataset',dataset);
                        % check duplicates
                        if ~isempty(this.RelaxData)
                            new_bloc = checkDuplicates(this, new_bloc);
                        end
                        % append them to the current data
                        bloc = [bloc new_bloc]; %#ok<AGROW>
                    end
                case 3 %mat
                    for i = 1:length(file)
                        filename = [path file{i}];
                        % read the .mat file
                        obj = load(filename);
                        var = fieldnames(obj);
                        % check duplicates
                        new_bloc = obj.(var{1});
                        if ~isempty(this.RelaxData)
                            new_bloc = checkDuplicates(this, new_bloc);
                        end
                        % append them to the current data
                        bloc = [bloc new_bloc]; %#ok<AGROW>
                    end
            end
            % append data to RelaxData
            this.RelaxData = [this.RelaxData bloc];
            % update FileManager
            add(this.FileManager.gui.tree, bloc, 0);
                %%-------------------------------------------------------%%
                % Check if duplicates are imported and let the user decides
                % if we keep them and add '_bis' to their filename or just
                % remove them from the current array of object "bloc".
                function bloc = checkDuplicates(this, bloc)
                    % check if duplicates have been imported
                    [~,idx,~] = intersect({bloc.fileID}, {this.RelaxData.fileID});
                    if ~isempty(idx)
                        % create a cell array of string with:
                        % 'filename' (Sequence: 'sequence')
                        listDuplicate = arrayfun(@(x) sprintf(['%s\t'...
                            '(Sequence: %s)'],x.filename,x.sequence),...
                            bloc(idx),'UniformOutput',0);
                        % ask the user what to do
                        answer = questdlg(sprintf(['The following files '...
                           'are already stored in FitLike:\n\n%s\nDo you '...
                           'still want to keep them or not?\n'...
                           'Note: Filename will be changed if Yes'],...
                           sprintf('%s \n',listDuplicate{:})),...
                           'Importation','Yes','No','No');
                       if strcmp(answer,'Yes')
                           % rename bloc: add '_bis'
                           new_filename = arrayfun(@(x) [x.filename '_bis'],...
                               bloc(idx),'UniformOutput',0);
                           [bloc(idx).filename] = new_filename{:};
                       else
                           % delete duplicated
                           bloc(idx) = [];
                       end
                    end
                end %checkDuplicated
                %%-------------------------------------------------------%%
        end %open
        
        % Remove funcion: allow to remove files, sequence, dataset
        function this = remove(this)
            % check the selected files in FileManager
            fileID = nodes2fileID(this.FileManager.gui.tree);
            % remove files in RelaxData 
            [~,idx,~] = intersect({this.RelaxData.fileID},fileID);
            this.RelaxData = remove(this.RelaxData, idx);
            % update FileManager
            remove(this.FileManager.gui.tree);
        end %remove
        
        % Export function: allow to export data (dispersion, model)
        function export(this, src)
            
        end %export
        
        % Save function: allow to save all data in .mat dataset
        function save(this)
            relaxData = this.RelaxData; %#ok<NASGU>
            uisave('relaxData','data');
            disp('File saved!')
        end %save

        %%% Edit Menu
        % Move function: allow to move files to another sequence, dataset
        function this = move(this)
            
        end %move
        
        % Copy function : allow to copy files to another sequence, dataset
        function this = copy(this)
            
        end %copy
        
        % Sort function: allow to sort files, sequence or dataset
        function this = sort(this, src)
            
        end %sort
        
        % Merge function: allow to merge/unmerge files
        function this = merge(this)
            % get the selected files
            fileID = nodes2fileID(this.FileManager.gui.tree);
            [~,indx,~] = intersect({this.RelaxData.fileID}, fileID);
            % check if files are already merged or not
            if all(cellfun(@isempty,  {this.RelaxData(indx).subUnitList}) == 1)
                % check if their dataset/sequence are the same
                if ~all(strcmp({this.RelaxData(indx).dataset},...
                               this.RelaxData(indx(1)).dataset) == 1) ||... 
                   ~all(strcmp({this.RelaxData(indx).sequence},...
                               this.RelaxData(indx(1)).sequence) == 1)
                    % ask user
                    warning('Not done yet!')
                    return                      
                end
                % merge files
                mergedFile = merge(this.RelaxData(indx));
                % update tree
                fileID = [this.RelaxData(indx(1)).dataset,'@',...
                          this.RelaxData(indx(1)).sequence,'@',...
                          this.RelaxData(indx(1)).filename];
                fileID2modify(this.FileManager.gui.tree,...
                    {fileID}, {mergedFile.filename}, {[]}, 0);
                fileID2delete(this.FileManager.gui.tree, {this.RelaxData(indx(2:end)).fileID});
                % update model
                remove(this.RelaxData, indx);
                this.RelaxData = [this.RelaxData mergedFile];
            elseif all(cellfun(@isempty,  {this.RelaxData(indx).subUnitList}) == 0)
                % unmerged files
                for k = 1:numel(indx)
                    relaxList = unMerge(this.RelaxData(indx(k)));
                    % update tree
                    fileID = [this.RelaxData(indx(k)).dataset,'@',...
                          this.RelaxData(indx(k)).sequence,'@',...
                          this.RelaxData(indx(k)).filename];
                    % check if label
                    if ~isempty(relaxList(1).label)
                        name = ['[',relaxList(1).label,'] ',relaxList(1).filename];
                    else
                        name = relaxList(1).filename;
                    end
                    fileID2modify(this.FileManager.gui.tree,...
                        {fileID}, {name}, {[]}, 0);
                    add(this.FileManager.gui.tree, relaxList(2:end), 0);
                    % update model
                    remove(this.RelaxData, indx(k));
                    this.RelaxData = [this.RelaxData, relaxList];
                end
            else
               warning('Not done yet!') 
               return
            end
        end %merge       
        
        %%% View Menu
        % Axis function: allow to set the axis scaling
        function this = setAxis(this, src)
            
        end %setAxis
        
        % Plot function: allow to plot data by name or label
        function this = setPlot(this, src)
            
        end %setPlot
        
        % CreateFig function: allow to export current axis in new figure
        function createFig(this)
            % get the handle of the selected tab
            h = this.DisplayManager.gui.tab.SelectedTab;
            % call createFig() in the concerned tab
            createFig(h.Children);
        end %createFig
        
        
        %%% Tool Menu
        % Filter function: allow to apply filters on data
        function this = applyFilter(this)
            
        end %applyFilter
        
        % Mean function: allow to average files in a new one
        function this = average(this)
            
        end %average
        
        % Normalise: allow to normalise data
        function this = normalise(this)
            
        end %normalise
        
        % BoxPlot: allow to plot model results as boxplot
        function this = boxplott(this)
            
        end %boxplott
        
        
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
        % File selection callback
        function selectFile(this, ~, event)
            % check the current action: select or edit
            if strcmp(event.Action,'NodeChecked')
                % avoid problems: enable 'off'
                %src.Enable = 'off';
                % get the fileID list of the checked object
                fileID = nodes2fileID(this.FileManager.gui.tree, event.Nodes);
                % get the corresponding index
                [~,indx,~] = intersect({this.RelaxData.fileID}, fileID);
                % check the state of the node
                if event.Nodes.Checked
                    % add data to current plot
                    [~, plotFlag, tf] = addPlot(this.DisplayManager, this.RelaxData(indx));
                    % check if everything have been plotted 
                    if ~plotFlag
                        str = cellfun(@(x,y) sprintf('%s (Sequence: %s)',x,y),...
                                {this.RelaxData(indx(tf)).filename},...
                                {this.RelaxData(indx(tf)).sequence},'Uniform',0);
                        warndlg(sprintf(['The following data have not been '...
                            'displayed because their type do not fit with '...
                            'the graph type: \n\n%s.'], sprintf('%s \n',str{:})))
                        drawnow; pause(0.05);
                        % uncheck these nodes
                        fileID2check(this.FileManager.gui.tree,...
                            {this.RelaxData(indx(tf)).fileID});
                    end
                else
                    % add data from the current plot
                    removePlot(this.DisplayManager, this.RelaxData(indx));
                end
                % enable tree
                %src.Enable = 'on';  
            elseif strcmp(event.Action,'NodeEdited')
                % check if the node has been edited
                if ~strcmp(event.NewName, event.OldName)
                    oldName = event.OldName;
                    newName = event.NewName;
                    % check if file
                    if strcmp(event.Nodes.Value, 'file')
                        % check if label
                        idx = strfind(event.OldName,']');
                        if ~isempty(idx)
                            label = [event.OldName(1:idx(1)),' '];
                            % check if the label exists in the new name
                            if ~contains(event.NewName, label)
                                warndlg('You can not modify the label of the filename.')
                                drawnow;
                                event.Nodes.Name = event.OldName;
                                return
                            elseif numel(idx) > 1 ||...
                                    any(contains(event.NewName,'@')) ||...
                                    numel(strfind(event.NewName,'[')) > 1
                                warndlg('You can not use ''@'' in any name and ''['' or '']'' for the filename.')
                                drawnow;
                                event.Nodes.Name = event.OldName;
                                return
                            end
                           oldName = strtrim(oldName(idx+1:end));
                           newName = strtrim(newName(idx+1:end));
                        end
                    elseif any(contains(event.NewName,'@'))
                        warndlg('You can not use @ in the sequence or dataset name.')
                        drawnow;
                        event.Nodes.Name = event.OldName;
                        return
                    end

                    PROP_LIST = {'dataset','sequence','filename','displayName'};
                    % get the path ID of the nodes and split it
                    ancestorID = TreeManager.getAncestorID(event.Nodes);
                    ancestorID = strtrim(strsplit(ancestorID{1},'@'));
                    ancestorID = [ancestorID(1:end-1), oldName];
                    % get the selection by looping over the properties
                    tf = true(size(this.RelaxData));
                    for k = 1:numel(ancestorID)
                        tf = tf & strcmp({this.RelaxData.(PROP_LIST{k})},...
                            ancestorID{k});
                    end
                    % now update the data
                    [this.RelaxData(tf).(PROP_LIST{k})] = deal(strtrim(newName));
                    % notify
                    eventdata = TreeEventData('Action','UpdateName',...
                                  'Parent',event.Nodes.Parent,...
                                  'OldName',event.OldName,...
                                  'NewName',event.NewName);
                    notify(this.FileManager.gui.tree, 'TreeUpdate', eventdata);
                end
            end
        end %selectFile
        
        % Callback to update data when using DragDrop method
        function editDragDropFile(this, oldFileID, newFileID)
            PROP_LIST = {'dataset','sequence','filename','displayName'};
            % get the corresponding object
            oldFileID = strsplit(oldFileID,'@');
            tf = true(size(this.RelaxData));
            for k = 1:numel(oldFileID)
                tf = tf & strcmp({this.RelaxData.(PROP_LIST{k})},...
                    oldFileID{k});
            end
            % update their properties
            newFileID = strsplit(newFileID,'@');
            for k = 1:numel(newFileID)-1
                [this.RelaxData(tf).(PROP_LIST{k})] = deal(newFileID{k});
            end
        end %editDragDropFile
        
        % Callback right-click: add label
        function addLabel(this, ~, ~)
            % ask user
            answer = inputdlg({'Enter a label (avoid @, [, ]):'},...
                'Label input',[1 40],{'0'});
            % check output and set it
            if isempty(answer)
                return
            elseif contains(answer{1},{'@','[',']'})
                warndlg('The following character are not allowed: @, [, ].')
                return
            else 
                % get the selected file nodes and update their name
                hNodes = this.FileManager.gui.tree.SelectedNodes;
                % if sequence, dataset update all the children
                while ~strcmp(hNodes(1).Value, 'file')
                    hNodes = get(hNodes, 'Children');
                    if iscell(hNodes)
                        hNodes = [hNodes{:}];
                    end
                end
                PROP_LIST = {'dataset','sequence','filename','displayName'};
                % update name
                for k = 1:numel(hNodes)
                    name = hNodes(k).Name;
                    % remove previous label
                    idx = strfind(name,']');
                    if ~isempty(idx)
                        new_name = strtrim(name(idx+1:end));
                    else
                        new_name = strtrim(name);
                    end
                    % update model
                    ancestorID = TreeManager.getAncestorID(hNodes(k));
                    ancestorID = strtrim(strsplit(ancestorID{1},'@'));
                    ancestorID{end} = new_name;
                    % replace it
                    new_name = ['[',strtrim(answer{1}),'] ',new_name]; %#ok<AGROW>
                    hNodes(k).Name = new_name;
                    % get the selection by looping over the properties
                    tf = true(size(this.RelaxData));
                    for i = 1:numel(ancestorID)
                        tf = tf & strcmp({this.RelaxData.(PROP_LIST{i})},...
                            ancestorID{i});
                    end
                    % now update the data
                    [this.RelaxData(tf).label] = deal(strtrim(answer{1}));
                    % notify
                    eventdata = TreeEventData('Action','UpdateName',...
                                      'Parent',hNodes(k).Parent,...
                                      'OldName',name,...
                                      'NewName',new_name);
                    notify(this.FileManager.gui.tree, 'TreeUpdate', eventdata);
                end
            end
        end %addLabel
    end   
    %% -------------------- DisplayManager Callback -------------------- %% 
    methods (Access = public)
        % Tab selection callback
        function selectTab(this, src)
            % get the selected tab
            hTab = src.SelectedTab.Children;
            resetTree(this.FileManager.gui.tree);
            if isa(hTab,'EmptyPlusTab')
                % add new tab
                addTab(this.DisplayManager);
            elseif isa(hTab,'EmptyTab')
                % dumb
            elseif isa(hTab,'DispersionTab')
                % get the fileID plotted and check them
                fileID2check(this.FileManager.gui.tree, getFileID(hTab));
            end
        end %selectTab
        
        % Mask data
        function setMask(~, ~, event)
            if strcmp(event.Action,'SetMask')
                % get boundaries
                xmin = event.XRange(1); xmax = event.XRange(2);
                ymin = event.YRange(1); ymax = event.YRange(2);
                % define mask
                mask = arrayfun(@(data) data.mask &...
                                        ~((xmin < data.x & data.x < xmax) &...
                                          (ymin < data.y & data.y < ymax)),...
                                         event.Data,'Uniform',0);
                [event.Data.mask] = mask{:};
                % notify
                notify(event.Data, 'DataHasChanged')
            elseif strcmp(event.Action,'ResetMask')
                % reset mask
                mask = arrayfun(@(data) true(size(data.y)),...
                            event.Data,'Uniform',0);
                [event.Data.mask] = mask{:};
                % notify
                notify(event.Data, 'DataHasChanged')
            end
        end % setMask
    end
    %% ------------------ ProcessingManager Callback ------------------- %%
    methods (Access = public)
        % Run process
        function this = runProcess(this)
            % check if data are selected
            tree = this.ProcessingManager.gui.tree;
            fileID = nodes2fileID(tree, tree.CheckedNodes);
            % according to the mode process, run it
            if isempty(fileID)
                warndlg('You need to select file to run process!','Warning')
                return
            elseif this.ProcessingManager.gui.BatchRadioButton.Value
                % Batch mode
                tab = this.ProcessingManager.gui.tab.SelectedTab.Children;
                % check the selected pipeline
                tf = ProcessTab.checkProcess(tab);
                % check output
                if ~tf
                    return
                end
                % get the process array
                ProcessArray = flip(tab.ProcessArray);
                % loop over the file
                for k = 1:numel(fileID)
                    % get fileID
                    ifileID = split(fileID{k},'@');
                    % check for correspondance
                    indx = find(strcmp(ifileID{1},{this.RelaxData.dataset}) &... 
                        strcmp(ifileID{2},{this.RelaxData.sequence}) &... 
                        strcmp(ifileID{3},{this.RelaxData.filename}));
                    % get the ancestor
                    bloc = this.RelaxData(indx(1)); %take the first one
                    while ~isempty(bloc.parent)
                        bloc = bloc.parent;
                    end
                    % create a copy of the object, for the process
                    relaxObj = copy(bloc);
                    if ~isempty(relaxObj.children)
                        remove(relaxObj.children); % remove children
                    end
                    % apply the pipeline
                    for j = 1:numel(ProcessArray) 
                        % assign the process
                        assignProcessingFunction(relaxObj, ProcessArray(j));
                        % apply the process
                        relaxObj = processData(relaxObj);
                    end                        
                    % replace the new relaxObj in the main array
                    this.RelaxData = remove(this.RelaxData, indx);
                    this.RelaxData = [this.RelaxData, relaxObj];
                    % update FileManager
                    hParent = fileID2nodes(this.FileManager.gui.tree, fileID(k));
                    hNodes = hParent.Children;
                    n = numel(hNodes);
                    m = numel(relaxObj);
                    if n < m
                        nodes2modify(this.FileManager.gui.tree, hNodes,...
                            {relaxObj(1:n).displayName}, repmat({class(relaxObj)},1,n), 1); 
                        add(this.FileManager.gui.tree, relaxObj(n+1:end), 1);
                    elseif n > numel(relaxObj)
                        nodes2modify(this.FileManager.gui.tree, hNodes,...
                            {relaxObj.displayName}, repmat({class(relaxObj)},1,m), 1); 
                        remove(this.FileManager.gui.tree, hNodes(m+1));
                    else
                        nodes2modify(this.FileManager.gui.tree, hNodes,...
                            {relaxObj.displayName}, repmat({class(relaxObj)},1,n), 1);                     
                    end
                    % try to plot
                    [~, plotFlag, ~] = addPlot(this.DisplayManager, relaxObj);
                    % check if everything have been plotted 
                    if ~plotFlag
                        str = cellfun(@(x,y) sprintf('%s (Sequence: %s)',x,y),...
                                {relaxObj.filename},...
                                {relaxObj.sequence},'Uniform',0);
                        warndlg(sprintf(['The following data have not been '...
                            'displayed because their type do not fit with '...
                            'the graph type: \n\n%s.'], sprintf('%s \n',str{:})))
                        drawnow; pause(0.05);
                        % uncheck these nodes
                        fileID2check(this.FileManager.gui.tree,{relaxObj.fileID});
                    end
                end %for
            else
                % Simulation mode
                % TO DO
            end
        end %runProcess
    end
    
    methods (Access = public, Static = true)
        
    end
    %% --------------------- ModelManager Callback --------------------- %%
    methods (Access = public)
        % Run Fit
        function this = runFit(this)
            % check if data are selected
            tree = this.ModelManager.gui.tree;
            fileID = nodes2fileID(tree, tree.CheckedNodes);
            % according to the mode process, run it
            if isempty(fileID)
                warndlg('You need to select file to run process!','Warning')
                return
            elseif this.ModelManager.gui.BatchRadioButton.Value
                % Batch mode
                tab = this.ModelManager.gui.tab.SelectedTab.Children;
                % get the process array
                ModelArray = tab.ModelArray;
                 % loop over the file
                for k = 1:numel(fileID)
                    % check for correspondance
                    tf = strcmp(fileID{k},{this.RelaxData.fileID});
                    % apply the fit to the file
                    procObj = DispersionLsqCurveFit;
                    procObj = addModel(procObj,ModelArray);
                    assignProcessingFunction(this.RelaxData(tf), procObj);
                    % apply the process
                    processData(this.RelaxData(tf)); 
                    % update model name
                    this.RelaxData(tf).processingMethod.model.modelName = tab.TabTitle;
                end
                % notify    
                [~,~,idx] = intersect(fileID,{this.RelaxData.fileID});
                notify(this.RelaxData(idx), 'DataHasChanged');
                updateResultTable(this.ModelManager);
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
    end
end

