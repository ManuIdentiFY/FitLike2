classdef FileManager  < handle
    %
    % View for FileManager in FitLike
    %
    %
    % M.Petit - 11/2018
    % manuel.petit@inserm.fr
    
    properties
        gui % GUI (View)
        FitLike % Presenter
        SelectedTree
    end
    
    % icons 
    properties (Hidden)
        DatasetIcon = fullfile(matlabroot,'toolbox','matlab','icons','foldericon.gif');
        SequenceIcon = fullfile(matlabroot,'toolbox','matlab','icons','greencircleicon.gif');
        FileIcon = fullfile(matlabroot,'toolbox','matlab','icons','HDF_filenew.gif');
        RelaxObjIcon = {fullfile(matlabroot,'toolbox','matlab','icons','unknownicon.gif'),...
                        fullfile(matlabroot,'toolbox','matlab','icons','HDF_object01.gif'),...
                        fullfile(matlabroot,'toolbox','matlab','icons','HDF_object02.gif')};          
    end
    
    events
        DataSelected
        FileEdited
        ThrowMessage
    end
    
    methods (Access = public)
        % Constructor
        function this = FileManager(FitLike)
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Make the figure and box
            this.gui.fig = figure('Name','File Manager','NumberTitle','off',...
                'MenuBar','none','ToolBar','none','Units','normalized',...
                'Position',[0.02 0.1 0.22 0.78],'Tag','fig','Visible','off'); 
            vbox = uix.VBox('Parent',...
                uix.Grid( 'Parent', this.gui.fig, 'Spacing', 0));
            hbox = uix.HBox('Parent', vbox);
            % Make the file panel           
            pfile = uix.Panel( 'Parent', hbox,...
                        'Title', 'File directory',...
                        'Padding',2);
            this.gui.treefile = TreeManager(FitLike, 'Parent', pfile,...
                'Editable',true, 'DndEnabled',true,'FontSize',8,...
                'CheckboxClickedCallback',@(s,e) selectFile(this, s, e),...
                'ButtonUpFcn',@(s,e) editFile(this, s, e),...
                'RootVisible',false, 'Tag','treefile');
            % set the valid target for DnD
            this.gui.treefile.valid_target = {'filename',{'filename'};
                                              'sequence',{'sequence'};
                                              'dataset',{'dataset'}};
            % Make the data panel           
            dfile = uix.Panel( 'Parent', hbox,...
                        'Title', 'Data directory',...
                        'Padding',2);
            this.gui.tab = uitabgroup(dfile,'SelectionChangedFcn',@(s,e) changeTree(this, s, e));
            tab = uitab(this.gui.tab, 'Title', 'Dispersion');
            this.gui.treedata(1) = TreeManager(FitLike, 'Parent', tab,...
                'Editable',false, 'DndEnabled',false,'FontSize',7,...
                'CheckboxClickedCallback',@(s,e) selectData(this, s, e),...
                'Tag','Dispersion');
            tab = uitab(this.gui.tab, 'Title', '  Zone  ');
            this.gui.treedata(2) = TreeManager(FitLike, 'Parent', tab,...
                'Editable',false, 'DndEnabled',false,'FontSize',7,...
                'CheckboxClickedCallback',@(s,e) selectData(this, s, e),...
                'Tag','Zone');
            tab = uitab(this.gui.tab, 'Title', '  Bloc  ');
            this.gui.treedata(3) = TreeManager(FitLike, 'Parent', tab,...
                'Editable',false, 'DndEnabled',false,'FontSize',7,...
                'CheckboxClickedCallback',@(s,e) selectData(this, s, e),...
                'Tag','Bloc');   
            this.SelectedTree = this.gui.treedata(1);
            
            %  Make a console panel
            ifile = uix.Panel( 'Parent', vbox,...
                        'Title', 'Console',...
                        'Padding',2);
            this.gui.console = uicontrol('Style','edit',...
                                        'String',{'>> '},...
                                        'Enable','inactive',...
                                        'Units','normalized',...
                                        'Position',[0 0 1 1],...
                                        'Max',2,...
                                        'HorizontalAlignment','left',...
                                        'Parent',ifile);
            this.gui.jhEdit = findjobj(this.gui.console); %java wrapper
                    
            % resize
            vbox.Heights = [-3.5 -1];
            hbox.Widths = [-1.5 -1];
            drawnow;                      
            %%-------------------------CALLBACK--------------------------%%
            % Replace the close function by setting the visibility to off
            set(this.gui.fig,  'closerequestfcn', ...
                @(src, event) this.FitLike.hideWindowPressed(src)); 
        end %FileManager
        
        % Destructor
        function deleteWindow(this)
            %remove the closerequestfcn from the figure, this prevents an
            %infitie loop with the following delete command
            set(this.gui.fig,  'closerequestfcn', '');
            %delete the object
            delete(this.gui.fig);
            % clear pointer
            this.gui = [];
        end  %deleteWindow   
    end
    
    % Tree methods: add/delete/update
    methods
       % add file. OK [14/01/19]
       function this = addFile(this, relaxObj)
             % loop over the input
            for k = 1:length(relaxObj)
                % + dataset
                hDataset = TreeManager.addNode(this.gui.treefile.Root,...
                    relaxObj(k).dataset, this.DatasetIcon, 'dataset');
                % + sequence
                hSequence = TreeManager.addNode(hDataset,...
                    relaxObj(k).sequence, this.SequenceIcon, 'sequence');
                % + filename: add handle to the relaxObj
                TreeManager.addNode(hSequence, relaxObj(k).filename,...
                    this.FileIcon, 'filename', 'UserData', relaxObj(k));
                %hFile.UserData = relaxObj(k).fileID;
                % expand
                expand(hDataset)
                expand(hSequence)
            end
       end %addFile
        
       % delete file. OK [14/01/19]
       function this = deleteFile(this, relaxObj)
           if nargin < 2
               % get checked nodes
               hNodes = this.gui.treefile.CheckedNodes;
           else
               for k = numel(relaxObj):-1:1
                   % find nodes
                   hNodes(k) = search(this, relaxObj(k));
               end
           end
           
           if isempty(hNodes); return; end
           
           % clear data tree
           if ~isempty(this.SelectedTree.Root)
               delete(this.SelectedTree.Root.Children);
           end
           
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           % Could be simplify by overwriting the delete() method of the
           % TreeNode and this condition. [Manu]
           % root
           for k = 1:numel(hNodes)
               if isempty(hNodes(k).Parent)
                   delete(hNodes(k).Children);
                   this.gui.treefile.Root.Checked = 0;
               else
                   delete(hNodes(k));
               end   
           end
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       end %deleteFile
       
       % check file.
       function this = checkFile(this, relaxObj)
           % check input
           if isempty(relaxObj)
               return
           end
           % loop over the input
           for k = 1:numel(relaxObj)
               % get the node
               hNode = search(this.gui.treefile, relaxObj(k));
               % check and add data
               addData(this, [hNode.UserData]);
               hNode.Checked = 1;
           end
       end %checkFile
       
       % add data. OK [14/01/19]
       function this = addData(this, relaxObj)
           % set icon for selected tree
           icon = this.RelaxObjIcon{this.gui.treedata == this.SelectedTree};
           % loop over the input
           for k = 1:numel(relaxObj)
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % get the data info: displayName
               hData = getData(relaxObj(k), this.SelectedTree.Tag);
               %datainfo = getFileInfo(this.FitLike, hFile(k).UserData);
               %fld = fieldnames(datainfo);
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % check if data
               %tf = strcmp(fld, this.SelectedTree.Tag);
               
               if ~isempty(hData)
                   % add file
                   hParent = TreeManager.addNode(this.SelectedTree.Root,...
                        relaxObj(k).filename, this.FileIcon, 'filename',...
                        'UserData',relaxObj(k));
                   % if not dispersion tab, add the zone index
                   if ~strcmp(this.SelectedTree.Tag, 'Dispersion')
                       nZone = numel(getfield(relaxObj(k),'ZONE')); %#ok<GFLD>
                   else
                       nZone = [];
                   end
                   % add relaxObj
                   addRelaxObj(this, hParent, icon, {hData.displayName}, nZone);
                   % expand
                   expand(hParent);
               end
           end %for file
       end %addData
       
       % add relaxobj. name is a cell array 1xN displayName. nZone is a
       % scalar indicating the number of zone in the relaxObj. OK [14/01/19]
       function this = addRelaxObj(this, hParent, icon, name, nZone)
           % check if idx are included
           if ~isempty(nZone)
               for i = 1:numel(name)
                   hChildren = TreeManager.addNode(hParent,...
                          name{i}, icon, 'dataObj'); 
                  for j = 1:nZone
                      TreeManager.addNode(hChildren,...
                          sprintf('%s %d',this.SelectedTree.Tag, j), [], 'idx');
                  end
               end
           else
               for i = 1:numel(name)
                   TreeManager.addNode(hParent,...
                          name{i}, icon, 'dataObj'); 
               end
           end
       end %addRelaxObj
       
       % remove data. OK [14/01/19]
       function this = removeData(this, relaxObj)
           % check if files
           if isempty(this.SelectedTree.Root.Children)
               return
           end
           % loop over the fileID
           for k = 1:numel(relaxObj)
               %search and delete
               nodes = this.SelectedTree.Root.Children;
               tf = arrayfun(@(x) isequal(x.UserData, relaxObj), nodes);
               if ~all(tf == 0)
                   delete(nodes(tf));
               end
           end         
       end %removeData
       
       % check data. dataObj is a DataUnit object.
       function this = checkData(this, dataObj, idxZone, flag)
            % check input
            if isempty(dataObj)
                return
            end
            % loop over the input
            for k = 1:numel(dataObj)
                % get the node file
                nodes = this.SelectedTree.Root.Children;
                tf = arrayfun(@(x) isequal(x.UserData, dataObj(k).relaxObj), nodes);
                hData = nodes(tf).Children;
                if isnan(idxZone(k))
                    tf = strcmp({hData.Name}, dataObj(k).displayName);
                    if ~all(tf == 0) && ~flag
                        hData(tf).Checked = 0;
                    elseif ~all(tf == 0)
                        hData(tf).Checked = 1;
                    end
                else
                    tf = strcmp({hData.Name}, dataObj(k).displayName);
                    hData = hData(tf).Children;
                    tf = cellfun(@(str) strcmp(regexp(str,'\d*','match'),...
                                        num2str(idxZone(k))), {hData.Name});
                    if ~all(tf == 0) && ~flag
                        hData(tf).Checked = 0;
                    elseif ~all(tf == 0)
                        hData(tf).Checked = 1;
                    end
                end
            end 
       end % checkData
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % update data if dataobj is changed. dataObj is a DataUnit.
       function this = updateData(this, relaxObj)
           
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           % get data info
%            datainfo = getFileInfo(this.FitLike, fileID);
%            fld = fieldnames(datainfo);
%            % check if data
%            tf = strcmp(fld, this.SelectedTree.Tag);
            displayName = getDataInfo(relaxObj, this.SelectedTree.Tag);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
           if ~isempty(displayName)
               % set icon
               icon = this.RelaxObjIcon{this.gui.treedata == this.SelectedTree};
               % if not dispersion tab, add the zone index
               if ~strcmp(this.SelectedTree.Tag, 'Dispersion')
                   nZone = numel(getfield(relaxObj,'ZONE')); %#ok<GFLD>
               else
                   nZone = [];
               end
               % get the tree root
               root = this.SelectedTree.Root;
               if numel(root.Children) < 1
                   % add new node
                   hFile = TreeManager.addNode(root,...
                       relaxObj.filename, this.FileIcon, 'filename',...
                       'UserData', relaxObj);
