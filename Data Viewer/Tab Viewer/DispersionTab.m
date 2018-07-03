classdef DispersionTab < DisplayTab
    %
    % Class that design containers for dispersion data
    %
    % SEE ALSO DISPLAYTAB, DISPLAYMANAGER
    
    % set display properties
    properties (Access = public)
        % Dispersion data settings
        DataLineStyle = 'none';
        DataMarkerStyle = 'o';
        DataMarkerSize = 2;
        % Dispersion data masked settings
        DataMaskedMarkerStyle = '+';
        % Dispersion fit settings
        FitLineStyle = '-';
        FitMarkerStyle = 'none';
        % Dispersion colors
        Color = [];
    end
    
    % list of new components
    properties (Access = public)
        DataCheckButton % check button to display data
        ErrorCheckButton % check button to display error
        LegendCheckButton % check button to display legend
        FitCheckButton % check button to display fit
        ResidualCheckButton % check button to display residual
        MaskCheckButton % check button to display masked data
        RadioButtonRaw % radio button to display raw data
        RadioButtonFilter % radio button to display filtered data
    end
    
    methods (Access = public)
        % Constructor
        function this = DispersionTab(FitLike, tab)
            % call the superclass constructor
            this = this@DisplayTab(FitLike, tab);
            % set the name of the subtab 
            this.Parent.Title = 'Dispersion';
            % add new components to the tab
            % add a panel in box to display options
            panel = uix.Panel( 'Parent', this.box,...
                               'Title', 'Display options',...
                               'Padding',2);
            grid = uix.Grid( 'Parent', panel); 
            hbox = uix.HBox( 'Parent', grid);

            % show data options: data, error, legend
            opts_button_box1 = uix.VButtonBox( 'Parent', hbox,...
                                               'Spacing', 5,...
                                               'ButtonSize', [100 20] );                                

            this.DataCheckButton = uicontrol( 'Parent', opts_button_box1,...
                                  'Style', 'checkbox',...
                                  'Value',1,...
                                  'String', 'Show data',...
                                  'Tag','DataCheckButton',...
                                  'Callback',@(src, event) this.FitLike.updatePlot(src));
            this.ErrorCheckButton = uicontrol( 'Parent', opts_button_box1,...
                                  'Style', 'checkbox',...
                                  'Value',0,...
                                  'String', 'Show error',...
                                  'Tag','ErrorCheckButton',...
                                  'Callback',@(src,event) this.FitLike.updatePlot(src));                  
            this.LegendCheckButton = uicontrol( 'Parent', opts_button_box1,...
                                  'Style', 'checkbox',...
                                  'Value',1,...
                                  'String', 'Show legend',...
                                  'Tag','LegendCheckButton',...
                                  'Callback',@(src,event) this.FitLike.updatePlot(src));

            % show fit options: fit, residuals, mask
            opts_button_box2 = uix.VButtonBox( 'Parent', hbox,...
                                               'Spacing', 5,...
                                               'ButtonSize', [100 20] );                                

            this.FitCheckButton = uicontrol( 'Parent', opts_button_box2,...
                                  'Style', 'checkbox',...
                                  'Value',1,...
                                  'Tag','FitCheckButton',...
                                  'String', 'Show fit',...
                                  'Callback',@(src,event) this.FitLike.updatePlot(src));
            this.ResidualCheckButton = uicontrol( 'Parent', opts_button_box2,...
                                  'Style', 'checkbox',...
                                  'Tag','ResidualCheckButton',...
                                  'String', 'Show residual',...
                                  'Callback',@(src,event) this.FitLike.updatePlot(src));
            this.MaskCheckButton = uicontrol( 'Parent', opts_button_box2,...
                                  'Style', 'checkbox',...
                                  'Tag','MaskCheckButton',...
                                  'String', 'Show mask data',...
                                  'Callback',@(src,event) this.FitLike.updatePlot(src));

            % button radio to display raw or filtered data
            opts_button_box3 =  uix.VButtonBox( 'Parent', hbox,...
                                               'Spacing', 10,...
                                               'VerticalAlignment','middle',...
                                               'ButtonSize', [200 25]);

            this.RadioButtonRaw = uicontrol( 'Parent', opts_button_box3 ,...
                                 'Style', 'radiobutton',...
                                 'String', 'Show Raw Data',...
                                 'Tag','RadioButtonRaw',...
                                 'Value',1);

            this.RadioButtonFilter = uicontrol( 'Parent', opts_button_box3,...
                                 'Style', 'radiobutton',...
                                 'String', 'Show Filtered Data',...
                                 'Tag','RadioButtonFilter',...
                                 'Value',0);
            % set the grid
            this.box.Heights = [-7 -1];
            % set the color 
            this.Color = get(this.axe,'colororder');
        end
    end
    
    % Abstract methods
    methods (Access = public)
        % Add new dispersion data to the current axis.
        % fileID is a unique identifier for the file to plot
        % label is the name of the file that appear in the legend
        % addPlot() select the data to plot by looking at their fileID
        % avoiding doublons. It also check for visualisation settings
        % (data, error, legend, masked data, fit, residual).
        function this = addPlot(this, x, y, dy, label, fileID, mask, fitobj)
            % check if we need to plot error and replace by array of nan if
            % false
            if ~this.ErrorCheckButton.Value 
                dy = cellfun(@(x) nan(length(x),1), x, 'UniformOutput',0);
            end
            % loop over the lines
            for i = length(fileID):-1:1   
                % set the color
                color = chooseColor(this, fileID{i});
                
                % depending on the DataCheckButton Or ErrorCheckButton, show the data
                if (this.DataCheckButton.Value || this.ErrorCheckButton.Value) &&...
                        isempty(findobj(this.axe.Children,'Type','ErrorBar','Tag',fileID{i}))                      
                     % plot data 
                     errorbar(this.axe,x{i}(mask{i}),y{i}(mask{i}),dy{i}(mask{i}),...
                        'DisplayName', label{i},...
                        'Color',color,...
                        'LineStyle',this.DataLineStyle,...
                        'Marker',this.DataMarkerStyle,...
                        'MarkerSize',this.DataMarkerSize,...
                        'MarkerFaceColor','auto',...
                        'Tag',fileID{i}); 
                end
                
                % depending on the MaskCheckButton, show the masked data
                if this.MaskCheckButton.Value &&...
                        isempty(findobj(this.axe.Children,...
                        'Type','ErrorBar','Tag',fileID{i},'UserData','Mask'))
                    % plot the masked data with no error (nan)
                    h = errorbar(this.axe,x{i}(~mask{i}),y{i}(~mask{i}),...
                        nan(size(x{i}(~mask{i}))),...
                        'Color',color,...
                        'LineStyle',this.DataLineStyle,...
                        'Marker',this.DataMaskedMarkerStyle,...
                        'MarkerSize',this.DataMarkerSize,...
                        'MarkerFaceColor','auto',...
                        'UserData','Mask',...
                        'Tag',fileID{i}); 
                    % avoid this plot in legend by setting the
                    % IconDisplayStyle to 'off'
                    set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                end               
                
                % depending on the FitCheckButton, show the fit if
                % possible
                if this.FitCheckButton.Value && ~isempty(fitobj{i}) &&...
                        isempty(findobj(this.axe.Children,'Type','Line','Tag',fileID{i}))
                    % get the y-value using the fitobj and increase the 
                    % number of point to obtain better visualisation
                    % keep the result for residuals
                    x_fit{i} = linspace(min(x{i}), max(x{i}), 2*numel(x{i}));
                    y_fit{i} = fitobj{i}(x_fit{i});
                    % change the displayed name and add the rsquare
                    fitName = sprintf('Fit: %s (R^2 = 0.99)',label{i});
                    % plot
                    plot(this.axe, x_fit{i}, y_fit{i},...
                    'DisplayName', fitName,...
                    'Color',color,...
                    'LineStyle',this.FitLineStyle,...
                    'Marker',this.FitMarkerStyle,...
                    'Tag',fileID{i}); 
                end                   
            end % loop
            
            % check if residuals need to be displayed
