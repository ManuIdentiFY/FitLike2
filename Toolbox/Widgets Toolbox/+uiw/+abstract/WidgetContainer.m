classdef WidgetContainer < uiw.abstract.BaseContainer & ...
        uiw.mixin.HasContainer  & uiw.mixin.HasPanel & uiw.mixin.HasLabel &...
        uiw.mixin.AssignPVPairs & matlab.mixin.SetGet
    % WidgetContainer - Base class for a graphical widget
    %
    % This class provides the basic properties needed for a panel that will
    % contain a group of graphics objects to build a complex widget. It
    % also has a label which may optionally be used. The label will be
    % shown once any Label* property has been set.
    %
    
    %   Copyright 2008-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $
    %   $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (Access=private)
        InnerSize_ double = [1 1] % Cache of the inner pixel size of the widget (will not report below a minimum size)
    end
    
    
    %% Constructor
    methods
        
        function obj = WidgetContainer()
            % Construct the control
            
            % Call superclass constructors
            obj@uiw.mixin.HasPanel();
            obj@uiw.abstract.BaseContainer();
            obj@uiw.mixin.HasLabel();
            
            % Assign parents
            obj.hLabel.Parent = obj;
            obj.hBasePanel.Parent = obj;
            
            % Adjust sizing of label and widget panel
            obj.onContainerResized();
            
        end
        
    end %constructor/destructor methods
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function redraw(obj)
            % Handle state changes that may need UI redraw - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
            end %if obj.IsConstructed
            
        end % function
        
        
        function onResized(obj)
            % Handle changes to widget size - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Default behavior: Set all uicontrols depth 1 that have an Enable field
                hHasEnableProps = [obj.hLabel;
                    findall(obj.hBasePanel,'-property','Enable','-depth',1) ];
                set(hHasEnableProps,'Enable',obj.Enable);
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onVisibleChanged(obj)
            % Handle updates to Visible state - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style changes - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Look for all encapsulated graphics objects
                hEncapsulatedCell = struct2cell(obj.h);
                isGraphicsObj = cellfun(@ishghandle,hEncapsulatedCell,'UniformOutput',false);
                isGraphicsObj = cellfun(@all,isGraphicsObj,'UniformOutput',true);
                hEncapsulated = [hEncapsulatedCell{isGraphicsObj}]';
                
                % Get any other objects at the top level of the widget
                hTopLevel = [obj.hLabel; findall(obj.hBasePanel,'-depth',1) ];
                
                % Combine them all
                hAll = unique([hEncapsulated(:); hTopLevel(:)]);
                
                % Set all objects that have font props
                set(hAll( isprop(hAll,'FontName') ),...
                    'FontName',obj.FontName,...
                    'FontWeight',obj.FontWeight,...
                    'FontAngle',obj.FontAngle,...
                    'FontUnits',obj.FontUnits,...
                    'FontSize',obj.FontSize);
                
                % Set all objects that have ForegroundColor
                hasFGColor = isprop(hAll,'ForegroundColor');
                % Exclude boxpanels
                isBoxPanel = arrayfun(@(x)isa(x,'uiw.BoxPanel'),hAll);
                set(hAll( hasFGColor & ~isBoxPanel ),...
                    'ForegroundColor',obj.ForegroundColor);
                
                % Set all objects that have BackgroundColor
                hasBGColor = isprop(hAll,'BackgroundColor');
                set(hAll( hasBGColor ),...
                    'BackgroundColor',obj.BackgroundColor);
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onContainerBeingDestroyed(obj)
            % Triggered on container destroyed - subclass may override
            
            delete(obj);
            
        end %function
        
    end %methods
    
    
    %% Debugging methods
    methods
        
        function debugRedraw(obj)
            % For debugging only - trigger the widget's protected redraw method
            
            obj.redraw();
            
        end %function
        
        function debugResize(obj)
            % For debugging only - trigger the widget's protected redraw method
            
            obj.onResized();
            
        end %function
        
    end %methods
    
    
    
    %% Sealed Protected methods
    methods (Sealed, Access=protected)
        
        function [w,h] = getInnerPixelSize(obj)
            % Return the widget's inner pixel size
            
            h = obj.InnerSize_(2);
            w = obj.InnerSize_(1);
            
        end % getInnerPixelSize
        
        
        function onContainerResized(obj)
            % Triggered on resize of the widget's container
            
            % Get the outer container position
            [wC,hC] = obj.getPixelSize();
            spc = obj.LabelSpacing;
            pad = obj.Padding;
            wL = obj.LabelWidth;
            hL = obj.LabelHeight;
            
            % Place the label
            if obj.LabelVisible_
                
                switch obj.LabelLocation
                    case 'left'
                        posL = [pad+1 pad+1 wL hC-2*pad];
                        x0U = posL(1)+posL(3)+spc;
                        posU = [x0U pad+1 wC-pad-x0U+1 hC-2*pad];
                        
                    case 'top'
                        posL = [pad+1 hC-pad-hL+1 wC-2*pad hL];
                        hU = posL(2)-pad-spc-1;
                        posU = [pad+1 pad+1 wC-2*pad hU];
                        
                    case 'right'
                        posL = [wC-pad-wL+1 pad+1 wL hC-2*pad];
                        wU = posL(1)-pad-spc-1;
                        posU = [pad+1 pad+1 wU hC-2*pad];
                        
                    case 'bottom'
                        posL = [pad+1 pad+1 wC-2*pad hL];
                        y0U = posL(2)+posL(4)+spc;
                        posU = [pad+1 y0U wC-2*pad hC-pad-y0U+1];
                        
                    otherwise
                        error('Invalid LabelLocation: %s',obj.LabelLocation);
                end
                posU = max(posU,1);
                posL = max(posL,1);
                obj.hLabel.Position = posL;
                obj.hBasePanel.Position = posU;
            else
                % No Label
                posU = [1 1 wC hC];
                posU = max(posU,1);
                obj.hBasePanel.Position = posU;
            end
            
            % Store inner size of the hBasePanel for performance
            obj.InnerSize_ = max(posU(3:4), [10 10]);
            
            % Trigger resize for the rest of the widget
            obj.onResized();
            
        end % function
        
    end %methods
    
    
    %% Display Customization
    methods (Access=protected)
        
        function propGroup = getPropertyGroups(obj)
            
            widgetProps = [
                properties('uiw.abstract.WidgetContainer')
                properties('uiw.mixin.HasContainer') ];
            thisProps = setdiff(properties(obj), widgetProps);
            propGroup = [
                matlab.mixin.util.PropertyGroup(thisProps)
                obj.getWidgetPropertyGroup()
                obj.getLabelPropertyGroup()
                ];
            
        end %function
        
        
        function propGroup = getWidgetPropertyGroup(obj)
            titleTxt = sprintf(['Widget Properties: (<a href = '...
                '"matlab: helpPopup %s">help on this widget</a>)'],class(obj));
            thisProps = {
                'Parent'
                'Enable'
                'Position'
                'Units'
                'Padding'
                'Spacing'
                'FontName'
                'FontSize'
                'FontWeight'
                'ForegroundColor'
                'BackgroundColor'
                'InvalidBackgroundColor'
                'InvalidForegroundColor'
                'Tag'};
            propGroup = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
        end %function
        
        
        function propGroup = getLabelPropertyGroup(~)
            titleTxt = 'Label Properties:';
            thisProps = {
                'Label'
                'LabelLocation'
                'LabelHeight'
                'LabelWidth'
                'LabelFontName'
                'LabelFontSize'
                'LabelFontWeight'
                'LabelForegroundColor'
                'LabelHorizontalAlignment'
                'LabelTooltipString'
                'LabelLocation'
                'LabelHeight'
                'LabelWidth'
                'LabelSpacing'
                'LabelVisible'};
            propGroup = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
            
        end %function
            
    end %methods
    
end % classdef