%                    hFile.UserData = fileID;
                   % add relaxObj
                   addRelaxObj(this, hFile, icon, nZone);
               else
                   % check if the file exists
                   hFile = root.Children;
                   tf_file = arrayfun(@(x) isequal(x.UserData, relaxObj), hFile);
                   
                   if all(tf_file == 0)
                       % add new node
                       hFile = TreeManager.addNode(root,...
                           relaxObj.filename, this.FileIcon, 'filename',...
                          'UserData', relaxObj);
%                        hFile.UserData = fileID;
                       % add relaxObj
                       addRelaxObj(this, hFile, icon, nZone);
                   else
                       % get the file node
                       hFile = hFile(tf_file);
                       hRelax = hFile.Children;
                       % check how many relaxObj are inside the file node
                       % remove or add some relaxObj
                       if numel(hRelax) > numel(displayName)
                           % remove some relaxObj
                           delete(hRelax(numel(displayName)+1:end));
                           hRelax(numel(displayName)+1:end) = []; %clear
                           %hRelaxObj = hRelaxObj(1:nOldRelax); %clear
                       elseif numel(hRelax) < numel(displayName)
                           % add some relaxObj
                           addRelaxObj(this, hFile, icon,...
                               repmat({''},1,1:numel(displayName)-numel(hRelax)), nZone);
                       end
                       % set new name
                       [hRelax.Name] = displayName{:};
                   end
               end
               % expand
               expand(hFile);   
           end
       end %updateData
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       % reset tree: unchecked all nodes. OK [14/01/19]
       function this = reset(this)
          % get the file tree
          hNodes = this.gui.treefile.CheckedNodes;
          % reset
          if ~isempty(hNodes)
               [hNodes.Checked] = deal(false);
          end
          % clear data tree
          if ~isempty(this.SelectedTree.Root)
              delete(this.SelectedTree.Root.Children);
          end
       end %reset
       
       % add label to the selected nodes. OK [14/01/19]
       function this = addLabel(this, icon)
           % get the selected nodes (files)
           hFile = TreeManager.getEndChild(this.gui.treefile.CheckedNodes);
           
           if ~isempty(hFile)
               % set label
               for k = 1:numel(hFile)
                   setIcon(hFile(k), icon);
               end
           end
       end %addLabel
       
       % remove label. OK [14/01/19]
       function this = removeLabel(this, relaxObj) 
           % reset their icon
           for k = 1:numel(relaxObj)
               hFile = search(this.gui.treefile, relaxObj(k));
               setIcon(hFile, this.FileIcon);
           end
       end %remove Label
    end
    
    % Tree methods: Data and File access
    methods       
        % select file  OK [14/01/19]
        function this = selectFile(this, ~, event) 
            % be sure to get the file
            hFile = TreeManager.getEndChild(event.CheckedNodes);
            % add or remove data according to 'checked'
            %src.Enable = 'off';
            if all([hFile.Checked] == 0)
               % fire event
               for k = 1:numel(hFile)
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   % get all the data corresponding to the relaxObj
                   hData = getData(hFile(k).UserData, this.SelectedTree.Tag);
                   
                   if isempty(hData); continue; end
                   
                   % if not dispersion tab, notify for each index
                   if ~strcmp(this.SelectedTree.Tag, 'Dispersion')
                       % get the number of zone
                       nZone = numel(getfield(hFile(k).UserData,'ZONE')); %#ok<GFLD>
                       idxZone = repmat(1:nZone,1,numel(hData));
                       hData = repelem(hData, nZone);
                   else
                       idxZone = nan(1,numel(hData));
                   end
                   
                   % create event and notify
                   event = EventFileManager('Action','Deselect',...
                       'Data',hData,'idxZone',idxZone);
                   notify(this, 'DataSelected', event);

