classdef DisplayTab < uix.Container & handle
    
    %
    % Abtract class that define the containers for the DisplayManager of
    % FitLike. Container can then be customised in subclasses.
    %
    
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
    
    methods (Access = public)        
        % mask(): create a draggable rectangle in the current axis and
        % return the x-y selection
        function [xrange, yrange] = mask(this)
            % desactivate warnings: problem with negative value
            warning off all 
            % create draggable rectangle. 
            rect = imrect(this.axe);
            % set a function that keep the rectangle inside the original XLim
            % and YLim ranges of the axes.
            % NOTE: Problems appear with the log scale plot: the rectangle
            % doesn't keep his size if the user drag the obj. To fix in a future
            % release 
            fcn = makeConstrainToRectFcn('imrect',this.axe.XLim,...
                                                 this.axe.YLim);
            setPositionConstraintFcn(rect, fcn);
            % wait until the user double-click on the rectangle to get the
            % position
            pos = wait(rect);       
            % delete the rectangle obj
            delete(rect);
            warning on all
            % range
            xrange = [pos(1) pos(1)+pos(3)];
            yrange = [pos(2) pos(2)+pos(4)];
        end %mask       
        
        % Export current axis in a new fig: createFig()
        function createFig(this)
            % create a new fig 
            new_fig = figure();
            % copy the axe information into this new fig
            copyobj(this.axe, new_fig);
        end %createFig
    end
    
    methods (Abstract)
        % Add new data to the current axis
        addPlot(this, varargin)
        % Remove data from the current axis
        removePlot(this, varargin)
        % Set the legend in the current axis
        update(this, varargin)
    end    
end

