function fig = buildFitLikeView()
%
% Build the menu of FitLike. It is also the main figure of FitLike (View).
%

% Menu Manager
fig = figure('Name','FitLike','NumberTitle','off',...
    'MenuBar','none','Units',...
    'normalized','Position',[0.25 0.92 0.5 0],...
    'Tag','menu');

% +File menu
fileMenu = uimenu( fig, 'Label', 'File' );
uimenu( fileMenu, 'Label', 'Open file','Tag','Open');
uimenu( fileMenu, 'Label', 'Open folder','Tag','OpenFolder');
uimenu( fileMenu, 'Label', 'Remove file','Tag','Remove');
exportData = uimenu( fileMenu, 'Label', 'Export');
uimenu( exportData, 'Label', 'Model parameters','Tag','Export_Model');
uimenu( exportData, 'Label', 'Dispersion data','Tag','Export_Dispersion');
uimenu( fileMenu, 'Label', 'Save','Accelerator','S','Tag','Save');
uimenu( fileMenu, 'Label', 'Exit','Accelerator','Q','Tag','Quit');

% + Edit menu
editMenu = uimenu( fig, 'Label', 'Edit' );
labelMenu = uimenu( editMenu, 'Label', 'Label...','Tag','LabelList');
uimenu( labelMenu, 'Label', 'Add Label','Tag','addLabel');
uimenu( labelMenu, 'Label', 'Remove Label','Tag','removeLabel');
% uimenu( editMenu, 'Label', 'Move','Tag','Move');
% uimenu( editMenu, 'Label', 'Copy','Tag','Copy');
% sortEdit = uimenu( editMenu, 'Label', 'Sort');
% uimenu( sortEdit, 'Label', 'By classe','Tag','Sort_Class');
% uimenu( sortEdit, 'Label', 'By name','Tag','Sort_File');
% uimenu( editMenu, 'Label', 'Merge/Unmerge','Tag','Merge');
% uimenu( editMenu, 'Label', 'Mask/Unmask','Tag','Mask');

% + View menu
viewMenu = uimenu( fig, 'Label', 'View' );
% axisView = uimenu( viewMenu, 'Label', 'Axis');
% uimenu(axisView, 'Label', 'Linear','Checked','off','Tag','Axis_XYLin');
% uimenu(axisView, 'Label', 'Semilog x','Checked','off','Tag','Axis_XLogYLin');
% uimenu(axisView, 'Label', 'Semilog y','Checked','off','Tag','Axis_XLinYLog');
% uimenu(axisView, 'Label', 'Loglog','Checked','on','Tag','Axis_XYLog');
% plotView = uimenu(viewMenu, 'Label', 'Plot');
% uimenu(plotView, 'Label', 'File', 'Checked', 'on','Tag','Plot_File');
% uimenu(plotView, 'Label', 'Class', 'Checked', 'off','Tag','Plot_Class');
uimenu(viewMenu, 'Label', 'Create Figure','Accelerator','F','Tag','Create_Fig');

% +Tools menu
filterMenu = uimenu( fig, 'Label', 'Tools');
% uimenu( filterMenu, 'Label', 'Filter','Tag','Filter');
% uimenu( filterMenu, 'Label', 'Mean','Tag','Mean');
% uimenu( filterMenu, 'Label', 'Normalise','Tag','Normalise');
% uimenu( filterMenu, 'Label', 'Boxplot','Tag','Boxplot');

% +Display
displayMenu = uimenu( fig, 'Label', 'Display');
uimenu(displayMenu, 'Label', 'FileManager','Tag','FileManager','Checked','on');
uimenu(displayMenu, 'Label', 'DisplayManager','Tag','DisplayManager','Checked','on');
uimenu(displayMenu, 'Label', 'ProcessingManager','Tag','ProcessingManager','Checked','off');
uimenu(displayMenu, 'Label', 'ModelManager','Tag','ModelManager','Checked','on');
% uimenu(displayMenu, 'Label', 'AcquisitionManager','Tag','AcquisitionManager','Checked','off');

% + Help menu
helpMenu = uimenu( fig, 'Label', 'Help' );
% uimenu( helpMenu, 'Label', 'Documentation','Tag','Documentation');
end

