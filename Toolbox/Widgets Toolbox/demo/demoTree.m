%% Tree
%   Copyright 2012-2018 The MathWorks, Inc.

%% Create the widget

f = figure(...
    'Toolbar','none',...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Units','pixels',...
    'Position',[100 100 220 320]);
movegui(f,[100 -100])

w = uiw.widget.Tree(...
    'Parent',f,...
    'SelectionChangeFcn',@(h,e)disp(e),...
    'Label','Tree:', ...
    'LabelLocation','top',...
    'LabelHeight',18,...
    'Units', 'pixels', ...
    'Position', [10 10 200 300]);

topNode =  uiw.widget.TreeNode('Name','TopNode','Parent',w.Root);
branchA = uiw.widget.TreeNode('Name','BranchA','Parent',w.Root);
branchB = uiw.widget.TreeNode('Name','BranchB','Parent',w.Root);

for idx = 1:5
    nodesA(idx) = uiw.widget.TreeNode('Name',sprintf('NodeA %d',idx),'Parent',branchA); %#ok<SAGROW>
    nodesB(idx) = uiw.widget.TreeNode('Name',sprintf('NodeB %d',idx),'Parent',branchB); %#ok<SAGROW>
end


%% Expand branches

branchA.expand();
branchB.expand();


%% Hide the root

w.RootVisible = false;


%% Change selection mode

w.SelectionType = 'discontiguous';
w.SelectionChangeFcn = @(h,e)disp({h.SelectedNodes.Name}');


%% Select nodes programmatically

w.SelectedNodes = [nodesA(2) nodesB(4)];


%% Toggle Enable

w.Enable = 'off';


%% Toggle Enable back on

w.Enable = 'on';


%% Change some node properties

% Rename a node
topNode.Name = 'TopNode (renamed)';

% Set an icon
branchIcon = fullfile(matlabroot,'toolbox','matlab','icons','pagesicon.gif');
nodeIcon = fullfile(matlabroot,'toolbox','matlab','icons','pageicon.gif');
setIcon(branchA,branchIcon);
setIcon(topNode,nodeIcon);


%% Allow interactively renaming a node

% Not working consistently
% w.Editable = true;
% w.NodeEditedCallback = @(h,e)disp({h.SelectedNodes.Name}');


%% Relocate nodes

% Move nodes around
nodesB(1).Parent = nodesA(1);


%% Add context menus

% For the whole tree
treeContextMenu = uicontextmenu('Parent',f);
uimenu(treeContextMenu,'Label','Refresh');
set(w,'UIContextMenu',treeContextMenu)

% For nodesA only
nodesAContextMenu = uicontextmenu('Parent',f);
uimenu(nodesAContextMenu,'Label','Node1');
set(nodesA,'UIContextMenu',nodesAContextMenu)


%% Drag and drop support

% Note this only supports moving nodes within the tree. It does not support
% dragging to/from other parts of the user interface.

w.DndEnabled = true;
w.NodeDraggedCallback = @(h,e)dragDropCallback(h,e);
w.NodeDroppedCallback = @(h,e)dragDropCallback(h,e);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback for drag and drop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dropOk = dragDropCallback(h,e) %#ok<INUSL>

% Is this the drag or drop part?
doDrop = ~(nargout); % The drag callback expects an output, drop does not

% Get the source and destination
srcNode = e.Source;
dstNode = e.Target;

% If drop is allowed
if ~doDrop
    % Is dstNode a valid drop location?
    
    % For example, assume it always is. Tree will prevent dropping on
    % itself or existing parent.
    dropOk = true;
    
elseif strcmpi(e.DropAction,'move')
    
    % De-parent
    srcNode.Parent = [];
    
    % Then get index of destination
    dstLevelNodes = [dstNode.Parent.Children];
    dstIndex = find(dstLevelNodes == dstNode);
    
    % Re-order children and re-parent
    dstLevelNodes = [dstLevelNodes(1:(dstIndex-1)) srcNode dstLevelNodes(dstIndex:end)];
    for idx = 1:numel(dstLevelNodes)
        dstLevelNodes(idx).Parent = dstNode.Parent;
    end
    
end

end %function