%             if this.ResidualCheck.Value
%                plotResidual(this); 
%             end
            
            % check if legend is required
            if this.LegendCheckButton.Value
                resetLegend(this);
            end
        end %addPlot()                     
        
        % Remove data from the current axis
        function this = removePlot(this, fileID)
            % loop over the file to delete
            for i = 1:length(fileID)
                % get the corresponding line handle(s)
                currentFileID = get(findobj(this.axe.Children),'Tag');
                idx = strcmp(fileID{i},currentFileID);
                % delete them
                delete(this.axe.Children(idx));
            end  
            % hide legend if no more data
            if isempty(this.axe.Children)
                legend(this.axe,'hide');
            end
        end %removePlot()
        
        % Update the current axis visualisation settings
        function this = update(this, src)
            % depending on the source, change the plot
            switch src.Tag
                case 'DataCheckButton'
                    if src.Value
                        % get the handle to the data
                        h = findobj(this.axe.Children,'Type','ErrorBar');
                        % reset the DataMarkerType
                        this.DataMarkerStyle = 'o';
                        set(h,'Marker',this.DataMarkerStyle);
                        % reset the DataMaskedMarkerType
                        this.DataMaskedMarkerStyle = '+';
                        set(findobj(h,'UserData','Mask'),'Marker',this.DataMaskedMarkerStyle);
                        % reset the legend icons
                        if numel(h) == 1
                            set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
                        elseif numel(h) > 1
                            cellfun(@(x) set(get(x,'LegendInformation'),'IconDisplayStyle','on'),...
                                get(h,'Annotation'),'UniformOutput',0);
                        end
                        % reset the plot if user add data previously
                        addPlot(this.FitLike);
                    else
                        % get the handle to the data
                        h = findobj(this.axe.Children,'Type','ErrorBar');
                        % set invisible DataMarkerType
                        this.DataMarkerStyle = 'none';
                        set(h,'Marker',this.DataMarkerStyle);
                        % set invisible DataMaskedMarkerType
                        this.DataMaskedMarkerStyle = 'none';
                        % set the legend icons to 'off'
                        if numel(h) == 1
                            set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                        elseif numel(h) > 1
                            cellfun(@(x) set(get(x,'LegendInformation'),'IconDisplayStyle','off'),...
                                get(h,'Annotation'),'UniformOutput',0);
                        end
                    end
                    % reset legend
                    resetLegend(this);
                case 'ErrorCheckButton'
                    if src.Value
                        % need to delete and replot (error data
                        % has been erased previously)
                        delete(findobj(this.axe.Children,'Type','ErrorBar'));
                        addPlot(this.FitLike);
                    else
                        % just replace the error by an empty array
                        set(findobj(this.axe.Children,'Type','ErrorBar'),...
                            'YNegativeDelta',[],'YPositiveDelta',[]);
                    end
                    % reset legend
                    resetLegend(this);
                case 'LegendCheckButton'
                    if src.Value 
                        resetLegend(this);
                    else
                        legend(this.axe,'hide');
                    end  
                case 'FitCheckButton'
                    if src.Value
                        % get the handle to fit data
                        h = findobj(this.axe.Children,'Type','Line');
                        % set default LineStyle
                        this.FitLineStyle = '-';
                        set(h,'LineStyle',this.FitLineStyle); 
                        % reset the legend icons
                        if numel(h) == 1
                            set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
                        elseif numel(h) > 1
                            cellfun(@(x) set(get(x,'LegendInformation'),'IconDisplayStyle','on'),...
                                get(h,'Annotation'),'UniformOutput',0);
                        end
                        % reset the plot if user add data previously
                        addPlot(this.FitLike);  
                    else
                       % get the handle to fit data
                       h = findobj(this.axe.Children,'Type','Line');
                       % set invisible LineStyle
                       this.FitLineStyle = 'none';
                       set(h,'LineStyle',this.FitLineStyle); 
                       % set the legend icons visibility to 'off'
                       if numel(h) == 1
                            set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                       elseif numel(h) > 1
                            cellfun(@(x) set(get(x,'LegendInformation'),'IconDisplayStyle','off'),...
                                get(h,'Annotation'),'UniformOutput',0);
                       end
                    end
                    % reset legend
                    resetLegend(this);
                case 'DataMaskedCheckButton'
                    if 1
                        %TO DO
                    else
                        %TO DO
                    end
                case 'ResidualCheckButton'
                    if 1
                        %TO DO
                    else
                        %TO DO
                    end
            end %switch            
        end %update
    end
    
    % Other methods
    methods (Access = public)  
        %Reset legend: sort the input and hide legend if nothing is
        %actually displayed
        function this = resetLegend(this)
            % check the LegendCheckButton
            if ~this.LegendCheckButton.Value
                return
            end
            % do some check to know if legend is required
            if isempty(this.axe.Children)  
                % if no data displayed, hide the legend
                legend(this.axe,'hide');
            elseif ~this.ErrorCheckButton.Value &&...
                    ~this.DataCheckButton.Value && ~this.FitCheckButton.Value
                % If nothing need to be displayed, hide the legend
                legend(this.axe,'hide');
            elseif ~this.ErrorCheckButton.Value &&...
                    ~this.DataCheckButton.Value && isempty(findobj(this.axe,'Type','Line'))
                % If no data need to be displayed and no fit are stored,
                % hide the legend
                legend(this.axe,'hide');
            elseif length(this.axe.Children) > 1
                % sort the axis children according to their tag (fileID)
                % use also the type to sort the data and the fit in the
                % same order (like: data1 fit1 data2 fit2 data3 fit3...and
                % not data1 fit1 fit2 data2 data3 fit3...)
                currentFileID = get(findobj(this.axe.Children),'Tag');
                currentType = get(findobj(this.axe.Children),'Type');
                [~,idx] = sort(strcat(currentFileID,currentType));
                this.axe.Children = this.axe.Children(flipud(idx));
                % show legend and use 'AutoUpdate' to fit with the new
                % children order
                legend(this.axe,'show');
            else
                legend(this.axe,'show');
            end
        end %resetLegend
        
        % This function choose a color for the plot following this rules:
        % *always follow the same order (Matlab color order)
        % *keep previous plot as they are
        % It also handles the color coupling between data, masked data and
        % fit.
        function color = chooseColor(this, fileID)
            % check if current axis is empty
            if isempty(this.axe.Children)
                color = this.Color(1,:);
            elseif ~isempty(findobj(this.axe.Children,'Tag',fileID))
                % see if another file with same Tag is currently
                % plotted and get its color (data, mask or fit)
                color = get(findobj(this.axe.Children,'Tag',fileID),'Color');
                if iscell(color)
                    color = color{1}; %prevent if multiple
                end
            else
                % count the apparition of the colors in the Matlab
                % color index order and set the one that appear the
                % less and is the first according to the order.
                colorcount = zeros(size(this.Color,1),1);
                color = get(findobj(this.axe.Children),'Color');
                for iColor = 1:length(color)
                    [~,idx,~] = intersect(this.Color,color{iColor},'rows');
                    colorcount(idx) = colorcount(idx) + 1;
                end
                % take the one that appear the less
                [~,idxColor] = min(colorcount);
                % set as new color
                color = this.Color(idxColor,:);
            end
        end %chooseColor
        
        % Plot the residuals in two other axis. Create them if needed. 
        function this = plotResidual(this)
           % TO DO! 
        end %plotResidual
        
        %Get fileID
        function listFileID = getFileID(this)
            % get all the fileID by looking at the 'Tag'
            if ~isempty(this.axe.Children)
                listFileID = get(findobj(this.axe.Children),'Tag');
            else
                listFileID = [];
            end
        end %getFileID
    end   
end

