classdef EmptyTab < DisplayTab
    %
    % Empty container for DisplayManager
    %
    % SEE ALSO DISPERSIONTAB, DISPLAYMANAGER
    
    % set the abstract property
    properties
        
    end
    
    methods
        % Constructor
        function this = EmptyTab(FitLike, tab)
            % call the superclass constructor
            this = this@DisplayTab(FitLike, tab);
            % set the name of the subtab 
            this.Parent.Title = 'Untitled';
            % set the axis visibility to "off"
            this.axe.Visible = 'off';
        end %EmptyTab
    end
    
    % Create concrete class by adding dummy methods
    methods (Access = public)
        % Add new data to the current axis: addPlot()
        function this = addPlot(this)
            return
        end %removePlot()
        % Remove data from the current axis: removePlot()
        function this = removePlot(this)
            return
        end %removePlot()
        % Set the legend: setLegend()
        function this = update(this)
            return
        end %setLegend
    end
    
end

