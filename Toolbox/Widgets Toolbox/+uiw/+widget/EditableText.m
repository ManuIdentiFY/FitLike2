classdef EditableText < uiw.abstract.EditableTextControl
    % EditableText - A simple text or numeric edit field
    %
    % Create a widget with editable text.
    %
    % Syntax:
    %           w = uiw.widget.EditableText('Property','Value',...)
    %
    
    % Copyright 2005-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $
    %   $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        FieldType char = 'text' % Type of text entry for validation (['text'],'number','matrix','eval')
        Validator function_handle = function_handle.empty(0,0) % Custom validation function for text entry
        ShowDialogOnError logical = true; % Should a dialog be presented on an invalid entry?
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = EditableText(varargin)
            % Construct the widget
            
            % Call superclass constructors
            obj@uiw.abstract.EditableTextControl();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.redraw();
            obj.onStyleChanged();
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    %% Protected methods
    methods (Access=protected)
        
        function StatusOk = checkValue(obj,value)
            % Return true if the value is valid
            
            StatusOk = true;
            if ~isempty(obj.Validator)
                try
                    obj.Validator(value);
                catch err
                    StatusOk = false;
                    if obj.ShowDialogOnError
                        hDlg = errordlg(err.message,obj.LabelString,'modal');
                        uiwait(hDlg);
                    end
                end
            end
            
        end %function
        
        
        function value = interpretStringAsValue(obj,str)
            % Convert entered text to stored data type
            
            switch obj.FieldType
                case 'text'
                    value = str;
                case {'number','matrix'}
                    value = str2num(str); %#ok<ST2NM>
                case 'eval'
                    value = eval(str);
            end
            
        end %function
        
        
        function str = interpretValueAsString(obj,value)
            % Convert stored data to displayed text
            
            switch obj.FieldType
                case 'text'
                    str = value;
                case 'number'
                    str = num2str(value);
                case 'matrix'
                    str = mat2str(value);
                case 'eval'
                    str = value;
            end
            
        end %function
        
    end % Protected methods
    
    
    %% Get/Set methods
    methods
        
        function set.FieldType(obj,value)
            value = validatestring(value,{'text','number','matrix','eval'});
            obj.FieldType = value;
        end
        
        function set.ShowDialogOnError(obj,value)
            validateattributes(value,{'logical'},{'scalar'});
            obj.ShowDialogOnError = value;
        end
        
    end % Get/Set methods
    
end % classdef
