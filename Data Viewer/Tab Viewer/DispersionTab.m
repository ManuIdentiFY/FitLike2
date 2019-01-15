classdef DispersionTab < EmptyTab
    %
    % Class that design containers for dispersion data
    %
    % SEE ALSO DISPLAYTAB, DISPLAYMANAGER, DISPERSION
    
    % Note: Plotting data requires lot of time, especially because
    % we need to dynamically update the legend (50% maybe) and the axis
    % (10%). Could be improved.
    %
    % To do:
    % - add a method to handle axis configuration
    % - change sortChildren() method (also name maybe?)
    % - check the legend!!
    %
    % M.Petit - 11/2018
    % manuel.petit@inserm.fr
    
    % Display properties
    properties (Access = public)
        % Dispersion data settings
        DataLineStyle = 'none';
        DataMarkerStyle = {'o','^','s','>','*','p'}; % 6 plots from the same file at the same time
        DataMarkerSize = 6;
        % Dispersion data masked settings
        DataMaskedMarkerStyle = '+';
        % Dispersion fit settings
        FitLineStyle = '-';
        FitMarkerStyle = 'none';
        % Residual settings
        ResidualSize = 3;
        ResidualStyle = 'none';
        % Dispersion colors
        Color = get(groot,'defaultAxesColorOrder');
        % Selected point
        SelectedPoint
    end
    
    % Axis properties
    properties (Access = public, SetObservable) %%??? [Manu]
        axe
        AxePosition = [0.09 0.09 0.86 0.86]; %position of the main axis
    end
    
    % Axis and Control properties
    properties (Access = public)
        optsButton % all the display/data options uicontrol
        axezone  % axis to visualise quickly zone data
        axeres   % axis for the scatter plot (residuals)
        axehist  % axis for the histogram (residuals)
    end
    
    events
        UpdateHist
    end
    
    methods (Access = public)
        % Constructor
        function this = DispersionTab(DisplayManager, tab)
            % call the superclass constructor and set the Presenter
            this = this@EmptyTab(DisplayManager, tab);
            % set the name of the subtab
            this.Parent.Title = 'Dispersion';
            this.inputType = 'Dispersion';
            % change the main axis into a subplot
            this.axe = axes('Parent', uicontainer('Parent',this.box),...
                        'FontSize',8,...
                        'ActivePositionProperty', 'outerposition',...
                        'Position',[0.09 0.09 0.86 0.86],...
                        'NextPlot','Add');
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
        function this = addPlot(this, hData, idxZone)
            % check input
            if ~isa(hData, this.inputType); return; end
            
            % check if duplicates
            if isempty(this.hData) || all(strcmp(getPlotID(this),...
                    getPlotID(this, hData, idxZone)) == 0) 
                % append data
                this.hData = [this.hData hData];
                this.idxZone = [this.idxZone idxZone];

                % add listener 
                addlistener(hData,'DataUpdate',@(src, event) updateData(this, src, event));
                addlistener(hData,'DataDeletion', @(src, event) deletePlot(this, hData));
                addlistener(hData.relaxObj,'FileHasChanged',@(src, event) updateLegend(this, src, event));
                
                % set plot specification
                getPlotSpec(this, hData);
            end
            
            % + data
            showData(this);

            % + fit
            showFit(this);
            
            % + residuals
            showResidual(this);
            
            % + axis
            setLabel(this, hData);
        end %addPlot
        
        % Remove plot.
        function this = deletePlot(this, hData, idxZone)
            % check input
            if nargin < 3; idxZone = NaN; end
            
            % get all plot corresponding to the hData and delete them
            hAxe = findobj(this, 'Type', 'axes');
            plotID = getPlotID(this, hData, idxZone);
            % check input          
            if isnan(idxZone)
                % remove all zone belonging to hData
                indx = strfind(plotID, '@');
                dataID = plotID(1:indx(2)-1);
                % loop over axis
                for k = 1:numel(hAxe)
                    if isempty(hAxe(k).Children)
                        continue
                    end
                    tf = contains(get(hAxe(k).Children,'Tag'), dataID);
                    delete(hAxe(k).Children(tf));
                end
                fileID = arrayfun(@(x) getRelaxProp(x, 'fileID'),...
                                           this.hData, 'Uniform', 0);
                tf = strcmp(strcat(fileID,'@', {this.hData.displayName}), dataID);  
            else
                % loop over axis
                for k = 1:numel(hAxe)
                    delete(findobj(hAxe(k).Children, 'Tag', plotID));
                end
                drawnow;
                tf = strcmp(getPlotID(this), plotID);  
            end    
            % notify
            notify(this, 'UpdateHist');
            % reset & check legend
            showLegend(this);
            checkLegend(this, hData);
            % remove handle
            this.hData = this.hData(~tf); 
            this.PlotSpec = this.PlotSpec(~tf);
            this.idxZone = this.idxZone(~tf);    
        end %deletePlot    
                        
        % Reset data
        function this = updateData(this, src, event)
            % check if the source is a new data
            tf = this.hData == src;
            if all(tf == 0)
                %add plot
                addPlot(this, src, event.idxZone);
            else     
               plotID = getPlotID(this, src, event.idxZone);
               % find plot containing this ID
               tf_plot = strcmp(get(this.axe.Children,'Tag'), plotID);
               hPlot = this.axe.Children(tf_plot);
                   
               % reset data
               hData = findobj(hPlot,'Type','ErrorBar');
               % check existence
               if ~isempty(hData)
                   % get data
                   [x,y,dy,mask] = getData(src, event.idxZone);
                   % update data
                   hData.XData = x(mask);
                   hData.YData = y(mask);
                   % add error if needed
                   if ~isempty(hData.YNegativeDelta)
                        hData.YNegativeDelta = -dy(mask);
                        hData.YPositiveDelta = +dy(mask);
                   end
                   % clear if needed
                   if isempty(hData.YData)
                       delete(hData); 
                   end
               end

               % reset mask
               hMask = findobj(hPlot,'Type','Scatter');
               % check existence
               if ~isempty(hMask)
                   % check data existence
                   if ~exist('x','var')
                       [x,y,~,mask] = getData(src, event.idxZone);
                   end
                   % update data
                   hMask.XData = x(~mask);
                   hMask.YData = y(~mask);
                   % clear if needed
                   if isempty(hMask.YData)
                       delete(hMask);
                   end
               end

               % reset fit
               hFit = findobj(hPlot,'Type','Line');
               [xfit, yfit] = getFit(src, event.idxZone,[]);
               % check existence
               if isempty(hFit) && ~isempty(yfit)
                   % plot
                   showFit(this);
               elseif ~isempty(hFit)
                   % update data
                   hFit.XData = xfit;
                   hFit.YData = yfit;
                   % clear if needed
                   if isempty(hFit.YData)
                       delete(hFit);
                   end
               end

               % reset residuals
               if ~isempty(this.axeres)
                   hResidual = findobj(this.axeres.Children,'Tag',plotID);
                   % get residual data
                   [x,y,~,mask] = getData(src, event.idxZone);
                   [~, yfit] = getFit(src, event.idxZone, x(mask));
                   yres = y(mask) - yfit;
                   if isempty(hResidual) && ~isempty(yres)
                       % plot
                       showResidual(this);
                   else
                       set(hResidual,'XData',x(mask),'YData',yres);
                       % clear if needed
                       if isempty(hResidual.YData)
                           delete(hResidual);
                       end
                   end
                   % notify
                   notify(this, 'UpdateHist');
               end
            end
