classdef EditablePopup < uiw.abstract.JavaEditableText
    % EditablePopup - A popup control with editable text
    %
    % Create a widget that is an editable popup/combobox/dropdown
    %
    % Syntax:
    %           w = uiw.widget.EditablePopup('Property','Value',...)
    %
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $
    %   $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet)
        Items cell = cell(0,1) %Cell array of all items in the list [cell of strings]
    end
    
    properties (Dependent, AbortSet)
        SelectedIndex double % The selected index from the list of choices (0 if edited)
    end
    
    
    %% Constructor / Destructor
    methods
        function obj = EditablePopup(varargin)
            
            % Create the control
            %obj.createJControl('javax.swing.JComboBox');
            % The JIDE version expands the dropdown to accomodate wide text
            obj.createJControl('com.jidesoft.combobox.ListComboBox');
            obj.JControl.setEnabled(true);
            obj.JControl.setEditable(true);
            obj.JControl.ActionPerformedCallback = @(h,e)onTextEdited(obj,h,e);
            %obj.JControl.FocusLostCallback = @(h,e)onTextEdited(obj,h,e);
            obj.JControl.KeyTypedCallback = @(h,e)onTextEdited(obj,h,e);
            obj.JEditor = javaObjectEDT(obj.JControl.getEditor().getEditorComponent());
            obj.JEditor.setOpaque(true); %Needed for background color
            
            % For JComboBox, the *editor* is what needs focusability
            obj.JControl.setFocusable(false);
            obj.setFocusProps(obj.JEditor);
            
            % Default value (twice because AbortSet treats [] and '' the
            % same)
            obj.Value = 'temp';
            obj.Value = '';
            
            % These args must be set last
            [lastArgs,firstArgs] = obj.splitArgs({'SelectedIndex'},varargin{:});
            
            % Set properties from P-V pairs
            obj.assignPVPairs(firstArgs{:},lastArgs{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.onStyleChanged();
            obj.redraw();
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Public Methods
    methods
        
        function [str,data] = onCopy(obj)
            % Execute a copy operation on the control
            
            obj.JEditor.copy();
            str = clipboard('paste');
            data = str;
            
        end %function
        
        
        function [str,data] = onCut(obj)
            % Execute a cut operation on the control
            
            obj.JEditor.cut();
            str = clipboard('paste');
            data = str;
            
        end %function
        
        
        function onPaste(obj,str)
            % Execute a paste operation on the control
            
            if ischar(str)
                obj.JEditor.paste();
            end
            
        end %function
        
    end %methods
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function onResized(obj)
            % Handle changes to widget size
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                
                % Calculations for a normal uicontrol popup:
                % FontSize =  10: Height = 25
                % FontSize =  20: Height = 42
                % FontSize =  50: Height = 92
                % FontSize = 100: Height = 175
                % Buffer is 8-9, so h = FontSize*1.6666 + 8
                
                % Calculate popup height based on font size
                if strcmp(obj.FontUnits,'points')
                    hW = round(obj.FontSize*1.666666) + 8;
                    pos = [1 h-hW+1 w hW];
                else
                    pos = [1 1 w h];
                end
                
                % Update position
                set(obj.HGJContainer,'Position',pos);
                
            end %if obj.IsConstructed
        end %function onResized(obj)
        
        % This method may be overridden for custom behavior
        function onStyleChanged(obj,~)
            % Handle updates to style and value validity changes
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.JavaEditableText(obj);
                
                % Also need font change on list part (JIDE only)
                % This fails, because it doesn't widen to the new list
                %jList = obj.JControl.getList;
                %jList.setFont(obj.getJFont());
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function setValue(obj,value)
            % Set the selection to Java control
            
            validateattributes(value,{'char'},{})
            obj.JControl.setSelectedItem(value);
            obj.Value = value;
            
        end %function
        
        
        function onFocusLost(obj,h,e)
            % Triggered on focus lost from the control - subclass may override
            
            % Call superclass method
            obj.onFocusLost@uiw.abstract.JavaControl(h,e);
            
            % Complete any text edits
            obj.onTextEdited(h,e);
            
        end %function
        
        
        function onTextEdited(obj,~,~)
            % Handle interaction with text field
            
            % Ensure the construction is complete
            if obj.isvalid && obj.IsConstructed && obj.CallbacksEnabled
                
                str = deblank(obj.getValue());
                value = obj.interpretStringAsValue(str);
                
                % Validate
                ok = checkValue(obj,value);
                if ok
                    % Trigger callback if value changed
                    if ~isequal(obj.Value, value)
                        evt = struct('Source', obj, ...
                            'Interaction', 'Edit', ...
                            'OldSelectedIndex', obj.SelectedIndex, ...
                            'NewSelectedIndex', [],...
                            'OldValue', obj.Value, ...
                            'NewValue', '',...
                            'NewString', str);
                        obj.Value = obj.interpretValueAsString(value);
                        evt.NewSelectedIndex = obj.SelectedIndex;
                        evt.NewValue = obj.Value;
                        obj.callCallback(evt);
                    end
                else
                    % Value was invalid, so revert
                    %obj.CallbacksEnabled = false;
                    str = obj.interpretValueAsString(obj.Value);
                    obj.setValue(str);
                    %obj.CallbacksEnabled = true;
                end
                
            end %if obj.IsConstructed && obj.CallbacksEnabled
            
        end %function
        
    end % Protected methods
    
    
    %% Get/Set methods
    methods
        
        % Items
        function set.Items(obj,value)
            validateattributes(value,{'cell'},{})
            value = cellstr(value(:)');
            obj.Items = value;
            % If the Items was just edited, perhaps we shouldn't replace
            % the whole model. Only replace model if very new Items? Check
            % performance.
            if isempty(value)
                value = {''};
            end
            currentValue = obj.Value;
            jModel = javaObjectEDT('javax.swing.DefaultComboBoxModel',value);
            obj.JControl.setModel(jModel);
            javaMethod('setSelectedItem',obj.JControl,currentValue);
        end
        
        % SelectedIndex
        function value = get.SelectedIndex(obj)
            if obj.IsConstructed
                value = javaMethodEDT('getSelectedIndex',obj.JControl) + 1;
                if value==0
                    value = [];
                end
            else
                value = [];
            end
        end
        function set.SelectedIndex(obj,value)
            obj.CallbacksEnabled = false;
            validateattributes(value,{'numeric'},{'nonnegative','integer','finite','<=',numel(obj.Items)})
            if value~=0
                obj.setValue(obj.Items{value});
            else
                obj.setValue('');
            end
            %javaMethodEDT('setSelectedIndex',obj.JControl,value-1);
            obj.CallbacksEnabled = true;
        end
        
    end % Get/Set methods
    
end % classdef
