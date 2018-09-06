classdef (Abstract) HasCallback < handle
    % HasCallback - Mixin to provide a callback for a widget
    % ---------------------------------------------------------------------
    % This is a mixin class. It provides a callback for a widget.
    %
    % The class must inherit this object to access the Callback property
    % and callCallback method. The callback must be stored as a function
    % handle, such as:
    %
    %   obj.Callback = @(src,evt)foo(obj,evt);
    %
    % or if you do not want to provide event data:
    %
    %   obj.Callback = @(src,evt)foo(obj);
    %
    % Call the callback with custom event data like this:
    %
    %   evt = struct('Source',obj,'Interaction','AddButtonPress');
    %   obj.callCallback(evt);
    %
    
    % Copyright 2016-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 26 $  $Date: 2018-01-10 16:54:41 -0500 (Wed, 10 Jan 2018) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet)
        Callback function_handle = function_handle.empty(0,1) %function handle to call when the widget is edited
    end
    
    
    %% Methods
    
    methods (Access=protected)
        
        function callCallback( obj, eventdata )
            % Call the function handle based callback
            
            if ~isempty(obj.Callback)
                if nargin>1
                    obj.Callback(obj, eventdata);
                else
                    obj.Callback(obj);
                end
            end
            
        end %function
        
    end %methods
    
    
    %% Get/set methods
    methods
        
        % Callback
        function set.Callback(obj,value)
            if isempty(value)
                obj.Callback = function_handle.empty(0,1);
            else
                obj.Callback = value;
            end
        end %function
        
    end %methods
    
end %classdef