%             drawnow;
            showLegend(this);
            checkLegend(this, src);
            drawnow;
        end %updateData
        
        % Update legend: if filename changed
        function this = updateLegend(this, src, event)
            % get the plot
            tf = contains(get(this.axe.Children,'Tag'), src.fileID);
            hPlot = this.axe.Children(tf);
            % replace their legend
            for k = 1:numel(hPlot)
                % check if displayName
                if ~isempty(hPlot(k).DisplayName)
                   hPlot(k).DisplayName = strrep(hPlot(k).DisplayName,...
                                                event.OldName, event.NewName);                   
                end
            end            
        end %updateLegend
    end
    
    % Respond to the display options callback
    methods 
        function this = showData(this)
            % check input
            if this.optsButton.DataCheckButton.Value
                % get ID
                plotID = getPlotID(this);
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axe.Children,...
                        'Type','ErrorBar','Tag', plotID{k});
                    if isempty(hPlot)
                        h = plotData(this.hData(k), this.idxZone(k), plotID{k},...
                            this.axe, this.PlotSpec(k).Color, this.DataLineStyle,...
                            this.PlotSpec(k).DataMarker, this.DataMarkerSize);
                        % add callback to dispersion 
                        set(h,'ButtonDownFcn',@(s,e) selectData(this,s,e));
                        % check legend
                        checkLegend(this, this.hData(k));
                    end
                end
                showError(this);
                showMask(this);
            else
                delete(findobj(this.axe.Children,'Type','ErrorBar'));
                delete(findobj(this.axe.Children,'Type','Scatter'));
            end
            drawnow;
            showLegend(this);
        end %showData
        
        function this = showError(this)
            % check input
            if this.optsButton.ErrorCheckButton.Value
                 % get ID
                plotID = getPlotID(this);
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axe.Children,...
                        'Type','ErrorBar','Tag', plotID{k});
                    if ~isempty(hPlot)
                        addError(this.hData(k), this.idxZone(k), hPlot);
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
                % get ID
                plotID = getPlotID(this);
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axe.Children,...
                        'Type','Line', 'Tag', plotID{k});
                    if isempty(hPlot)
                        plotFit(this.hData(k), this.idxZone(k), plotID{k},...
                            this.axe, this.PlotSpec(k).Color,...
                            this.FitLineStyle, this.FitMarkerStyle);
                        % check legend
                        checkLegend(this, this.hData(k));
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
                % get ID
                plotID = getPlotID(this);
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axe.Children,...
                        'Type','Scatter', 'Tag', plotID{k});
                    if isempty(hPlot)
                        plotMaskedData(this.hData(k), this.idxZone(k), plotID{k},...
                            this.axe, this.PlotSpec(k).Color,...
                            this.DataMaskedMarkerStyle, this.DataMarkerSize);
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
                % check if residual axis exists
                if isempty(this.axeres)
                    createResidualAxis(this);            
                end
                % get ID
                plotID = getPlotID(this);
                for k = 1:numel(this.hData)
                    % check plot existence
                    hPlot = findobj(this.axeres.Children, 'Tag', plotID{k});
                    if isempty(hPlot)
                        plotResidual(this.hData(k), this.idxZone(k),...
                            plotID{k}, this.axeres, this.PlotSpec(k).Color,...
                            this.ResidualStyle, this.PlotSpec(k).DataMarker,...
                            this.ResidualSize);
                    end
                end
                % notify
                notify(this, 'UpdateHist');
            else
                % delete the residual axis
                delete(this.axeres); this.axeres = [];
                delete(this.axehist); this.axehist = [];
                % reset the main axis
                if isempty(this.axezone)
                    subplot(3,2,1:6, this.axe);
                    this.axe.Position = this.AxePosition;
                else
                    subplot(3,2,[1 3 5], this.axe);
                    subplot(3,2,[2 4 6], this.axezone);
                end
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
               end
           else
               legend(this.axe, 'off');
           end
        end %showLegend
    end
    
    % Plot methods: residuals
    methods (Access = public)               
        % Create residual axis
        function this = createResidualAxis(this)
            % move the main axis
            if isempty(this.axezone)
                subplot(3,2,1:4, this.axe);
            else
                subplot(3,2,[1 3], this.axe);
                subplot(3,2,[2 4], this.axezone);
            end
            % create the axis
            this.axeres = subplot(3,2,5);
            this.axehist = subplot(3,2,6);
            % axis settings
            this.axeres.NextPlot = 'add'; 
            grid(this.axeres, 'on'); box(this.axeres, 'on');
            set(this.axeres,'XScale',this.axe.XScale,'XLim',this.axe.XLim,...
                'FontSize',this.axe.FontSize-2);
            xlabel(this.axeres, this.axe.XLabel.String);
            ylabel(this.axeres, 'Residual');
            % link some prop to the main axis
            addlistener(this.axe, 'XScale', 'PostSet',...
                @(~,~) set(this.axeres,'XScale',this.axe.XScale));
            addlistener(this.axe, 'XLim', 'PostSet',...
                @(~,~) set(this.axeres,'XLim',this.axe.XLim));
            % update dynamically histogram
            addlistener(this, 'UpdateHist', @(~,~) makeResidualHistogram(this));
        end %createResidualAxis
        
        % Add an histogram of the residuals
        function this = makeResidualHistogram(this)
            % check existence
            if isempty(this.axeres); return; end
            
            % check if residuals
            if isempty(this.axeres.Children)
                title(this.axehist,'');
            else
                % get all the residuals 
                residual = get(this.axeres.Children,'YData');
                if iscell(residual)
                   residual = [residual{:}]; %append residuals
                end
                % make an histogram
                histogram(this.axehist,residual);
                set(this.axehist,'FontSize',this.axeres.FontSize);
                xlabel(this.axehist, 'Residual');
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
        
        % Just callback 
        function this = selectData(this, src, e)
            % check source 
            if strcmp(src.Tag, 'SelectedPoint')
                % delete current selected point
                delete(this.SelectedPoint);
                this.SelectedPoint = []; %clear
                % delete zone axis
                delete(this.axezone); this.axezone = [];
                % reset other axis
                if isempty(this.axeres)
                    subplot(3,2,1:6, this.axe);
                    this.axe.Position = this.AxePosition;
                else
                    subplot(3,2,1:4, this.axe);
                end
                return
            end
            % get the associated data
            [~,idx,~] = intersect(getPlotID(this), src.Tag);
            % check if associated idxZone
            idxZone = strsplit(src.Tag,'@');
            idxZone = str2double(idxZone{end});
            % if no zone, get it by the intersection point
            if isnan(idxZone)
                % get the zone index
                [~,idxZone] = min(abs(this.hData(idx).x - e.IntersectionPoint(1)));
                % check if the object is selected
                if isempty(this.SelectedPoint)
                    % create a marker
                    this.SelectedPoint = plot(this.axe,...
                            this.hData(idx).x(idxZone), this.hData(idx).y(idxZone),...
                            'LineStyle','none','Marker','s','MarkerSize',14,...
                            'Color','k','ButtonDownFcn',@(s,e) selectData(this,s,e),...
                            'Tag','SelectedPoint');
                    set(get(get(this.SelectedPoint,'Annotation'),...
                        'LegendInformation'),'IconDisplayStyle','off');
                    % create a new axis
                    if isempty(this.axeres)
                        subplot(3,2,[1 3 5], this.axe);
                        this.axezone = subplot(3,2,[2 4 6]);
                    else
                        subplot(3,2,[1 3], this.axe);
                        this.axezone = subplot(3,2,[2 4]);
                    end
                    this.axezone.NextPlot = 'add'; 
                    % plot parent data with error
                    h = plotData(this.hData(idx).parent, idxZone, '',...
                        this.axezone, src.Color, src.LineStyle, src.Marker, src.MarkerSize);
                    addError(this.hData(idx).parent, idxZone, h);
                    % add fit
                    plotFit(this.hData(idx).parent, idxZone, '', this.axezone,... 
                        src.Color, this.FitLineStyle, this.FitMarkerStyle);
                    % set fontsize
                    set(this.axezone, 'FontSize', 8);
                    xlabel(this.axezone, this.hData(idx).parent.xLabel);
                    ylabel(this.axezone, this.hData(idx).parent.yLabel);
                    % add legend
                    legend(this.axezone,'show');
                    set(this.axezone.Legend,'Interpreter','none');
                else
                    % update selected point
                    this.SelectedPoint.XData = this.hData(idx).x(idxZone);
                    this.SelectedPoint.YData = this.hData(idx).y(idxZone);
                    % update current plot obj
                    [x,y,dy,mask] = getData(this.hData(idx).parent, idxZone);
                    % +data
                    hData = findobj(this.axezone, 'Type', 'errorbar');
                    if ~isempty(hData) && ~isempty(y(mask))
                        set(hData, 'XData', x(mask), 'YData', y(mask));
                        % add error
                        if ~isempty(dy)
                            set(hData, 'YNegativeDelta',-dy(mask),...
                                'YPositiveDelta',dy(mask));
                        end
                        % update color, marker, displayName
                        set(hData,'Color',src.Color,'LineStyle',src.LineStyle,...
                            'Marker',src.Marker,'MarkerSize',src.MarkerSize);
                        leg = getLegend(this.hData(idx).parent, idxZone, 'Data', 0);
                        if ~strcmp(leg, hData.DisplayName)
                            hData.DisplayName = leg;
                        end
                    elseif ~isempty(hData)
                        delete(hData);
                    end
                    % +fit
                    hFit = findobj(this.axezone, 'Type', 'line');
                    [xfit, yfit] = getFit(this.hData(idx).parent, idxZone, []);
                    if ~isempty(hFit) && ~isempty(yfit)
                        set(hFit, 'XData', xfit, 'YData', yfit);
                        % update color, marker, displayName
                        set(hFit,'Color',src.Color);
                        leg = getLegend(this.hData(idx).parent, idxZone, 'Fit', 0);
                        if ~strcmp(leg, hData.DisplayName)
                            hFit.DisplayName = leg;
                        end
                    elseif ~isempty(hFit)
                        delete(hFit);
                    end
                end
            else
                % for now
                return
            end
        end % selectData
    end
    
    % Other function
    methods (Access = public)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Change for legend sorting [Manu]
        % this function sort the axis children according to their tag
        % as well as their type (data1 fit1 data2 fit2 ...)
        function this = sortChildren(this)
            % Check if several plot
            if numel(this.axe.Children) > 1
                % get the fileID and the type
                plotID = get(this.axe.Children,'Tag');
                type = get(this.axe.Children,'Type');
                % concatenate and sort
                [~,idx] = sort(strcat(plotID, type));
                % re-order children
                this.axe.Children = this.axe.Children(flipud(idx));
            end
        end %sortChildren
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % This function check the legend and check for duplicates from hData. If
        % duplicates are found, the displayName property is added to the
        % input. If this property is not longer required (no duplicate), it
        % is removed.
        function this = checkLegend(this, hData)
            % check children number
            if numel(this.hData) < 2
                return
            end
            % to help: will be removed latter [M.Petit]
            type = {'Data','Fit','Mask'};
            plottype = {'ErrorBar','Line','Scatter'};
            % check if other hData are coming from same file
            fileID = arrayfun(@(x) getRelaxProp(x, 'fileID'),...
                                           this.hData, 'Uniform', 0);
            idx = find(strcmp(fileID, getRelaxProp(hData, 'fileID')));

            % change legend
            if numel(idx) > 1
                tf = contains(get(this.axe.Children,'Tag'),...
                    getRelaxProp(hData, 'fileID'));
                hPlot = this.axe.Children(tf);
                % check if multiple plot with same legend
                if numel(hPlot) > 1 && ~all(strcmpi(get(hPlot,'Type'),...
                                            hPlot(1).Type) == 0)
                    extend = 1;
                else
                    extend = 0;
                end
                % loop over the plot
                for j = 1:numel(hPlot)
                    % get idxZone
                    idxZone = strsplit(hPlot(j).Tag,'@');
                    idxZone = str2double(idxZone{end});
                    % get type
                    tf = strcmpi(plottype, hPlot(j).Type);
                    % assign legend: simplify or extend
                    leg = getLegend(hData, idxZone, type{tf}, extend);
                    if ~strcmp(hPlot(j).DisplayName, leg)
                        hPlot(j).DisplayName = leg;
                    end
                end
            end
        end %checkLegend
        
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
                fileID = arrayfun(@(x) getRelaxProp(x, 'fileID'),...
                                           this.hData, 'Uniform', 0);
                tf_plot = strcmp(fileID, getRelaxProp(hData, 'fileID'));
                
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
                    if sum(tf_plot) < numel(this.DataMarkerStyle)
                        idx = sum(tf_plot) + 1;
                    else
                        idx = numel(this.DataMarkerStyle);
                    end
                    this.PlotSpec(n+1).DataMarker = this.DataMarkerStyle{idx};
                end
            end
        end % setPlotSpec  
        
        % set label
        function this = setLabel(this, hData)
            % check axis
            if isempty(this.axe.XLabel.String)
                % set name defined in hData
                xlabel(this.axe, hData.xLabel,'FontSize',10)
                ylabel(this.axe, hData.yLabel,'FontSize',10)
            else
                % check if the same or not
                xName = this.axe.XLabel.String;
                if ~strcmp(xName, hData.xLabel)
                    txt = 'Warning: A new label for x-axis is detected!\n';
                    throwWrapMessage(this.DisplayManager, txt)
                end
                
                yName = this.axe.YLabel.String;
                if ~strcmp(yName, hData.yLabel)
                    txt = 'Warning: A new label for y-axis is detected!\n';
                    throwWrapMessage(this.DisplayManager, txt)
                end               
            end
        end %setLabel
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
            else
                % reset 
                set(this.optsButton.XPosText,'String','');
                set(this.optsButton.YPosText,'String','');
            end
            drawnow;
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
                txt = 'Warning: Show or import data to mask them!\n';
                throwWrapMessage(this.DisplayManager, txt)
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
                               'idxZone', this.idxZone,...
                               'Action', 'SetMask',...
                               'XRange',xrange,'YRange',yrange);
            setMask(this.DisplayManager, this, eventdata);
        end % maskData
        
        % Reset mask data
        function resetMaskData(this)
            % check if data are displayed
            if ~this.optsButton.DataCheckButton.Value || isempty(this.hData)
                txt = 'Warning: Show or import data to mask them!\n';
                throwWrapMessage(this.DisplayManager, txt)
                return
            end
            
            % call the presenter with the axis limit
            eventdata = struct('Data',this.hData,...
                               'idxZone', this.idxZone,...
                               'Action', 'ResetMask');
            setMask(this.DisplayManager, this, eventdata);
        end % resetMaskData
        
        % get legend: avoid fit
        function [leg, relaxObj] = getLegend(this)
            % get the data plotted
            hData = findobj(this.axe.Children,'Type','ErrorBar');
            
            if isempty(hData)
                leg = []; relaxObj = []; return
            else
                leg = {hData.DisplayName}; 
                relaxObj = [hData.relaxObj];
            end
        end %getLegend
    end
end

