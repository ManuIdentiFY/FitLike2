function fig = buildDisplayManager()
%
% FIG = BUILDDISPLAYMANAGER() create the GUI for DisplayManager returning
% the figure and its associated childs
%
fig = figure('Name','Display Manager','NumberTitle','off',...
    'MenuBar','none','ToolBar','figure','DockControls','off',...
    'Units','normalized','Position',[0.25 0.1 0.5 0.75],...
    'Tag','fig');
% + TabPanel
uitabgroup(fig,'Position',[0 0 1 1],'Tag','tab');
end

