classdef TreeManager < uiextras.jTree.CheckboxTree
    %
    % Extension of the checkboxtree class from Robyn Jackey.
    % https://fr.mathworks.com/matlabcentral/fileexchange/47630-tree-controls-for-user-interfaces
    % Adaptation to the FileManager tree(s)
    %
    % M. Petit - 11/2018
    % manuel.petit@inserm.fr
    
    properties
        FitLike
    end
    
    properties (Hidden)
        valid_target % define the valid target for each source
    end
    
    events
       TreeHasChanged        
    end
    
    methods (Access= public)
        % Constructor
        function this = TreeManager(FitLike, varargin)
            % call superconstructor
            this = this@uiextras.jTree.CheckboxTree(varargin{:});
            % add Controller
            this.FitLike = FitLike;
            % add callback if possible
            if this.DndEnabled
                 set(this,'NodeDraggedCallback',@(s,e) DragDrop(this,s,e));
                 set(this,'NodeDroppedCallback', @(s,e) DragDrop(this,s,e));
            end
        end %TreeManager
        
        % this function determines if the dragged target is valid or not
        % and drop the object.
        % VALID_TARGET input defines if the target is valid according
        % to the source (can be empty). The property Value is used to do
        % the comparison.
        % VALID_TARGET is a Nx2 cell array if non empty where the first
        % column if the source and the second, a cell array,
        % the single or multiple target(s).
        function DropOk = DragDrop(this, ~, event)
            % Is this the drag or drop part?
            DoDrop = ~(nargout); % The drag callback expects an output, drop does not

            % get source and target
            src = event.Source;
            target = event.Target;
            
            % check if the target is valid according to the source selected
            if ~isempty(this.valid_target)
                % find which source is activated
                tf = strcmp(src.Value, this.valid_target(:,1));
                
                if all(tf == 0)
                    error('Source is unknown!');
                end
                
                % check if the current target is one of the possible valid target
                if ~all(strcmp(target.Value, this.valid_target{tf,2}) == 0)
                    DropOk = true;
                else
                    DropOk = false;
                end
            else
                DropOk = true;
            end

            % If drop is allowed
            if DoDrop && strcmpi(event.DropAction,'move')
                % Get list of children in target container
                hChildren = [target.Parent.Children];
                % Get index or source and target
                idxTarget = find(hChildren == target);
                idxSource = find(hChildren == src);
                isChecked = logical(src.Checked);
                % check if we change the parent node
                if src.Parent ~= target.Parent
                    % store parent handle for updating
                    hParent = src.Parent;                    
                    % set the new order
                    new_order = [1:(idxTarget-1) NaN idxTarget:numel(hChildren)];
                    
                    % check if duplicate
                    tf = strcmp({hChildren.Name}, src.Name);
                    if ~all(tf == 0)
                        % throw warning
                        msg = sprintf(['You can not drop your %s as is in this %s '...
                            'because it already contains the same %s: %s.'],src.Value,...
                            hParent.Value, src.Value, src.Name);
                        dispMsg(this.FitLike, msg);
                        return
                    else
                        % update data
                        nodes = TreeManager.getEndChild(src);
                        target_node = target;
                        while ~isempty(target_node.Parent.Parent)
                            target_node = target_node.Parent;
                            editFile(this.FitLike, {nodes.UserData},...
                                target_node.Value, target_node.Name);   
                        end
                    end
                    
                    % De-parent
                    src.Parent = [];
                    % reorder children
                    this.Visible = 'off';
                    TreeManager.stackNodes(hChildren, new_order, src);
                    this.Visible = 'on';
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
                end

                % re-check node if needed
                if isChecked
                   src.Checked = 1; 
                end
            end
        end %DragDrop 
        
        % Search node based on its tag (userdata). Stop at the first node!
        function hNode = search(this, tag)
            % search recursively along the tree
            hNode = visit(this.Root, tag, this.Root);
            
            %%% ---- Nested function ----- %%%
            function currentNode = visit(currentNode, tag, stopNode)
                % check the currentNode
                if isempty(currentNode)
                    return
                elseif strcmp(currentNode.UserData, tag)
                    return
                else
                    % check if children
                    while ~isempty(currentNode.Children)
                        currentNode = currentNode.Children(1);
                        if strcmp(currentNode.UserData, tag)
                            return
                        end
                    end
                    % push and visit
                    currentNode = TreeManager.push(currentNode, stopNode);
                    currentNode = visit(currentNode, tag, stopNode);
                end
            end %visit
        end %search
    end
    
    % Adapt the edit/check methods:
    % *1 click on node activates the edit mode
    % *1 click on the checkbox activates the check mode
    %
    % Here multiple and unwanted calls are manage using a modified version of 
    % isMultipleCall() from http://undocumentedmatlab.com/ website.  
    methods (Access = protected)
        % Overwrite the checked box method to avoid multiple call (add the
        % static method isMultipleCall(). Also get the checked node instead
        % of all the checked nodes.
        function onCheckboxClicked(tObj,~)   
            
            % Avoid multiple calls
            if TreeManager.isMultipleCall('onCheckboxClicked');  return;  end
            
            if callbacksEnabled(tObj)  
                
                % Get the position of the mouse
                pos = tObj.jTree.getMousePosition();
                
                if isempty(pos)
                    return
                end
                
                x = pos.getX();
                y = pos.getY();    
                
                % Was a tree node clicked?
                treePath = tObj.jTree.getPathForLocation(x,y);
                if ~isempty(treePath)
                    % get node
                    nObj = get(treePath.getLastPathComponent,'TreeNode');
                    % Prepare the event data
                    e1 = struct('CheckedNodes',nObj);
                    % Call the custom callback
                    hgfeval(tObj.CheckboxClickedCallback, tObj, e1); 
                end
                
                % EDT
                drawnow;
            end %if callbacksEnabled(tObj)            
        end
        
        % Overwrite the button up method to edit nodes with only one
        % click.
        function onButtonUp(tObj,e)
            
            % Avoid multiple calls
            if TreeManager.isMultipleCall('onButtonUp');  return;  end
            
            % Is there a custom ButtonUpFcn?
            if callbacksEnabled(tObj) && ~isempty(tObj.ButtonUpFcn)
                
                % Get the click position
                x = e.getX;
                y = e.getY;
                
                % Was a tree node clicked?
                nObj = getNodeFromMouseEvent(tObj,e); 
                
                % If it is a node, edit it
                if ~isempty(nObj)
                    
                    % get the current name
                    oldName = nObj.Name;
                    % Edit the selected nodes
                    treePath = tObj.jTree.getPathForLocation(x,y); 
                    tObj.jTree.startEditingAtPath(treePath)
                    % wait until the path is not edit anymore
                    while tObj.jTree.isEditing
                        pause(0.001);
                    end
                    % avoid edit/selection problem. Remove the node
                    % from selection.
                    tObj.jTree.removeSelectionPath(treePath);
                    % get new name and call the custom callback
                    newName = nObj.Name;
                    e1 = struct('Nodes',nObj,...
                        'OldName',oldName,'NewName',newName);
                    hgfeval(tObj.ButtonUpFcn, tObj, e1);
                end
                drawnow;
            end
        end
    end
    
    methods (Static)
         % Function from http://undocumentedmatlab.com/ website.
         % Modified to handle multiple callbacks call (here edit and
         % check).
         function flag = isMultipleCall(CallbackName)
             % create a persistent variable that keep in memory a previous
             % and specific function call (here onCheckboxClicked).
             persistent n
                         
             flag = false;
             
             if strcmp('onCheckboxClicked', CallbackName)
                 n = 1;
             elseif ~isempty(n)
                 % if the persistent variable is not empty, previous call
                 % was made with the specific function (onCheckboxClicked).
                 flag = true;
                 clear n
                 return
             else
                 clear n
                 return
             end
             
             % Get the stack
             s = dbstack();
             if numel(s) <= 2
                 % Stack too short for a multiple call
                 return
             end
             
             % How many calls to the calling function are in the stack?
             names = {s(:).name};
             TF = strcmp(s(2).name, names(2:end));
             count = sum(TF);
             
             if count>1
                 % More than 1
                 flag = true;
             end
        end
                 
        % add new nodes. Pass to children nodes if duplicates.
        function hChildren = addNode(hParent, name, icon, type)
            % check if children
            if ~isempty(hParent.Children)
                % check if the wanted name corresponds to a children in the
                % parent container
                tf = strcmp(get(hParent.Children,'Name'), name);
                if ~all(tf == 0)
                    hChildren = hParent.Children(tf);
                    return
                end
            end
            % add checkbox               
            hChildren = uiextras.jTree.CheckboxTreeNode('Parent', hParent,...
                                         'Checked',0,...
                                         'Name', name,...
                                         'Value', type);
            if ~isempty(icon)
                setIcon(hChildren, icon);
            end
        end % addNode
        
        % get all deepest child (root is automaticaly removed)
        function hChildren = getEndChild(hParent)
            % loop over the input
            if isempty(hParent)
                return
            end
            % init
            for k = numel(hParent):-1:1
                if isempty(hParent(k).Children)
                    hChildren{k} = hParent(k); 
                else
                    % search recursively along the tree
                    [hChildren{k}, ~] = visit(hParent(k), [], hParent(k));
                end
            end       
            % uncell
            hChildren = [hChildren{:}];
            
            %%% ---- Nested function ----- %%%
            function [hChild, currentNode] = visit(currentNode, hChild, hStop)
                % check the currentNode
                if isempty(currentNode)
                    return
                else
                    % check if children
                    while ~isempty(currentNode.Children)
                        currentNode = currentNode.Children(1);
                    end
                    % add child (not if root)
                    if ~isempty(currentNode.Parent)
                        hChild = [hChild, currentNode];
                    end
                    % push and visit
                    currentNode = TreeManager.push(currentNode, hStop);
                    [hChild, currentNode] = visit(currentNode, hChild, hStop);
                end
            end %visit
        end %getEndChild
        
        % function that find the next left node according to a current
        % node (backtracking). The function is called recursively until a new node is
        % found.
        function currentNode = push(currentNode, stopNode)
            % check the current node 
            if isequal(stopNode, currentNode)
                currentNode = []; %stop node
                return
            end
            ancestor = currentNode.Parent;
            % get the node position
            idx = find(ancestor.Children == currentNode);
            % go to the next child if possible and check
            if numel(ancestor.Children) ~= idx
                currentNode = ancestor.Children(idx+1);
            else
                % call recursively push
                currentNode = TreeManager.push(ancestor, stopNode);
            end
        end %push
        
        % This function allow to reorder nodes. A new node can also be
        % insert at the position indicates by 'NaN'.
        % Example: hNodes = stackNodes(hNodes,[1 3 2]);
        %          hNodes = stackNodes(hNodes,[1 3 NaN 4),newNode);
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
     end
end

