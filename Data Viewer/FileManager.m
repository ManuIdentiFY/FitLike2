classdef FileManager < handle
    %
    % View for FileManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
    end
    
    % Icons properties
    properties
        DatasetIcon = fullfile(matlabroot,'toolbox','matlab','icons','foldericon.gif');
        SequenceIcon = fullfile(matlabroot,'toolbox','matlab','icons','greencircleicon.gif');
        FileIcon = fullfile(matlabroot,'toolbox','matlab','icons','HDF_filenew.gif');
        RelaxObjIcon = {fullfile(matlabroot,'toolbox','matlab','icons','HDF_object02.gif'),...
                        fullfile(matlabroot,'toolbox','matlab','icons','HDF_object01.gif'),...
                        fullfile(matlabroot,'toolbox','matlab','icons','unknownicon.gif')};
    end
    
    methods (Access = public)
        % Constructor
        function this = FileManager(FitLike)
            % import tree package
            import uiextras.jTree.*
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Make the figure
            this.gui.fig = figure('Name','File Manager','NumberTitle','off',...
                'MenuBar','none','ToolBar','none','Units','normalized',...
                'Position',[0.04 0.1 0.2 0.775],'Tag','fig');
            
            % Make the tree
            this.gui.tree = CheckboxTree('Parent',this.gui.fig,...
                'Editable',true, 'DndEnabled',true,...
                'NodeDraggedCallback', @(s,e) FileManager.DragDrop_Callback(this, s,e),...
                'NodeDroppedCallback', @(s,e) FileManager.DragDrop_Callback(this, s,e),...
                'MouseClickedCallback', @(s,e) this.FitLike.selectFile(s, e),...
                'Tag','tree','RootVisible',false);           
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
            %delete the figure
            delete(this.gui.fig);
            %clear out the pointer to the figure - prevents memory leaks
            this.gui = [];
        end  %deleteWindow   
    end
    
    methods (Access = public)
        % Add new data to the tree. Type is 'bloc', 'zone', 'dispersion'.
        function this = addData(this, type, dataset, sequence, filename, displayName)
            % check input type
            if ischar(dataset) && ischar(sequence) && ischar(filename) && ischar(type)
                % convert to cell
                type = {type};
                dataset = {dataset};
                sequence = {sequence};
                filename = {filename};
                displayName = {displayName};
            elseif iscell(dataset) && iscell(sequence) && iscell(filename) &&...
                    iscell(type) && iscell(displayName)
                % check if size is consistent
                if ~isequal(length(dataset),length(sequence)) ||...
                        ~isequal(length(dataset),length(filename)) ||...
                        ~isequal(length(filename),length(displayName)) ||...
                        ~isequal(length(type),length(displayName))
                    error('FileManager:addData','Input size is not consistent')
                end
            else
                error('FileManager:addData','Input type is not consistent')
            end
            
            % import tree package
            import uiextras.jTree.*      
            
            % loop over the input
            for k = 1:length(dataset)
                % + dataset
                hDataset = FileManager.checkNodeExistence(this.gui.tree.Root,...
                    dataset{k}, this.DatasetIcon, 'dataset');
                % + sequence
                hSequence = FileManager.checkNodeExistence(hDataset,...
                    sequence{k}, this.SequenceIcon, 'sequence');
                % + filename
                hFile = FileManager.checkNodeExistence(hSequence,...
                    filename{k}, this.FileIcon, 'file');
                % + relaxobj
                switch lower(type{k}) % case-insensitive
                    case 'bloc'
                        idx = 1;
                    case 'zone'
                        idx = 2;
                    case 'dispersion'
                        idx = 3;
                end
                FileManager.checkNodeExistence(hFile, displayName{k},...
                    this.RelaxObjIcon{idx}, 'relaxObj');
            end
        end %addData
        
        % Remove data from the tree. 
        function this = removeData(this, varargin)
            % just delete the selected nodes and their children
            delete(this.gui.tree.CheckedNodes);
        end %removeData       
        
        % check or delete the nodes corresponding to fileID. fileID can be
        % partial.
        % mode = {'check','delete'};
        function this = fileID2tree(this, fileID, mode)
            % format input
            if iscell(fileID)
                if size(fileID,2) ~= 1
                    fileID = fileID';
                end
                % split the fileID 
                str = split(fileID,'@');
                str = str';
            else
                % split the fileID
                str = split(fileID,'@');
            end
    
            % get tree root
            hRoot = this.gui.tree.Root;
            % loop over the fileID
            for iFile = 1:size(str,2)
                hNodes = hRoot;
                for iLevel = 1:size(str,1)
                    tf = strcmp(str{iLevel, iFile},{hNodes.Children.Name});
                    hNodes = hNodes.Children(tf);
                end
                % check the mode to apply
                switch mode
                    case 'check'
                        hNodes.Checked = 1;
                    case 'delete'
                        delete(hNodes);                        
                end
            end
        end %fileID2tree
    end
    
    % Methods to help tree construction/modification
    methods (Access = public, Static = true)       
        % Get the fileID list of the selected nodes
        function fileID = Checkbox2fileID(nodes)
            % check input
            if isempty(nodes)
                fileID = [];
                return
            end
            % initialise fileID
            fileID = [];
            % loop over the selected nodes
            for k = 1:numel(nodes)                                
                % check if the selected node is the root
                if strcmp(nodes(k).Name,'Root')
                    nodes(k) = nodes(k).Children(1);
                end
                
                % get the nodeID by looking at its ancestor
                hAncestor = nodes(k);
                nodeID = hAncestor.Name;
                
                while ~isempty(hAncestor.Parent.Parent)
                    hAncestor = hAncestor.Parent;
                    nodeID = [hAncestor.Name,'@',nodeID]; %#ok<AGROW>
                end
                % check if descendant are available
                if isempty(nodes(k).Children)
                    fileID = [fileID, {nodeID}]; %#ok<AGROW>
                    continue
                else
                    % keep the nodeID
                    currentID = nodeID;
                    % start at the first descendant
                    hDescendant = nodes(k).Children(1);
                    stopFlag = 1;
                    idx = 1;
                    while stopFlag
                        % go to the object at the same tree level
                        hDescendant = hDescendant.Parent.Children(idx);
                        % move to the next level until reaching relaxObj
                        while ~isempty(hDescendant.Children)                      
                            currentID = [currentID,'@',hDescendant.Name]; %#ok<AGROW>
                            hDescendant = hDescendant.Children(1);
                        end
                        % store the relaxObj found
                        fileID = [fileID, {[currentID,'@',hDescendant.Name]}]; %#ok<AGROW>
                        % find the index of the current obj
                        idx = find(hDescendant.Parent.Children == hDescendant);
                        % check if other branch at the same level
                        while numel(hDescendant.Parent.Children) == idx && stopFlag
                            % no more object at this level, go back
                            hDescendant = hDescendant.Parent;
                            % reset the index
                            idx = find(hDescendant.Parent.Children == hDescendant);
                            % remove the current level name
                            currentID = currentID(1:end-numel(hDescendant.Name)-1);
                            % check if we reach the end of the selection
                            if hDescendant == nodes(k) 
                                stopFlag = 0;
                            end
                        end
                        % increment to reach the nex branch
                        idx = idx + 1;
                    end % while
                end
            end %for
        end %Checkbox2fileID
        
        % this function determines if the dragged target is valid or not
        % and drop the object.
        % *User can drag dataset, sequence and file
        % *File can be dropped in sequence or file
        % *Sequence can be dropped in dataset or sequence
        % *Dataset can be dropped in dataset
        function DropOk = DragDrop_Callback(this, tree, event)
            % Is this the drag or drop part?
            DoDrop = ~(nargout); % The drag callback expects an output, drop does not

            % get source and target
            src = event.Source;
            target = event.Target;
            
            % Check if the source & target are valid:
            % *User can drag dataset, sequence and file
            % *File can be dropped in sequence or file
            % *Sequence can be dropped in dataset or sequence
            % *Dataset can be dropped in dataset
            if strcmp(src.Value,'file') &&...
                  (strcmp(target.Value,'sequence') || strcmp(target.Value,'file'))
                % file to sequence/file
                DropOk = true;
            elseif strcmp(src.Value,'sequence') &&...
                  (strcmp(target.Value,'dataset') || strcmp(target.Value,'sequence')) 
                % sequence to dataset/sequence
                DropOk = true;
            elseif strcmp(src.Value,'dataset') && strcmp(target.Value,'dataset')
                % dataset to dataset
                DropOk = true;
            else
                % invalid target or source
                DropOk = false;
            end

            % If drop is allowed
            if DoDrop && strcmpi(event.DropAction,'move')
                % Get list of children in target container
                hChildren = [target.Parent.Children];
                % Get index or source and target
                idxTarget = find(hChildren == target);
                idxSource = find(hChildren == src);
                
                % check if we change nodes or not
                if src.Parent ~= target.Parent
                    % store parent handle for updating
                    hParent = src.Parent;
                    
                    % check if target type is the same as source type
                    if ~strcmp(src.Value, target.Value)
                        hChildren = target.Children;
                        new_order = [NaN 1:numel(hChildren)];
                    else
                        new_order = [1:(idxTarget-1) NaN idxTarget:numel(hChildren)];
                    end
                    
                    % check if duplicate
                    tf = strcmp({hChildren.Name}, src.Name);
                    if ~all(tf == 0)
                        % throw warning
                        msg = sprintf(['You can not drop your %s as is in this %s '...
                            'because it already contains the same %s: %s.'],src.Value,...
                            hParent.Value, src.Value, src.Name);
                        warndlg(msg, 'Warning: duplicate');
                        return
                    end
                    
                    % De-parent
                    src.Parent = [];
                    % reorder children
                    FileManager.stackNodes(tree, hChildren, new_order, src);
                    
                    % delete old parent if no more children
                    if isempty(hParent.Children)
                        delete(hParent)
                    end
                else                 
                    % prepare re-ordering
                    new_order = 1:numel(hChildren);
                    new_order(idxTarget) = idxSource; 
                    new_order(idxSource) = idxTarget;
                    % reorder children
                    FileManager.stackNodes(tree, hChildren, new_order, []);
                end
                % update ProcessingManager
                updateTree(this.FitLike.ProcessingManager);
            end
        end %DragNodeCallback
        
        % This function allow to reorder nodes. A new node can also be
        % insert at the position indicates by 'NaN'.
        % Example: hNodes = stackNodes(tree, hNodes,[1 3 2]);
        %          hNodes = stackNodes(tree, hNodes,[1 3 NaN 4),newNode);
        function stackNodes(tree, hNodes, new_order, newNode)
            % check if a new node need to be inserted
            if isempty(newNode) && numel(hNodes) == numel(new_order)
                % re-order nodes
                hNodes = hNodes(new_order);
                % re-parent to finish the process
                FileManager.reparentNodes(tree, hNodes, hNodes(1).Parent);  
            elseif isa(newNode,'uiextras.jTree.CheckboxTreeNode')
                % get parent
                hParent = hNodes(1).Parent;
                % stack new node
                hNodes = [hNodes newNode];
                % replace scalar '0'
                new_order(isnan(new_order)) = numel(hNodes);
                % re-order nodes
                hNodes = hNodes(new_order);
                % re-parent to finish the process
                FileManager.reparentNodes(tree, hNodes, hParent);                
            end
        end %stackNodes
        
        % re-parent nodes: need to be done explicitely
        function reparentNodes(tree, hNodes, hParent)
            % set visibility of the tree 'off' to avoid display issues
            tree.Visible = 'off';
            for k = 1:numel(hNodes)
                hNodes(k).Parent = hParent;
            end
            tree.Visible = 'on';
        end %reparentNodes
        
        % Check node existence and create it if needed. 
        % this function also take an icon and a type (dataset, sequence,...)
        % that will be add to the new children.
        function hChildren = checkNodeExistence(hParent, nodeName, icon, type)
            % import tree package
            import uiextras.jTree.*
            % check if children
            if isempty(hParent.Children)
                hChildren = CheckboxTreeNode('Parent', hParent,...
                                             'Name', nodeName,...
                                             'Value', type);
                setIcon(hChildren,icon);                         
            else
                % check if the wanted name corresponds to a children in the
                % parent container
                tf = strcmp(get(hParent.Children,'Name'),nodeName);
                % if true, get the handle. If false, create new node
                if all(tf == 0)
                    hChildren = CheckboxTreeNode('Parent',hParent,...
                                                 'Name',nodeName,...
                                                 'Value',type);
                    setIcon(hChildren,icon);  
                else
                    hChildren = hParent.Children(tf);
                end
            end
        end %checkNodeExistence
    end   
end

