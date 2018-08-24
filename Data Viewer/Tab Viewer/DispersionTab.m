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
        accumColor; % help to know whick color to assign to a new plot
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
            this.accumColor = zeros(1,size(this.Color,1));
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
                                  'Callback',@(src,event) update(this, src));

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
        function this = addPlot(this, hData)
            % check input handle object if Dispersion
            if ~isa(hData,'Dispersion')
                return
            end
            
            % append data
            this.hDispersion = [this.hDispersion hData];
            
            % + data
            plotData(this, hData);

            % + fit
            plotFit(this, hData);
            
            % + residuals
            plotResidual(this);
            
            % reorder Children
            sortChildren(this);
            % reset legend
            resetLegend(this);
        end %addPlot
        
        % Remove data from the tab:
        %   *Delete children in main axis
        %   *Delete children in residual axis
        %   *Delete data handle
        function this = removePlot(this, fileID)
            % get data handle
            tf = strcmp(fileID, {this.hDispersion.fileID});
            % check if possible
            if all(tf == 0)
                return
            end
            % remove them
            this.hDispersion = this.hDispersion(~tf);

            % get the corresponding line handle(s) in main axis
            tf = strcmp(fileID, get(this.axe.Children,'Tag'));
            % get the color of the line to update accumColor
            color = get(findobj(this.axe.Children(tf),'-property','Color'),'Color');
            % delete line
            delete(this.axe.Children(tf));               

            % delete associated residual if needed
            removeResidual(this, fileID, []);

            % update accumColor
            if iscell(color)
                color = color{1};
            end
            [~,idxColor] = intersect(this.Color,color,'rows');
            this.accumColor(idxColor) = this.accumColor(idxColor) - 1;

            % clear axis if no more data
            if isempty(this.axe.Children)
                cla(this.axe, 'reset');
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
                    else
                        % just replace the error by an empty array
                        set(findobj(this.axe.Children,'Type','ErrorBar'),...
                            'YNegativeDelta',[],'YPositiveDelta',[]);
                    end
                    
                case 'LegendCheckButton'
                    if ~src.Value 
                        legend(this.axe,'off');
                    end  
                    
                case 'FitCheckButton'
                    if src.Value
                        % reset fit
                        plotFit(this, this.hDispersion);  
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
            
            % reset the axis
            resetLegend(this);
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
                    % choose color
                    color = chooseColor(this, hData(k).fileID);
                    % choose marker
                    marker = chooseDataMarker(this, hData(k).fileID);
                    % plot
                    errorbar(this.axe,...
                            hData(k).x(hData(k).mask),...
                            hData(k).y(hData(k).mask),...
                            [],...
                            'DisplayName', hData(k).filename,...
                            'Color',color,...
                            'LineStyle',this.DataLineStyle,...
                            'Marker',marker,...
                            'MarkerSize',this.DataMarkerSize,...
                            'MarkerFaceColor','auto',...
                            'Tag',hData(k).fileID); 
                end
            else
                % loop over the data
                for k = 1:length(hData)
                    % choose color
                    color = chooseColor(this, hData(k).fileID);
                    % choose marker
                    marker = chooseDataMarker(this, hData(k).fileID);
                    % plot
                    errorbar(this.axe,...
                            hData(k).x(hData(k).mask),...
                            hData(k).y(hData(k).mask),...
                            hData(k).dy(hData(k).mask),...
                            'DisplayName', hData(k).filename,...
                            'Color',color,...
                            'LineStyle',this.DataLineStyle,...
                            'Marker',marker,...
                            'MarkerSize',this.DataMarkerSize,...
                            'MarkerFaceColor','auto',...
                            'Tag',hData(k).fileID); 
                end
            end
            
            % + plot masked data
            plotMaskedData(this, hData)   
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
                % get color
                color = chooseColor(this, hData(k).fileID);
                % plot
                h = scatter(this.axe,...
                    hData(k).x(~hData(k).mask),...
                    hData(k).y(~hData(k).mask),...
                    'MarkerEdgeColor',color,...
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
                % init color
                color = [];
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
                    
                    % choose color if required
                    if isempty(color)
                        color = chooseColor(this, hData(k).fileID);
                    end
                    % choose style
                    style = chooseFitStyle(this, hData(k).fileID);
                    
                    % plot
                    plot(this.axe, x_fit, y_fit,...
                        'DisplayName', fitName,...
                        'Color',color,...
                        'LineStyle',style,...
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
            
            % delete it residuals if needed
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
                    plot(this.axeResScatter, x, residual,...
                        'LineStyle','none',...
                        'Color',hData.Color,...
                        'Marker',hData.Marker,...
                        'MarkerFaceColor','auto',...
                        'MarkerSize',2,...
                        'Tag',hData.Tag,...
                        'UserData',hFit(iModel).UserData); 
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
    
    % Other function
    methods (Access = public)
        % this function sort the axis children according to their tag
        % as well as their type (data1 fit1 data2 fit2 ...)
        function this = sortChildren(this)
            % get the fileID and the type
            fileID = get(this.axe.Children,'Tag');
            type = get(this.axe.Children,'Type');
            % check if several plot
            if iscell(fileID)
                % concatenate and sort
                [~,idx] = sort(strcat(fileID, type));
                % re-order children
                this.axe.Children = this.axe.Children(flipud(idx));
            end
        end %sortChildren
        
        % reset the legend if needed and check if unique names are
        % displayed. If not, set an unique name by adding the field
        % 'displayName' from hDispersion array handle.
        function this = resetLegend(this)
            % check if legend exists
            if isempty(this.axe.Legend)
                % check if legend should exist
                if this.LegendCheckButton.Value && ~isempty(this.axe.Children)
                    legend(this.axe,'show')
                end
            else              
                if ~this.LegendCheckButton.Value || isempty(this.axe.Children)
                    % check if legend should be deleted
                    legend(this.axe,'off')
                else
                    % check if legend should be updated: duplicates?
                    leg = this.axe.Legend.String;
                    [uniqueLeg, ~, idx] = unique(leg);
                    if length(leg) ~= length(uniqueLeg)
                        % find duplicates
                        occ = histc(idx, 1:numel(uniqueLeg));
                        duplicateLeg = uniqueLeg(occ > 1);
                        % loop over duplicates and update their DisplayName
                        for k = 1:length(duplicateLeg)
                            % find the corresponding line and handle
                            % TO DO
                        end
                    end
                end
            end                           
        end %resetLegend
        
        % choose plot color:
        % This function following these rules:
        % *always follow the same order (Color, Marker, Style order)
        % *keep previous plot as they are
        function color = chooseColor(this, fileID)
            % get handle to the children in main axis
            hPlot = this.axe.Children;
            % check if available plot
            if isempty(hPlot)
                color = this.Color(1,:);
                % reset accumColor
                this.accumColor = [1 zeros(1,6)];
            else
                % check if other plot have the same fileID
                isSameFile = strcmp(fileID, get(hPlot,'Tag'));
                idxColor = find(isSameFile);
                % choose color 
                if ~isempty(idxColor)
                    color = hPlot(idxColor(1)).Color;
                else
                    [~,idxColor] = min(this.accumColor);
                    color = this.Color(idxColor,:); 
                    % increment accumColor
                    this.accumColor(idxColor) = this.accumColor(idxColor) + 1;
                end    
            end
        end %chooseColor
        
        % choose marker
        function marker = chooseDataMarker(this, fileID)
            % get handle to the children in main axis
            hPlot = this.axe.Children;
            % check if available plot
            if isempty(hPlot)
                marker = this.DataMarkerStyle{1};
            else
                % check if other plot have the same fileID and same type
                TF = strcmp(fileID, get(hPlot,'Tag')) & strcmpi('ErrorBar',{hPlot.Type});
                % setdiff between the current markers and the ones defined in
                % properties
                marker = setdiff(this.DataMarkerStyle, {hPlot(TF).Marker}, 'stable');
                if isempty(marker)
                    error('plotData:TooMuchDataPlot', ['Cannot display more than %d'...
                        ' dispersion curves from the same file!'],length(this.DataMarkerStyle))
                else
                    marker = marker{1}; %get the first one
                end
            end
        end %chooseDataMarker
        
        % choose style
        function style = chooseFitStyle(this, fileID)
            % get handle to the children in main axis
            hPlot = this.axe.Children;
            % check if available plot
            if isempty(hPlot)
                style = this.FitLineStyle{1};
            else
                % check if other plot have the same fileID and same type
                TF = strcmp(fileID, get(hPlot,'Tag')) & strcmpi('Line',{hPlot.Type});
                % setdiff between the current markers and the ones defined in
                % properties
                style = setdiff(this.FitLineStyle, {hPlot(TF).LineStyle}, 'stable');
                if isempty(style)
                    error('plotData:TooMuchDataPlot', ['Cannot display more than %d'...
                        ' fit models from the same file!'],length(this.FitLineStyle))
                else
                    style = style{1}; %get the first one
                end
            end
        end %chooseFitStyle
    end   
end

