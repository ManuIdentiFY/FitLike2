classdef Slider < uiw.abstract.JavaControl & ...
        uiw.mixin.HasEditableText & uiw.mixin.HasCallback
    % Slider - A numeric slider with editable text value
    %
    % Create a widget with a slider and edit text.
    %
    % Syntax:
    %           w = uiw.widget.Slider('Property','Value',...)
    %
    
    % Copyright 2017-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $
    %   $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet, Dependent)
        Orientation % Slider orientation [horizontal|vertical]
    end
    
    properties (AbortSet)
        Min = 0 % Minimum value allowed
        Max = 100 % Maximum value allowed
        EnforceRange logical = true % Require edit field to also be in range?
        FlipText logical = false % Put text on opposite side [true|(false)]
        TextHeight double = 30 % Pixel height of edit text (applies to top|bottom location)
        TextWidth double = 35 % Pixel width of edit text (applies to left|right location)
        ShowTicks logical = true % Whether to show ticks [(true)|false]
    end
    
    properties (Access=protected)
        Multiplier = 1 % Multiplier used for internal calculation
        hEditBox = [] % Editable text box
    end
    
    
    
    %% Constructor / Destructor
    methods
        
        function obj = Slider(varargin)
            % Construct the control
            
            % Create the edit control
            obj.hEditBox = uicontrol(...
                'Parent',obj.hBasePanel,...
                'Style','edit',...
                'HorizontalAlignment','center',...
                'Units','pixels',...
                'Callback', @(h,e)obj.onTextEdited() );
            obj.hTextFields = obj.hEditBox;
            
            % Create the slider
            obj.createJControl('javax.swing.JSlider');
            %obj.JControl.StateChangedCallback = @(h,e)onSliderMotion(obj);
            obj.JControl.MouseReleasedCallback = @(h,e)onSliderChanged(obj);
            obj.HGJContainer.Units = 'pixels';
            obj.JControl.setOpaque(false);
            
            % Use the default value
            obj.Value = obj.JControl.getValue();
            
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
        
        function onValueChanged(obj,~)
            % Handle updates to value changes
            
            obj.redraw();
            
        end %function
        
        
        function redraw(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Update edit text value
                obj.hEditBox.String = obj.interpretValueAsString(obj.Value);
                
                % Update slider value
                jValue = obj.Value * obj.Multiplier;
                javaMethodEDT('setValue',obj.JControl,jValue);
                
                % Are we enforcing the range? If not, we need to recheck
                % coloring.
                if ~obj.EnforceRange
                    obj.onStyleChanged();
                end
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onResized(obj,~,~)
            % Handle changes to widget size
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                pad = obj.Padding;
                spc = obj.Spacing;
                hT = min(obj.TextHeight, h);
                wT = min(obj.TextWidth, w);
                
                % Calculate new positions
                if strcmpi(obj.Orientation,'horizontal')
                    wT = min(wT, w/2);
                    pad = floor( min(pad, wT/8) );
                    if obj.FlipText
                        div = wT+pad;
                        tPos = [1 (h-hT)/2 wT hT];
                        jPos = [1+(div+pad) 1 (w-div-pad) h];
                    else
                        div = w-wT-pad;
                        jPos = [1 1 (div-pad) h];
                        tPos = [1+(div+pad) (h-hT)/2 wT hT];
                    end
                else %vertical
                    hT = min(hT, h/2);
                    pad = floor( min(spc/2, hT/8) );
                    if obj.FlipText
                        div = h-hT-pad;
                        jPos = [1 1 w (div-pad)];
                        tPos = [1 1+(div+pad) w hT];
                    else
                        div = hT+pad;
                        tPos = [1 1 w hT];
                        jPos = [1 1+(div+pad) w (h-div-pad)];
                    end
                end
                
                % Set positions
                obj.HGJContainer.Position = jPos;
                obj.hEditBox.Position = tPos;
                % We want to have up to 10 major ticks and five minor ticks in
                % between. We try to get major ticks on powers of ten.
                
                % Get the widget width and use it to determine the maximum
                % number of tick marks. We allow a minimum of 25 pixels between
                % each major tick-mark.
                if strcmpi(obj.Orientation,'horizontal')
                    maxnum = floor(w/25);
                else
                    maxnum = floor(h/25);
                end
                
                % Work out our desired spacing
                range = (obj.Max - obj.Min);
                major = power( 10, ceil( log10( range/100 ) ) );
                
                % Increase the spacing until we have sufficiently few
                while range/major > maxnum
                    if range/(major*2) <= maxnum
                        major = major*2;
                    elseif range/(major*5) <= maxnum
                        major = major*5;
                    else
                        major = major*10;
                    end
                end
                
                % Minor ticks are 5 per major tick
                minor = major/5;
                
                % We need to use integers so use a multiplier if spacing is
                % fractional
                obj.Multiplier = max(1/minor, 1);
                mMin = obj.Min;
                mMax = obj.Max;
                jMin = mMin * obj.Multiplier;
                jMax = mMax * obj.Multiplier;
                jMinor = minor * obj.Multiplier;
                jMajor = major * obj.Multiplier;
                
                % Now set them
                javaMethodEDT('setMinimum',obj.JControl,jMin);
                javaMethodEDT('setMaximum',obj.JControl,jMax);
                javaMethodEDT('setMinorTickSpacing',obj.JControl,jMinor);
                javaMethodEDT('setMajorTickSpacing',obj.JControl,jMajor);
                
                % Set ticks displayon/off
                javaMethodEDT('setPaintTicks',obj.JControl,obj.ShowTicks);
                javaMethodEDT('setPaintLabels',obj.JControl,obj.ShowTicks);
                
                % The labels need to recreated to lie on the major ticks
                if obj.ShowTicks
                    numMajor = numel(jMajor);
                    jHash = java.util.Hashtable(numMajor);
                    tickValues = int32(jMin:jMajor:jMax);
                    thisLabelVal = mMin;
                    for idx=1:numel(tickValues)
                        jThisLabel = javax.swing.JLabel(num2str(thisLabelVal));
                        jHash.put(tickValues(idx),jThisLabel);
                        thisLabelVal = thisLabelVal + major;
                    end
                    javaMethodEDT('setLabelTable',obj.JControl,jHash);
                end %if obj.ShowTicks
                
                % Update slider value
                jValue = obj.Value * obj.Multiplier;
                javaMethodEDT('setValue',obj.JControl,jValue);
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onEnableChanged@uiw.abstract.JavaControl(obj);
                onEnableChanged@uiw.mixin.HasEditableText (obj);
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style and value validity changes
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.JavaControl(obj);
                onStyleChanged@uiw.mixin.HasEditableText(obj);
                
                % Are we enforcing the range?
                if ~obj.EnforceRange && obj.TextIsValid &&...
                        (obj.Value>obj.Max) || (obj.Value<obj.Min)
                    % Color yellow if the value is out of range
                    set(obj.hTextFields, 'BackgroundColor', [1 1 .7]);
                end
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function StatusOk = checkValue(~, value)
            % Return true if the value is valid
            
            StatusOk = isnumeric(value) && isscalar(value) && ~isnan(value);
            
        end %function
        
        
        function value = interpretStringAsValue(obj,str)
            % Convert entered text to stored data type
            
            value = min(obj.Max, max(obj.Min,str2double(str)));
            
        end %function
        
        
        function str = interpretValueAsString(~,value)
            % Convert stored data to displayed text
            
            str = num2str(value);
            
        end %function
        
        
        % function onSliderMotion(obj)
        %     newValue = obj.JControl.getValue();
        %     evt = struct('Source', obj, ...
        %         'Interaction', 'Slider Motion', ...
        %         'OldValue', obj.Value, ...
        %         'NewValue', newValue);
        %     obj.Value = newValue / obj.Multiplier;
        %     obj.redraw();
        %     %RAJ - not working for now
        %     %obj.callCallback(evt);
        % end
        
        
        function onSliderChanged(obj)
            % Handle interaction with slider
            
            newValue = obj.JControl.getValue();
            evt = struct('Source', obj, ...
                'Interaction', 'Slider Changed', ...
                'OldValue', obj.Value, ...
                'NewValue', newValue);
            obj.Value = newValue / obj.Multiplier;
            obj.redraw();
            obj.callCallback(evt);
            
        end %function
        
        
        function onTextEdited(obj)
            % Handle interaction with edit box
            
            newValue = str2double(obj.hEditBox.String);
            
            evt = struct('Source', obj, ...
                'Interaction', 'Edit Changed', ...
                'OldValue', obj.Value, ...
                'NewValue', newValue);
            
            if obj.Min <=newValue && obj.Max >= newValue
                % Set the new value
                obj.Value = newValue;
                obj.redraw();
                obj.callCallback(evt);
            elseif obj.EnforceRange
                % Outside range, so revert
                obj.hEditBox.String = num2str(obj.Value);
                obj.redraw();
            else
                % Allow edit outside range but color slider
                obj.Value = newValue;
                obj.redraw();
                obj.callCallback(evt);
            end
            
        end %function
        
    end % Protected methods
    
    
    
    %% Get/Set methods
    methods
        
        function set.Min(obj,value)
            validateattributes(value,{'numeric'},{'scalar','finite'})
            obj.Min = value;
            if obj.Max < obj.Min %#ok<MCSUP>
                obj.Max = value;%#ok<MCSUP>
            end
            obj.onResized();
            if obj.EnforceRange && obj.Value < obj.Min %#ok<MCSUP>
                obj.Value = obj.Min;
            end
            obj.redraw();
        end
        
        function set.Max(obj,value)
            validateattributes(value,{'numeric'},{'scalar','finite'})
            obj.Max = value;
            if obj.Min > obj.Max %#ok<MCSUP>
                obj.Min = value;%#ok<MCSUP>
            end
            obj.onResized();
            if obj.EnforceRange && obj.Value > obj.Max %#ok<MCSUP>
                obj.Value = obj.Max;
            end
            obj.redraw();
        end
        
        function set.ShowTicks(obj,value)
            validateattributes(value,{'logical'},{'scalar'});
            obj.ShowTicks = value;
            obj.onResized();
        end
        
        function value = get.Orientation(obj)
            switch obj.JControl.Orientation
                case 0
                    value = 'horizontal';
                case 1
                    value = 'vertical';
                otherwise
                    error( 'uiw:widget:Slider:BadValue', 'Unknown orientation' );
            end
        end
        function set.Orientation(obj,value)
            value = validatestring(value,{'horizontal','vertical'});
            jValue = strcmp(value,'vertical');
            javaMethodEDT('setOrientation',obj.JControl,jValue);
            obj.onResized();
        end
        
        function set.FlipText(obj,value)
            validateattributes(value,{'logical'},{'scalar'});
            obj.FlipText = value;
            obj.onResized();
        end
        
        % LabelWidth
        function set.TextWidth(obj, value)
            uiw.utility.validatePosIntScalar(value);
            obj.TextWidth = value;
            obj.onResized();
        end
        
        % TextBoxHeight
        function set.TextHeight(obj, value)
            uiw.utility.validatePosIntScalar(value);
            obj.TextHeight = value;
            obj.onResized();
        end
        
    end % Data access methods
    
end % classdef
