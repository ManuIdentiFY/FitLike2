classdef EmptyTab < uix.Container & handle
    
    %
    % class that define the containers for the DisplayManager of
    % FitLike. Container can then be customised in subclasses.
    %
    
    % data
    properties (Access = public)
        hData     % handle data
        idxZone   % zone index
        inputType % input type accepted
        PlotSpec  % structure containing the display specifications
    end
    
    % list of the components
    properties (Access = public)
        FitLike % Presenter
        box % handle to box
    end
        
    methods (Access = public)
        % Constructor
        function this = EmptyTab(FitLike, tab)
            % Call superclass constructor
            this@uix.Container();
            this.FitLike = FitLike;
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
        function [c, fileID, displayName, idx] = getDataID(this)
            % check if possible 
            if isempty(this.hData)
                c = []; fileID = []; displayName = []; idx = [];
            else
                c = class(this.hData);
                fileID = {this.hData.fileID};
                displayName = {this.hData.displayName};
                idx = this.idxZone;
            end
        end % getDataID
        
        % get legend
        function leg = getLegend(this)
            leg = [];
        end %getLegend
        
        % get the plotID
        function plotID = getPlotID(this, hData, idxZone)
            % check input
            if nargin < 2
                if isempty(this.hData)
                    plotID = [];
                else
                    % concatenate the original ID with the zone index
                    plotID = strcat({this.hData.fileID},'@',{this.hData.displayName},'@',...
                        cellfun(@num2str, num2cell(this.idxZone),'Uniform',0));
                end
            else
                if isempty(hData)
                    plotID = [];
                else
                    plotID = strcat(hData.fileID,'@', hData.displayName,'@',...
                        num2str(idxZone));
                end
            end
        end %getPlotID
        
        % dummy method
        function moveMouse(this)
            return
        end
    end   
end

