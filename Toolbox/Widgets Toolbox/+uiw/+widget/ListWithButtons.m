classdef ListWithButtons < uiw.widget.List & uiw.mixin.ListSortingButtons
    % ListWithButtons - A listbox with ordering and action buttons
    %
    % Create a widget that provides a list with adjacent buttons to edit
    % and order items from a listbox
    %
    % Syntax:
    %           w = uiw.widget.ListWithButtons('Property','Value',...)
    %
    
    % Copyright 2016-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $
    %   $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ListWithButtons(varargin)
            % Construct the control
            
            % Parent the buttons
            set(obj.h.Button,'Parent',obj.hBasePanel);
            
            % Do the following only if the object is not a subclass
            if strcmp(class(obj), 'uiw.widget.ListWithButtons') %#ok<STISA>
                
                % Populate public properties from P-V input pairs
                obj.assignPVPairs(varargin{:});
                
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
            
            % Call superclass method
            obj.redraw@uiw.widget.List();
            
            % Update button enable states
            obj.redrawButtons(obj.SelectedIndex, numel(obj.Items));
            
        end %function redraw
        
        
        function onResized(obj)
            % Handle changes to widget size
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                
                % Position buttons first, and return remaining space for
                % the list
                [x0,y0,w,h] = obj.positionButtons(w,h);
                
                % Position listbox
                obj.h.Listbox.Position = [x0,y0,w,h];
                
            end %if obj.IsConstructed
            
        end %function onResized(obj)
        
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Update button enable states
                obj.redrawButtons(obj.SelectedIndex, numel(obj.Items));
                
            end %if obj.IsConstructed
            
        end %function onEnableChanged(obj)
        
        
        function onSelectionChanged(obj)
            % Triggered on selection change
            
            % Redraw the component
            obj.redraw();
            
            % Call the callback
            evt = struct('Source',obj,'Interaction','Select');
            evt.SelectedItems = obj.SelectedItems;
            evt.SelectedIndex = obj.SelectedIndex;
            obj.callCallback(evt);
            
        end %function
        
        
        function onButtonPressed(obj,h,~)
            % Triggered on button press
            
            % Prepare eventdata
            evt = struct('Source',obj,'Interaction',h.Tag);
            evt.SelectedItems = obj.SelectedItems;
            evt.SelectedIndex = obj.SelectedIndex;
            
            % Take custom action
            switch h.Tag
                
                case 'MoveDown'
                    [idxNew, idxDest] = obj.shiftIndexInList(...
                        obj.SelectedIndex, numel(obj.Items), 1);
                    obj.SelectedIndex = idxDest; %must do this before redraw
                    obj.Items = obj.Items(idxNew); %calls redraw()
                    evt.NewOrder = idxNew;
                    evt.DestIndex = idxDest;
                    
                case 'MoveUp'
                    [idxNew, idxDest] = obj.shiftIndexInList(...
                        obj.SelectedIndex, numel(obj.Items), -1);
                    obj.SelectedIndex = idxDest; %must do this before redraw
                    obj.Items = obj.Items(idxNew); %calls redraw()
                    evt.NewOrder = idxNew;
                    evt.DestIndex = idxDest;
                    
                otherwise
                    
                    % Nothing special, just trigger the callback
                    
            end %switch Interaction
            
            % Call the callback
            obj.callCallback(evt);
            
        end %function onButtonPressed
        
    end %methods
    
end %classdef