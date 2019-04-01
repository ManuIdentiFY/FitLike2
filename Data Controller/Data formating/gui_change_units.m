function hData = gui_change_units(hData)
%
% This function uses a small dialog box to change the data units and apply
% the corresponding transformation (data*10^(X) with X integer usually).
% 
% M.Petit - 03/2019
% manuel.petit@inserm.fr

% UNIT AVAILABLE
UNITS = {{'s^{-1}','ms^{-1}','us^{-1}','ps^{-1}'};...
         {'s','ms','us','ns'};...
         {'GHz','MHz','kHz','Hz'};...
         {'A.U. *10^-9','A.U. *10^-6','A.U. *10^-3','A.U.','A.U. *10^3','A.U. *10^6','A.U. *10^9'}};

TRANSFORMATION = {[1 10^3 10^6 10^9];...
                  [1 10^-3 10^-6 10^-9];...
                  [10^9 10^6 10^3 1];...
                  [10^-9 10^-6 10^-3 1 10^3 10^6 10^9]};
% check input
if ~isa(hData, 'DataUnit')
    error('Wrong input type')
end
     
% get current units
x_units = arrayfun(@(x) regexp(x.xLabel,'(?<=\()\S+(?=\))','match'), hData, 'Uniform', 0);
y_units = arrayfun(@(x) regexp(x.yLabel,'(?<=\()\S+(?=\))','match'), hData, 'Uniform', 0);

% get only the last index if multiple
x_units = cellfun(@(x) x{end}, x_units, 'Uniform', 0);
y_units = cellfun(@(x) x{end}, y_units, 'Uniform', 0);

%% Check if multiple units
[x_units,~,idx] = unique(x_units);
if numel(x_units) > 1
    % keep only one units (the most represented)
    [~,tf] = max(histcounts(idx));
    
    % throw message
    str = sprintf('%s (%s)\n', hData(idx ~= tf).displayName,...
        getRelaxProp(hData(idx ~= tf), 'filename'));
    warndlg(['Multiple X units were found in the data. Only the most'...
        ' represented one was kept (%s). The following data were removed:\n%s'],...
        x_units{tf}, str);
    
    hData = hData(idx == tf);
    y_units = y_units(idx == tf);
    x_units = x_units{tf};
end

[y_units,~,idx] = unique(y_units);
if numel(y_units) > 1
    % keep only one units (the most represented)
    [~,tf] = max(histcounts(idx));
    
    % throw message
    str = sprintf('%s (%s)\n', hData(idx ~= tf).displayName,...
        getRelaxProp(hData(idx ~= tf), 'filename'));
    warndlg(['Multiple Y units were found in the data. Only the most'...
        ' represented one was kept (%s). The following data were removed:\n%s'],...
        y_units{tf}, str);
    
    hData = hData(idx == tf);
    y_units = y_units{tf};
end

%% Check if available units
tf_x_units = cellfun(@(x) any(strcmp(x, x_units) == 1), UNITS);
tf_y_units = cellfun(@(x) any(strcmp(x, y_units) == 1), UNITS);

if all(tf_x_units == 0)
    errordlg('The X unit (%s) is not known!', x_units);
elseif all(tf_y_units == 0)
    errordlg('The Y unit (%s) is not known!', y_units);
end

% finally get the current unit
idx_x_units = find(strcmp(UNITS{tf_x_units}, x_units));
idx_y_units = find(strcmp(UNITS{tf_y_units}, y_units));

%% Create GUI
% default value
idx_data = 1;
idx_unit = idx_x_units;

% Create an empty dialog box
fig = dialog('Units','normalized','Position',[0.42 0.3 0.15 0.3],'Name','Unit converter');

uicontrol('Parent',fig,...
       'Style','text',...
       'Units','normalized',...
       'Position',[0.02 0.8 0.96 0.15],...
       'String',['Warning: units are set during processing treatment. If'...
       ' you re-apply process on the converted data, units changes will be'...
       ' canceled.'], 'HorizontalAlignment', 'left');

uicontrol('Parent',fig,...
       'Style','text',...
       'Units','normalized',...
       'Position',[0.02 0.59 0.5 0.1],...
       'String','Select data to convert:', 'HorizontalAlignment', 'left');   
   
uicontrol('Parent',fig,...
    'Style','popup',...
    'Units','normalized',...
    'Position',[0.55 0.6 0.3 0.1],...
    'String',{'X';'Y'},...
    'Value',idx_data,...
    'Callback',@selectData);

