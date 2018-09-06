classdef Password < uiw.abstract.JavaEditableText
    % Password - A password control that hides typed characters
    %
    % Create a widget for entering a password
    %
    % Syntax:
    %     w = uiw.widget.Password('Property','Value',...)
    %
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $
    %   $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Constructor / Destructor
    methods
        function obj = Password(varargin)
            % Construct the control
            
            % Create
            obj.createJControl('javax.swing.JPasswordField');
            obj.JEditor = obj.JControl;
            obj.JControl.ActionPerformedCallback = @(h,e)onTextEdited(obj,h,e);
            
            % Set properties from P-V pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.onStyleChanged();
            obj.redraw();
            
        end % constructor
    end %methods - constructor/destructor
    
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function onFocusLost(obj,h,e)
            % Triggered on focus lost from the control
            
            % Call superclass method
            obj.onFocusLost@uiw.abstract.JavaControl(h,e);
            
            % Complete any text edits
            obj.onTextEdited(h,e);
            
        end %function
        
    end % Protected methods
    
end % classdef