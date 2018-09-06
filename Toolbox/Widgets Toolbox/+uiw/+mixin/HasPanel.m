classdef (Abstract) HasPanel < handle
    % HasPanel - Mixin class for a base uipanel and font properties
    %
    % This class provides a uipanel and font properties for widgets,
    % dialogs, etc. The widget must implement onStyleChanged to be called
    % when font styles have been updated.
    %
    
    % Copyright 2017-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $  $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet, Dependent)
        FontAngle %Style of the font [(normal)|italic]
        FontName %Name of the font 
        FontSize %Size of the font
        FontUnits %Units of the font [inches|centimeters|characters|normalized|(points)|pixels]
        FontWeight %Weight of the font [(normal)|bold]
        ForegroundColor %Foreground/font color of the panel
    end %properties
    
    properties (SetAccess=immutable, GetAccess=protected)
        hBasePanel = matlab.ui.container.Panel.empty(0,1); %The internal panel upon which the widget contents are placed
    end %properties

    
    
    %% Abstract Methods
    methods (Abstract, Access=protected) %Must be defined in subclass
        onStyleChanged(obj,evt) %Handle updates to style changes - subclass must implement
    end %methods
    
    
    
    %% Constructor
    methods
        function obj = HasPanel()
            % Construct the panel
            
            if isempty(obj.hBasePanel)
                obj.hBasePanel = matlab.ui.container.Panel(...
                    'HandleVisibility','off',...
                    'BorderType','none',...
                    'Units','pixels',...
                    'FontSize', 10);
            end
            
        end %function
    end %constructor
    
    
    
    %% Get/Set methods
    methods
        
        % ForegroundColor
        function value = get.ForegroundColor(obj)
            value = obj.hBasePanel.ForegroundColor;
        end
        function set.ForegroundColor(obj,value)
            evt = struct('Property','ForegroundColor',...
                'OldValue',obj.ForegroundColor,...
                'NewValue',value);
            obj.hBasePanel.ForegroundColor = value;
            obj.onStyleChanged(evt);
        end
        
        % FontAngle
        function value = get.FontAngle(obj)
            value = obj.hBasePanel.FontAngle;
        end
        function set.FontAngle(obj,value)
            evt = struct('Property','FontAngle',...
                'OldValue',obj.FontAngle,...
                'NewValue',value);
            obj.hBasePanel.FontAngle = value;
            obj.onStyleChanged(evt);
        end
        
        % FontName
        function value = get.FontName(obj)
            value = obj.hBasePanel.FontName;
        end
        function set.FontName(obj,value)
            evt = struct('Property','',...
                'OldValue',obj.FontName,...
                'NewValue',value);
            obj.hBasePanel.FontName = value;
            obj.onStyleChanged(evt);
        end
        
        % FontSize
        function value = get.FontSize(obj)
            value = obj.hBasePanel.FontSize;
        end
        function set.FontSize(obj,value)
            evt = struct('Property','FontSize',...
                'OldValue',obj.FontSize,...
                'NewValue',value);
            obj.hBasePanel.FontSize = value;
            obj.onStyleChanged(evt);
        end
        
        % FontUnits
        function value = get.FontUnits(obj)
            value = obj.hBasePanel.FontUnits;
        end
        function set.FontUnits(obj,value)
            evt = struct('Property','FontUnits',...
                'OldValue',obj.FontUnits,...
                'NewValue',value);
            obj.hBasePanel.FontUnits = value;
            obj.onStyleChanged(evt);
        end
        
        % FontWeight
        function value = get.FontWeight(obj)
            value = obj.hBasePanel.FontWeight;
        end
        function set.FontWeight(obj,value)
            evt = struct('Property','FontWeight',...
                'OldValue',obj.FontWeight,...
                'NewValue',value);
            obj.hBasePanel.FontWeight = value;
            obj.onStyleChanged(evt);
        end
        
    end % Get/Set methods
    
    
end % classdef