%                        
%                    hData = search(this.SelectedTree, hFile(k).UserData);
%                    if ~isempty(hData)
%                        % get 
%                        legendTag = {hData.Children.Name};
%                        removeData(this.FitLike, this.SelectedTree.Tag,...
%                               repmat({hData.UserData},1,numel(legendTag)),...
%                               legendTag, repelem(NaN, 1, numel(legendTag)));
%                    end
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               end
               % remove data from the data panel
               removeData(this, [hFile.UserData]);
            else
               % add data to the data panel
               addData(this, [hFile.UserData]);
            end
            drawnow nocallbacks
            %src.Enable = 'on';
        end %selectFile
        
        % edit file  OK [14/01/19]
        function this = editFile(this, ~, event)
            % check if dragdrop call
            if isa(event,'EventFileManager')
                notify(this, 'FileEdited', event);
            % check if node was edited
            elseif ~strcmp(event.OldName, event.NewName)
                % get the node type
                prop = event.Nodes.Value;
                % get the node concerned
                hFile = TreeManager.getEndChild(event.Nodes);
                % throw event
                event = EventFileManager('Data',[hFile.UserData],...
                    'Value', event.NewName,'Prop',prop);
                notify(this, 'FileEdited', event);
            end  
        end %editFile
        
        % select data  OK [14/01/19]
        function this = selectData(this, ~, event)
            % get the selected data
            [hData, idxZone] = getSelectedData(this, event.CheckedNodes);
            % fire event
            %src.Enable = 'off';
            if all([event.CheckedNodes.Checked] == 0)
                % create event
                event = EventFileManager('Action','Deselect',...
                    'Data',hData,'idxZone',idxZone);
            else
                % create event
                event = EventFileManager('Action','Select',...
                    'Data',hData,'idxZone',idxZone);
            end
            % notify
            notify(this, 'DataSelected', event);
            notify(this.SelectedTree, 'TreeHasChanged');
            %src.Enable = 'on';
            drawnow nocallbacks
        end %selectData
       
       % set the selected tree  OK [14/01/19]
       function this = setTree(this, type)
           % check if different
           if strcmpi(this.SelectedTree.Tag, type)
               return
           end
           % get the tab titles and change the selected tree
           tabtitle = strtrim(get(this.gui.tab.Children,'Title'));
           tf = strcmp(tabtitle, type);
           % check if possible
           if all(tf == 0)
               return
           end
           % set the selected tree
           if this.SelectedTree ~= this.gui.treedata(tf)    
               this.gui.tab.SelectedTab = this.gui.tab.Children(tf);
               changeTree(this, this.gui.tab, struct('NewValue', this.gui.tab.SelectedTab));
           end
       end %setTree
       
       % callback when selected tree is modified  OK [14/01/19]
       function this = changeTree(this, s, e)
           % remove the children from the previous selected tree
           delete(this.SelectedTree.Root.Children);
           % set the new selected tree
           this.SelectedTree = this.gui.treedata(s.Children == e.NewValue);
           % add the checked files
           hFile = TreeManager.getEndChild(this.gui.treefile.CheckedNodes);
           addData(this, [hFile.UserData]);
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           % Move to FitLike! [Manu]
           % check if we need to check data
