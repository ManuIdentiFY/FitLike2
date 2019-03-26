function fig = make_gui_settings(filename)
%
% This function creates a small GUI to visualise the settings stored in
% FitLike regarding the .sdf v1 format (number of column, real and
% imaginary part assignation,...).
%
% Input:
% - filename: path to the MAT File containing the settings. See
%             GETFORMATDLG to get the organisation of the file.
%
% M.Petit - 03/2019
% manuel.petit@inserm.fr

%% Try to get the data
try
    % load the table
    saveObj = load(filename);
    var = fieldnames(saveObj);
    data = saveObj.(var{1});
catch
    error('File could not be loaded!')
end
%% Make GUI
fig = figure('Name','Settings window','NumberTitle','off',...
             'MenuBar','none','ToolBar','none','DockControls','off',...
             'Units','normalized','CloseRequestFcn',@exit);

% information panel
hp1 = uipanel('Title','Information','Parent',fig,...
    'Units','normalized','Position',[0.01 0.80 0.98,0.19],'FontSize',9);
uicontrol('Parent',hp1,'Style','text','String',...
    sprintf(['The table below contains the current settings to read .sdf version 1 (Stelar file).'...
    ' Sequence and number of column defined the format case and real, imag and time the index of'...
    ' the column to read.\nYou can delete settings by selecting row(s) and clicking on'...
    ' ''Delete'' pushbutton. Settings are automaticaly saved if you keep the checkbox checked.']),...
    'Units','normalized','Position',[0 -0.05 1 1],'HorizontalAlignment','left');

% table panel
hp2 = uipanel('Title','Settings','Parent',fig,...
              'Units','normalized','Position',[0.01 0.22 0.98 ,0.56],'FontSize',9);
% prepare data for table
data_table = [table2cell(data), num2cell(false(size(data,1),1))];
colname = {'Sequence','Number of column','Real index','Imag index','Time index', 'Selection'};

htable = uitable(hp2, 'Data',data_table ,'Position',[20 10 500 190],...
    'Columnwidth',{110 110 75 75 75 60},'ColumnName',colname,'RowName',[],...
    'ColumnEditable',[false false false false false true],'FontSize',7);


% option panel
hp3 = uipanel('Title','Options','Parent',fig,...
              'Units','normalized','Position',[0.01 0.01 0.98 ,0.2],'FontSize',9);
hcheck = uicontrol(hp3,'Style','checkbox','String','Save settings','Value',1,...
                'Units','normalized','Position',[0.03 0.1 0.3 0.3]);
uicontrol(hp3,'Style','pushbutton','String','Delete',...
                'Units','normalized','Position',[0.03 0.52 0.2 0.35],'Callback',@delete);    
uicontrol(hp3,'Style','pushbutton','String','Ok',...
                'Units','normalized','Position',[0.75 0.1 0.2 0.35],'Callback',@exit);              

    function delete(~,~)
        % get the table data (the selected rows)
        tf = vertcat(htable.Data{:,end});
        htable.Data = htable.Data(~tf,:);
    end

    function exit(~,~)
        % check if the current settings need to be saved
        if hcheck.Value
            % get data
            settings = htable.Data(:,1:end-1); % remove selection column
            settings = cell2table(settings,'VariableNames',...
                {'Sequence' 'nCol' 'realIdx' 'imagIdx','timeIdx'}); %convert to table
            save(filename, 'settings')
            fprintf('Settings saved!\n')
            pause(0.005);
        end
        % return fig
        closereq
    end
end

