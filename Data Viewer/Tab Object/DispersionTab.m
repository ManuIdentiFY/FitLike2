classdef DispersionTab < EmptyTab
    %
    % Class that design containers for dispersion data. Only Dispersion
    % object can be added to this tab class.
    %
    % SEE ALSO EMPTYTAB, DISPLAYMANAGER, DISPERSION
    %
    %
    % Note: Plotting data requires lot of time, especially because
    % we need to dynamically update the legend (50% maybe) and the axis
    % (10%). Could be improved.
    %
    % Note2: Code is quite complex and could probably be simplify by
    % creating new classes of graphical object that linked Dispersion
    % object to the graphical object. In this case, listeners that respond
    % to the data updates could be simplified.
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
    
    % Axis and Control properties
    properties (Access = public)
        AxePosition = [0.09 0.09 0.86 0.86]; %position of the main axis
        optsButton % all the display/data options uicontrol
        axezone  % axis to visualise quickly zone data
        axeres   % axis for the scatter plot (residuals)
        axehist  % axis for the histogram (residuals)
    end
    
    properties (Hidden)
        ls % listeners
    end
    
    events
        UpdateHist
    end
    
    methods (Access = public)
        % Constructor
        function this = DispersionTab(DisplayManager, tab)
            % call the superclass constructor
            this = this@EmptyTab(DisplayManager, tab);
            % set the name of the subtab
            this.Parent.Title = 'Dispersion';
            this.inputType = 'Dispersion';
            % change the main axis into a subplot
            this.axe.Visible = 'on';
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
        end %DispersionTab
        
        % Destructor
        function delete(this)
            % clear handle to plot
            this = clearGroup(this);
            % remove handle if needed
            if ~isempty(this.hData)
                this.hData = [];
            end
            % delete the listener
            delete(this.ls); this.ls = [];
            % delete the selected point
            if ~isempty(this.SelectedPoint)
                this.SelectedPoint.UserData.Object{1}.DeleteFcn = [];
                delete(this.SelectedPoint.UserData);
            end
        end %delete
    end
    
    methods (Access = public)        
        % THIS = ADDPLOT(THIS, HDATA, IDXZONE) adds new dispersion data to
        % the main axis. HDATA should be a Dispersion object and IDXZONE a
        % scalar indicating the wanted zone. Remember that IDXZONE should
        % be NaN if all the zone are displayed (case for dispersion
        % profile).
        function this = addPlot(this, hData, idxZone)
            % check input
            if ~isa(hData, this.inputType); return; end
            
            % check if duplicates
            if isempty(this.hData) || all(strcmp(getPlotID(this),...
                    getPlotID(this, hData, idxZone)) == 0) 
                 % set plot specification
                getPlotSpec(this, hData);
                
                % append data and create group object
                this.hData = [this.hData hData];
                this.idxZone = [this.idxZone idxZone];
                
                this.hGroup = [this.hGroup struct('hPlot',[],...
                                      'Tag', getPlotID(this, hData, idxZone))];
                                  
                % check if other plot need to be update (legend)
                if numel(this.PlotSpec) > 1
                    [~,idx,~] = intersect(vertcat(this.PlotSpec(1:end-1).Color),...
                        this.PlotSpec(end).Color,'rows');
                    if numel(idx) == 1
                        % get all the plot of this group and update the legend
                        for k = 1:numel(this.hGroup(idx).hPlot)
                            leg = getLegend(this.hData(idx),this.idxZone(idx),...
                                this.hGroup(idx).hPlot(k).Tag,1);
                            this.hGroup(idx).hPlot(k).DisplayName = leg;
                        end
                    end
                end

                % add listener 
                l(1,1) = addlistener(hData,{'x','y','dy','mask','processingMethod'},...
                            'PostSet', @(src, event) updateData(this, src, event));
                l(2,1) = addlistener(hData,'DataDeletion',...
                            @(src, event) deletePlot(this, src));
                l(3,1) = addlistener(hData,{'xLabel','yLabel'},...
                            'PostSet', @(src, event) setLabel(this, src, event));
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Need to solve this issue: How to add listener to
                % underlined relaxObj. [Manu]