%            [dataObj, idxZone] = getTabData(this.FitLike);
%            checkData(this, dataObj, idxZone, 1);
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
           % notify
           notify(this.SelectedTree, 'TreeHasChanged');
           drawnow nocallbacks
       end %changeTree

        % Throw the relaxObj selected  OK [14/01/19]
        function relaxObj = getSelectedFile(this)
            % get checked nodes
            hNodes = this.gui.treefile.CheckedNodes;
            % check input
            if isempty(hNodes)
                relaxObj = [];
            else
                hFiles = TreeManager.getEndChild(hNodes);
                relaxObj = [hFiles.UserData];
            end
        end %getSelectedFile
        
        % Throw the DataUnit selected and their zone index  OK [14/01/19]
        function [hData, idxZone] = getSelectedData(this, hNodes)
            % get checked nodes
            if nargin < 1 || isempty(hNodes)
                hNodes = this.SelectedTree.CheckedNodes;
            end
            % check input
            if isempty(hNodes)
                hData = []; idxZone = [];
            else
                % get data
                hNodes = TreeManager.getEndChild(hNodes);
                % get the fileID
                for k = numel(hNodes):-1:1
                    % define the zone index and get the associated DataUnit
                    if strcmp(hNodes(k).Value, 'idx')
                        hData(k) = getData(hNodes(k).Parent.Parent.UserData,...
                            this.SelectedTree.Tag, hNodes(k).Parent.Name);
                        idxZone(k) = str2double(regexp(hNodes(k).Name,'\d*','match'));
                    else
                        hData(k) = getData(hNodes(k).Parent.UserData,...
                            this.SelectedTree.Tag, hNodes(k).Name);
                        idxZone(k) = NaN;
                    end
                end
            end
        end %getSelectedData
    end
    
    % Console methods: add text
    methods
        % Wrapper to throw messages in the console or in the terminal in
        % function of FitLike input.
        function this = throwWrapMessage(this, txt)
            % check FitLike
            if ~isa(this.FitLike,'FitLike')
                fprintf(txt);
            else
                notify(this, 'ThrowMessage', EventMessage('txt',txt));
            end
        end % throwWrapMessage
        
        % Throw a message in the console according to the input text.
        % Messages are automaticaly formatted as:
        % >> (previous text)
        % >> txt
        % >>
        function this = throwMessage(this, txt)
            % get previous text
            msg = this.gui.console.String;
            % check if we need to add new line or not
            if ~contains(txt,'\n')
                % add new txt
                msg{end} = [msg{end}, txt];
            else
                % add new txt and line
                txt = strrep(txt,'\n','');
                msg{end} = [msg{end}, txt];
                msg = [msg;{'>> '}];
            end
            % add new one
            set(this.gui.console, 'String', msg); drawnow;
            % get the Java object and move the position to the end
            jEdit = this.gui.jhEdit.getComponent(0).getComponent(0);
            javaMethodEDT('setCaretPosition', jEdit, jEdit.getDocument.getLength);
        end %throwMessage
    end 
end

