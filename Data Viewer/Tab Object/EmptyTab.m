classdef EmptyTab < uix.Container & handle
    
    %
    % class that define the containers for the DisplayManager of
    % FitLike. Container can then be customised in subclasses.
    %
    % M.Petit - 03/2019
    % manuel.petit@inserm.fr
    
    % data
    properties (Access = public)
        hData     % handle data
        idxZone   % zone index
    end
    
    % plot
    properties
        hGroup    % contain handle of the plot object
        PlotSpec  % structure containing the display specifications
        inputType % input type accepted
    end
    
    % list of the components
    properties (Access = public)
        DisplayManager % Presenter
        box % handle to box
        axe % handle to the axis
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
            % add an axis (not visible)
            this.axe = axes('Parent', uicontainer('Parent',this.box),...
                'FontSize',8,'Visible','off',...
                'ActivePositionProperty', 'outerposition',...
                'Position',[0.09 0.09 0.86 0.86],...
                'NextPlot','Add');
            % set the Parent 
            this.Parent = tab;
            % set the name of the subtab 
            this.Parent.Title = 'Untitled';
            drawnow;
        end %DisplayTab
        
        % delete handle properly
        function delete(this)
            % remove handle if needed
            if ~isempty(this.hData)
                this.hData = [];
            end
        end
    end
    
    methods        
        % CREATEFIG(THIS) copy the current main axis into an external
        % figure.
        function createFig(this)
            % create a new fig 
            new_fig = figure();
            % copy the axe information into this new fig
            copyobj(this.axe, new_fig);
        end %createFig
        
        % [HDATA, IDXZONE] = GETDATA(THIS) returns the current data stored
        % in the tab. HDATA is an array of DataUnit and IDXZONE a vector of
        % the corresponding zone displayed. Remember that if all zones are
        % displayed for a given HDATA(i) then IDXZONE(i) is NaN.
        function [hData, idxZone] = getData(this)
             % get data
             hData = this.hData;
             idxZone = this.idxZone;
        end % getDataID
        
        % LEG = GETLEGEND(THIS) returns the current legend. Dummy function
        % here that avoid error if DisplayManager asks for legend to this
        % tab.
        function leg = getLegend(this) %#ok<MANU>
            leg = [];
        end %getLegend
        
        % PLOTID = GETPLOTID(THIS, HDATA, IDXZONE) returns a cell array of
        % plot ID. plotID are used to identify plot and are built as
        % [fileID,'@',displayName,'@',idxZone].
        % PLOTID = GETPLOTID(THIS) returns the current plotID list in the
        % tab. It uses the data and idxZone stored in the tab (hData and
        % idxZone property).
        % PLOTID = GETPLOTID(THIS, HDATA, IDXZONE) returns the list of
        % plotID corresponding to the HDATA and IDXZONE. HDATA should be an
        % array of DataUnit and IDXZONE a vector of the wanted zones.
        % Remember that if one wants all the zone for a given HDATA(i) then
        % IDXZONE(i) is NaN.
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
        
        % THIS = MOVEMOUSE(THIS) dummy function that avoid errors when
        % DisplayManager fires it.
        function moveMouse(this) %#ok<MANU>
            return
        end
    end   
    
    methods (Static)               
        % IDXZONE = GETIDXZONE(HPLOT) returns the IDXZONE of a given
        % graphical object (usually line, errorbar,...). The plotID of the
        % given graphical object should be stored in the Tag property to
        % avoid errors.
        % IDXZONE returned is a scalar indicating the zone displayed. If
        % all the zone are displayed then IDXZONE = NaN
        function idxZone = getIdxZone(hPlot)
            % check input
            if isempty(hPlot)
                idxZone = [];
            else
                str = strsplit(hPlot.Tag,'@');
                idxZone = str2double(str{3});
            end
        end
    end
end

