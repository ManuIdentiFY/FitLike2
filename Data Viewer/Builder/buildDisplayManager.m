function fig = buildDisplayManager(toggletool_list, pushtool_list)
%
% Builder for the DisplayManager View
%

% Make the figure
fig = figure('Name','Display Manager','NumberTitle','off',...
    'MenuBar','none','ToolBar','figure','DockControls','off',...
    'Units','normalized','Position',[0.25 0.1 0.5 0.75],...
    'Visible','off','Tag','fig');

% List all the uipushtool and uitoggletool and remove the
% unwanted tool.
tgl = findall(fig,'Type','uitoggletool');
psh = findall(fig,'Type','uipushtool');

[tgl.Separator] = deal('off');
[psh.Separator] = deal('off');

[~,idx] = setdiff({tgl.TooltipString}, toggletool_list);
delete(tgl(idx));
[~,idx] = setdiff({psh.TooltipString}, pushtool_list);
delete(psh(idx));
delete(findall(fig,'Type','uitogglesplittool'));

% Make a tab group
tab = uitabgroup(fig,'Position',[0 0 1 1],'Tag','tab');

% Add an empty tab and one with the mention "+"
EmptyTab(uitab(tab));
EmptyPlusTab(uitab(tab));  
end

