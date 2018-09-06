classdef MouseEvent < uiw.event.EventData
    % MouseEvent - Class for eventdata for mouse actions
    % 
    % This class provides storage of data for a mouse event
    %
    % Syntax:
    %           obj = uiw.event.MouseEvent
    %           obj = uiw.event.MouseEvent('Property','Value',...)
    %
    
    % Copyright 2017-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 59 $  $Date: 2018-02-27 15:40:39 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        HitObject matlab.graphics.Graphics
        MouseSelection matlab.graphics.Graphics
        Axes matlab.graphics.axis.Axes
        AxesPoint double
        Figure matlab.ui.Figure
        FigurePoint double
        ScreenPoint double
    end %properties
  
    
    %% Constructor / destructor
    methods
        
        function obj = MouseEvent(varargin)
            % Construct the event
            
            % Call superclass constructors
            obj@uiw.event.EventData(varargin{:});
            
        end %constructor
        
    end %methods
    
end % classdef