classdef DispersionTab < DisplayTab
    %
    % Class that design containers for dispersion data
    %
    % SEE ALSO DISPLAYTAB, DISPLAYMANAGER, DISPERSION
    
    % Note: Plotting data requires lot of time, especially because
    % we need to dynamically update the legend (50% maybe) and the axis
    % (10%). Could be improved.
    
    % Display properties
    properties (Access = public)
        % Dispersion data settings
        DataLineStyle = 'none';
        DataMarkerStyle = {'o','^','s','>','*','p'}; % 6 plots from the same file at the same time
        DataMarkerSize = 4;
        % Dispersion data masked settings
        DataMaskedMarkerStyle = '+';
        % Dispersion fit settings
        FitLineStyle = '-';
        FitMarkerStyle = 'none';
        % Dispersion colors
        Color = get(groot,'defaultAxesColorOrder');
    end
    
    % Axis properties
    properties (Access = public, SetObservable)
        AxePosition = [0.09 0.09 0.86 0.86]; %position of the main axis
    end
    
    % Axis and Control properties
    properties (Access = public)
        optsButton % all the display/data options uicontrol
        axeres = [] % axis for the scatter plot (residuals)
        axehist = [] % axis for the histogram (residuals)
    end
    
    methods (Access = public)
        % Constructor
        function this = DispersionTab(FitLike, tab)
            % call the superclass constructor and set the Presenter
            this = this@DisplayTab(FitLike, tab);
            % set the name of the subtab and init accumColor
            this.Parent.Title = 'Dispersion';
            % change the main axis into a subplot (residuals plot)
            this.axe = subplot(3,2,1:6, this.axe);
            this.axe.Position = this.AxePosition; %reset Position
            
            % add display options under the axis
            this.optsButton = buildDisplayOptions(this.box);
            
            % set the default axis
            this.axe.XScale = this.optsButton.XAxisPopup.String{this.optsButton.XAxisPopup.Value};
            this.axe.YScale = this.optsButton.YAxisPopup.String{this.optsButton.YAxisPopup.Value}; 
            %%% ----------------------- CALLBACK ---------------------- %%%
            % checkbox callback
            set(this.optsButton.DataCheckButton,'Callback',...
                @(src, event) showData(this));           
            set(this.optsButton.ErrorCheckButton,'Callback',...
                @(src, event) showError(this));            
            set(this.optsButton.FitCheckButton,'Callback',...
                @(src, event) showFit(this));            
            set(this.optsButton.MaskCheckButton,'Callback',...
                @(src, event) showMask(this));            
            set(this.optsButton.ResidualCheckButton,'Callback',...
                @(src, event) showResidual(this));              
            set(this.optsButton.LegendCheckButton,'Callback',...
                @(src, event) showLegend(this)); 
                       
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
            drawnow;
        end
    end
    
    methods (Access = public)        
        % Add plot. 
        function [this, tf] = addPlot(this, hData, varargin)
            % check input
            if ~isa(hData,'Dispersion')
                tf = 1;
                return
            end
            % check if duplicates
            if isempty(this.hData)
                tf = 0;
            elseif ~all((this.hData == hData) == 0)
                tf = 1;
                return
            else
                tf = 0;
            end
            % append data
            this.hData = [this.hData hData];
            % add listener 
            addlistener(hData,'FileHasChanged',@(src, event) updateID(this, src)); 
            addlistener(hData,'DataHasChanged',@(src, event) updateData(this, src));
            addlistener(hData,'FileDeletion', @(src, event) removeData(this, hData));
            % + set plot specification
            getPlotSpec(this, hData);
            
            % + data
            showData(this);

            % + fit
            showFit(this);
            
            % + residuals
            showResidual(this);

            % + legend
            showLegend(this);
            
            % + axis
            setLabel(this, hData);
        end %addPlot
        
        % Remove plot.
        function this = deletePlot(this, hData, varargin)
            % get all plot corresponding to the hData and delete them
            hAxe = findobj(this, 'Type', 'axes');
            % loop
            for k = 1:numel(hAxe)
                hPlot = findobj(hAxe(k).Children, 'Tag', hData.fileID);
                delete(hPlot)
            end
            drawnow;
            showLegend(this);
            % remove handle
            tf = strcmp({this.hData.fileID}, hData.fileID);  
            this.hData = this.hData(~tf);
            this.PlotSpec = this.PlotSpec(~tf);
        end %deletePlot    
                        
        % Reset data
        function this = updateData(this, src)
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
               elseif this.optsButton.MaskCheckButton.Value
                   tf = strcmp({this.hData.fileID}, src(k).fileID);
                   plotMaskedData(src(k), this.axe, this.PlotSpec(tf).Color,...
                        this.DataMaskedMarkerStyle, this.DataMarkerSize);
               end
               
               % reset fit
               hFit = findobj(hPlot,'Type','Line');
               if ~isempty(hFit) && ~isempty(src(k).processingMethod)
                    hFit.XData = sort(src(k).x(src(k).mask));
                    hFit.YData = evaluate(src(k).processingMethod, hFit.XData);
                    % clear if needed
                    if isempty(hFit.YData)
                       delete(hFit); 
                    end
               elseif this.optsButton.FitCheckButton.Value
                   tf = strcmp({this.hData.fileID}, src(k).fileID);
                   plotFit(src(k), this.axe, this.PlotSpec(tf).Color,...
                    this.FitLineStyle, this.FitMarkerStyle);
               end
               
               % reset residuals
               if ~isempty(this.axeres)
                    hResidual = findobj(this.axeres.Children, 'Tag', src(k).fileID);
                    if ~isempty(hResidual)
                       hResidual.XData = hData.XData;
                       hResidual.YData = hFit.YData - hData.YData; 
                       % clear if needed
                       if isempty(hResidual.YData)
                            delete(hResidual); 
                       end
                    end
               end
            end
            drawnow;
        end %updateData
                        
        % Update fileID of the plot
        function this = updateID(this, hData)
            % find which field has changed
            fileID = strsplit(hData.fileID,'@');
            tf_prop = strcmp(fileID,...
                {hData.dataset, hData.sequence, hData.filename, hData.displayName});
            % get the corresponding plot
            hPlot = findobj(this.axe.Children, 'Tag', hData.fileID);
            % update their fileID
            if ~isempty(hPlot)
                % get the current fileID
                new_fileID = strcat(hData.dataset,'@',hData.sequence,'@',...
                    hData.filename,'@',hData.displayName);
                % update all the fileID
                [hPlot.Tag] = deal(new_fileID);
                
                % if filename or legendTag, update legend ?
                if tf_prop(3) == 0
                    [hPlot.DisplayName] = deal(hData.filename);
                    checkDisplayName(this);
                elseif tf_prop(4) == 0
                    checkDisplayName(this);
                end
            end 
        end %updateID
    end
    
    % Respond to the display options callback
    methods 
        function this = showData(this)
            % check input
            if this.optsButton.DataCheckButton.Value
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axe.Children,'Type','ErrorBar','Tag',this.hData(k).fileID);
                    if isempty(hPlot)
                        hPlot = plotData(this.hData(k), this.axe,...
                            this.PlotSpec(k).Color, this.DataLineStyle,...
                            this.PlotSpec(k).DataMarker, this.DataMarkerSize);
                        set(hPlot, 'ButtonDownFcn' ,...
                            @(src, event) selectZone(this.FitLike, src, event));
                    end
                end
                drawnow;
                showError(this);
                showMask(this);
            else
                delete(findobj(this.axe.Children,'Type','ErrorBar'));
                delete(findobj(this.axe.Children,'Type','Scatter'));
                drawnow;
            end
            showLegend(this);
        end %showData
        
        function this = showError(this)
            % check input
            if this.optsButton.ErrorCheckButton.Value
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axe.Children,'Type','ErrorBar','Tag',this.hData(k).fileID);
                    if ~isempty(hPlot)
                        addError(this.hData(k), hPlot);
                    end
                end
            else
                set(findobj(this.axe.Children,'Type','ErrorBar'),...
                    'YNegativeDelta',[],'YPositiveDelta',[]);
            end
            drawnow;
        end %showError
        
        function this = showFit(this)
            % check input
            if this.optsButton.FitCheckButton.Value
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axe.Children, 'Type','Line', 'Tag',this.hData(k).fileID);
                    if isempty(hPlot)
                        plotFit(this.hData(k), this.axe, this.PlotSpec(k).Color,...
                            this.FitLineStyle, this.FitMarkerStyle);
                    end
                end
            else
                delete(findobj(this.axe.Children,'Type','Line'));
            end
            drawnow;
            showLegend(this);
        end %showFit
        
        function this = showMask(this)
            % check input
            if this.optsButton.MaskCheckButton.Value
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axe.Children, 'Type','Scatter', 'Tag',this.hData(k).fileID);
                    if isempty(hPlot)
                        plotMaskedData(this.hData(k), this.axe,...
                            this.PlotSpec(k).Color, this.DataMaskedMarkerStyle,...
                            this.DataMarkerSize);
                    end
                end
            else
                delete(findobj(this.axe.Children,'Type','Scatter'));
            end
            drawnow;
        end %showMask
        
        function this = showResidual(this)
            % check input
            if this.optsButton.ResidualCheckButton.Value
                plotResidual(this);
            else
                % delete the residual axis
                delete(this.axeres); this.axeres = [];
                delete(this.axehist); this.axehist = [];
                % reset the main axis
                subplot(3,2,1:6, this.axe);
                this.axe.Position = this.AxePosition;
            end   
            drawnow;
        end %showResidual
        
        function this = showLegend(this)
           if this.optsButton.LegendCheckButton.Value
               % check if children
               if isempty(this.axe.Children)
                   legend(this.axe, 'off');
               else                  
                   legend(this.axe, 'show');
                   set(this.axe.Legend,'Interpreter','none');
                   sortChildren(this);
                   % check display names
                   checkDisplayName(this);
               end
           else
               legend(this.axe, 'off');
           end
           drawnow;
        end %showLegend
    end
    
    % Plot methods: residuals
    methods (Access = public)               
        % Add residual data
        function this = plotResidual(this)
            % get the handle to the plot(s)
            hFit = findobj(this.axe.Children, 'Type', 'Line');
            % check if fit
            if isempty(hFit)
                return
            else
                hfileID = {hFit.Tag};
            end
            
            % check if residual axis exists
            if isempty(this.axeres)
                createResidualAxis(this);            
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
                h = plot(this.axeres, x, residual,...
                    'LineStyle','none',...
                    'Color',hData.Color,...
                    'Marker',hData.Marker,...
                    'MarkerFaceColor',hData.Color,...
                    'MarkerSize',2,...
                    'Tag',hData.Tag);
                % addlistener to update dynamically the graph
                addlistener(hData,'Tag','PostSet',@(~,~)set(h,'Tag',hData.Tag)); 
            end %loop plot
            
            makeResidualHistogram(this);
        end %plotResidual  
        
        % Create residual axis
        function this = createResidualAxis(this)
            % move the main axis
            subplot(3,2,1:4, this.axe);
            % create the axis
            this.axeres = subplot(3,2,5);
            this.axehist = subplot(3,2,6);
            % axis settings
            this.axeres.NextPlot = 'add'; 
            grid(this.axeres, 'on'); box(this.axeres, 'on');
            title(this.axeres, 'Residuals');
            % link some prop to the main axis
            addlistener(this.axe, 'XScale', 'PostSet',...
                @(~,~) set(this.axeres,'XScale',this.axe.XScale));
            addlistener(this.axe, 'XLim', 'PostSet',...
                @(~,~) set(this.axeres,'XLim',this.axe.XLim));
            addlistener(this.axe, 'XLabel', 'PostSet',...
                @(~,~) set(this.axeres,'XLabel',this.axe.XLabel));
            addlistener(this.axe, 'YLabel', 'PostSet',...
                @(~,~) set(this.axeres,'YLabel',this.axe.YLabel));
            addlistener(this.axe, 'FontSize', 'PostSet',...
                @(~,~) set(this.axeres,'FontSize',this.axe.FontSize-2)); 
            % update dynamically histogram
            addlistener(this.axeres, 'FontSize', 'PostSet',...
                @(~,~) set(this.axehist,'FontSize',this.axeres.FontSize)); 
            addlistener(this.axeres, 'YLabel', 'PostSet',...
                @(~,~) set(this.axehist,'XLabel', this.axeres.YLabel));
        end %createResidualAxis
        
        % Add an histogram of the residuals
        function this = makeResidualHistogram(this)
            % check if residuals
            if isempty(this.axeres.Children)
                cla(this.axehist)
                title(this.axehist,'')
            else
                % get all the residuals 
                residual = get(this.axeres.Children,'YData');
                if iscell(residual)
                   residual = [residual{:}]; %append residuals
                end
                % make an histogram
                histogram(this.axehist,residual)
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
                title(this.axehist, txt);
                drawnow;
            end
        end %makeResidualHistogram
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
                    fileID = strsplit(fileID,'@');
                    if ~strcmp(fileID{3},str_leg)
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
        function this = getPlotSpec(this, hData)
            % set properties
            if numel(this.hData) == 1
                this.PlotSpec(1).Color = this.Color(1,:);
                this.PlotSpec(1).DataMarker = this.DataMarkerStyle{1};
            else
                n = numel(this.PlotSpec);
                % set specification: look if same file is plot
                plotID = strcat({this.hData.dataset},...
                                 {this.hData.sequence},...
                                 {this.hData.filename});
                tf_plot = strcmp(plotID(1:end-1), strcat(hData.dataset,...
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
        
        function this = setLabel(this, hData)
            % check axis
            if isempty(this.axe.XLabel.String)
                % set name defined in hData
                xlabel(this.axe, hData.xLabel,'FontSize',12)
                ylabel(this.axe, hData.yLabel,'FontSize',12)
            else
                % check if the same or not
                xName = this.axe.XLabel.String;
                if ~strcmp(xName, hData.xLabel)
                    warndlg('Not the same xLabel!')
                end
                
                yName = this.axe.YLabel.String;
                if ~strcmp(yName, hData.yLabel)
                    warndlg('Not the same xLabel!')
                end               
            end
        end %setLabel
        
        % Get fileID 
        function fileID = getFileID(this)
            % check if possible 
            if isempty(this.hData)
                fileID = [];
            else
                fileID = {this.hData.fileID};
            end
        end % getFileID
    end
    
    % Data Options methods
    methods
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
            if ~this.optsButton.DataCheckButton.Value || isempty(this.hData)
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
            eventdata = struct('Data',this.hData,...
                               'Action', 'SetMask',...
                               'XRange',xrange,'YRange',yrange);
            setMask(this.FitLike, this, eventdata);
        end % maskData
        
        % Reset mask data
        function resetMaskData(this)
            % check if data are displayed
            if ~this.optsButton.DataCheckButton.Value || isempty(this.hData)
                warning('Show or import data to reset mask!')
                return
            end
            
            % call the presenter with the axis limit
            eventdata = struct('Data',this.hData,...
                               'Action', 'ResetMask');
            setMask(this.FitLike, this, eventdata);
        end % resetMaskData
    end
end

