classdef FileManager2  < handle
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
    
    methods (Access = public)
        % Constructor
        function this = FileManager2(FitLike)
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
            this.gui.treefile = TreeManager2(FitLike, 'Parent', pfile,...
                'Editable',true, 'DndEnabled',true,'FontSize',8,...
                'CheckboxClickedCallback',@(s,e) selectFile(this, s, e),...
                'ButtonUpFcn',@(s,e) editFile(this, s, e),...
                'RootVisible',false, 'Tag','treefile');
            
            % Make the data panel           
            dfile = uix.Panel( 'Parent', hbox,...
                        'Title', 'Data directory',...
                        'Padding',2);
            this.gui.tab = uitabgroup(dfile,'SelectionChangedFcn',@(s,e) changeTree(this, s, e));
            tab = uitab(this.gui.tab, 'Title', 'Dispersion');
            this.gui.treedata(1) = TreeManager2(FitLike, 'Parent', tab,...
                'Editable',false, 'DndEnabled',false,'FontSize',7,...
                'CheckboxClickedCallback',@(s,e) selectData(this, s, e),...
                'Tag','dispersion');
            tab = uitab(this.gui.tab, 'Title', '  Zone  ');
            this.gui.treedata(2) = TreeManager2(FitLike, 'Parent', tab,...
                'Editable',false, 'DndEnabled',false,'FontSize',7,...
                'CheckboxClickedCallback',@(s,e) selectData(this, s, e),...
                'Tag','zone');
            tab = uitab(this.gui.tab, 'Title', '  Bloc  ');
            this.gui.treedata(3) = TreeManager2(FitLike, 'Parent', tab,...
                'Editable',false, 'DndEnabled',false,'FontSize',7,...
                'CheckboxClickedCallback',@(s,e) selectData(this, s, e),...
                'Tag','bloc');   
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
            this.gui.jhEdit = findjobj(this.gui.console); %java wraper
                    
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
       % add file
       function this = addFile(this, DataUnit)
             % loop over the input
            for k = 1:length(DataUnit)
                % + dataset
                hDataset = TreeManager2.addNode(this.gui.treefile.Root,...
                    DataUnit(k).dataset, this.DatasetIcon, 'dataset');
                % + sequence
                hSequence = TreeManager2.addNode(hDataset,...
                    DataUnit(k).sequence, this.SequenceIcon, 'sequence');
                % + filename
                hFile = TreeManager2.addNode(hSequence,...
                    DataUnit(k).filename, this.FileIcon, 'filename');
                hFile.UserData = DataUnit(k).fileID;
                % expand
                expand(hDataset)
                expand(hSequence)
            end
       end %addFile
        
       % delete file. If no input, delete checked nodes. Else, use 
       % cell array of fileID.
       function this = deleteFile(this)
           % get checked nodes
           hNodes = this.gui.treefile.CheckedNodes;
           if isempty(hNodes)
               return
           end
           % get fileID and clear other trees
           hFile = TreeManager2.getEndChild(hNodes);
           removeData(this, {hFile.UserData});
           % root
           if isempty(hNodes.Parent)
               delete(hNodes.Children);
               this.gui.treefile.Root.Checked = 0;
           else
               delete(hNodes);
           end     
       end %deleteFile
       
       % check file.
       function this = checkFile(this, fileID)
           % check input
           if isempty(fileID)
               return
           end
           % loop over the input
           for k = 1:numel(fileID)
               % get the node
               hNode = search(this.gui.treefile, fileID{k});
               % check and add data
               addData(this, hNode);
               hNode.Checked = 1;
           end
       end %checkFile
       
       % add data
       function this = addData(this, hFile)
           % set icon for selected tree
           icon = this.RelaxObjIcon{this.gui.treedata == this.SelectedTree};
           % loop over the input
           for k = 1:numel(hFile)
               % get the data info: displayName
               datainfo = getFileInfo(this.FitLike, hFile(k).UserData);
               fld = fieldnames(datainfo);
               % check if data
               tf = strcmp(fld, this.SelectedTree.Tag);
               
               if ~all(tf == 0) && ~isempty(datainfo.(fld{tf}))
                   % add file
                   hParent = TreeManager2.addNode(this.SelectedTree.Root,...
                        hFile(k).Name, this.FileIcon, 'filename'); % WHY CHECKED?
                   hParent.UserData = hFile(k).UserData;
                   % add relaxObj
                   addRelaxObj(this, hParent, icon, datainfo.(fld{tf}));
                   % expand
                   expand(hParent);
               end
           end %for file
       end %addData
       
       % add relaxobj. name is a cell array 1x1 or 1x2 where
       % *name{1}: name of the relaxobj (cell array)
       % *name{2}: name of the idx (cell array)
       function this = addRelaxObj(this, hParent, icon, name)
           % check if idx are included
           if numel(name) > 1
               for i = 1:numel(name{1})
                   hChildren = TreeManager2.addNode(hParent,...
                          name{1}{i}, icon, 'relaxObj'); 
                  for j = 1:numel(name{2})
                      TreeManager2.addNode(hChildren,...
                          name{2}{j}, [], 'idx');
                  end
               end
           else
               for i = 1:numel(name{1})
                   TreeManager2.addNode(hParent,...
                          name{1}{i}, icon, 'relaxObj'); 
               end
           end
       end %addRelaxObj
       
       % remove data.
       function this = removeData(this, fileID)
           % check if files
           if isempty(this.SelectedTree.Root.Children)
               return
           end
           % loop over the fileID
           for k = 1:numel(fileID)
               %search and delete
               nodes = this.SelectedTree.Root.Children;
               tf = strcmp({nodes.UserData}, fileID(k));
               if ~all(tf == 0)
                   delete(nodes(tf));
               end
           end         
       end %removeData
       
       % check data
       function this = checkData(this, fileID, name, idx, flag)
            % check input
            if isempty(fileID)
                return
            end
            % loop over the input
            for k = 1:numel(fileID)
                % get the node file
                nodes = this.SelectedTree.Root.Children;
                tf = strcmp({nodes.UserData}, fileID(k));
                hData = nodes(tf).Children;
                if isnan(idx(k))
                    tf = strcmp({hData.Name}, name{k});
                    if ~all(tf == 0) && ~flag
                        hData(tf).Checked = 0;
                    elseif ~all(tf == 0)
                        hData(tf).Checked = 1;
                    end
                else
                    tf = strcmp({hData.Name}, name{k});
                    hData = hData(tf).Children;
                    tf = cellfun(@(str) strcmp(regexp(str,'\d*','match'),...
                                        num2str(idx(k))), {hData.Name});
                    if ~all(tf == 0) && ~flag
                        hData(tf).Checked = 0;
                    elseif ~all(tf == 0)
                        hData(tf).Checked = 1;
                    end
                end
            end 
       end % checkData
       
       % update data if dataobj defined by fileID changed.
       function this = updateData(this, filename, fileID)
           % get data info
           datainfo = getFileInfo(this.FitLike, fileID);
           fld = fieldnames(datainfo);
           % check if data
           tf = strcmp(fld, this.SelectedTree.Tag);
           
           if ~all(tf == 0) && ~isempty(datainfo.(fld{tf}))
               % set icon
               icon = this.RelaxObjIcon{this.gui.treedata == this.SelectedTree};
               % get the tree root
               root = this.SelectedTree.Root;
               if numel(root.Children) < 1
                   % add new node
                   hFile = TreeManager2.addNode(root,...
                       filename, this.FileIcon, 'filename');
                   hFile.UserData = fileID;
                   % add relaxObj
                   addRelaxObj(this, hFile, icon, datainfo.(fld{tf}))
               else
                   % check if the file exists
                   hFile = root.Children;
                   tf_file = strcmp({hFile.UserData}, fileID);
                   
                   if all(tf_file == 0)
                       % add new node
                       hFile = TreeManager2.addNode(root,...
                           filename, this.FileIcon, 'filename');
                       hFile.UserData = fileID;
                       % add relaxObj
                       addRelaxObj(this, hFile, icon, datainfo.(fld{tf}));
                   else
                       % get the file node
                       hFile = hFile(tf_file);
                       hRelaxObj = hFile.Children;
                       % check how many relaxObj are inside the file node
                       nOldRelax = numel(hRelaxObj);
                       nNewRelax = numel(datainfo.(fld{tf}){1});
                       % remove or add some relaxObj
                       if nOldRelax > nNewRelax
                           % remove some relaxObj
                           delete(hRelaxObj(nNewRelax+1:end))
                           hRelaxObj(nNewRelax+1:end) = []; %clear
                           %hRelaxObj = hRelaxObj(1:nOldRelax); %clear
                       elseif nOldRelax < nNewRelax
                           name = datainfo.(fld{tf});
                           name{1} = name{1}(1:nNewRelax-nOldRelax);
                           % add some relaxObj
                           addRelaxObj(this, hFile, icon, name)
                       end
                       % set new name
                       [hRelaxObj.Name] = datainfo.(fld{tf}){1}{:};
                   end
               end
               % expand
               expand(hFile);   
           end
       end %updateData
       
       % reset file tree: unchecked all nodes
       function this = resetFileTree(this)
          % get the file tree
          hNodes = this.gui.treefile.CheckedNodes;
          % reset
          if ~isempty(hNodes)
               [hNodes.Checked] = deal(false);
          end
          % delete all data nodes
          for k = 1:numel(this.gui.treedata)
              delete(this.gui.treedata(k).Root.Children);
              this.gui.treedata(k).Root.Checked = 0;
          end                  
       end %resetFileTree
    end
    
    % Tree methods: Data and File access
    methods       
        function this = selectFile(this, src, event)
            % be sure to get the file
            hFile = TreeManager2.getEndChild(event.CheckedNodes);
            % add or remove data
            src.Enable = 'off';
            if all([hFile.Checked] == 0)
               % fire event
               for k = 1:numel(hFile)
                   hData = search(this.SelectedTree, hFile(k).UserData);
                   legendTag = {hData.Children.Name};
                   removeData(this.FitLike, this.SelectedTree.Tag,...
                          repmat({hData.UserData},1,numel(legendTag)),...
                          legendTag, repelem(NaN, 1, numel(legendTag)));
               end
               % remove data from the data panel
               removeData(this, {hFile.UserData});
            else
               % add data to the data panel
               addData(this, hFile);
            end
            drawnow nocallbacks
            src.Enable = 'on';
        end %selectFile
        
        function this = editFile(this, ~, event)
            % check if node was edited
            if ~strcmp(event.OldName, event.NewName)
                 % get the node type
                propname = event.Nodes.Value;
                % get the node concerned
                hFile = TreeManager2.getEndChild(event.Nodes);
                % throw event
                editFile(this.FitLike, {hFile.UserData}, propname,...
                                event.NewName); 
            end  
        end %editFile
        
        function this = selectData(this, src, event)
            % get the selected data
            [hData, fileID, legendTag, idx] = getSelectedData(this, event.CheckedNodes);
            % fire event
            src.Enable = 'off';
            if all([hData.Checked] == 0)
                   removeData(this.FitLike, this.SelectedTree.Tag,...
                        fileID, legendTag, idx);
            else
                   addData(this.FitLike, hData, this.SelectedTree.Tag,...
                        fileID, legendTag, idx);
            end
            src.Enable = 'on';
            drawnow nocallbacks
        end %selectData
       
       % set the selected tree
       function this = setSelectedTree(this, type)
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
       end %setSelectedTree
       
       % callback when selected tree is modified
       function this = changeTree(this, s, e)
           % remove the children from the previous selected tree
           delete(this.SelectedTree.Root.Children);
           % set the new selected tree
           this.SelectedTree = this.gui.treedata(s.Children == e.NewValue);
           % get the checked nodes
           hFile = TreeManager2.getEndChild(this.gui.treefile.CheckedNodes);
           addData(this, hFile);
           % check if we need to check data
           [~, fileID, name, idx] = getTabData(this.FitLike);
           checkData(this, fileID, name, idx, 1);
           drawnow nocallbacks
       end %changeTree

        % Throw the fileID of the selected file
        function fileID = getSelectedFile(this)
            % get checked nodes
            hNodes = this.gui.treefile.CheckedNodes;
            % check input
            if isempty(hNodes)
                fileID = [];
            else
                hFiles = TreeManager2.getEndChild(hNodes);
                fileID = {hFiles.UserData};
            end
        end %getSelectedFile
        
        % Throw the fileID of the selected file
        function [hData, fileID, legendTag, idx] = getSelectedData(this, hNodes)
            % get checked nodes
            if nargin < 1 || isempty(hNodes)
                hNodes = this.SelectedTree.CheckedNodes;
            end
            % check input
            if isempty(hNodes)
                fileID = []; legendTag = []; idx = [];
            else
                % get data
                hData = TreeManager2.getEndChild(hNodes);
                % get the fileID
                for k = numel(hData):-1:1
                    if strcmp(hData(k).Value, 'idx')
                        fileID{k} = hData(k).Parent.Parent.UserData;
                        legendTag{k} = hData(k).Parent.Name;
                        idx(k) = str2double(regexp(hData(k).Name,'\d*','match'));
                    else
                        fileID{k} = hData(k).Parent.UserData;
                        legendTag{k} = hData(k).Name;
                        idx(k) = NaN;
                    end
                end
            end
        end %getSelectedData
    end
    
    % Console methods: add text
    methods
        % Throw a message in the console according to the input text.
        % Messages are automaticaly formatted as:
        % >> (previous text)
        % >> txt
        % >>
        function this = throwMessage(this, txt)
            % get previous text
            msg = this.gui.console.String;
            % complete the last one with the new txt
            msg{end} = [msg{end}, txt];
            msg = [msg;{'>> '}];
            % add new one
            set(this.gui.console, 'String', msg); drawnow;
            % get the Java object and move the position to the end
            jEdit = this.gui.jhEdit.getComponent(0).getComponent(0);
            javaMethodEDT('setCaretPosition', jEdit, jEdit.getDocument.getLength);
        end %throwMessage
    end 
end
