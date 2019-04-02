function processObj = gui_process_settings(processObj)
%
% PROCESSOBJ = GUI_PROCESS_SETTINGS(PROCESSOBJ) displays a dialog box where
% parameters of the PROCESSOBJ can be modified. 
% PROCESSOBJ should be a ProcessDataUnit object and defined parameters that
% can be modified. Precisely, GUI_PROCESS_SETTINGS will call the method 
% getProcessParameter() to define the list of parameter to display. If this
% list is empty, then GUI_PROCESS_SETTINGS do not display the dialog box
% and return an empty value.
% 
% 

% check input
if ~isa(processObj,'ProcessDataUnit')
    error('Input should be a ProcessDataUnit object')
end

% load the parameter structure
parameter = getProcessParameter(processObj);

if isempty(parameter)
    processObj = []; return
else
    tab_name = fieldnames(parameter);
end

% create the figure
% Make the figure and box
fig = figure('Name',[processObj.functionName,' settings'],...
    'NumberTitle','off','MenuBar','none','ToolBar','none',...
    'Units','normalized','Position',[0.3 0.3 0.4 0.4]);

% create a uitabgroup inside the figure
tab = uitabgroup(fig,'Position',[0 0 1 1]);

% loop over the tab 
for k = 1:numel(tab_name)
    % create a tab
    t = uitab(tab,'Title',tab_name{k});
    
    % get the data
    data = parameter.(tab_name{k});
    fld = fieldnames(data);
    
    % check data
    for i = numel(fld):-1:1
        % check data type 
        if isnumeric(data.(fld{i}))
            format{i} = 'numeric';
        elseif islogical(data.(fld{i}))
            format{i} = 'logical';
        elseif ischar(data.(fld{i}))
            format{i} = data.(fld{i});
        else
            error('Unknown type of data!')
        end
    end
    % create a table
    uitable(t,'Data',);
    
    
end
end

