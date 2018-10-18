classdef TreeManager < uiextras.jTree.CheckboxTree
    %
    % Class that manages checkboxtree in FitLike.
    %
    
    properties
        FitLike
        DatasetIcon = fullfile(matlabroot,'toolbox','matlab','icons','foldericon.gif');
        SequenceIcon = fullfile(matlabroot,'toolbox','matlab','icons','greencircleicon.gif');
        FileIcon = fullfile(matlabroot,'toolbox','matlab','icons','HDF_filenew.gif');
        RelaxObjIcon = {fullfile(matlabroot,'toolbox','matlab','icons','HDF_object02.gif'),...
                        fullfile(matlabroot,'toolbox','matlab','icons','HDF_object01.gif'),...
                        fullfile(matlabroot,'toolbox','matlab','icons','unknownicon.gif')};
    end
    
    events
        TreeUpdate
    end
    
    methods
        % Constructor
        function this = TreeManager(FitLike, varargin)
            % call superconstructor
            this = this@uiextras.jTree.CheckboxTree(varargin{:});
            % add Controller
            this.FitLike = FitLike;
            % add callback if possible
            if this.DndEnabled
                 set(this,'NodeDraggedCallback',@(s,e) DragDrop(this, s,e));
                 set(this,'NodeDroppedCallback', @(s,e) DragDrop(this, s,e));
            end
        end %TreeManager
        
        % Add new data to the tree.
        function this = add(this, DataUnit, checkFlag)
            % check input 
            tf = arrayfun(@(x) all(strcmp(superclasses(x),'DataUnit') == 0), DataUnit);
            if ~ all(tf == 0)
                error('FileManager:addData','Input type is not correct')
            end
            
            % import tree package
            import uiextras.jTree.*      
            
            % loop over the input
            for k = 1:length(DataUnit)
                % + dataset
                hDataset = checkNodeExistence(this, this.Root,...
                    DataUnit(k).dataset, this.DatasetIcon, 'dataset');
                expand(hDataset);
                % + sequence
                hSequence = checkNodeExistence(this, hDataset,...
                    DataUnit(k).sequence, this.SequenceIcon, 'sequence');
                expand(hSequence);
                % + filename
                hFile = checkNodeExistence(this, hSequence,...
                    DataUnit(k).filename, this.FileIcon, 'file');
                expand(hFile);
                % + relaxobj
                [~,~,idx] = intersect({'bloc','zone','dispersion'},...
                                            lower(class(DataUnit(k))));
                hObj = checkNodeExistence(this, hFile, DataUnit(k).displayName,...
                    this.RelaxObjIcon{idx}, ['relaxObj:',type]);
                % check flag
                if checkFlag
                    hObj.Checked = 1;
                end
            end
        end %addData 
        
        % Remove data from the tree 
        function this = remove(this, varargin)
            % check input
            if nargin < 2
                hNodes = this.CheckedNodes;
            else
                hNodes = varargin{1};
            end
            % check if nodes
            if isempty(hNodes)
                return
            end
            % loop recursively to find ancestor if alone child
            for k = 1:numel(hNodes)
                while numel(hNodes(k).Parent.Children) < 2
                    hNodes(k) = hNodes(k).Parent;
                end
            end
            % notify
            eventdata = TreeEventData('Action','Delete',...
                                      'Data',hNodes);
            notify(this, 'TreeUpdate', eventdata);
            % just delete the selected nodes and their children
            delete(hNodes);
        end %removeData 
        
        % Check node existence and create it if needed. 
        % this function also take an icon and a type (dataset, sequence,...)
        % that will be add to the new children.
        function hChildren = checkNodeExistence(this, hParent, nodeName, icon, type)
            % import tree package
            import uiextras.jTree.*
            % check if children
            if ~isempty(hParent.Children)
                % check if the wanted name corresponds to a children in the
                % parent container
                tf = strcmp(get(hParent.Children,'Name'),nodeName);
                if ~all(tf == 0)
                    hChildren = hParent.Children(tf);
                    return
                end
            end
            % add checkbox               
            hChildren = CheckboxTreeNode('Parent', hParent,...
                                         'Name', nodeName,...
                                         'Value', type);
            setIcon(hChildren,icon);
            % notify
            eventdata = TreeEventData('Action','Add',...
                                      'Parent',hParent,...
                                      'Data',hChildren);
            notify(this, 'TreeUpdate', eventdata);
        end %checkNodeExistence
        
        % Return the fileID of nodes. If no input: checked nodes.
        function fileID = nodes2fileID(this, varargin)
           % check input
           if nargin < 2
               hNodes = this.CheckedNodes;
           else
               hNodes = varargin{1};
           end
           % check if root
           if isempty(hNodes)
               fileID = [];
               return
           elseif strcmp(hNodes(1).Name, 'Root')
               hNodes = [hNodes.Children];
           end
           % get the ancestor ID
           ancestorID = TreeManager.getAncestorID(hNodes);
           % use it and get the descendant ID
           fileID = TreeManager.getDescendantID(hNodes, ancestorID);
        end
        
        % Return the nodes corresponding to the fileID list. fileID can be
        % partial (dataset@sequence, dataset@sequence@file,...).
        function hNodes = fileID2nodes(this, fileID)
            % format input and split fileID
            if isempty(fileID)
                return
            elseif numel(fileID) == 1
                str = split(fileID,'@');
            else
                if size(fileID,2) ~= 1
                    fileID = fileID';
                end
                str = split(fileID,'@');
                str = str';
            end
            % get tree root
            hRoot = this.Root;
            % loop over the fileID
            for iFile = size(str,2):-1:1
                hNodes(iFile) = hRoot;
                for iLevel = 1:size(str,1)
                    tf = strcmp(str{iLevel, iFile},{hNodes(iFile).Children.Name});
                    hNodes(iFile) = hNodes(iFile).Children(tf);
                end
            end
        end %fileID2nodes
        
        % Delete nodes from fileID
        function this = fileID2delete(this, fileID)
            % check input
            if isempty(fileID)
                return
            else
                % get the nodes and delete them
                hNodes = fileID2nodes(this, fileID);
                remove(this, hNodes);
            end    
        end %fileID2delete
        
         % Modify node from fileID. Modification can be:
         % - Name
         % - Type (Icon): bloc, zone, dispersion
         % - Checked: checkFlag (logical)
         function this = fileID2modify(this, fileID, name, type, checkFlag)
            % check input
            if isempty(fileID)
                return
            else
                % get the nodes and modify them
                hNodes = fileID2nodes(this, fileID);
                % loop over the files
                for k = 1:numel(hNodes)
                    % update name
                   if ~strcmp(hNodes(k).Name, name{k}) && ~isempty(name{k})
                       hNodes(k).Name = name{k};
                   end
                   % update icon if relaxObj
                   if contains(hNodes(k).Value, 'relaxObj') && ~isempty(type{k})
                       if ~contains(hNodes(k).Value, type{k})
                            resetIcon(this, hNodes(k), type{k});
                       end
                   end
                   % update check
                   if checkFlag
                       hNodes(k).Checked = 1;
                   end
                end
            end 
         end %fileID2modify
        
        % Check/Uncheck nodes from fileID 
        function this = fileID2check(this, fileID)
            % check input
            if isempty(fileID)
                return
            else
                % get the nodes state
                hNodes = fileID2nodes(this, fileID);
                state = cellfun(@(x) ~logical(x), {hNodes.Checked},'Uniform',0);
                % invert state
                [hNodes.Checked] = state{:};
            end            
        end %fileID2check
        
        % Set icon according to an input type
        function this = resetIcon(this, hNodes, type)
            [~,~,idx] = intersect({'bloc','zone','dispersion'},lower(type));
            setIcon(hNodes, this.RelaxObjIcon{idx});
        end %resetIcon
        
        % this function determines if the dragged target is valid or not
        % and drop the object.
        % *User can drag dataset, sequence and file
        % *File can be dropped in sequence or file
        % *Sequence can be dropped in dataset or sequence
        % *Dataset can be dropped in dataset
        function DropOk = DragDrop(this, ~, event)
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
                isChecked = logical(src.Checked);
                % check if we change nodes or not
                if src.Parent ~= target.Parent
                    % store parent handle for updating
                    hParent = src.Parent;
                    
                    % check if target type is the same as source type
                    if ~strcmp(src.Value, target.Value)
                        hChildren = target.Children;
                        new_order = [NaN 1:numel(hChildren)];
                        % get target fileID
                        ancestorID_target = TreeManager.getAncestorID(target.Children(1));
                    else
                        new_order = [1:(idxTarget-1) NaN idxTarget:numel(hChildren)];
                        % get target fileID
                        ancestorID_target = TreeManager.getAncestorID(target);
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
                    else
                        % update data
                        ancestorID_src = TreeManager.getAncestorID(src);
                        editDragDropFile(this.FitLike, ancestorID_src{1},...
                            ancestorID_target{1});
                    end
                    
                    % De-parent
                    oldParent = src.Parent;
                    src.Parent = [];
                    % reorder children
                    this.Visible = 'off';
                    TreeManager.stackNodes(hChildren, new_order, src);
                    this.Visible = 'on';
                    % notify
                    eventdata = TreeEventData('Action','DragDrop',...
                                      'Data', src,...
                                      'OldParent',oldParent,...
                                      'Parent',src.Parent,...
                                      'NewOrder',new_order);
                    notify(this,'TreeUpdate',eventdata)
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
                    this.Visible = 'off';
                    TreeManager.stackNodes(hChildren, new_order, []);
                    this.Visible = 'on';
                    % notify
                    eventdata = TreeEventData('Action','ReOrder',...
                                      'Data', hChildren,...
                                      'NewOrder',new_order);
                    notify(this,'TreeUpdate',eventdata)
                end
                % checked
                if isChecked
                   src.Checked = 1; 
                end
            end
        end %DragNodeCallback                
               
        % Reset tree: uncheck all the nodes
        function this = resetTree(this)
            % check the tree state
            if ~isempty(this.CheckedNodes)
               % uncheck
               [this.CheckedNodes.Checked] = deal(false);
            end
        end %resetTree
    end
    methods (Static)
        % This function allow to reorder nodes. A new node can also be
        % insert at the position indicates by 'NaN'.
        % Example: hNodes = stackNodes(tree, hNodes,[1 3 2]);
        %          hNodes = stackNodes(tree, hNodes,[1 3 NaN 4),newNode);
        function hNodes = stackNodes(hNodes, new_order, newNode)
            % check if a new node need to be inserted
            if isempty(newNode) && numel(hNodes) == numel(new_order)
                % re-order nodes
                hNodes = hNodes(new_order);
                % re-parent to finish the process
                for k = 1:numel(hNodes)
                    hNodes(k).Parent = hNodes(1).Parent;
                end 
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
                for k = 1:numel(hNodes)
                    hNodes(k).Parent = hParent;
                end               
            end
        end %stackNodes        
        
        % Search a specific node inside another tree
        function treeNode = searchNode(root, node)
            % check input
            if isempty(root.Children)
                treeNode = [];
                return
            end
            % start by checking the depth of search (dataset, sequence,...)
            children = root.Children;
            if strcmp(children(1).Value, node.Value)
                tf = strcmp({children.Parent.Children.Name}, node.Name);
                treeNode = root.Children(tf);
            else
                % pathway
                parent = node;
                parentNode = [];
                while ~strcmp(parent.Name, 'Root')
                    parentNode = [parent parentNode]; %#ok<AGROW>
                    parent = parent.Parent;
                end
                % now loop over the level
                treeNode = root;
                for k = 1:numel(parentNode)
                    tf = strcmp({treeNode.Children.Name}, parentNode(k).Name);
                   	treeNode = treeNode.Children(tf);
                end
            end    
        end
        
        % Get the fileID of the ancestor 
        % Example: dataset@sequence@file for a given node (file type)
        function ancestorID = getAncestorID(nodes)
            % check input
            if isempty(nodes)
                return
            end
            % check if an ancestor if available
            ancestorID = {nodes.Name};
            %loop over the input
            for k = 1:numel(nodes)
                hAncestor = nodes(k);
                % loop until we reach the root    
                while ~strcmp(hAncestor.Parent.Name,'Root')
                    hAncestor = hAncestor.Parent;
                    ancestorID{k} = [hAncestor.Name,'@',ancestorID{k}];
                end
            end
        end %getAncestorID
        
        % Get the fileID of the descendant nodes. You can directly add a
        % fileID to complete (if you use getAncestorID for instance).
        function fileID = getDescendantID(nodes, varargin)
            % check input
            if isempty(nodes)
                return
            end
            if nargin < 2
                fileID = {nodes.Name};
            else
                fileID = varargin{1};
            end
            % initialise and search recurvisely
            [fileID, ~] = searchDescendantID(nodes, fileID);
            
            % Nested function
            function [fileID, hNodes] = searchDescendantID(hNodes, fileID)
                % check children
                indx = find(~cellfun(@isempty, {hNodes.Children}));
                % check output and concatenate fileID
                if isempty(indx)
                    return
                else
                    for k = 1:numel(indx)
                        names = arrayfun(@(x) x.Name,...
                            hNodes(indx(k)).Children, 'Uniform', 0);
                        fileID{indx(k)} = strcat(repmat(strcat(fileID(indx(k)),'@'),...
                            1,numel(names)), names);
                    end 
                    %uncell
                    fileID = [fileID{:}];
                    % call the function again
                    [fileID, hNodes] = searchDescendantID([hNodes.Children], fileID);
                end
            end
        end %getDescendantID
    end   
end

