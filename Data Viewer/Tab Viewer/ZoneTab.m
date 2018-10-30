classdef ZoneTab < DispersionTab
    %
    % Class that design containers for zone data
    %
    % See also DISPERSIONTAB, DISPLAYTAB
    
    % Note: Plotting data requires lot of time, especially because
    % we need to dynamically update the legend (50% maybe) and the axis
    % (10%). Could be improved.
    % Note2: the hData input should be improved to be: one object = one
    % plot. A possibility could be the creation of a subzone object
    % containing all the information for only one zone.
    
    properties
    end
    
    methods
        % constructor
        function this = ZoneTab(FitLike, tab)
            % call the superclass constructor and set the Presenter
            this = this@DispersionTab(FitLike, tab);
            % update title and type
            this.Parent.Title = 'Zone';
            this.inputType = 'Zone';
        end % ZoneTab
        
        % overwrite addplot function to select zone index
        function this = addPlot(this, hData, varargin) 
            % append data
            this.hData = [this.hData hData];
            
            % add listener 
            addlistener(hData,'FileHasChanged',@(src, event) updateID(this, src)); 
            addlistener(hData,'DataHasChanged',@(src, event) updateZoneData(this, src));
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
        end %addPlot
        
        % overwrite deleteplot function to delete zone
        function this = deletePlot(this, hData, varargin)
            % get the           
            % get all plot corresponding to the hData and delete them
            hAxe = findobj(this, 'Type', 'axes');
            % loop
            for k = 1:numel(hAxe)
                hPlot = findobj(hAxe(k).Children, '-regexp', 'Tag', hData.fileID);
                delete(hPlot)
            end
            drawnow;
            showLegend(this);                
        end %deletePlot
    end
    
end

