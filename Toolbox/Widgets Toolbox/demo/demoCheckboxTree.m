%% Checkbox Tree
%   Copyright 2012-2018 The MathWorks, Inc.

%% Create the widget

% This checkbox tree behaves almost identical to the normal tree, except
% adding the checkbox capabilities

f = figure(...
    'Toolbar','none',...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Units','pixels',...
    'Position',[100 100 220 220]);
movegui(f,[100 -100])

w = uiw.widget.CheckboxTree(...
    'Parent',f,...
    'SelectionChangeFcn',@(h,e)disp(e),...
    'Label','Checkbox Tree:', ...
    'LabelLocation','top',...
    'LabelHeight',18,...
    'Units', 'pixels', ...
    'Position', [10 10 200 200]);

topNode =  uiw.widget.CheckboxTreeNode('Name','TopNode','Parent',w.Root);
branchA = uiw.widget.CheckboxTreeNode('Name','BranchA','Parent',w.Root);
branchB = uiw.widget.CheckboxTreeNode('Name','BranchB','Parent',w.Root);

for idx = 1:5
    nodesA(idx) = uiw.widget.CheckboxTreeNode('Name',sprintf('NodeA %d',idx),'Parent',branchA); %#ok<SAGROW>
    nodesB(idx) = uiw.widget.CheckboxTreeNode('Name',sprintf('NodeB %d',idx),'Parent',branchB); %#ok<SAGROW>
end

%% Toggle settings

% Setting this false makes clicking on the label also toggle the checkbox
w.ClickInCheckBoxOnly = false;

% Setting this turns off checking a branch checks its children
w.DigIn = false;