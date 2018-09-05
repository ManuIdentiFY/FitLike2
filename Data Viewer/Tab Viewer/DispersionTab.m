classdef DispersionTab < DisplayTab
    %
    % Class that design containers for dispersion data
    %
    % SEE ALSO DISPLAYTAB, DISPLAYMANAGER, DISPERSION
    
    
    % Data: Dispersion
    properties (Access = public)
        hDispersion = [] % handle array to Dispersion data (see class Dispersion)
    end
    
    % Fit: model selected
    properties (Access = public)
        selectedModel = ''; % cell array of string (handle)
    end
    
    % Display properties
    properties (Access = public)
        % Dispersion data settings
        DataLineStyle = 'none';
        DataMarkerStyle = {'o','^','s','>','*','p'}; % 6 plots from the same file at the same time
        DataMarkerSize = 2;
        % Dispersion data masked settings
        DataMaskedMarkerStyle = '+';
        % Dispersion fit settings
        FitLineStyle = {'-','--',':','-.'}; % 4 models from the same plot at the same time
        FitMarkerStyle = 'none';
        % Dispersion colors
        Color = get(groot,'defaultAxesColorOrder');
        % Display structure
        PlotSpec = [];
    end
    
    % Axis properties (residuals)
    properties (Access = public)
        axeResScatter = [] % axis for the scatter plot (residuals)
        axeResHist = [] % axis for the histogram (residuals)
        mainAxisPosition = [0.09 0.09 0.86 0.86]; %position of the main axis
    end
    
    % New components
    properties (Access = public)
        DataCheckButton % check button to display data
        ErrorCheckButton % check button to display error
        LegendCheckButton % check button to display legend
        FitCheckButton % check button to display fit
        ResidualCheckButton % check button to display residual
        MaskCheckButton % check button to display masked data
    end
    
    methods (Access = public)
        % Constructor
        function this = DispersionTab(tab)
            % call the superclass constructor
            this = this@DisplayTab(tab);
            % set the name of the subtab and init accumColor
            this.Parent.Title = 'Dispersion';
            % change the main axis into a subplot to plot residuals. 
            new_axe = copyobj(this.axe, this.axe.Parent);
            delete(this.axe);
            this.axe = subplot(3,2,1:6, new_axe);
            this.axe.Position = this.mainAxisPosition; %reset Position
            % set the default axis
            this.axe.XScale = 'log';
            this.axe.YScale = 'log';
            
            % add new components to the tab
            % add a panel in box to display options
            panel = uix.Panel( 'Parent', this.box,...
                               'Title', 'Display options',...
                               'Padding',2);
            grid = uix.Grid( 'Parent', panel); 
            hbox = uix.HBox( 'Parent', grid);

            % show data options: data, legend
            opts_button_box1 = uix.VButtonBox( 'Parent', hbox,...
                                               'Spacing', 5,...
                                               'ButtonSize', [100 20] );                                

            this.DataCheckButton = uicontrol( 'Parent', opts_button_box1,...
                                  'Style', 'checkbox',...
                                  'Value',1,...
                                  'String', 'Show data',...
                                  'Tag','DataCheckButton',...
                                  'Callback',@(src, event) update(this, src));                
            this.LegendCheckButton = uicontrol( 'Parent', opts_button_box1,...
                                  'Style', 'checkbox',...
                                  'Value',1,...
                                  'String', 'Show legend',...
                                  'Tag','LegendCheckButton',...
                                  'Callback',@(src,event) setLegend(this));

            % show fit options: error, mask
            opts_button_box2 = uix.VButtonBox( 'Parent', hbox,...
                                               'Spacing', 5,...
                                               'ButtonSize', [100 20] );  
                                           
            this.ErrorCheckButton = uicontrol( 'Parent', opts_button_box2,...
                                  'Style', 'checkbox',...
                                  'Value',0,...
                                  'String', 'Show error',...
                                  'Tag','ErrorCheckButton',...
                                  'Callback',@(src,event) update(this, src));                                 
             this.MaskCheckButton = uicontrol( 'Parent', opts_button_box2,...
                                  'Style', 'checkbox',...
                                  'Tag','MaskCheckButton',...
                                  'String', 'Show mask data',...
                                  'Callback',@(src,event) update(this, src));
                              
            % show fit options: fit, residuals
            opts_button_box3 = uix.VButtonBox( 'Parent', hbox,...
                                               'Spacing', 5,...
                                               'ButtonSize', [100 20] );  
                                           
            this.FitCheckButton = uicontrol( 'Parent', opts_button_box3,...
                                  'Style', 'checkbox',...
                                  'Value',1,...
                                  'Tag','FitCheckButton',...
                                  'String', 'Show fit',...
                                  'Callback',@(src,event) update(this, src));
            this.ResidualCheckButton = uicontrol( 'Parent', opts_button_box3,...
                                  'Style', 'checkbox',...
                                  'Tag','ResidualCheckButton',...
                                  'String', 'Show residual',...
                                  'Callback',@(src,event) update(this, src));

            % set heights                  
            this.box.Heights = [-10 -1];
        end
    end
    
    % Abstract methods
    methods (Access = public)        
        % Add new data to the tab using handle. hData must be a Dispersion
        % object. 
        function [this, tf] = addPlot(this, hData)
            % check input handle object if Dispersion and no duplicates
            if ~isa(hData,'Dispersion')
                tf = 1;
                return
            elseif ~all((this.hDispersion == hData) == 0)
                tf = 0;
                return
            else
                tf = 0;
            end
            
            % + set plot specification
            setPlotSpec(this, hData);
            
            % append data
            this.hDispersion = [this.hDispersion hData];                        
            % add listener 
            addlistener(hData,'FileDeletion',@(src, event) removePlot(this, src));
            addlistener(hData,'FileHasChanged',@(src, event) updateID(this, src)); 
            
            % + data
            plotData(this, hData);

            % + fit
            plotFit(this, hData);
            
            % + residuals
            plotResidual(this);

            % update graph
            sortChildren(this);
            setLegend(this);
        end %addPlot
        
        % Remove data from the tab:
        %   *Delete children in main axis
        %   *Delete children in residual axis
        %   *Delete data handle
        function this = removePlot(this, hData)
            % get data handle
            tf = strcmp(hData.fileID, {this.hDispersion.fileID});
            % check if possible
            if all(tf == 0)
                return
            end
            % remove them
            this.hDispersion = this.hDispersion(~tf);
            this.PlotSpec = this.PlotSpec(~tf);

            % get the line handle(s) in main axis and delete them
            tf = strcmp(hData.fileID, get(this.axe.Children,'Tag'));
            delete(this.axe.Children(tf));               

            % delete associated residual if needed
            removeResidual(this, hData.fileID, []);

            % clear axis if no more data
            if isempty(this.axe.Children)
                legend(this.axe,'off');
                % clear pointer - prevent memory leaks
                this.hDispersion = [];
            end
        end %removePlot
                
        % Update the current axis visualisation settings
        function this = update(this, src)
            % depending on the source, update axis
            switch src.Tag
                case 'DataCheckButton'
                    if src.Value
                        % reset data
                        plotData(this, this.hDispersion);
                        sortChildren(this);
                    else
                        % delete data
                        delete(findobj(this.axe.Children,'Type','ErrorBar'));
                        delete(findobj(this.axe.Children,'Type','Scatter'));
                    end
                    
                case 'ErrorCheckButton'
                    if src.Value
                        % reset errorbar
                        delete(findobj(this.axe.Children,'Type','ErrorBar'));
                        delete(findobj(this.axe.Children,'Type','Scatter'));
                        % plot with error
                        plotData(this, this.hDispersion); % TO IMPROVE
                        sortChildren(this);
                    else
                        % just replace the error by an empty array
                        set(findobj(this.axe.Children,'Type','ErrorBar'),...
                            'YNegativeDelta',[],'YPositiveDelta',[]);
                    end
                    
                case 'FitCheckButton'
                    if src.Value
                        % reset fit
                        plotFit(this, this.hDispersion);  
                        sortChildren(this);
                    else
                        % delete fit
                        delete(findobj(this.axe.Children,'Type','Line'));
                    end
                    
                case 'MaskCheckButton'
                    if src.Value
                        % reset masked data
                        plotMaskedData(this, this.hDispersion);
                    else
                        % delete data
                        delete(findobj(this.axe.Children,'Type','Scatter'));
                    end
                    
                case 'ResidualCheckButton'
                    if src.Value
                        plotResidual(this);
                    else
                        % delete the residual axis
                        delete(this.axeResScatter)
                        delete(this.axeResHist)
                        % reset the main axis
                        subplot(3,2,1:6, this.axe);
                        this.axe.Position = [0.09 0.09 0.86 0.86];
                    end
            end %switch  
            setLegend(this);
        end %update
    
    end
    
    % Plot methods: data, mask, fit, residual
    methods (Access = public)
        % Add dispersion data to the main axis. 
        function this = plotData(this, hData) 
            % check if we need to plot something
            if ~this.DataCheckButton.Value
                return
            end
            
            % check if we plot error or not
            if ~this.ErrorCheckButton.Value
                % loop over the data
                for k = 1:length(hData)
                    % find the index of the dispersion object
                    tf = this.hDispersion == hData(k);
                    % plot
                    errorbar(this.axe,...
                            hData(k).x(hData(k).mask),...
                            hData(k).y(hData(k).mask),...
                            [],...
                            'DisplayName', hData(k).filename,...
                            'Color',this.PlotSpec(tf).Color,...
                            'LineStyle',this.DataLineStyle,...
                            'Marker',this.PlotSpec(tf).DataMarker,...
                            'MarkerSize',this.DataMarkerSize,...
                            'MarkerFaceColor','auto',...
                            'Tag',hData(k).fileID); 
                end
            else
                % loop over the data
                for k = 1:length(hData)
                    % find the index of the dispersion object
                    tf = this.hDispersion == hData(k);
                    % plot
                    errorbar(this.axe,...
                            hData(k).x(hData(k).mask),...
                            hData(k).y(hData(k).mask),...
                            hData(k).dy(hData(k).mask),...
                            'DisplayName', hData(k).filename,...
                            'Color',this.PlotSpec(tf).Color,...
                            'LineStyle',this.DataLineStyle,...
                            'Marker',this.PlotSpec(tf).DataMarker,...
                            'MarkerSize',this.DataMarkerSize,...
                            'MarkerFaceColor','auto',...
                            'Tag',hData(k).fileID);
                end
            end
            
            % + plot masked data
            plotMaskedData(this, hData);
        end %plotData  
        
        % Add masked data
        function this = plotMaskedData(this, hData) 
            % check if we need to plot something
            if ~this.MaskCheckButton.Value
                return
            end
            
            % plot
            for k = 1:length(hData)
                % check if data to plot
                if isempty(hData(k).y(~hData(k).mask))
                    continue
                end
                % find the index of the dispersion object
                tf = this.hDispersion == hData(k);
                % plot
                scatter(this.axe,...
                    hData(k).x(~hData(k).mask),...
                    hData(k).y(~hData(k).mask),...
                    'MarkerEdgeColor',this.PlotSpec(tf).Color,...
                    'Marker',this.DataMaskedMarkerStyle,...
                    'SizeData',this.DataMarkerSize,...
                    'MarkerFaceColor','auto',...
                    'Tag',hData(k).fileID);
                % remove this plot from legend
                set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
            end
        end %plotMaskedData
        
        % Add fit
        function this = plotFit(this, hData) 
            % check if we need to plot something
            if ~this.FitCheckButton.Value || isempty(this.selectedModel)
                return
            end
            
            % loop over the files
            for k = 1:length(hData)
                % get x-values
                x = hData(k).x(hData(k).mask);
                % calculate yfit values and increase the  number of 
                % point to obtain better visualisation. Ensure you dont 
                % repeat point by geting the middle point each time
                x_add = diff(x/2); % get the interval between x pts
                x_fit = sort([x, x(1:end-1)+x_add]); %add it
                
                % loop over the models
                for iModel = 1:length(this.selectedModel)
                    % check if the model exists in the file
                    TF = strcmp(this.selectedModel{iModel}, {hData(k).model.modelName});
                    if all(TF == 0)
                        continue
                    end
                    % get y-values
                    y_fit = hData(k).model(TF).fitobj(x_fit);
                    
                    % change the displayed name and add the rsquare
                    fitName = sprintf('%s: %s (R^2 = %.3f)',...
                        this.selectedModel{iModel}, hData(k).filename,...
                        hData(k).model(TF).gof.rsquare);
                    
                    % plot
                    plot(this.axe, x_fit, y_fit,...
                        'DisplayName', fitName,...
                        'Color',this.PlotSpec(k).Color,...
                        'LineStyle',this.PlotSpec(k).FitStyle,...
                        'Marker',this.FitMarkerStyle,...
                        'Tag',hData(k).fileID,...
                        'UserData',this.selectedModel{iModel}); 
                end
            end
        end %plotFit
        
        % Remove fit
        function this = removeFit(this, modelName)
            % get the corresponding fit handle(s)
            idx = strcmp(modelName, get(this.axe.Children,'UserData'));
            % delete them
            delete(this.axe.Children(idx));
            
            % delete its residuals if needed
            if ~isempty(this.axeResScatter)
                removeResidual(this, [], modelName)
            end
        end %removeFit
        
        % Add residual data
        function this = plotResidual(this)
            % check if we need to plot something
            if ~this.ResidualCheckButton.Value 
                return
            end
            
            % get the handle to the plot(s)
            hPlot = this.axe.Children;
            % get fileID
            hfileID = unique({hPlot.fileID});
            
            % check if residual axis exists
            if isempty(this.axeResScatter)
                % move the main axis
                subplot(3,2,1:4, this.axe);
                % create the axis
                this.axeResScatter = subplot(3,2,5);
                this.axeResHist = subplot(3,2,6);
                % axis settings
                this.axeResScatter.NextPlot = 'add';              
            end
            
            % loop over the plot
            for k = 1:length(hfileID)
                % check if possible to plot residual
                hData = hPlot(strcmp(hfileID{k}, {hPlot.fileID}) &&...
                    strcmpi('ErrorBar', {hPlot.Type}));
                hFit = hPlot(strcmp(hfileID{k}, {hPlot.fileID}) &&...
                    strcmpi('Line', {hPlot.Type}));
                
                if isempty(hData) || isempty(hFit)
                    continue
                end
                
                % make intersection between x from data and x from fit
                x = hData.XData;
                [~,idxx,~] = intersect(x, this.hFit(1).XData);
                
                % loop over the models
                for iModel = 1:length(hFit)                    
                    % calculate residuals
                    residual = hData.YData - hFit(iModel).YData(idxx); 
                    % plot and set color, marker identical to data
                    % use fileID from data but add the model specification
                    % as userdata field
                    h = plot(this.axeResScatter, x, residual,...
                        'LineStyle','none',...
                        'Color',hData.Color,...
                        'Marker',hData.Marker,...
                        'MarkerFaceColor','auto',...
                        'MarkerSize',2,...
                        'Tag',hData.Tag,...
                        'UserData',hFit(iModel).UserData); 
                    % addlistener to update dynamically the graph
                    addlistener(hData,'Tag','PostSet',@(~,~)set(h,'Tag',hData.Tag)); 
                end % loop model
            end %loop plot
            
            % update the histogram
            makeResidualHistogram(this);
        end %plotResidual  
        
        % Remove residual data.
        function this = removeResidual(this, fileID, modelName)
            % check if we need to remove something
            if ~this.ResidualCheckButton.Value 
                return
            end
            
            % check input
            if isempty(fileID) 
                TF_fileID = true(1);
            else
                TF_fileID = strcmp(fileID, get(this.axeResScatter.Children,'Tag'));
            end
            
            if isempty(modelName)
                TF_modelName = true(1);
            else
                TF_modelName = strcmp(modelName, get(this.axeResScatter.Children,'UserData'));
            end
            
            % delete them
            toDelete = TF_fileID & TF_modelName;
            delete(this.axeResScatter.Children(toDelete));             
            
            % check if no more children and clear axis
            if isempty(this.axeResScatter.Children)
                cla(this.axeResHist)
                this.axeResHist.Title = []; %reset title
            else
                % update histogram
                makeResidualHistogram(this);
            end
        end %removeResidual
        
        % Add an histogram of the residuals
        function this = makeResidualHistogram(this)
            % get all the residuals 
            residual = get(this.axeResScatter.Children,'YData');
            if iscell(residual)
               residual = [residual{:}]; %append residuals
            end
            % make an histogram
            histogram(this.axeResHist,residual)
            % add legend to see if gaussian
            [gauss, pval] = chi2gof(residual,'cdf',@normcdf); 
            if gauss
               if pval < 0.001
                   txt = 'Gaussian profile (p<0.001)';
               else
                   txt = sprintf('Gaussian profile (p=%.3f)',pval);
               end
            else
               txt = sprintf('Non-Gaussian profile (p=%.3f)',pval);
            end
            % legend settings         
            title(this.axeResHist,txt); 
            % axis settings
            this.axeResHist.XLabel.String = this.axeResScatter.YLabel.String;  
        end %makeResidualHistogram
    end
    
    methods (Access = protected)
        % update fileID
        function this = updateID(this, src)
            % find which field has changed
            tf_prop = strcmp(split(src.fileID,'@'),...
                {src.dataset, src.sequence, src.filename, src.displayName}');
            newFileID = strcat(src.dataset,'@',src.sequence,'@',src.filename,'@',src.displayName);
            % get the corresponding plot
            tf_plot = strcmp({this.axe.Children.Tag},src.fileID);
            % update their ID
            [this.axe.Children(tf_plot).Tag] = deal(newFileID);
            % if filename has changed, update legend
            if tf_prop(3) == 0
                [this.axe.Children(tf_plot).DisplayName] = deal(src.filename);
                setLegend(this) % avoid same legend
            end
        end
    end
    
    % Other function
    methods (Access = public)
        % this function sort the axis children according to their tag
        % as well as their type (data1 fit1 data2 fit2 ...)
        function this = sortChildren(this)
            % Check if several plot
            if numel(this.axe.Children) > 1
                % get the fileID and the type
                fileID = get(this.axe.Children,'Tag');
                type = get(this.axe.Children,'Type');
                % concatenate and sort
                [~,idx] = sort(strcat(fileID, type));
                % re-order children
                this.axe.Children = this.axe.Children(flipud(idx));
            end
        end %sortChildren
        
        % reset the legend if needed and check if unique names are
        % displayed. If not, set an unique name by adding the field
        % 'displayName' from hDispersion array handle.
        function this = setLegend(this)                
            % check if we have children
            if isempty(this.axe.Children) || ~this.LegendCheckButton.Value
                legend(this.axe,'off');
                return
            elseif isempty({this.axe.Children.DisplayName})
                %delete legend and return
                legend(this.axe,'off');
                return
            else 
                legend(this.axe,'show')
            end
            % check if duplicates
            str_leg = {this.axe.Children.DisplayName};
            if numel(str_leg) ~= numel(unique(str_leg))
                % find which plot is duplicates
                [unique_str,~,idx] = unique(str_leg);
                count = accumarray(idx,1);
                val_count = [unique_str, count];
                % loop over the result
                duplicate_str = unique_str(val_count{end} ~= 1);
                for k = 1:numel(duplicate_str)
                    tf_plot = strcmp(str_leg,duplicate_str{k});
                    hPlot = this.axe.Children(tf_plot);
                    % replace their displayname
                    for j = 1:numel(hPlot)
                        tf_data = strcmp({this.hDispersion.fileID},hPlot(j).Tag);
                        hPlot(j).DisplayName = [hPlot(j).DisplayName,...
                            ' (',this.hDispersion(tf_data).displayName,')'];                        
                    end
                end
            end
        end %checkLegend
        
        % This function set the color, the marker and the style for the
        % hDispersion object according to the possible Color, Marker and
        % Style defined in properties.
        % All these properties are stored in a structure.
        % NOTE: LINESTYLE IS NOT IMPLEMENTED YET
        function this = setPlotSpec(this, hData)
            % set properties
            if isempty(this.hDispersion)
                this.PlotSpec(1).Color = this.Color(1,:);
                this.PlotSpec(1).DataMarker = this.DataMarkerStyle{1};
                %this.setPlotSpec(1).FitStyle = this.FitLineStyle{1};
            else
                n = numel(this.PlotSpec);
                % set specification: look if same file is plot
                plotID = strcat({this.hDispersion.dataset},...
                                 {this.hDispersion.sequence},...
                                 {this.hDispersion.filename});
                tf_plot = strcmp(plotID, strcat(hData.dataset,...
                                        hData.sequence, hData.filename));
                if all(tf_plot == 0)
                    color_count = zeros(1,size(this.Color,1));
                    % set the color that appear the less
                    [~,count] = ismember(vertcat(this.PlotSpec.Color),this.Color,  'rows');
                    count = accumarray(count,1);
                    color_count(1:numel(count)) = count;
                    [~,idx] = min(color_count);
                    this.PlotSpec(n+1).Color = this.Color(idx,:);
                    % set the first marker
                    this.PlotSpec(n+1).DataMarker = this.DataMarkerStyle{1};
                else
                    % set the same color as file found
                    color = {this.PlotSpec(tf_plot).Color};
                    this.PlotSpec(n+1).Color = color{1}; %if multiple 
                    % set the next marker
                    this.PlotSpec(n+1).DataMarker = this.DataMarkerStyle{sum(tf_plot)+1};
                end
            end
        end % setPlotSpec        
    end   
end

