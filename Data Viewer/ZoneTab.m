classdef ZoneTab < DisplayTab
    %
    % Class that design containers for zone data
    %
    % SEE ALSO DISPLAYTAB, DISPLAYMANAGER, DISPERSIONTAB
    
    properties
        hData % handle to the DataUnit
        Dim % dimension to read in DataUnit
        PlotSpec % structure containing the color, marker,...
    end
    
    properties
        optsButton % all the display/data options uicontrol
        Position = [0.09 0.09 0.86 0.86]; %position of the main axis
        resaxe = []; % residual axis
        histaxe = []; % histogram axis
    end
    
    methods
        % Constructor
        function this = ZoneTab(FitLike, tab)
            % call the superclass constructor and set the Presenter
            this = this@DisplayTab(FitLike, tab);
            % set the name of the tab
            this.Parent.Title = 'Zone';
            % change the main axis into a subplot (residuals plot)
            this.axe = subplot(3,2,1:6, this.axe);
            this.axe.Position = this.Position; %reset Position
            
            % add display options under the axis
            this.optsButton = buildDisplayOptions(this.box);
            
            % set the default axis
            this.axe.XScale = this.optsButton.XAxisPopup.String{this.optsButton.XAxisPopup.Value};
            this.axe.YScale = this.optsButton.YAxisPopup.String{this.optsButton.YAxisPopup.Value};            
            %%% ----------------------- CALLBACK ---------------------- %%%
            % checkbox callback
            set(this.optsButton.DataCheckButton,'Callback',...
                @(src, event) plotData(this));
            
            set(this.optsButton.ErrorCheckButton,'Callback',...
                @(src, event) plotData(this));
            
            set(this.optsButton.FitCheckButton,'Callback',...
                @(src, event) plotFit(this));
            
            set(this.optsButton.MaskCheckButton,'Callback',...
                @(src, event) plotMaskedData(this));
            
            set(this.optsButton.ResidualCheckButton,'Callback',...
                @(src, event) plotResidual(this));  
            
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
    
    % Abstract method
    methods
        % Add new data to the tab using handle. hData must be a Zone
        % object. 
        function [this, tf] = addPlot(this, hData)
            % check input handle object if Zone
            if ~isa(hData,'Zone')
                tf = 1;
                return
            else
                tf = 0;
            end
            % duplicates
            if ~all((this.hDispersion == hData) == 0)
                return
            end
            
            % append data
            this.hData = [this.hData hData];           
            % add listener 
            addlistener(hData,'FileDeletion',@(src, event) removePlot(this, src));
            addlistener(hData,'FileHasChanged',@(src, event) updateID(this, src)); 
            addlistener(hData,'DataHasChanged',@(src, event) resetData(this, src));
            
            % check the zone to read in the file and plot them
            
            
            % + data
            if this.optsButton.DataCheckButton.Value
                plotData(this, x, y, dy, mask, displayName, fileID, SpecLine);
            end           
            % + fit
            if this.optsButton.FitCheckButton.Value
                plotFit(this, x, mask, fitobj, displayName, fileID, SpecLine);
            end            
            % + residuals
            if this.optsButton.FitCheckButton.Value && this.optsButton.DataCheckButton.Value
                plotResidual(this, fitobj);
            end            
            % + graph
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
    end
    
    % plot methods: data, mask, fit
    methods
        % plot data. Input must be cell except for SpecLine.
        % Usage: plotData(this, x, y, dy, mask, displayName, fileID,
        % PlotSpec)
        % OR plotData(this) will plot all the data in memory
        function this = plotData(this, varargin)
            % check if data must be plot
            if ~this.optsButton.DataCheckButton.Value
                return
            end
            % check input number
            if nargin < 2
                % get data from the tab
                for k = 1:numel(this.hData)
                    % check if zone to plot
                    if ~isempty(this.Dim{k})
                        for i = 1:numel(this.Dim{k})
                            zone = this.Dim{k}(i);
                            plotData(this, this.hData(k).x(:,zone),...
                                this.hData(k).y(:,zone), this.hData(k).dy(:,zone),...
                                this.hData(k).mask(:,zone), this.hData(k).filename,...
                                this.hData(k).fileID, this.PlotSpec(k));
                        end
                    else
                        plotData(this, this.hData(k).x,...
                            this.hData(k).y, this.hData(k).dy,...
                            this.hData(k).mask, this.hData(k).filename,...
                            this.hData(k).fileID, this.PlotSpec(k));
                    end
                end
            else
                % check if we plot error or not
                if ~this.optsButton.ErrorCheckButton.Value
                    dy = cellfun(@(x) nan(size(x)),x,'Uniform',0);
                end
                % loop over the data
                for k = 1:numel(x)
                    % plot
                    errorbar(this.axe,...
                            x{k}(mask{k}),...
                            y{k}(mask{k}),...
                            dy{k}(mask{k}),...
                            'DisplayName', displayName{k},...
                            'Color',PlotSpec(k).Color,...
                            'LineStyle',this.DataLineStyle,...
                            'Marker',PlotSpec(k).Marker,...
                            'MarkerSize',this.DataMarkerSize,...
                            'MarkerFaceColor','auto',...
                            'Tag',fileID{k}); 
                    drawnow;
                end

                % + plot masked data
                if this.optsButton.MaskCheckButton.Value
                    plotMaskedData(this, x, y, mask, fileID, PlotSpec)
                end
            end
        end %plotData
        
        % plot masked data. Not in legend
        function  this = plotMaskedData(this, x, y, mask, fileID, PlotSpec)           
            % plot
            for k = 1:numel(x)
                % check if data to plot
                if isempty(y{k}(~mask{k}))
                    continue
                end
                % plot
                h = scatter(this.axe,...
                    x{k}(mask{k}),...
                    y{k}(mask{k}),...
                    'MarkerEdgeColor',PlotSpec(k).Color,...
                    'Marker',this.DataMaskedMarkerStyle,...
                    'SizeData',this.DataMarkerSize,...
                    'MarkerFaceColor','auto',...
                    'Tag',fileID{k});
                % remove this plot from legend
                set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                drawnow;
            end
        end %plotMaskedData
        
        % plot fit
        function this = plotFit(this, x, mask, fitobj, displayName, fileID, PlotSpec)            
            % plot
            for k = 1:numel(x)
                % check if possible to plot fit
                if isempty(fitobj(k))
                    continue
                end
                % get x-values
                x = x{k}(mask{k});
                % calculate yfit values and increase the  number of 
                % point to obtain better visualisation. Ensure you dont 
                % repeat point by geting the middle point each time
                x_add = diff(x/2); % get the interval between x pts
                x_fit = sort([x; x(1:end-1)+x_add]); %add it              
                % get y-values
                y_fit = evaluate(fitobj(k), x_fit);

                % change the displayed name and add the rsquare
                fitName = sprintf('%s: %s (R^2 = %.3f)',...
                    fitobj(k).model.modelName, displayName{k},...
                    fitobj(k).model.gof.rsquare);

                % plot
                plot(this.axe, x_fit, y_fit,...
                    'DisplayName', fitName,...
                    'Color',PlotSpec(k).Color,...
                    'LineStyle',PlotSpec(k).FitStyle,...
                    'Marker',this.FitMarkerStyle,...
                    'Tag',fileID{k}); 
                drawnow;
            end
        end %plotFit
    end
    
    % plot residuals methods
    methods 
        % Add residual data
        function this = plotResidual(this)
            % get the handle to the plot(s)
            hFit = findobj(this.axe.Children, 'Type', 'Line');
            % get fileID
            hfileID = {hFit.Tag};
            
            % check if residual axis exists
            if isempty(this.resaxe)
                % move the main axis
                subplot(3,2,1:4, this.axe);
                % create the axis
                this.resaxe = subplot(3,2,5);
                this.histaxe = subplot(3,2,6);
                % axis settings
                set(this.reaxe, {'NextPlot','XScale','XLim','FontSize'},...
                    {'add',this.axe.XScale, this.axe.XLim,this.axe.FontSize});
            end
            
            % loop over the plot
            for k = 1:length(hfileID)
                % check if possible to plot residual
                hPlot = findobj(this.axe.Children,'Type','ErrorBar','Tag',hfileID{k});
                if isempty(hPlot)
                    continue
                end
                
                % make intersection between x from data and x from fit
                x = hPlot.XData;
                [~,~,idxx] = intersect(x, hFit(k).XData,'stable');
                                   
                % calculate residuals
                residual = hPlot.YData - hFit(k).YData(idxx); 
                % plot and set color, marker identical to data
                % use fileID from data but add the model specification
                % as userdata field
                h = plot(this.axeResScatter, x, residual,...
                    'LineStyle','none',...
                    'Color',hPlot.Color,...
                    'Marker',hPlot.Marker,...
                    'MarkerFaceColor',hPlot.Color,...
                    'MarkerSize',2,...
                    'Tag',hPlot.Tag);
                % addlistener to update dynamically the graph
                addlistener(hPlot,'Tag','PostSet',@(~,~)set(h,'Tag',hPlot.Tag)); 
                drawnow;
            end %loop plot
            
            % set axis
            grid(this.resaxe,'on');
            box(this.resaxe,'on');
            title(this.resaxe,'Residuals');
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
                tf = strcmp(fileID, get(this.resaxe.Children,'Tag'));
            end
            
            % delete them
            delete(this.resaxe.Children(tf));             
            drawnow;
            % check if no more children and clear axis
            if isempty(this.resaxe.Children)
                cla(this.histaxe)
                this.histaxe.Title = []; %reset title
            else
                % update histogram
                makeResidualHistogram(this);
            end
        end %removeResidual
        
        % Add an histogram of the residuals
        function this = makeResidualHistogram(this)
            % get all the residuals 
            residual = get(this.resaxe.Children,'YData');
            if iscell(residual)
               residual = [residual{:}]; %append residuals
            end
            % make an histogram
            histogram(this.histaxe,residual)
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
            % axis settings     
            set(this.histaxe,{'Title','FontSize'},{txt, this.resaxe.FontSize});
            this.axeResHist.XLabel.String = this.axeResScatter.YLabel.String; 
            drawnow;
        end %makeResidualHistogram
    end
    
    methods
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
    end
    
    methods
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
        
        % reset the legend if needed.
        function this = setLegend(this)                
            % check if we have children
            if isempty(this.axe.Children) || ~this.optsButton.LegendCheckButton.Value
                legend(this.axe,'off');
                return
            else
                legend(this.axe,'show')
                % reset interpreter
                set(this.axe.Legend,'Interpreter','none')
            end
        end %setLegend
    end
    
    % Method to mask data
    methods
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
                               'Dim',this.Dim,...
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
                               'Dim',this.Dim,...
                               'Action', 'ResetMask');
            setMask(this.FitLike, this, eventdata);
        end % resetMaskData
    end
end