%                 l(3) = addlistener(hData.relaxObj,'FileHasChanged',...
%                             @(src, event) updateLegend(this, src, event));
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                this.ls = [this.ls, l];
            end
            
            % + data
            showData(this);

            % + fit
            showFit(this);
            
            % + residuals
            showResidual(this);
            
            % + axis
            setLabel(this, hData, []);
        end %addPlot
        
        % THIS = DELETEPLOT(THIS, HDATA, IDXZONE) removes dispersion data
        % from the main axis. HDATA should be a Dispersion object and IDXZONE a
        % scalar indicating the wanted zone. Remember that IDXZONE should
        % be NaN if all the zone are deleted (case for dispersion
        % profile).
        function this = deletePlot(this, hData, idxZone)
            % check input
            tf = this.hData == hData;
            if nargin > 2 && ~isnan(idxZone)
                tf = tf & this.idxZone == idxZone;
            end
            
            if all(tf == 0); return; end
            % Prepare legend update depending on the hData deleted. Check
            % if other plot has same color
            if ~isempty([this.PlotSpec(~tf).Color])
                [~,idx,~] = intersect(vertcat(this.PlotSpec(~tf).Color),...
                        this.PlotSpec(find(tf,1,'first')).Color,'rows');
            else
                idx = [];
            end
            
            % get all plot corresponding to the hData and delete them
            delete(this.hGroup(tf).hPlot); this = clearGroup(this);
            drawnow; %EDT
            
            % remove handle and listener
            this.hData = this.hData(~tf);
            this.PlotSpec = this.PlotSpec(~tf);
            this.hGroup = this.hGroup(~tf);
            this.idxZone = this.idxZone(~tf);   
            delete(this.ls(:,tf)); this.ls = this.ls(:,~tf);
            
            % update leg if needed
            if numel(idx) == 1
                % get all the plot of this group and simplify the legend
                for k = 1:numel(this.hGroup(idx).hPlot)
                    leg = getLegend(this.hData(idx),this.idxZone(idx),...
                        this.hGroup(idx).hPlot(k).Tag,0);
                    this.hGroup(idx).hPlot(k).DisplayName = leg;
                end
            end
            
            % notify
            notify(this, 'UpdateHist');
        end %deletePlot    
                        
        % THIS = UPDATEDATA(THIS, ~, EVENT) responds to callback to update
        % the current displayed data. See ADDPLOT where listeners are set
        % that activated this function.
        % Brifly, data are update if X, Y, DY or process object are
        % modified in the handle object (Dispersion object).
        function this = updateData(this, ~, event)
            % get all plots corresponding to the source
            src = event.AffectedObject;
            idx = find(this.hData == event.AffectedObject);
            tf_hist = 0; %for histogram update
            
            for k = 1:numel(idx)
                % get group of plot and their associated idxZone
                idxZone = EmptyTab.getIdxZone(this.hGroup(idx(k)));
                plotID = getPlotID(this, src, idxZone);
                
                % +ID
                if ~strcmp(this.hGroup(idx(k)).Tag, plotID)
                    this.hGroup(idx(k)).Tag = plotID;
                end
                
                % +data
                if this.optsButton.DataCheckButton.Value
                    tf_data = strcmp(get(this.hGroup(idx(k)).hPlot,'Tag'), 'Data');
                    hPlot = this.hGroup(idx(k)).hPlot(tf_data);
                    % +legend
                    if numel(this.PlotSpec) == 1
                       leg = getLegend(this.hData(idx(k)),this.idxZone(idx(k)),'Data',0); 
                    elseif isempty(intersect(vertcat(this.PlotSpec([1:idx(k)-1,idx(k)+1:end]).Color),...
                            this.PlotSpec(idx(k)).Color,'rows'))
                        leg = getLegend(this.hData(idx(k)),this.idxZone(idx(k)),'Data',0);
                    else
                        % generate more accurate legend
                        leg = getLegend(this.hData(idx(k)),this.idxZone(idx(k)),'Data',1);
                    end
                    
                    if isempty(hPlot)
                        % plot data
                        tf_data = [tf_data 1]; %#ok<AGROW> % for residual flag
                        h = plotData(this.hData(idx(k)), this.idxZone(idx(k)),...
                            'Color',this.PlotSpec(idx(k)).Color,...
                            'LineStyle',this.DataLineStyle,...
                            'Marker',this.PlotSpec(idx(k)).Marker,...
                            'MarkerFaceColor','auto',...
                            'MarkerSize',this.DataMarkerSize,...
                            'DisplayName',leg,...
                            'Tag','Data',...
                            'Parent',this.axe);
                        if ~isempty(h)
                            this = addPlotObj(this, idx(k), h);
                            % add callback to dispersion
                            set(h,'ButtonDownFcn',@(s,e) selectData(this,s,e));
                        end
                    elseif isempty(src.y(src.mask))
                        % remove plot
                        delete(hPlot); this = clearGroup(this, this.hGroup(idx(k)));
                    elseif ~isequal(src.y(src.mask), hPlot.YData') ||...
                            ~isequal(src.x(src.mask), hPlot.XData')
                        % update
                        hPlot.XData = src.x(src.mask);
                        hPlot.YData = src.y(src.mask);
                        % + error
                        if ~isempty(hPlot(tf_data).YNegativeDelta)
                            hPlot.YNegativeDelta = -src.dy(src.mask);
                            hPlot.YPositiveDelta = +src.dy(src.mask);
                        end
                        % +legend
                        if ~strcmp(hPlot(tf_data).DisplayName,leg)
                            hPlot(tf_data).DisplayName = leg;
                        end
                    end
                end
                
                %+mask
                if this.optsButton.MaskCheckButton.Value
                    tf_mask = strcmp(get(this.hGroup(idx(k)).hPlot,'Tag'), 'Mask');
                    hPlot = this.hGroup(idx(k)).hPlot(tf_mask);
                    
                    if isempty(hPlot)
                        % plot masked data
                        h = plotMaskedData(this.hData(idx(k)), this.idxZone(idx(k)),...
                            'Color',this.PlotSpec(idx(k)).Color,...
                            'LineStyle',this.DataLineStyle,...
                            'Marker',this.DataMaskedMarkerStyle,...
                            'MarkerSize',this.DataMarkerSize,...
                            'Tag','Mask',...
                            'Parent',this.axe);
                        if ~isempty(h)
                            this = addPlotObj(this, idx(k), h);
                        end
                    elseif isempty(src.y(~src.mask))
                        % remove plot
                        delete(hPlot); this = clearGroup(this, this.hGroup(idx(k)));
                    elseif ~isequal(src.y(~src.mask), hPlot.YData')  ||...
                            ~isequal(src.x(~src.mask), hPlot.XData')
                        % update
                        hPlot.XData = src.x(~src.mask);
                        hPlot.YData = src.y(~src.mask);
                    end
                end
                %+fit
                if this.optsButton.FitCheckButton.Value
                    tf_fit = strcmp(get(this.hGroup(idx(k)).hPlot,'Tag'), 'Fit');
                    hPlot = this.hGroup(idx(k)).hPlot(tf_fit);
                    % +legend
                    if numel(this.PlotSpec) == 1
                        leg = getLegend(this.hData(idx(k)),this.idxZone(idx(k)),'Fit',0);
                    elseif isempty(intersect(vertcat(this.PlotSpec([1:idx(k)-1,idx(k)+1:end]).Color),...
                            this.PlotSpec(idx(k)).Color,'rows'))
                        leg = getLegend(this.hData(idx(k)),this.idxZone(idx(k)),'Fit',0);
                    else
                        % generate more accurate legend
                        leg = getLegend(this.hData(idx(k)),this.idxZone(idx(k)),'Fit',1);
                    end
                    % get data
                    [xfit, yfit] = getFit(src, idxZone,[]);
                    
                    if isempty(hPlot) && ~isempty(yfit) && this.optsButton.FitCheckButton.Value
                        tf_fit = [tf_fit 1]; %#ok<AGROW> % for residual flag
                        % plot fit
                        h = plotFit(this.hData(idx(k)), this.idxZone(idx(k)),...
                            'LineStyle',this.FitLineStyle,...
                            'Color',this.PlotSpec(idx(k)).Color,...
                            'Marker',this.FitMarkerStyle,...
                            'DisplayName',leg,...
                            'Tag','Fit',...
                            'Parent',this.axe);
                        if ~isempty(h)
                            this = addPlotObj(this, idx(k), h);
                        end
                    else
                        if isempty(yfit)
                            % remove plot
                            delete(hPlot); this = clearGroup(this, this.hGroup(idx(k)));
                        else
                            % update
                            hPlot.XData = xfit;
                            hPlot.YData = yfit;
                            % +legend
                            if ~strcmp(hPlot.DisplayName,leg)
                                hPlot.DisplayName = leg;
                            end
                        end
                    end
                end
                 
                %+residuals 
                if this.optsButton.ResidualCheckButton.Value
                    if ~isempty(this.axeres) && any(tf_data ~= 0) && any(tf_fit ~= 0)
                        tf_hist = 1;
                        tf_res = strcmp(get(this.hGroup(idx(k)).hPlot,'Tag'), 'Residual');
                        hPlot = this.hGroup(idx(k)).hPlot(tf_res);
                        % get residual data
                        [x,y,~,mask] = getData(src, idxZone);
                        [~,yfit] = getFit(src, idxZone, x(mask));
                        yres = y(mask) - yfit;
                        if isempty(hPlot) && ~isempty(yres)
                            % plot
                            h = plotResidual(this.hData(idx(k)), this.idxZone(idx(k)),...
                                'Color', this.PlotSpec(idx(k)).Color,...
                                'LineStyle', this.ResidualStyle,...
                                'Marker', this.PlotSpec(idx(k)).Marker,...
                                'MarkerFaceColor',this.PlotSpec(idx(k)).Color,...
                                'MarkerSize', this.ResidualSize,...
                                'Tag', 'Residual',...
                                'Parent', this.axeres);
                            if ~isempty(h)
                                this = addPlotObj(this, idx(k), h);
                                set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                            end
                        elseif ~isempty(yres)
                            set(hPlot,'XData',x(mask),'YData',yres);
                        else
                            % clear
                            delete(hPlot); this = clearGroup(this, hthis.hGroup(idx(k)));
                        end
                    end
                end
            end %fot loop
            
            %+histogram
            if tf_hist
                notify(this, 'UpdateHist');
            end
            drawnow;
        end %updateData
        
%         % THIS = UPDATELEGEND(THIS, SRC, EVENT) 
%         function this = updateLegend(this, src, event)
%             % get the plot
%             tf_data = contains(get(this.axe.Children,'Tag'), src.fileID);
%             hPlot = this.axe.Children(tf_data);
%             % replace their legend
%             for k = 1:numel(hPlot)
%                 % check if displayName
%                 if ~isempty(hPlot(k).DisplayName)
%                    hPlot(k).DisplayName = strrep(hPlot(k).DisplayName,...
%                                                 event.OldName, event.NewName);                   
%                 end
%             end            
%         end %updateLegend
    end
    
    % Respond to the display options callback
    methods 
        % THIS = SHOWDATA(THIS) respond to checkbox callback (show data) or
        % to ADDPLOT(). Depending on the checkbox state it deletes or
        % displays the dispersion data. Duplicates are avoided by checking
        % the presence of the wanted dispersion data in the main axis.
        function this = showData(this)
            % check input
            if this.optsButton.DataCheckButton.Value
                for k = 1:numel(this.hData)
                    % check existence
                    if isempty(findobj(this.hGroup(k).hPlot ,'Tag','Data'))
                        % check if other plot has same color
                        if numel(this.PlotSpec) == 1
                            leg = getLegend(this.hData(k),this.idxZone(k),'Data',0);
                        elseif isempty(intersect(vertcat(this.PlotSpec([1:k-1,k+1:end]).Color),...
                                this.PlotSpec(k).Color,'rows'))
                            leg = getLegend(this.hData(k),this.idxZone(k),'Data',0);
                        else
                            % generate more accurate legend
                            leg = getLegend(this.hData(k),this.idxZone(k),'Data',1);
                        end
                        % plot
                        h = plotData(this.hData(k), this.idxZone(k),...
                                    'Color',this.PlotSpec(k).Color,...
                                    'LineStyle',this.DataLineStyle,...
                                    'Marker',this.PlotSpec(k).Marker,...
                                    'MarkerFaceColor','auto',...
                                    'MarkerSize',this.DataMarkerSize,...
                                    'DisplayName',leg,...
                                    'Tag','Data',...
                                    'Parent',this.axe);
                        if ~isempty(h)
                            this = addPlotObj(this, k, h);
                            % add callback to select dispersion point
                            set(h,'ButtonDownFcn',@(s,e) selectData(this,s,e));
                        end
                    end
                end
                showError(this);
                showMask(this);
            else
                delete(findobj(this.axe.Children,'Tag','Data'));
                delete(findobj(this.axe.Children,'Tag','Mask'));
                % remove invalid handle
                this = clearGroup(this);
            end
            drawnow;
            showLegend(this);
        end %showData
        
        % THIS = SHOWERROR(THIS) respond to checkbox callback (show error) or
        % to SHOWDATA(). Depending on the checkbox state it deletes or
        % displays the dispersion data error. No errors are displayed if
        % the dispersion data plot are missing.
        function this = showError(this)
            % check input
            if this.optsButton.ErrorCheckButton.Value
                 % get ID
                %plotID = getPlotID(this);
                for k = 1:numel(this.hData)
                    % check plot existence
                    %hParent = findobj(this.axe.Children, 'Tag', plotID{k});
                    h = findobj(this.hGroup(k).hPlot ,'Tag','Data');
                    if ~isempty(h)
                        addError(this.hData(k), this.idxZone(k), h);
                    end
                end
            else
                set(findobj(this.axe.Children,'Tag','Data'),...
                    'YNegativeDelta',[],'YPositiveDelta',[]);
            end
            drawnow;
        end %showError
        
        % THIS = SHOWFIT(THIS) respond to checkbox callback (show fit) or
        % to ADDPLOT(). Depending on the checkbox state it deletes or
        % displays the dispersion fit. Duplicates are avoided by checking
        % the presence of the wanted dispersion fit in the main axis.
        function this = showFit(this)
            % check input
            if this.optsButton.FitCheckButton.Value
                for k = 1:numel(this.hData)
                    % check plot existence
                    if isempty(findobj(this.hGroup(k).hPlot ,'Tag','Fit')) 
                        % check if other plot has same color
                        if numel(this.PlotSpec) == 1
                            leg = getLegend(this.hData(k),this.idxZone(k),'Fit',0);
                        elseif isempty(intersect(vertcat(this.PlotSpec([1:k-1,k+1:end]).Color),...
                                this.PlotSpec(k).Color,'rows'))
                            leg = getLegend(this.hData(k),this.idxZone(k),'Fit',0);
                        else
                            % generate more accurate legend
                            leg = getLegend(this.hData(k),this.idxZone(k),'Fit',1);
                        end
                        % plot
                        h = plotFit(this.hData(k), this.idxZone(k),...
                                    'LineStyle',this.FitLineStyle,...
                                    'Color',this.PlotSpec(k).Color,...
                                    'Marker',this.FitMarkerStyle,...
                                    'DisplayName',leg,...
                                    'Tag','Fit',...
                                    'Parent',this.axe);
                        if ~isempty(h)
                            this = addPlotObj(this, k, h);
                        end
                    end
                end
            else
                delete(findobj(this.axe.Children,'Tag','Fit'));
                % remove invalid handle
                this = clearGroup(this);
            end
            drawnow;
            showLegend(this);
        end %showFit
        
        % THIS = SHOWMASK(THIS) respond to checkbox callback (show mask) or
        % to SHOWDATA(). Depending on the checkbox state it deletes or
        % displays the dispersion masked data. Duplicates are avoided by checking
        % the presence of the wanted dispersion masked data in the main axis.
        function this = showMask(this)
            % check input
            if this.optsButton.MaskCheckButton.Value
                for k = 1:numel(this.hData)
                    % check plot existence
                    if isempty(findobj(this.hGroup(k).hPlot ,'Tag','Mask'))
                        h = plotMaskedData(this.hData(k), this.idxZone(k),...
                                    'Color',this.PlotSpec(k).Color,...
                                    'LineStyle',this.DataLineStyle,...
                                    'Marker',this.DataMaskedMarkerStyle,...
                                    'MarkerSize',this.DataMarkerSize,...
                                    'Tag','Mask',...
                                    'Parent',this.axe);
                         if ~isempty(h)
                            this = addPlotObj(this, k, h);
                         end
                    end
                end
            else
                delete(findobj(this.axe.Children,'Tag','Mask'));
                % remove invalid handle
                this = clearGroup(this);
            end
            drawnow;
        end %showMask
        
        % THIS = SHOWRESIDUAL(THIS) respond to checkbox callback (show residual) or
        % to SHOWDATA(). Depending on the checkbox state it deletes or
        % displays the dispersion fit residuals. 
        % This function fires also the creation and update of the histogram
        % residual plot.
        % Residual plot required the presence of fit data.
        function this = showResidual(this)
            % check input
            if this.optsButton.ResidualCheckButton.Value
                % check if residual axis exists
                if isempty(this.axeres)
                    createResidualAxis(this);            
                end

                for k = 1:numel(this.hData)
                    % check plot existence
                    if isempty(findobj(this.hGroup(k).hPlot ,'Tag','Residual'))
                        h = plotResidual(this.hData(k), this.idxZone(k),...
                            'Color', this.PlotSpec(k).Color,...
                            'LineStyle', this.ResidualStyle,...
                            'Marker', this.PlotSpec(k).Marker,...
                            'MarkerFaceColor',this.PlotSpec(k).Color,...  
                            'MarkerSize', this.ResidualSize,...                                                    
                            'Tag', 'Residual',...
                            'Parent', this.axeres);
                        if ~isempty(h)
                            this = addPlotObj(this, k, h);
                            set(get(get(h, 'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                        end
                    end
                end
                % notify
                notify(this, 'UpdateHist');
            else
                % delete the residual axis
                delete(this.axeres); this.axeres = [];
                delete(this.axehist); this.axehist = [];
                % clear invalid handle
                this = clearGroup(this);
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
        
        % THIS = SHOWLEGEND(THIS) respond to checkbox callback (show legend) or
        % to SHOWDATA(). Depending on the checkbox state it deletes or
        % displays the legend.
        function this = showLegend(this)
           if this.optsButton.LegendCheckButton.Value
               % check if children
               if isempty(this.axe.Children)
                   legend(this.axe, 'off');
               else                  
                   legend(this.axe, 'show');
                   set(this.axe.Legend,'Interpreter','none');
               end
           else
               legend(this.axe, 'off');
           end
        end %showLegend
    end
    
    % Plot methods: residuals
    methods (Access = public)  
        % THIS = CREATERESIDUALAXIS(THIS) creates two axis for the residual
        % plot. The second axis (histogram axis) is linked to the first one
        % for X axis scale and limit.
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
        
        % THIS = MAKERESIDUALHISTOGRAM(THIS) fills the histogram axis to
        % display the distribution of the residuals. A normality test is
        % also applied and set as title.
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
        
        % THIS = SELECTDATA(THIS,S,E) responds to the selection of one data
        % point (dispersion data). 
        % If a point is selected, SELECTDATA creates a new axis where
        % zone data of the selected point are displayed. If the axis
        % already axists SELECTDATA updates automaticaly the zone data
        % according to the new selected point. If the same point is clicked
        % again, SELECTDATA deletes the axis.
        function this = selectData(this, src, e)
            % check source 
            if strcmp(src.Tag, 'SelectedPoint')
                % delete listener and delete function
                this.SelectedPoint.UserData.Object{1}.DeleteFcn = [];
                delete(this.SelectedPoint.UserData);
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
            % check if listener activated
            if isa(e, 'PropertyEvent')
                % for now just delete selected point
                src.Tag = 'SelectedPoint';
                selectData(this, src, []);
                return
            end
            
            % get the associated data
            hPlot = arrayfun(@(x) findobj(x.hPlot,'Tag','Data'), this.hGroup, 'Uniform', 0);
            tf = cellfun(@(x) x == src, hPlot);
            
            % check if associated idxZone
            idxZone = EmptyTab.getIdxZone(this.hGroup(tf));

            % if no zone, get it by the intersection point
            if isnan(idxZone)
                if isa(e, 'PropertyEvent')
                    [~,idxZone] = min(abs(src.XData - this.SelectedPoint.XData));
                else
                    % get the zone index
                    [~,idxZone] = min(abs(this.hData(tf).x - e.IntersectionPoint(1)));
                end
                % check if the object is selected
                if isempty(this.SelectedPoint)
                    % create a marker
                    this.SelectedPoint = plot(this.axe,...
                            this.hData(tf).x(idxZone), this.hData(tf).y(idxZone),...
                            'LineStyle','none','Marker','s','MarkerSize',14,...
                            'Color','k','ButtonDownFcn',@(s,e) selectData(this,s,e),...
                            'Tag','SelectedPoint');
                    set(get(get(this.SelectedPoint,'Annotation'),...
                        'LegendInformation'),'IconDisplayStyle','off');
                    % add a deletion callback if the source object is
                    % destroyed
                    src.DeleteFcn = @(~,~) clearSelectedPoint(this);
                    % add listener if the source is modified
                    this.SelectedPoint.UserData = addlistener(src,...
                        'YData','PostSet',@(src, event) selectData(this, src, event));
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
                    h = plotData(this.hData(tf).parent, idxZone,...
                                 'Color',src.Color,...
                                 'LineStyle',src.LineStyle,...
                                 'Marker', src.Marker,...
                                 'MarkerFaceColor', 'auto',...
                                 'MarkerSize',src.MarkerSize,...
                                 'Parent', this.axezone);
                    addError(this.hData(tf).parent, idxZone, h);
                    % add fit
                    plotFit(this.hData(tf).parent, idxZone,...
                            'Color',src.Color,...
                            'LineStyle',this.FitLineStyle,...
                            'Marker',this.FitMarkerStyle,...
                            'Parent',this.axezone);
                    % set fontsize
                    set(this.axezone, 'FontSize', 8);
                    xlabel(this.axezone, this.hData(tf).parent.xLabel);
                    ylabel(this.axezone, this.hData(tf).parent.yLabel);
                    % add legend
                    legend(this.axezone,'show');
                    set(this.axezone.Legend,'Interpreter','none');
                else
                    % remove deleteFcn
                    this.SelectedPoint.UserData.Object{1}.DeleteFcn = [];
                    % update listener
                    delete(this.SelectedPoint.UserData);
                    this.SelectedPoint.UserData = addlistener(src,...
                        'YData','PostSet',@(src, event) selectData(this, src, event));
                    src.DeleteFcn = @(~,~) clearSelectedPoint(this);
                    % update selected point
                    this.SelectedPoint.XData = this.hData(tf).x(idxZone);
                    this.SelectedPoint.YData = this.hData(tf).y(idxZone);
                    % update current plot obj
                    [x,y,dy,mask] = getData(this.hData(tf).parent, idxZone);
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
                        leg = getLegend(this.hData(tf).parent, idxZone, 'Data', 0);
                        if ~strcmp(leg, hData.DisplayName)
                            hData.DisplayName = leg;
                        end
                    elseif ~isempty(hData)
                        delete(hData);
                    end
                    % +fit
                    hFit = findobj(this.axezone, 'Type', 'line');
                    [xfit, yfit] = getFit(this.hData(tf).parent, idxZone, []);
                    if ~isempty(hFit) && ~isempty(yfit)
                        set(hFit, 'XData', xfit, 'YData', yfit);
                        % update color, marker, displayName
                        set(hFit,'Color',src.Color);
                        leg = getLegend(this.hData(tf).parent, idxZone, 'Fit', 0);
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
         
%         function clearSelectedPoint(this)
%             % call selectData like if user hit the selected point
%             src.Tag = 'SelectedPoint';
%             selectData(this, src, []);
%         end
    end
    
    % Other function
    methods (Access = public)
        % THIS = SORTCHILDREN(THIS) sorts the current axis children
        % (dispersion plots) according to their type and tag (i.e. plotID).
        % Because legend is automaticaly updated according to this order,
        % SORTCHILDREN sorts also the legend input.
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
        
%         % This function check the legend and check for duplicates from hData. If
%         % duplicates are found, the displayName property is added to the
%         % input. If this property is not longer required (no duplicate), it
%         % is removed.
%         function this = checkLegend(this, hData)
%             % check children number
%             if numel(this.hData) < 2
%                 return
%             end
%             % to help: will be removed latter [M.Petit]
%             type = {'Data','Fit','Mask'};
%             plottype = {'ErrorBar','Line','Scatter'};
%             % check if other hData are coming from same file
%             fileID = arrayfun(@(x) getRelaxProp(x, 'fileID'),...
%                                            this.hData, 'Uniform', 0);
%             idx = find(strcmp(fileID, getRelaxProp(hData, 'fileID')));
% 
%             % change legend
%             if numel(idx) > 1
%                 tf = contains(get(this.axe.Children,'Tag'),...
%                     getRelaxProp(hData, 'fileID'));
%                 hPlot = this.axe.Children(tf);
%                 % check if multiple plot with same legend
%                 if numel(hPlot) > 1 && ~all(strcmpi(get(hPlot,'Type'),...
%                                             hPlot(1).Type) == 0)
%                     extend = 1;
%                 else
%                     extend = 0;
%                 end
%                 % loop over the plot
%                 for j = 1:numel(hPlot)
%                     % get idxZone
%                     idxZone = strsplit(hPlot(j).Tag,'@');
%                     idxZone = str2double(idxZone{end});
%                     % get type
%                     tf = strcmpi(plottype, hPlot(j).Type);
%                     % assign legend: simplify or extend
%                     leg = getLegend(hData, idxZone, type{tf}, extend);
%                     if ~strcmp(hPlot(j).DisplayName, leg)
%                         hPlot(j).DisplayName = leg;
%                     end
%                 end
%             end
%         end %checkLegend
        
        % THIS = GETPLOTSPEC(THIS, HDATA) updates the current PlotSpec
        % structure according to the input HDATA. HDATA is a Dispersion
        % object. PlotSpec is an array of structure containing the plot
        % specification (Color, Marker) for each graphical object.
        function this = getPlotSpec(this, hData)
            % set properties
            if isempty(this.hData)
                this.PlotSpec(1).Color = this.Color(1,:);
                this.PlotSpec(1).Marker = this.DataMarkerStyle{1};
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
                    this.PlotSpec(n+1).Marker = this.DataMarkerStyle{1};
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
                    this.PlotSpec(n+1).Marker = this.DataMarkerStyle{idx};
                end
            end
        end % setPlotSpec  
        
        % THIS = SETLABEL(THIS, HDATA) sets the X and Y labels of the main
        % axis according to the input HDATA. HDATA is a Dispersion object.
        % SETLABEL responds also to changes in DataUnit objects on the
        % xLabel, yLabel properties.
        function this = setLabel(this, hData, event)
            % check if event
            if ~isempty(event)
                hData = event.AffectedObject; %respond to listener
            end
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
                    xlabel(this.axe, hData.xLabel,'FontSize',10)
                end
                
                yName = this.axe.YLabel.String;
                if ~strcmp(yName, hData.yLabel)
                    txt = 'Warning: A new label for y-axis is detected!\n';
                    throwWrapMessage(this.DisplayManager, txt)
                    ylabel(this.axe, hData.yLabel,'FontSize',10)
                end               
            end
        end %setLabel
    end
    
    % Data Options methods
    methods
        % MOVEMOUSE(THIS) updates the X/Y position over the main axis
        % according to the position of the mouse. If the mouse is outside
        % the main axis then position are reset (empty).
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
        
        % SETAXIS(THIS, SRC) updates the axis scaling according to the
        % state of the popup menu.
        function setAxis(this, src)
            % check which axis need to be update
            if strcmp(src.Tag,'XAxisPopup')
                this.axe.XScale = src.String{src.Value};
            else
                this.axe.YScale = src.String{src.Value};
            end           
        end %setAxis
        
        % MASKDATA(THIS) responds to the pushbutton 'mask data','reset
        % mask' and create a draggable rectangle to select the data to
        % mask. Double-click on the draggable rectangle to validate the
        % selection.
        % If masked data are selected, they are unmasked.
        function maskData(this)
            % check if data are displayed
            if ~this.optsButton.DataCheckButton.Value || isempty(this.hData)
                txt = 'Warning: Show or import data to mask them!\n';
                throwWrapMessage(this.DisplayManager, txt);
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
                throwWrapMessage(this.DisplayManager, txt);
                return
            end
            
            % call the presenter with the axis limit
            eventdata = struct('Data',this.hData,...
                               'idxZone', this.idxZone,...
                               'Action', 'ResetMask');
            setMask(this.DisplayManager, this, eventdata);
        end % resetMaskData
        
        % CLEARGROUP(THIS, HGROUP) check the handle validity of the HGROUP
        % input. HGROUP should be a structure containing graphical objects.
        % If no HGROUP are specified, CLEARGROUP check the HGROUP property
        % structure stored in the tab.
        function this = clearGroup(this, hGroup)
            if nargin < 2
               % loop over the structure and remove the invalid handle
               for k = 1:numel(this.hGroup)
                   this.hGroup(k).hPlot = this.hGroup(k).hPlot(isvalid(this.hGroup(k).hPlot));
               end
            else
                % find the corresponding group and remove invalid handle
                for k = 1:numel(hGroup)
                    tf = strcmp({this.hGroup.Tag}, hGroup(k).Tag);
                    this.hGroup(tf).hPlot = this.hGroup(tf).hPlot(isvalid(this.hGroup(tf).hPlot));
                end
            end
        end
        
        % THIS = ADDPLOTOBJ(THIS, IDXGROUP, HPLOT) adds graphical object
        % handles HPLOT to the hGroup structure property specified by IDXGROUP.
        % HPLOT should be an array of graphical object (line, errorbar,...) 
        % and HPLOT a scalar indicating the index of the array of structure hGroup
        % where object are inserted.
        function this = addPlotObj(this, idxGroup, hPlot)
            % check input 
            if isempty(idxGroup) || isempty(hPlot); return; end
            
            this.hGroup(idxGroup).hPlot = [this.hGroup(idxGroup).hPlot hPlot];
        end %addPlotObj
        
        % THIS = GETLEGEND(THIS) returned the current legend of the main
        % axis. Fit legend input (dispersion fit object) are avoided.
        function leg = getLegend(this)
            % get the data plotted
            hData = findobj(this.axe.Children,'Type','ErrorBar');
            %relaxObj = [];
            
            if isempty(hData)
                leg = [];  return
            else
                leg = {hData.DisplayName}; 
                %relaxObj = [hData.relaxObj];
            end
        end %getLegend
    end
end

