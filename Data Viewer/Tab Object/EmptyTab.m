classdef EmptyTab < uix.Container & handle
    
    %
    % class that define the containers for the DisplayManager of
    % FitLike. Container can then be customised in subclasses.
    %
    
    % data
    properties (Access = public)
        hData     % handle data
        idxZone   % zone index
    end
    
    % plot
    properties
        Legend    % handle to the legend
        hGroup    % contain handle of the plot object
        PlotSpec  % structure containing the display specifications
        inputType % input type accepted
    end
    
    % list of the components
    properties (Access = public)
        DisplayManager % Presenter
        box % handle to box
    end
        
    methods (Access = public)
        % Constructor
        function this = EmptyTab(DisplayManager, tab)
            % Call superclass constructor
            this@uix.Container();
            this.DisplayManager = DisplayManager;
            % Create the container in the parent tab
            grid = uix.Grid('Parent',this,'Spacing', 5); 
            this.box = uix.VBox( 'Parent', grid, 'Padding', 5);
            % set the Parent 
            this.Parent = tab;
            % set the name of the subtab 
            this.Parent.Title = 'Untitled';
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
        
        % get the ID information of the data plotted
        function [hData, idxZone] = getData(this)
             % get data
             hData = this.hData;
             idxZone = this.idxZone;
        end % getDataID
        
        % get legend
        function [leg, hData] = getLegend(this) %#ok<MANU>
            leg = []; hData = [];
        end %getLegend
        
        % get the plotID
        function plotID = getPlotID(this, hData, idxZone)
            % check input
            if nargin < 2
                if isempty(this.hData)
                    plotID = [];
                else
                    % concatenate the original ID with the zone index
                    fileID = arrayfun(@(x) getRelaxProp(x, 'fileID'),...
                                           this.hData, 'Uniform', 0);
                    plotID = strcat(fileID,'@',{this.hData.displayName},'@',...
                        cellfun(@num2str, num2cell(this.idxZone),'Uniform',0));
                end
            else
                if isempty(hData)
                    plotID = [];
                else
                    plotID = strcat(getRelaxProp(hData, 'fileID'),'@',...
                        hData.displayName,'@', num2str(idxZone));
                end
            end
        end %getPlotID
        
        % dummy method
        function moveMouse(this) %#ok<MANU>
            return
        end
    end   
    
    methods (Static)               
        % getIdxZone
        function idxZone = getIdxZone(hData)
            % check input
            if isempty(hData)
                idxZone = [];
            else
                str = strsplit(hData.Tag,'@');
                idxZone = str2double(str{3});
            end
        end
    end
end

