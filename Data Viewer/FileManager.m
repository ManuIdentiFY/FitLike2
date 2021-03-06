classdef FileManager  < handle
    %
    % View for FileManager in FitLike. It is a stand alone component, just
    % replace FitLike input by anything else to use it.
    % See documentation and examples for off-line usage.
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
            this.gui.treefile = TreeManager(this, 'Parent', pfile,...
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
            this.gui.treedata(1) = TreeManager(this, 'Parent', tab,...
                'Editable',false, 'DndEnabled',false,'FontSize',7,...
                'CheckboxClickedCallback',@(s,e) selectData(this, s, e),...
                'Tag','Dispersion');
            tab = uitab(this.gui.tab, 'Title', '  Zone  ');
            this.gui.treedata(2) = TreeManager(this, 'Parent', tab,...
                'Editable',false, 'DndEnabled',false,'FontSize',7,...
                'CheckboxClickedCallback',@(s,e) selectData(this, s, e),...
                'Tag','Zone');
            tab = uitab(this.gui.tab, 'Title', '  Bloc  ');
            this.gui.treedata(3) = TreeManager(this, 'Parent', tab,...
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
            
            % Check if it is a stand-alone usage or not
            if isa(this.FitLike,'FitLike')
                % Replace the close function by setting the visibility to off
                set(this.gui.fig,  'closerequestfcn', ...
                    @(src, event) this.FitLike.hideWindowPressed(src)); 
            else
                % show figure
                set(this.gui.fig,'Visible','on');
                % Replace the close function by setting the visibility to off
                set(this.gui.fig,  'closerequestfcn', ...
                    @(src, event) deleteWindow(this)); 
            end
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
            this.SelectedTree = [];
        end  %deleteWindow   
    end
    
    % Tree methods: add/delete/update
    methods
       % THIS = ADDFILE(THIS, RELAXOBJ) add new file in the treefile
       % object. RELAXOBJ should be an array of RelaxObj.
       % File are classified in a hierarchical way where the first layer is
       % dataset, second layer is sequence and third is filename.
       function this = addFile(this, relaxObj)
             % loop over the input
            for k = 1:numel(relaxObj)
                % + dataset
                hDataset = TreeManager.addNode(this.gui.treefile.Root,...
                    relaxObj(k).dataset, this.DatasetIcon, 'dataset');
                % + sequence
                hSequence = TreeManager.addNode(hDataset,...
                    relaxObj(k).sequence, this.SequenceIcon, 'sequence');
                % + filename: add handle to the relaxObj
                TreeManager.addNode(hSequence, relaxObj(k).filename,...
                    this.FileIcon, 'filename', 'UserData', relaxObj(k));
                % expand
                expand(hDataset)
                expand(hSequence)
            end
       end %addFile
       
       % THIS = DELETEFILE(THIS, RELAXOBJ) delete files from the treefile.
       % RELAXOBJ should be an array of RelaxObj. This function can be
       % called with THIS = DELETEFILE(THIS) where checked nodes are
       % deleted instead.
       function this = deleteFile(this, relaxObj)
           if nargin < 2
               % get checked nodes
               hNodes = this.gui.treefile.CheckedNodes;
           else
               for k = numel(relaxObj):-1:1
                   % find nodes
                   hNodes(k) = TreeManager.findobj(this.gui.treefile.Root,...
                       'UserData',relaxObj(k)); %search from the root
               end
           end
           
           if isempty(hNodes); return; end
           
           % clear data tree
           if ~isempty(this.SelectedTree.Root)
               delete(this.SelectedTree.Root.Children);
           end
           
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           % Could be simplify by overwriting the delete() method of the
           % TreeNode [Manu]
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
       
       % THIS = CHECKFILE(THIS, RELAXOBJ) check files corresponding to 
       % the RELAXOBJ input in the treefile. RELAXOBJ should be an array 
       % of RelaxObj. 
       function this = checkFile(this, relaxObj)
           % check input
           if isempty(relaxObj)
               return
           end
           % loop over the input
           for k = 1:numel(relaxObj)
               % get the node
               hNode = TreeManager.findobj(this.gui.treefile.Root,...
                   'UserData',relaxObj(k));
               % check and add data
               addData(this, hNode);
               hNode.Checked = 1;
           end
       end %checkFile
       
       % THIS = ADDDATA(THIS, FILENODE) add file nodes to the selected data
       % tree (visible tab). FILENODE are an array of CheckboxTree and
       % corresponds to the third layer of node of the treefile (filename
       % layer). 
       function this = addData(this, fileNode)
           % set icon for selected tree
           icon = this.RelaxObjIcon{this.gui.treedata == this.SelectedTree};
           % loop over the input
           for k = 1:numel(fileNode)
               % get the data info: displayName
               hData = getData(fileNode(k).UserData, this.SelectedTree.Tag);
               
               if ~isempty(hData)
                   % check if this file is already plotted
                   if isempty(this.SelectedTree.Root.Children)
                       tf = 0;
                   else
                        tf = isequal(fileNode(k).UserData, [this.SelectedTree.Root.Children.UserData]);
                   end
                   % copy node if required
                   if all(tf == 0)
                       hParent = copy(fileNode(k), this.SelectedTree.Root);
                       hParent.Checked = 0;
                   else
                       hParent = this.SelectedTree.Root.Children(tf);
                   end
                   % if not dispersion tab, add the zone index
                   if ~strcmp(this.SelectedTree.Tag, 'Dispersion')
                       nZone = numel(getfield(fileNode(k).UserData,'BR')); %#ok<GFLD>
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
       
       % THIS = ADDRELAXOBJ(THIS, HPARENT, ICON, NAME, NZONE) add the data
       % nodes to the parent file node. HPARENT is a CheckboxTree (file node), 
       % ICON the pathname for icons, NAME a cell array of string corresponding 
       % to the displayName properties of the data object. NZONE is a
       % scalar indicating the number of zone nodes to display. If NZONE is
       % empty (dispersion case), no zone nodes are created.
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
       
       % THIS = REMOVEDATA(THIS, RELAXOBJ) remove all the data
       % corresponding to the RELAXOBJ. RELAXOBJ is an array of RelaxObj.
       % If data nodes corresponding to the RELAXOBJ array are checked, an
       % event is throwed to indicate that data were deselected.
       function this = removeData(this, relaxObj)
           % check if files
           if isempty(this.SelectedTree.Root.Children)
               return
           end
           
           % delete nodes
           nodes = this.SelectedTree.Root.Children;
           idx = intersect([nodes.UserData], relaxObj);
           if ~isempty(idx)
               % before deletion, see if data are checked. Notify if true
               for k = 1:numel(idx)
                    % get checked nodes
                    hNodes = TreeManager.findobj(nodes(idx(k)),'Checked',1);
                    % remove nodes with children
                    hNodes = hNodes(arrayfun(@(x) isempty(x.Children), hNodes));
                    if ~isempty(hNodes)
                        % check data type
                        if strcmp(this.SelectedTree.Tag,'Dispersion')
                            % get the data and notify
                            for j = 1:numel(hNodes)
                                hData = getData(nodes(idx(k)).UserData, 'Dispersion', hNodes(j).Name);
                                % create event and notify
                                event = EventFileManager('Action','Deselect',...
                                    'Data',hData,'idxZone',NaN);
                                notify(this, 'DataSelected', event);
                                disp(hData)
                            end
                        else
                            % get the data
                            for j = 1:numel(hNodes)
                                hData = getData(nodes(idx(k)).UserData, this.SelectedTree.Tag, hNodes(j).Parent.Name);
                                idxZone = str2double(regexp(hNodes(j).Name,'\d*','match'));
                                % create event and notify
                                event = EventFileManager('Action','Deselect',...
                                    'Data',hData,'idxZone',idxZone);
                                notify(this, 'DataSelected', event);
                                disp(hData)
                                disp(idxZone)
                            end                            
                        end
                    end
               end                   
               delete(nodes(idx));
           end %isempty
       end %removeData
       
       % THIS = REMOVEDATA(THIS, DATAOBJ, IDXZONE, FLAG) check (FLAG=1) or
       % uncheck (FLAG = 0) the data nodes that corresponds to the DATAOBJ 
       % and IDXZONE. DATAOBJ is an array of DataUnit and IDXZONE a vector
       % of idxZone. If DATAOBJ is a Dispersion, IDXZONE should be NaN.
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
                if isempty(nodes) % case when some data object are adly formed
                    continue
                end
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
            % notify
            % create event
            if flag
                event = EventFileManager('Action','Select',...
                    'Data',dataObj,'idxZone',idxZone);
            else
                event = EventFileManager('Action','Deselect',...
                    'Data',dataObj,'idxZone',idxZone); 
            end
            notify(this, 'DataSelected', event);
       end % checkData
       
       % THIS = UPDATEDATA(THIS, RELAXOBJ) update all the data nodes object
       % corresponding to RELAXOBJ. RELAXOBJ is an array of RelaxObj.
       function this = updateData(this, relaxObj)
           % loop over the input
           for k = 1:numel(relaxObj)
               % get data info
                displayName = getDataInfo(relaxObj(k), this.SelectedTree.Tag);
                displayName = displayName.(this.SelectedTree.Tag);

               if ~isempty(displayName)
                   % set icon
                   icon = this.RelaxObjIcon{this.gui.treedata == this.SelectedTree};
                   % if not dispersion tab, add the zone index
                   if ~strcmp(this.SelectedTree.Tag, 'Dispersion')
                       nZone = numel(getfield(relaxObj(k),'BR')); %#ok<GFLD>
                   else
                       nZone = [];
                   end
                   % get the tree root
                   root = this.SelectedTree.Root;
                   if numel(root.Children) < 1
                           hFile = TreeManager.addNode(root,...
                               relaxObj(k).filename, this.FileIcon, 'filename',...
                               'UserData', relaxObj(k));
                           % add relaxObj
                           addRelaxObj(this, hFile, icon, displayName, nZone);
                   else
                       % check if the file exists
                       hFile = root.Children;
                       tf_file = arrayfun(@(x) isequal(x.UserData, relaxObj(k)), hFile);

                       if all(tf_file == 0)
                           % add new node
                           hFile = TreeManager.addNode(root,...
                               relaxObj(k).filename, this.FileIcon, 'filename',...
                              'UserData', relaxObj(k));
                           % add relaxObj
                           addRelaxObj(this, hFile, icon, displayName, nZone);
                       else
                           % get the file node
                           hFile = hFile(tf_file);
                           n = numel(hFile.Children);
                           % check how many relaxObj are inside the file node
                           % remove or add some relaxObj
                           if n > numel(displayName)
                               % remove some relaxObj
                               delete(hFile.Children(numel(displayName)+1:end));
                               %hRelaxObj = hRelaxObj(1:nOldRelax); %clear
                           elseif n < numel(displayName)
                               % add some relaxObj
                               addRelaxObj(this, hFile, icon,...
                                   repelem({''}, numel(displayName)- n), nZone);
                           end
                           % set new name
                           [hFile.Children.Name] = displayName{:};
                       end
                   end
                   % expand
                   expand(hFile);   
               end
           end
       end %updateData
       
       % THIS = RESET(THIS) deselected all the file nodes (and thus all the
       % data nodes).
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
       
       % THIS = ADDLABEL(THIS, ICON) add the icon defining by the ICON
       % pathway to the checked file nodes (treefile).
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
       
       % THIS = REMOVELABEL(THIS, RELAXOBJ) reset the icons of the file
       % nodes corresponding to the RELAXOBJ array (RelaxObj array).
       function this = removeLabel(this, relaxObj) 
           % reset their icon
           for k = 1:numel(relaxObj)
               hFile = TreeManager.findobj(this.gui.treefile.Root,'UserData', relaxObj(k));
               setIcon(hFile, this.FileIcon);
           end
       end %remove Label
    end
    
    % Tree methods: Data and File access
    methods       
       % THIS = SELECTFILE(THIS, ~,EVENT) callbacks that is fired when a
       % file node is checked or unchecked. It then adds or remove the
       % corresponding data nodes of the file node.
        function this = selectFile(this, ~, event) 
            % be sure to get the file
            hFile = TreeManager.getEndChild(event.CheckedNodes);
            % add or remove data according to 'checked'
            if all([hFile.Checked] == 0)
               % remove data from the data panel
               removeData(this, [hFile.UserData]);
            else
               % add data to the data panel
               addData(this, hFile);
            end
            drawnow nocallbacks
        end %selectFile
        
       % THIS = EDITFILE(THIS, ~,EVENT) callbacks that is fired when a
       % file node is edited. File nodes can also be edited is drag and
       % drop action results in the modification of the sequence or dataset
       % property. If FileManager is used in stand alone mode, the
       % corresponding RelaxObj are updated automaticaly. Else, it throws
       % an event to FitLike.
        function this = editFile(this, ~, event)
            % check if dragdrop call
            if isa(event,'EventFileManager')
                if isa(this, 'FitLike')
                    % throw event to FitLike
                    notify(this, 'FileEdited', event);
                else
                    % update directly RelaxObj
                    [event.Data.(event.Prop)] = deal(event.Value);
                end
                % check if node was edited
            elseif ~strcmp(event.OldName, event.NewName)
                % get the node type
                prop = event.Nodes.Value;
                % get the node concerned
                hFile = TreeManager.getEndChild(event.Nodes);
                % throw event
                event = EventFileManager('Data',[hFile.UserData],...
                    'Value', event.NewName,'Prop',prop);
                % check if FitLike is set
                if isa(this.FitLike, 'FitLike')
                    notify(this, 'FileEdited', event);
                else
                    % update directly RelaxObj
                    [event.Data.(event.Prop)] = deal(event.Value);
                end
            end
        end %editFile
        
       % THIS = SELECTDATA(THIS, ~,EVENT) callbacks that is fired when a
       % data node is selected or deselected. An event is then throwed to
       % FitLike.
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
            %src.Enable = 'on';
            drawnow %nocallbacks
        end %selectData
       
       % THIS = SETTREE(THIS, TYPE) allows to change manually the selected
       % data tree (visible tab). Possible TYPE input are:
       % {'Dispersion','Zone','Bloc'};
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
       
       % THIS = CHANGETREE(THIS, S,E) callbacks that is fired when the
       % selected tree is changed (visible tab). In this case, previous
       % data nodes (from the old tab) are deleted and replaced by new
       % ones based on the selected file nodes.
       function this = changeTree(this, s, e)
           % remove the children from the previous selected tree
           delete(this.SelectedTree.Root.Children);
           % set the new selected tree
           this.SelectedTree = this.gui.treedata(s.Children == e.NewValue);
           % add the checked files
           hFile = TreeManager.getEndChild(this.gui.treefile.CheckedNodes);
           
           if ~isempty(hFile)
               addData(this, hFile);
               % notify
               notify(this.SelectedTree, 'TreeHasChanged');
               drawnow nocallbacks
           end
       end %changeTree

       % RELAXOBJ = GETSELECTED(THIS) returned the selected files as an
       % array of RelaxObj. 
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
        
       % RELAXOBJ = GETSELECTEDDATA(THIS, HNODES) returned the selected
       % data as an array of DataUnit object and a vector of idxZone (if
       % hData(i) is a Dispersion, idxZone(i) = NaN). It is possible to
       % specified the HNODES (array of CheckboxTree) to get the
       % corresponding data objects.
        function [hData, idxZone] = getSelectedData(this, hNodes)
            % get checked nodes
            if nargin == 1
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
        % THIS = THROWWRAPMESSAGE(THIS, TXT) is a wrapper to throw messages
        % in the console or in the terminal in function of FitLike input.
        function this = throwWrapMessage(this, txt)
            % check FitLike
            if ~isa(this.FitLike,'FitLike')
                fprintf(txt);
            else
                notify(this.FitLike, 'ThrowMessage', EventMessage('txt',txt));
            end
        end % throwWrapMessage
        
        % THIS = throwMessage(THIS, TXT) throw a message in the console 
        % according to the input text. TXT is a char. If TXT char finished
        % by '\n' then the message is displayed as:
        % >> (previous text)
        % >> TXT
        % >>
        %
        % Else
        % >> (previous text)
        % >> TXT
        %
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

