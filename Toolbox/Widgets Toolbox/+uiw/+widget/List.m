classdef List < uiw.abstract.WidgetContainer & uiw.mixin.HasCallback
    % List - A simple listbox control
    %
    % Create a widget that provides a listbox
    %
    % Syntax:
    %           w = uiw.widget.List('Property','Value',...)
    %
    
    % Copyright 2016-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 68 $
    %   $Date: 2018-03-08 11:37:51 -0500 (Thu, 08 Mar 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet)
        Items cell = cell(0,1) %Cell array of all items in the list [cell of strings]
        SelectedIndex double = 1 %Numeric indices of currently selected (highlighted) items in the list [column matrix]
        AllowMultiSelect (1,1) logical = false %Flag whether to allow multi-selection in the list. [true|(false)]
    end
    
    properties (Dependent, SetAccess=private)
        SelectedItems %Cell array of currently selected (highlighted) items [cell of char]
    end  
    
    
    %% Constructor / Destructor
    methods
        
        function obj = List(varargin)
            % Construct the control
            
            % List
            obj.h.Listbox = uicontrol( ...
                'Parent', obj.hBasePanel, ...
                'Style', 'listbox', ...
                'FontSize', 10, ...
                'String', cell(0,1),...
                'Units', 'pixels',...
                'Position', [0 0 1 1],...
                'Callback', @(h,e)onSelectionChanged(obj));
            
            % These args must be set last
            [lastArgs,firstArgs] = obj.splitArgs({'SelectedIndex'},varargin{:});
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(firstArgs{:},lastArgs{:});
            
            % Do the following only if the object is not a subclass
            if strcmp(class(obj), 'uiw.widget.List') %#ok<STISA>
                
                % Assign the construction flag
                obj.IsConstructed = true;
                
                % Redraw the widget
                obj.onResized();
                obj.onEnableChanged();
                obj.redraw();
                obj.onStyleChanged();
                
            end %if strcmp(class(obj),...
            
        end %constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function redraw(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Update the listbox
                if isempty(obj.Items)
                    obj.h.Listbox.String = {''};
                    obj.h.Listbox.Enable = 'off';
                else
                    uiw.utility.setPropsIfDifferent(obj.h.Listbox,'Enable',obj.Enable);
                    obj.h.Listbox.String = obj.Items;
                end
                
                % Remove any invalid indices
                obj.SelectedIndex(obj.SelectedIndex > numel(obj.Items)) = [];
                
                % If multiselect is on, or if empty selection, toggle multi
                % on for the list
                multiValue = 1 + obj.AllowMultiSelect + isempty(obj.SelectedIndex);
                obj.h.Listbox.Max = multiValue;

                % Set the selection
                obj.h.Listbox.Value = obj.SelectedIndex;
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onResized(obj,~,~)
            % Handle changes to widget size
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                pad = obj.Padding;
                %spc = obj.Spacing;
                
                % Position listbox
                listX = 1+pad;
                listY = 1+pad;
                listW = max(w - 2*pad, 0);
                listH = max(h - 2*pad, 0);
                obj.h.Listbox.Position = [listX listY listW listH];
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onSelectionChanged(obj)
            % Triggered on selection change
            
            % Prepare eventdata
            evt = struct('Source',obj,'Interaction','ListSelection');
            evt.SelectedItems = obj.SelectedItems;
            evt.SelectedIndex = obj.SelectedIndex;
            
            % Call the callback
            obj.callCallback(evt);
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        % Items
        function set.Items(obj,newItems)
            
            validateattributes(newItems,{'cell'},{})
            if ~all(cellfun(@(x)ischar(x),newItems))
                error('Expected a cell array containing char arrays.');
            end
            
            % Try to retain value selected, in case it moved on the list
            oldValue = obj.Items;
            if isempty(oldValue) || isempty(newItems)
                newIdxForValue = [];
            else
                [found,newIdxForValue] = ismember(newItems, oldValue);
                newIdxForValue(~found) = [];
            end
            
            % Set the new set of items
            obj.Items = newItems;
            
            % Set the selected index to retain if possible
            if isempty(newIdxForValue) && ~isempty(newItems) && ~obj.AllowMultiSelect %#ok<MCSUP>
                obj.SelectedIndex = 1; %#ok<MCSUP>
            else
                obj.SelectedIndex = newIdxForValue; %#ok<MCSUP>
            end
            
            % Redraw contents
            obj.redraw();
        end
        
        % SelectedItems
        function value = get.SelectedItems(obj)
            value = obj.Items( obj.SelectedIndex );
        end
        
        % SelectedIndex
        function set.SelectedIndex(obj,value)
            validateattributes(value,{'numeric'},{'positive','finite','<=',numel(obj.Items)}) %#ok<MCSUP>
            if ~obj.AllowMultiSelect && numel(value)>1 %#ok<MCSUP>
                error('uiw:widget:List:MultiSelectOff',...
                    ['The List must have a scalar '...
                    'SelectedIndex when AllowMultiSelect is false.'])
            end
            obj.SelectedIndex = value;
            obj.redraw();
        end
        
        % AllowMultiSelect
        function set.AllowMultiSelect(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowMultiSelect = value;
            obj.redraw();
        end
        
    end % Get/Set methods
    
    
end %classdef