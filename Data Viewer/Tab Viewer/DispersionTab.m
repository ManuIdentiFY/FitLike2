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
    
    % new axis (residuals)
    properties (Access = public)
        axeResScatter = [] % axis for the scatter plot (residuals)
        axeResHist = [] % axis for the histogram (residuals)
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
            % change the main axis into a subplot to plot residuals. 
            new_axe = copyobj(this.axe, this.axe.Parent);
            delete(this.axe);
            this.axe = subplot(3,2,1:6, new_axe);
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
                    % ensure you dont repeat point by geting the middle point
                    % each time
                    x_add = diff(x{i}/2); % get the interval between x pts
                    x_fit{i} = sort([x{i} x{i}(1:end-1)+x_add]); %add it
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
            if this.ResidualCheckButton.Value 
               plotResidual(this); 
            end
            
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
                currentFileID = get(this.axe.Children,'Tag');
                idx = strcmp(fileID{i},currentFileID);
                % delete them
                delete(this.axe.Children(idx));
            end  

            % delete residual
            removeResidual(this, fileID);
            
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
                    % get the handle to the data
                    hData = findobj(this.axe.Children,'Type','ErrorBar');
                    if src.Value
                        % reset the DataMarkerType/DataMaskedMarkerType
                        this.DataMarkerStyle = 'o';
                        this.DataMaskedMarkerStyle = '+'; 
                        % reset the legend icons
                        iconState = 'on';
                        % reset data
                        addPlot(this.FitLike);
                    else
                        % set invisible DataMarkerType/DataMaskedMarkerType
                        this.DataMarkerStyle = 'none';
                        this.DataMaskedMarkerStyle = 'none';
                        % set the legend icons to 'off'
                        iconState = 'off';
                    end
                    % set markers
                    set(hData,'Marker',this.DataMarkerStyle);
                    set(findobj(hData,'UserData','Mask'),'Marker',this.DataMaskedMarkerStyle);
                    % set the legend icons 
                    hData = hData(cellfun(@isempty, get(hData,'UserData'))); % reset only data
                    for i = 1:length(hData)
                        set(get(get(hData(i),'Annotation'),'LegendInformation'),'IconDisplayStyle',iconState);
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
                    % get the handle to fit data
                    hFit = findobj(this.axe.Children,'Type','Line');
                    if src.Value
                        % set default LineStyle
                        this.FitLineStyle = '-';
                        % reset the legend icons
                        iconState = 'on';
                        % reset the plot if user add data previously
                        addPlot(this.FitLike);  
                    else
                       % set invisible LineStyle
                       this.FitLineStyle = 'none';
                       % set the legend icons visibility to 'off'
                       iconState = 'off';
                    end
                    % set marker
                    set(hFit,'LineStyle',this.FitLineStyle); 
                    % set icons
                    for i = 1:length(hFit)
                        set(get(get(hFit(i),'Annotation'),'LegendInformation'),'IconDisplayStyle',iconState);
                    end
                    % reset legend
                    resetLegend(this);
                    
                case 'DataMaskedCheckButton'
                    % get the handle to the masked data
                    hMaskedData = findobj(this.axe.Children,'Type','ErrorBar','-and','UserData','Mask');
                    if src.Value
                        % reset the marker
                        this.DataMaskedMarkerStyle = '+'; 
                        % reset the plot if user add data previously
                        addPlot(this.FitLike);
                    else
                        % set invisible marker
                        this.DataMaskedMarkerStyle = 'none'; 
                    end
                    % set markers
                    set(hMaskedData,'Marker',this.DataMaskedMarkerStyle);
                    
                case 'ResidualCheckButton'
                    if src.Value
                        % change the current axis to have 3 x 2
                        % subplot. Set the main axis in 1:4 subplot and
                        % create two axis (axeResScatter & axeResHist)
                        % in the last subplots.
                        subplot(3,2,1:4, this.axe);
                        this.axeResScatter = subplot(3,2,5);
                        this.axeResHist = subplot(3,2,6);
                        % set axis properties
                        this.axeResScatter.FontSize = 8;
                        this.axeResScatter.NextPlot = 'add';
                        this.axeResScatter.YGrid = 'on';
                        this.axeResHist.FontSize = 8;
                        this.axeResHist.NextPlot = 'replacechildren';
                        % check if we have data to plot (i.e. fit data)
                        if all(strcmp('line',get(this.axe.Children,'Type')) == 0)
                            return
                        else
                            % plot the residuals
                            this = plotResidual(this);
                        end
                    else
                        % delete the residual axis
                        delete(this.axeResScatter)
                        delete(this.axeResHist)
                        % reset the main axis
                        subplot(3,2,1:6, this.axe);
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
            % set the difference between the data/fit in main axis and the
            % current residual plots
            hPlot = this.axe.Children;
            currentFileID = get(findobj(hPlot,'Type','Line'),'Tag');
            if ischar(currentFileID)
               currentFileID = {currentFileID};
            end
            oldFileID = get(this.axeResScatter.Children,'Tag');
            [~,idx] = setdiff(currentFileID, oldFileID);
            % loop over the plot to add
            for i = 1:length(idx)
               % get the index of the data to add
               isAdd = strcmp(get(hPlot,'Tag'),currentFileID{idx(i)});

               isFit = isAdd & strcmpi(get(hPlot,'Type'),'Line');
               isRaw = isAdd & ~isFit & cellfun(@isempty,get(hPlot,'UserData'));
               % get the data to add                                       
               x = hPlot(isRaw).XData;
               y = hPlot(isRaw).YData;
               % select the yfit fitting with x;
               [~,isXFit,~] = intersect(hPlot(isFit).XData,x);
               yfit = hPlot(isFit).YData(isXFit);
               % calculate the residuals
               residual = y - yfit;

               % add it to the scatter axis
               plot(this.axeResScatter,x,residual,...
                        'LineStyle','none',...
                        'Color',get(hPlot(isRaw),'Color'),...
                        'Marker','o',...
                        'MarkerFaceColor',get(hPlot(isRaw),'Color'),...
                        'MarkerSize',2,...
                        'Tag',currentFileID{idx(i)});        
            end %for 
            
            % axis settings
            this.axeResScatter.XScale = this.axe.XScale;
            this.axeResScatter.XLim = [-inf inf];
            this.axeResScatter.XLabel.String = this.axe.XLabel.String;
            this.axeResScatter.YLabel.String = 'Residues (s^{-1})';
            
           % update hist axis 
           residual = get(this.axeResScatter.Children,'YData');
           if iscell(residual)
               residual = [residual{:}]; %append residuals
           end
           histogram(this.axeResHist,residual)
           % add legend to see if gaussian
           [gauss, pval] = chi2gof(residual,'cdf',@normcdf); 
           if gauss
               txt = sprintf('Gaussian profile (p=%.3f)',pval);
           else
               txt = sprintf('Non-Gaussian profile (p=%.3f)',pval);
           end
           % legend settings         
           title(this.axeResHist,txt);
           % axis settings
           this.axeResHist.XLabel.String = this.axeResScatter.YLabel.String;  
        end %plotResidual
        
        % Remove residuals 
        function this = removeResidual(this,fileID)
            % check if axis exists
            if isempty(this.axeResScatter)
                return
            end
            % remove the corresponding plot
            for i = 1:length(fileID)
                 % get the corresponding line handle(s)
                currentFileID = get(this.axeResScatter.Children,'Tag');
                idx = strcmp(fileID{i},currentFileID);
                % delete them
                delete(this.axeResScatter.Children(idx));             
            end
            
            % check if no more children and clear axis
            if isempty(this.axeResScatter.Children)
                cla(this.axeResHist)
                this.axeResHist.Title = []; %reset title
            else
                % update hist axis
                residual = get(this.axeResScatter.Children,'YData');
                if iscell(residual)
                    residual = [residual{:}]; %append residuals
                end
                histogram(this.axeResHist,residual)
                % add legend to see if gaussian
                [gauss, pval] = chi2gof(residual,'cdf',@normcdf); 
                if gauss
                    txt = sprintf('Gaussian profile (p=%.3f)',pval);
                else
                    txt = sprintf('Non-Gaussian profile (p=%.3f)',pval);
                end
                % legend settings
                title(this.axeResHist,txt);
                % axis settings
                this.axeResHist.XLabel.String = this.axeResScatter.YLabel.String;  
            end
        end %removeResidual
        
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