uicontrol('Parent',fig,...
       'Style','text',...
       'Units','normalized',...
       'Position',[0.02 0.45 0.5 0.1],...
       'String','Current data units:', 'HorizontalAlignment', 'left');  

current_unit = uicontrol('Parent',fig,...
    'Style','edit',...
    'Units','normalized',...
    'Enable','inactive',...
    'Position',[0.55 0.48 0.3 0.08],...
    'String',x_units);

uicontrol('Parent',fig,...
       'Style','text',...
       'Units','normalized',...
       'Position',[0.02 0.3 0.5 0.1],...
       'String','Convert data units in:', 'HorizontalAlignment', 'left');  
   
unit_list = uicontrol('Parent',fig,...
    'Style','popup',...
    'Units','normalized',...
    'Position',[0.55 0.31 0.3 0.1],...
    'String',UNITS{tf_x_units},...
    'Value', idx_unit,...
    'Callback',@updateUnits); 

checkbox = uicontrol('Parent',fig,...
       'Style','checkbox',...
       'Units','normalized',...
       'Position',[0.02 0.18 0.8 0.1],...
       'Value',1,...
       'String','Apply data transformation (1*X)'); 
   
uicontrol('Parent',fig,...
       'Style','pushbutton',...
       'Units','normalized',...
       'Position',[0.55 0.05 0.3 0.08],...
       'String','Convert',...
       'Callback',@convert); 
   
uiwait(fig);      
   %%% ------------------- Nested function ------------------ %%%
    function selectData(src,~)
        % check if new value is different
        if src.Value ~= idx_data
            scaling = 1; % default
            % update the current unit
            if src.Value == 1
                % update the data to convert
                current_unit.String = x_units;
                % update the list of unit
                unit_list.String = UNITS{tf_x_units};
                unit_list.Value = idx_x_units;
                % update the checkbox string
                checkbox.String = sprintf(['Apply data transformation'...
                    '(%3g*X)'], scaling);
            else
                % update the data to convert
                current_unit.String = y_units;
                % update the list of unit
                unit_list.String = UNITS{tf_y_units};
                unit_list.Value = idx_y_units;
                % update the checkbox string
                checkbox.String = sprintf(['Apply data transformation'...
                    '(%3g*Y)'], scaling);
            end
            % update
            idx_data = src.Value;
            idx_unit = unit_list.Value;           
        end
    end %selectData

    function updateUnits(src, ~)
        % check if the new value is different
        if src.Value ~= idx_unit
            if idx_data == 1
                scaling = TRANSFORMATION{tf_x_units}(idx_x_units)/TRANSFORMATION{tf_x_units}(src.Value);
                data_type = 'X';
            else
                scaling = TRANSFORMATION{tf_y_units}(idx_y_units)/TRANSFORMATION{tf_y_units}(src.Value);
                data_type = 'Y';
            end
           % update the checkbox string
           checkbox.String = sprintf(['Apply data transformation'...
               '(%3g*%s)'], scaling, data_type);
           % update
           idx_unit = src.Value;
        end
    end %updateUnits

    function convert(~,~)
        % apply unit convertion to the wanted data if checkbox true
        if idx_data == 1
            if checkbox.Value
                scaling = TRANSFORMATION{tf_x_units}(idx_x_units)/TRANSFORMATION{tf_x_units}(idx_unit);
                x = arrayfun(@(x) scaling*x.x, hData, 'Uniform', 0);
                [hData.x] = x{:};
            end
            % update xLabel
            xLabel = hData(1).xLabel;
            xLabel = strrep(xLabel,x_units,UNITS{tf_x_units}{idx_unit});
            [hData.xLabel] = deal(xLabel{1});       
        else
            if checkbox.Value
                scaling = TRANSFORMATION{tf_y_units}(idx_y_units)/TRANSFORMATION{tf_y_units}(idx_unit);
                y = arrayfun(@(x) scaling*x.y, hData, 'Uniform', 0);
                [hData.y] = y{:};
            end
            % update yLabel
            yLabel = hData(1).yLabel;
            yLabel = strrep(yLabel,y_units,UNITS{tf_y_units}{idx_unit});
            [hData.yLabel] = deal(yLabel{1}); 
        end
        % delete the dialog box and return the data
        delete(fig);
    end %convert
end

