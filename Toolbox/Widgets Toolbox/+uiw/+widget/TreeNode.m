classdef TreeNode < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    % TreeNode - Node for a tree control
    %
    % Create a tree node object to be placed on a uiw.widget.Tree control.
    %
    % Syntax:
    %   nObj = uiw.widget.TreeNode
    %   nObj = uiw.widget.TreeNode('Property','Value',...)
    %

    %   Copyright 2012-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $  $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------

    
    %% Properties
    properties (AbortSet, Dependent)
        Name %Name to display on the tree node
        Value %User value to store in the tree node
        TooltipString %Tooltip text on mouse hover
        UserData %User data to store in the tree node
    end

    properties (AbortSet)
        Parent = uiw.widget.TreeNode.empty(0,1) %Parent tree node
        UIContextMenu %context menu to show when clicking on this node
    end
    
    properties (SetAccess=protected)
        Children = uiw.widget.TreeNode.empty(0,1) %Child tree nodes (read-only)
        Tree = uiw.widget.Tree.empty(0,1) %Tree on which this node is attached (read-only)
    end
    
    
    %% Internal properties

    properties (SetAccess=protected, GetAccess=protected)
        IsBeingDeleted = false; %true when the destructor is active (internal)
    end

    % The node needs to be accessible by the tree and nodes
    properties (SetAccess={?uiw.widget.Tree, ?uiw.widget.TreeNode},...
            GetAccess={?uiw.widget.Tree, ?uiw.widget.TreeNode})
        JNode %Java object for tree node
    end

    

    %% Constructor / Destructor
    methods
        
        function nObj = TreeNode(varargin)
            % Construct the node
            
            % Create a tree node for this element
            nObj.JNode = handle(javaObjectEDT('com.mathworks.consulting.widgets.tree.TreeNode'));
            
            % Add properties to the java object for MATLAB data
            schema.prop(nObj.JNode,'Value','MATLAB array');
            schema.prop(nObj.JNode,'TreeNode','MATLAB array');
            schema.prop(nObj.JNode,'UserData','MATLAB array');
            
            % Add a reference to this object
            nObj.JNode.TreeNode = nObj;

            % Set user-supplied property values
            if ~isempty(varargin)
                set(nObj,varargin{:});
            end

        end % constructor

        
        function delete(nObj)
            nObj.IsBeingDeleted = true;
            delete(nObj.Children(isvalid(nObj.Children)))
            if ~isempty(nObj.Parent) && isvalid(nObj.Parent) && ~nObj.Parent.IsBeingDeleted
                nObj.Parent(:) = [];
            end
            delete(nObj.JNode);
        end % destructor
        
    end %methods - constructor/destructor


    %% Public Methods
    methods

        function nObjCopy = copy(nObj,NewParent)
            % copy - Copy a TreeNode object
            %
            % Abstract: Copy a TreeNode object, including any children
            %
            % Syntax:
            %           nObj.copy()
            %           nObj.copy(NewParent)
            %
            % Inputs:
            %           nObj - TreeNode object to copy
            %           NewParent - new parent TreeNode object
            %
            % Outputs:
            %           nObjCopy - copy of TreeNode object
            %
            for idx = 1:numel(nObj)

                % Allow subclasses to instantiate copies of the same type
                fNodeConstructor = str2func(class(nObj(idx)));

                % Create a new node, and copy properties
                nObjCopy(idx) = fNodeConstructor(...
                    'Name',nObj(idx).Name,...
                    'Value',nObj(idx).Value,...
                    'TooltipString',nObj(idx).TooltipString,...
                    'UserData',nObj(idx).UserData,...
                    'UIContextMenu',nObj(idx).UIContextMenu); %#ok<AGROW>

                % Copy the icon's java object
                jIcon = getIcon(nObj(idx).JNode);
                setIcon(nObjCopy(idx).JNode,jIcon);

                % Set the parent, if specified
                if nargin>1
                    set(nObjCopy(idx),'Parent',NewParent);
                end

                % Recursively copy children and assign new parent
                % Need to loop in case children are of heterogeneous type
                ChildNodes = nObj(idx).Children;
                for cIdx = 1:numel(ChildNodes)
                    copy(ChildNodes(cIdx), nObjCopy(idx));
                end
            end
        end %function
        

        function collapse(nObj)
            % collapse - Collapse a TreeNode within a tree
            %
            % Abstract: Collapses the TreeNode
            %
            % Syntax:
            %           nObj.collapse()
            %
            % Inputs:
            %           nObj - TreeNode object
            %
            % Outputs:
            %           none
            %
            for idx = 1:numel(nObj)
                if ~isempty(nObj(idx).Tree)
                    collapseNode(nObj(idx).Tree, nObj(idx));
                end
            end
        end %function collapse()

        
        function expand(nObj)
            % expand - Expands a TreeNode within a tree
            %
            % Abstract: Expands the TreeNode
            %
            % Syntax:
            %           nObj.expand()
            %
            % Inputs:
            %           nObj - TreeNode object
            %
            % Outputs:
            %           none
            %
            for idx = 1:numel(nObj)
                if ~isempty(nObj(idx).Tree)
                    expandNode(nObj(idx).Tree, nObj(idx));
                end
            end
        end %function expand()

        
        function tf = isAncestor(nObj1,nObj2)
            % isAncestor - checks if another node is an ancestor
            %
            % Abstract: checks if node2 is an ancestor of node 1
            %
            % Syntax:
            %           tf = nObj1.isAncestor(nObj2)
            %
            % Inputs:
            %           nObj1 - TreeNode object
            %           nObj2 - TreeNode object
            %
            % Outputs:
            %           tf - logical result
            %
            validateattributes(nObj1,{'uiw.widget.TreeNode'},{'vector'})
            validateattributes(nObj2,{'uiw.widget.TreeNode'},{'vector'})

            tf = false(size(nObj1));
            for idx = 1:numel(nObj1)
                while ~tf(idx) && ~isempty(nObj1(idx).Parent)
                    tf(idx) = any(nObj1(idx).Parent == nObj2);
                    nObj1(idx) = nObj1(idx).Parent;
                end
            end

        end %function isAncestor()

        
        function tf = isDescendant(nObj1,nObj2)
            % isDescendant - checks if another node is a descendant
            %
            % Abstract: checks if another node is a descendant of this one
            %
            % Syntax:
            %           tf = nObj1.isDescendant(nObj2)
            %
            % Inputs:
            %           nObj1 - TreeNode object
            %           nObj2 - TreeNode object
            %
            % Outputs:
            %           tf - logical result
            %

            tf = isAncestor(nObj2,nObj1);

        end %function isDescendant()

        
        function setIcon(nObj,icon)
            % setIcon - Set icon of TreeNode
            %
            % Abstract: Changes the icon displayed on a TreeNode
            %
            % Syntax:
            %           nObj.setIcon(IconFilePath)
            %
            % Inputs:
            %           nObj - TreeNode object
            %           icon - path to the icon file (16x16 px)
            %
            % Outputs:
            %           none
            %
            % Examples:
            %   t = uiw.widget.Tree;
            %   n = uiw.widget.TreeNode('Name','Node1','Parent',t);
            %   setIcon(n,which('matlabicon.gif'));

            validateattributes(icon,{'char'},{})

            % Create a java icon
            IconData = javaObjectEDT('javax.swing.ImageIcon',icon);

            % Update the icon in the node
            setIcon(nObj.JNode, IconData);

            % Notify the model about the update
            nodeChanged(nObj.Tree, nObj)

        end %function setIcon()

        
        function s = getJavaObjects(nObj)
            % getJavaObjects - Returns underlying java objects
            %
            % Abstract: (For debugging use only) Returns the underlying
            % Java objects.
            %
            % Syntax:
            %           s = getJavaObjects(nObj)
            %
            % Inputs:
            %           nObj - TreeNode object
            %
            % Outputs:
            %           s - struct of Java objects
            %

            s = struct('JNode',nObj.JNode);
            
        end %function

    end %public methods


    
    %% Special Access Methods
    methods (Access={?uiw.widget.Tree, ?uiw.widget.TreeNode})

        function newParent = updateParent(nObj,newParent)
            % Handle updating the parent of the specified node

            % What action was taken?
            if nObj.IsBeingDeleted %Node is being deleted

                newParent = [];

                % Remove parent references to this child, if parent is not
                % being deleted
                if ~isempty(nObj.Parent) && ~nObj.Parent.IsBeingDeleted
                    ChildIdx = find(nObj.Parent.Children == nObj,1);
                    nObj.Parent.Children(ChildIdx) = [];
                    nObj.Tree.removeNode(nObj, nObj.Parent);
                end


            elseif isempty(newParent) %New parent is empty

                % Always make the parent an empty TreeNode, in case empty
                % [] was passed in
                newParent = uiw.widget.TreeNode.empty(0,1);

                % Is there an old parent to clean up?
                if ~isempty(nObj.Parent)
                    ChildIdx = find(nObj.Parent.Children == nObj,1);
                    nObj.Parent.Children(ChildIdx) = [];
                    nObj.Tree.removeNode(nObj, nObj.Parent);
                end

                % Update the reference to the tree in the hierarchy
                EmptyTree = uiw.widget.Tree.empty(0,1);
                updateTreeReference(nObj, EmptyTree)

            else % A new parent was provided

                % If new parent is a Tree, parent is the Root
                if isa(newParent,'uiw.widget.Tree')
                    newParent = newParent.Root;
                end

                % Is there an old parent to clean up?
                if ~isempty(nObj.Parent)
                    ChildIdx = find(nObj.Parent.Children == nObj,1);
                    nObj.Parent.Children(ChildIdx) = [];
                    nObj.Tree.removeNode(nObj, nObj.Parent);
                end

                % Update the reference to the tree in the hierarchy
                updateTreeReference(nObj,newParent.Tree)

                % Update the list of children in the parent
                ChildIdx = numel(newParent.Children) + 1;
                newParent.Children(ChildIdx) = nObj;

                % Add this node to the parent node
                if ~isempty(nObj.Tree) && isvalid(nObj.Tree)
                    nObj.Tree.insertNode(nObj, newParent, ChildIdx);
                end
                
            end %if isempty(newParent)

            % This internal function updates the tree reference in the
            % hierarchy
            function updateTreeReference(nObj,Tree)
                for idx=1:numel(nObj)
                    nObj(idx).Tree = Tree;
                    if ~isempty(nObj(idx).Children)
                        updateTreeReference(nObj(idx).Children, Tree);
                    end
                end
            end

        end %function updateParent()

    end %special access methods



    %% Get/Set methods
    methods

        % Name
        function value = get.Name(nObj)
            value = nObj.JNode.getUserObject();
        end
        function set.Name(nObj,value)
            validateattributes(value,{'char'},{});
            nObj.JNode.setUserObject(value);
            nodeChanged(nObj.Tree,nObj);
        end

        % Value
        function value = get.Value(nObj)
            value = nObj.JNode.Value;
        end
        function set.Value(nObj,value)
            nObj.JNode.Value = value;
        end

        % TooltipString
        function value = get.TooltipString(nObj)
            value = char(nObj.JNode.getTooltipString());
        end
        function set.TooltipString(nObj,value)
            validateattributes(value,{'char'},{});
            nObj.JNode.setTooltipString(java.lang.String(value));
        end

        % UserData
        function value = get.UserData(nObj)
            value = nObj.JNode.UserData;
        end
        function set.UserData(nObj,value)
            nObj.JNode.UserData = value;
        end

        % Parent
        function set.Parent(nObj,newParent)
            % Update the parent/child relationship
            if nObj.IsBeingDeleted %#ok<MCSUP>
                updateParent(nObj,newParent);
            else
                newParent = updateParent(nObj,newParent);
                % Set the parent value
                nObj.Parent = newParent;
            end
        end

        % UIContextMenu
        function set.UIContextMenu(tObj,value)
            tObj.UIContextMenu = value;
        end

    end %get/set methods

end %classdef
