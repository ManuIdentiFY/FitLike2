classdef DispersionTab < DisplayTab
    %
    % Class that design containers for dispersion data
    %
    % SEE ALSO DISPLAYTAB, DISPLAYMANAGER, DISPERSION
    
    % M.Petit Note: Plotting data requires lot of time, especially because
    % we need to dynamically update the legend (50% maybe) and the axis
    % (10%). Could be improved.
    
    % Data: Dispersion
    properties (Access = public)
        FitLike % Presenter
        hDispersion = [] % handle array to Dispersion data (see class Dispersion)
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
    
    % Axis and Control properties
    properties (Access = public)
        optsButton % all the display/data options uicontrol
        axeResScatter = [] % axis for the scatter plot (residuals)
        axeResHist = [] % axis for the histogram (residuals)
        mainAxisPosition = [0.09 0.09 0.86 0.86]; %position of the main axis
    end
    
    methods (Access = public)
        % Constructor
        function this = DispersionTab(FitLike, tab)
            % call the superclass constructor and set the Presenter
            this = this@DisplayTab(tab);
            this.FitLike = FitLike;
            % set the name of the subtab and init accumColor
            this.Parent.Title = 'Dispersion';
            % change the main axis into a subplot to plot residuals. 
            new_axe = copyobj(this.axe, this.axe.Parent);
            delete(this.axe);
            this.axe = subplot(3,2,1:6, new_axe);
            this.axe.Position = this.mainAxisPosition; %reset Position
            
            % add display options under the axis
            this.optsButton = buildDisplayOptions(this.box);
            
            % set the default axis
            this.axe.XScale = this.optsButton.XAxisPopup.String{this.optsButton.XAxisPopup.Value};
            this.axe.YScale = this.optsButton.YAxisPopup.String{this.optsButton.YAxisPopup.Value};            
            %%% ----------------------- CALLBACK ---------------------- %%%
            % checkbox callback
            set(this.optsButton.DataCheckButton,'Callback',...
                @(src, event) update(this, src));
            
            set(this.optsButton.ErrorCheckButton,'Callback',...
                @(src, event) update(this, src));
            
            set(this.optsButton.FitCheckButton,'Callback',...
                @(src, event) update(this, src));
            
            set(this.optsButton.MaskCheckButton,'Callback',...
                @(src, event) update(this, src));
            
            set(this.optsButton.ResidualCheckButton,'Callback',...
                @(src, event) update(this, src));  
            
            set(this.optsButton.LegendCheckButton,'Callback',...
                @(src, event) setLegend(this)); 
                       
            % X/Y axis callback
            set(this.optsButton.XAxisPopup,'Callback',...
                @(src, event) setAxis(this, src));
            set(this.optsButton.YAxisPopup,'Callback',...
                @(src, event) setAxis(this, src)); 
            
            % Mask callback
            set(this.optsButton.MaskDataPushButton,'Callback',...
                @(src, event) maskData(this));
            set(this.optsButton.ResetMaskPushButton,'Callback',...
                @(src, event) resetMaskData(this));
            %%% ------------------------------------------------------- %%%            
            % set heights                  
            this.box.Heights = [-8 -1];
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
            addlistener(hData,'DataHasChanged',@(src, event) resetData(this, src));
            
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
            drawnow;
            
            % delete associated residual if needed
            removeResidual(this, hData.fileID);

            % clear axis if no more data
            if isempty(this.axe.Children)
                legend(this.axe,'off');
                % clear pointer - prevent memory leaks
                this.hDispersion = [];
            else
                checkDisplayName(this);
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
                        % get all the errorbar
                        hPlot = findobj(this.axe.Children,'Type','Errorbar');
                        fileID = {this.hDispersion.fileID};
                        % loop to add error
                        for k = 1:numel(hPlot)
                            tf = strcmp(hPlot(k).Tag, fileID);
                            set(hPlot(k),...
                                'YNegativeDelta',-this.hDispersion(tf).dy(this.hDispersion(tf).mask),...
                            'YPositiveDelta',this.hDispersion(tf).dy(this.hDispersion(tf).mask));
                        end
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
                        % clear - prevent memory leaks
                        this.axeResScatter = [];
                        this.axeResHist = [];
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
            if ~this.optsButton.DataCheckButton.Value
                return
            end
            
            % check if we plot error or not
            if ~this.optsButton.ErrorCheckButton.Value
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
                    drawnow;
                    pause(0.001)
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
                     drawnow;
                end
            end
            
            % + plot masked data
            plotMaskedData(this, hData);
        end %plotData  
        
        % Add masked data
        function this = plotMaskedData(this, hData) 
            % check if we need to plot something
            if ~this.optsButton.MaskCheckButton.Value
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
                h = scatter(this.axe,...
                    hData(k).x(~hData(k).mask),...
                    hData(k).y(~hData(k).mask),...
                    'MarkerEdgeColor',this.PlotSpec(tf).Color,...
                    'Marker',this.DataMaskedMarkerStyle,...
                    'SizeData',this.DataMarkerSize,...
                    'MarkerFaceColor','auto',...
                    'Tag',hData(k).fileID);
                % remove this plot from legend
                set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                drawnow;
            end
        end %plotMaskedData
        
        % Add fit
        function this = plotFit(this, hData) 
            % check if we need to plot something
            if ~this.optsButton.FitCheckButton.Value
                return
            end
            
            % loop over the files
            for k = 1:length(hData)
                % find the index of the dispersion object
                tf = this.hDispersion == hData(k);
                % check if possible to plot fit
                if isempty(hData(k).processingMethod)
                    continue
                end
                % get x-values
                x = hData(k).x(hData(k).mask);
                % calculate yfit values and increase the  number of 
                % point to obtain better visualisation. Ensure you dont 
                % repeat point by geting the middle point each time
                x_add = diff(x/2); % get the interval between x pts
                x_fit = sort([x; x(1:end-1)+x_add]); %add it
                
                % get y-values
                y_fit = evaluate(hData(k).processingMethod,x_fit);

                % change the displayed name and add the rsquare
                fitName = sprintf('%s: %s (R^2 = %.3f)',...
                    hData(k).processingMethod.model.modelName, hData(k).filename,...
                    hData(k).processingMethod.model.gof.rsquare);

                % plot
                plot(this.axe, x_fit, y_fit,...
                    'DisplayName', fitName,...
                    'Color',this.PlotSpec(tf).Color,...
                    'LineStyle',this.PlotSpec(tf).FitStyle,...
                    'Marker',this.FitMarkerStyle,...
                    'Tag',hData(k).fileID); 
                drawnow;
            end
        end %plotFit
        
        % Add residual data
        function this = plotResidual(this)
            % check if we need to plot something
            if ~this.optsButton.ResidualCheckButton.Value 
                return
            end
            
            % get the handle to the plot(s)
            hFit = findobj(this.axe.Children, 'Type', 'Line');
            % get fileID
            hfileID = {hFit.Tag};
            
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
                hData = findobj(this.axe.Children,'Type','ErrorBar','Tag',hfileID{k});
                if isempty(hData)
                    continue
                end
                
                % make intersection between x from data and x from fit
                x = hData.XData;
                [~,~,idxx] = intersect(x, hFit(k).XData,'stable');
                                   
                % calculate residuals
                residual = hData.YData - hFit(k).YData(idxx); 
                % plot and set color, marker identical to data
                % use fileID from data but add the model specification
                % as userdata field
                h = plot(this.axeResScatter, x, residual,...
                    'LineStyle','none',...
                    'Color',hData.Color,...
                    'Marker',hData.Marker,...
                    'MarkerFaceColor',hData.Color,...
                    'MarkerSize',2,...
                    'Tag',hData.Tag);
                % addlistener to update dynamically the graph
                addlistener(hData,'Tag','PostSet',@(~,~)set(h,'Tag',hData.Tag)); 
                drawnow;
            end %loop plot
            % set axis
            this.axeResScatter.XScale = this.axe.XScale;
            this.axeResScatter.XLim = this.axe.XLim;
            this.axeResScatter.FontSize = this.axe.FontSize;
            grid(this.axeResScatter,'on');
            box(this.axeResScatter,'on');
            title(this.axeResScatter,'Residuals');
            % update the histogram
            makeResidualHistogram(this);
        end %plotResidual  
        
        % Remove residual data.
        function this = removeResidual(this, fileID)
            % check if we need to remove something
            if ~this.optsButton.ResidualCheckButton.Value 
                return
            end
            
            % check input
            if isempty(fileID) 
                tf = true(1);
            else
                tf = strcmp(fileID, get(this.axeResScatter.Children,'Tag'));
            end
            
            % delete them
            delete(this.axeResScatter.Children(tf));             
            drawnow;
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
            this.axeResHist.FontSize = this.axeResScatter.FontSize;
            % axis settings
            this.axeResHist.XLabel.String = this.axeResScatter.YLabel.String; 
            drawnow;
        end %makeResidualHistogram
        
        % Reset data
        function this = resetData(this, src)
            % flag for residuals
            residualFlag = 0;
            % loop over the file and reset data
            for k = 1:numel(src)
               % find plot
               hPlot = findobj(this.axe.Children,'Tag',src(k).fileID);
               
               % reset data
               hData = findobj(hPlot,'Type','ErrorBar');
               
               if ~isempty(hData)
                    hData.XData = src(k).x(src(k).mask);
                    hData.YData = src(k).y(src(k).mask);
                    % add error if needed
                    if ~isempty(hData.YNegativeDelta)
                        hData.YNegativeDelta = -src(k).dy(src(k).mask);
                        hData.YPositiveDelta = +src(k).dy(src(k).mask);
                    end
                    % clear if needed
                    if isempty(hData.YData)
                       delete(hData); 
                    end
                    drawnow;
               end
               
               
               % reset mask
               hMask = findobj(hPlot,'Type','Scatter');
               if ~isempty(hMask)
                    hMask.XData = src(k).x(~src(k).mask);
                    hMask.YData = src(k).y(~src(k).mask);
                    % clear if needed
                    if isempty(hMask.YData)
                       delete(hMask); 
                    end
                    drawnow;
               elseif this.optsButton.MaskCheckButton.Value
                   plotMaskedData(this, src(k));
               end
               
               % reset fit
               hFit = findobj(hPlot,'Type','Line');
               if ~isempty(hFit) && ~isempty(src.processingMethod)
                    hFit.XData = src(k).x(src(k).mask);
                    hFit.YData = evaluate(src.processingMethod, hFit.XData);
                    % clear if needed
                    if isempty(hFit.YData)
                       delete(hFit); 
                    end
                    drawnow;
               elseif this.optsButton.FitCheckButton.Value
                   plotFit(this, src(k));
               end
               % TO DO
               
               % reset residuals
               if ~isempty(this.axeResScatter)
                    hResidual = findobj(this.axeResScatter.Children,'Tag',src(k).fileID);
                    if ~isempty(hResidual)
                       hResidual.XData = hData.XData;
                       hResidual.YData = hFit.YData - hData.YData;
                       residualFlag = 1;   
                       % clear if needed
                       if isempty(hResidual.YData)
                            delete(hResidual); 
                       end
                    end
                    drawnow;
               end
            end
            % reset residual histogram if needed
            if residualFlag
                makeResidualHistogram(this);
            end
            % reset legend ?
            sortChildren(this);
        end %resetData
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
        
        % reset the legend if needed.
        function this = setLegend(this)                
            % check if we have children
            if isempty(this.axe.Children) || ~this.optsButton.LegendCheckButton.Value
                legend(this.axe,'off');
                return
            else
                legend(this.axe,'show')
                % check display names
                checkDisplayName(this);
            end
        end %setLegend
        
        % This function check the legend and check for duplicates. If
        % duplicates are found, the displayName property is added to the
        % input. If this property is not longer required (no duplicate), it
        % is removed.
        function this = checkDisplayName(this)
            % check if several children are displayed
            if numel(this.axe.Children) > 1
                % check data plot
                hPlot = findobj(this.axe.Children,'Type','ErrorBar');
                str_leg = get(hPlot,'DisplayName');
                fileID = get(hPlot,'Tag');
                % check if several data plot
                if iscell(str_leg)
                    % check if plot are coming from the same file
                    fileID = cellfun(@(x) strsplit(x,'@'),fileID,'Uniform',0);
                    plotID = cellfun(@(x) strcat(x{1:3}),fileID,'Uniform',0);
                    
                    [~,~,idx] = unique(plotID,'stable');
                    
                    for k = 1:max(idx)
                        % get plot coming from same file
                        tf = idx == k;
                        if sum(tf) > 1
                            % check if duplicate
                            if numel(unique({hPlot(tf).DisplayName})) ~= sum(tf)
                                hDuplicate = hPlot(tf);
                                % add extansion
                                for i = 1:numel(hDuplicate)
                                   ext = strsplit(hDuplicate(i).Tag,'@');
                                   new_leg = [hDuplicate(i).DisplayName,' (',ext{4},')'];
                                   hDuplicate(i).DisplayName = new_leg;
                                end
                            end
                        else
                            % check if same as filename
                            filename = fileID{tf};
                            if ~strcmp(hPlot(tf).DisplayName, filename{3})
                                hPlot(tf).DisplayName = filename{3};
                            end
                        end
                    end
                elseif ischar(str_leg)
                    fileID = strsplit(str_leg,'@');
                    if strcmp(fileID{3},str_leg)
                        % reset filename
                        set(hPlot,'DisplayName',fileID{3});
                    end
                end
            end
        end %checkDisplayName
        
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
                this.PlotSpec(1).FitStyle = this.FitLineStyle{1};
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
                    % set the first line style
                    this.PlotSpec(n+1).FitStyle = this.FitLineStyle{1};
                else
                    % set the same color as file found
                    color = {this.PlotSpec(tf_plot).Color};
                    this.PlotSpec(n+1).Color = color{1}; %if multiple 
                    % set the next marker
                    this.PlotSpec(n+1).DataMarker = this.DataMarkerStyle{sum(tf_plot)+1};
                    % set the next line style
                    this.PlotSpec(n+1).FitStyle = this.FitLineStyle{sum(tf_plot)+1};
                end
            end
        end % setPlotSpec  
        
        % update fileID if user change something
        function this = updateID(this, src)
            % find which field has changed
            tf_prop = strcmp(split(src.fileID,'@'),...
                {src.dataset, src.sequence, src.filename, src.displayName}');
            newFileID = strcat(src.dataset,'@',src.sequence,'@',src.filename,'@',src.displayName);
            % get the corresponding plot
            tf_plot = strcmp({this.axe.Children.Tag},src.fileID);
            % update their ID
            [this.axe.Children(tf_plot).Tag] = deal(newFileID);
            % if filename or displayname has changed, update legend
            if tf_prop(3) == 0
                [this.axe.Children(tf_plot).DisplayName] = deal(src.filename);
                checkDisplayName(this);
            elseif tf_prop(4) == 0
                checkDisplayName(this);
            end
        end %updateID
        
        % Display the mouse position
        function moveMouse(this)
            % get the current position
            C = get(this.axe,'CurrentPoint');
            % check if we are between boundaries
            if C(1,1) > this.axe.XLim(1) && C(1,1) < this.axe.XLim(2) &&...
                C(1,2) > this.axe.YLim(1) && C(1,2) < this.axe.YLim(2)
                % update the position in X/Y options
                set(this.optsButton.XPosText,'String',sprintf('%5.3e',C(1,1)));
                set(this.optsButton.YPosText,'String',sprintf('%5.3e',C(1,2)));
                drawnow;
            else
                % reset 
                set(this.optsButton.XPosText,'String','');
                set(this.optsButton.YPosText,'String','');
                drawnow;
            end
        end %moveMouse
        
        % Change axis scaling
        function setAxis(this, src)
            % check which axis need to be update
            if strcmp(src.Tag,'XAxisPopup')
                this.axe.XScale = src.String{src.Value};
            else
                this.axe.YScale = src.String{src.Value};
            end           
        end %setAxis
        
        % Mask data
        function maskData(this)
            % check if data are displayed
            if ~this.optsButton.DataCheckButton.Value || isempty(this.hDispersion)
                warning('Show or import data to mask them!')
                return
            end
            
            % let the user create a rectangle to select the data. Wait until
            % user double-click to get rectangle position
            warning off all %problem with negative value

            rectObj = imrect(this.axe);
            fcn = makeConstrainToRectFcn('imrect',this.axe.XLim,...
                this.axe.YLim);
            setPositionConstraintFcn(rectObj, fcn);
            pos = wait(rectObj);
            
            % delete the rectangle obj
            delete(rectObj)
            warning on all
            
            % range
            xrange = [pos(1) pos(1)+pos(3)];
            yrange = [pos(2) pos(2)+pos(4)];
            % call the presenter to update database
            eventdata = struct('Data',this.hDispersion,...
                               'Action', 'SetMask',...
                               'XRange',xrange,'YRange',yrange);
            setMask(this.FitLike, this, eventdata);
        end % maskData
        
        % Reset mask data
        function resetMaskData(this)
            % check if data are displayed
            if ~this.optsButton.DataCheckButton.Value || isempty(this.hDispersion)
                warning('Show or import data to reset mask!')
                return
            end
            
            % call the presenter with the axis limit
            eventdata = struct('Data',this.hDispersion,...
                               'Action', 'ResetMask');
            setMask(this.FitLike, this, eventdata);
        end % resetMaskData
        
        % Get fileID 
        function fileID = getFileID(this)
            % check if possible 
            if isempty(this.hDispersion)
                fileID = [];
            else
                fileID = {this.hDispersion.fileID};
            end
        end % getFileID
    end  
end

