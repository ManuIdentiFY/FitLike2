classdef DisplayTab < uix.Container & handle
    
    %
    % class that define the containers for the DisplayManager of
    % FitLike. Container can then be customised in subclasses.
    %
    
    % data
    properties 
        hData % handle data
        PlotSpec % structure containing the display specifications
    end
    
    % list of the components
    properties (Access = public)
        FitLike % Presenter
        box % handle to box
        axe % handle to the axis
    end
        
    methods (Access = public)
        % Constructor
        function this = DisplayTab(FitLike, tab)
            % Call superclass constructor
            this@uix.Container();
            this.FitLike = FitLike;
            % Create the container in the parent tab
            grid = uix.Grid('Parent',this,'Spacing', 5); 
            this.box = uix.VBox( 'Parent', grid, 'Padding', 5);
            % Create an axis for the tab
            this.axe = axes('Parent',uicontainer('Parent',this.box),...
                        'FontSize',8,...
                        'ActivePositionProperty', 'outerposition',...
                        'Position',[0.09 0.09 0.86 0.86],...
                        'NextPlot','Add');
            % set the Parent 
            this.Parent = tab;
            drawnow;
        end %DisplayTab
    end
    
    methods        
        % Export current axis in a new fig: createFig()
        function createFig(this)
            % create a new fig 
            new_fig = figure();
            % copy the axe information into this new fig
            copyobj(this.axe, new_fig);
        end %createFig
    end   
end

