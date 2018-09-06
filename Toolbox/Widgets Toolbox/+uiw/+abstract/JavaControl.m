classdef (Abstract) JavaControl < uiw.abstract.WidgetContainer
    % JavaControl - Base class for widgets with a Java control
    %
    % This is an abstract base class and cannot be instantiated. It
    % provides the basic properties and methods needed for a widget with a
    % Java control. It also has a label which may optionally be used. The
    % label will be shown once any Label* property has been set.
    %
    
    %   Copyright 2009-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 59 $
    %   $Date: 2018-02-27 15:40:39 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (Hidden, SetAccess=protected)
        JControl % The main Java control
        JScrollPane % The Java scrollpane (applies to some controls)
        JEditor % The editor component of the Java control (applies to some controls)
        HGJContainer % The container for the Java control
    end
    
    properties (AbortSet, Hidden, SetAccess=protected)
        CallbacksEnabled logical = true % Are callbacks active or should then be suspended? (in case updating a java widget would trigger undesired callbacks)
    end
    
    
    
    %% Events
    events
        MouseDrag %Triggered on mouse drag over the control
        MouseMotion %Triggered on mouse motion over the control
    end
    
    
    
    %% Public methods
    methods
        % These may be implemented by subclass if desired
        
        function [str,data] = onCopy(obj) %#ok<STOUT>
            % Triggered on copy interaction - subclass may override
            error('Copy not implemented for %s',class(obj));
        end
        
        function [str,data] = onCut(obj) %#ok<STOUT>
            % Triggered on cut interaction - subclass may override
            error('Cut not implemented for %s',class(obj));
        end
        
        function onPaste(obj,~)
            % Triggered on paste interaction - subclass may override
            error('Paste not implemented for %s',class(obj));
        end
        
    end %methods
    
    
    %% Sealed Protected methods
    methods (Sealed, Access=protected)
        
        function value = getJFont(obj)
            % Return a Java font object matching the widget's font settings
            
            jStyle = 0;
            if strcmp(obj.FontWeight,'bold')
                jStyle = jStyle + java.awt.Font.BOLD;
            end
            if strcmp(obj.FontAngle,'italic')
                jStyle = jStyle + java.awt.Font.ITALIC;
            end
            % Convert value from points to pixels
            %http://stackoverflow.com/questions/6257784/java-font-size-vs-html-font-size
            % Java font is in pixels, and assumes 72dpi. Windows is
            % typically 96dpi and up, depending on display settings.
            dpi = java.awt.Toolkit.getDefaultToolkit().getScreenResolution();
            jSize = round(obj.FontSize * dpi / 72);
            value = javax.swing.plaf.FontUIResource(obj.FontName, jStyle, jSize);
            
        end %function
        
        
        function evt = getMouseEventData(obj,jEvent)
            % Interpret a Java mouse event and return MATLAB data
            
            % Get info on the click location and type
            pos = [jEvent.getX() jEvent.getY()];
            ctrlOn = jEvent.isControlDown();
            shiftOn = jEvent.isShiftDown();
            altOn = jEvent.isAltDown();
            metaOn = jEvent.isMetaDown();
            buttonId = jEvent.getButton();
            numClicks = jEvent.getClickCount();
            if xor(metaOn,ctrlOn) && (~altOn && ~shiftOn)
                type = 'alt';
            elseif  (shiftOn && ~metaOn)
                type = 'extend';
            elseif numClicks>1
                type = 'open';
            else
                type = 'normal';
            end
            
            switch jEvent.getID()
                case 500
                    interaction = 'ButtonClicked';
                case 501
                    interaction = 'ButtonDown';
                case 502
                    interaction = 'ButtonUp';
                case 503
                    interaction = 'ButtonMotion';
                case 506
                    interaction = 'ButtonDrag';
            end %switch jEvent.getID()
            
            % Prepare eventdata
            evt = uiw.event.MouseEvent(...
                'HitObject',obj,...
                'MouseSelection',gobjects(0),...
                'Interaction',interaction,...
                'Position',pos,...
                'SelectionType',type,...
                'Button',buttonId,...
                'NumClicks',numClicks,...
                'MetaOn',metaOn,...
                'ControlOn',ctrlOn,...
                'ShiftOn',shiftOn,...
                'AltOn',altOn);
            
        end %function
        
        
        function showContextMenu(obj,cMenu)
            
            % Default to normal context menu
            if nargin<2
                cMenu = obj.UIContextMenu;
            end
            
            % Display the context menu
            if ~isempty(cMenu)
                tPos = getpixelposition(obj.HGJContainer,true);
                jmPos = obj.JControl.getMousePosition();
                if ~isempty(jmPos)
                dpi = java.awt.Toolkit.getDefaultToolkit().getScreenResolution();
                dpiAdj = 96/dpi;
                    mx = jmPos.getX() * dpiAdj;
                    my = jmPos.getY() * dpiAdj;
                    if isempty(obj.JScrollPane)
                        xScroll = 0;
                        yScroll = 0;
                    else
                        xScroll = obj.JScrollPane.getHorizontalScrollBar().getValue() * dpiAdj;
                        yScroll = obj.JScrollPane.getVerticalScrollBar().getValue() * dpiAdj;
                    end
                    mPos = [mx+tPos(1)-xScroll tPos(2)+tPos(4)-my+yScroll];
                    set(cMenu,'Position',mPos,'Visible','on');
                end
            end
            
        end %function
        
    end % Sealed Protected methods
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function createScrollPaneJControl(obj,JavaClassName,varargin)
            % Create the Java control on a scroll pane, and set any additional properties
            
            obj.JControl = obj.constructJObj(JavaClassName,varargin{:});
            obj.JScrollPane = createJControl(obj,'com.mathworks.mwswing.MJScrollPane',...
                obj.JControl);
            
        end %function
        
        function [jControl,hgContainer] = createJControl(obj, JavaClassName, varargin)
            % Create the Java control and set any additional properties
            
            [jControl, hgContainer] = javacomponent([{JavaClassName},varargin],...
                [1 1 100 100], obj.hBasePanel);
            set(hgContainer,'Units','Pixels','Position',[1 1 100 25]);
            if nargout<2
                obj.HGJContainer = hgContainer;
                if nargout<1
                    obj.JControl = jControl;
                end
            end
            
            % Set focusability of the object
            obj.setFocusProps(obj.JControl);
            
        end % createControl
        
        
        function setFocusProps(obj,jObj)
            % Set Java control focusability and tab order
            
            jObj.putClientProperty('TabCycleParticipant', true);
            jObj.setFocusable(true);
            
            CbProps = handle(jObj,'CallbackProperties');
            CbProps.FocusGainedCallback = @(h,e)onFocusGained(obj,h,e);
            CbProps.FocusLostCallback = @(h,e)onFocusLost(obj,h,e);
            
        end % setFocusProps
        
        
        function onFocusGained(obj,~,~)
            % Triggered on focus on the control, sets this widget as the figure's current object
            
            hFigure = ancestor(obj,'figure');
            hFigure.CurrentObject = obj;
            
        end
        
        
        function onFocusLost(~,~,~)
            % Triggered on focus lost from the control - subclass may override
            
        end
        
        
        function onResized(obj)
            % Handle changes to widget size - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize();
                
                % Adjust the java control, due to positioning issues
                obj.HGJContainer.Units = 'pixels';
                obj.HGJContainer.Position = [2 2 w-2 h-2];
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onEnableChanged@uiw.abstract.WidgetContainer(obj);
                
                % Enable/Disable the Java control
                IsEnable = strcmp(obj.Enable,'on');
                if ~isempty(obj.JScrollPane)
                    sb1 = get(obj.JScrollPane,'VerticalScrollBar');
                    sb2 = get(obj.JScrollPane,'HorizontalScrollBar');
                    sb1.setEnabled(IsEnable);
                    sb2.setEnabled(IsEnable);
                end
                if ~isempty(obj.JControl)
                    obj.JControl.setEnabled(IsEnable);
                end
                
            end %if obj.IsConstructed
            
        end % onEnableChanged
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.WidgetContainer(obj);
                
                % Set the font
                obj.JControl.setFont(obj.getJFont());
                
            end %if obj.IsConstructed
            
        end %function
        
    end % Protected methods
    
    
    %% Static Protected methods
    methods (Static)
        
        function jObj = constructJObj(JavaClass, varargin)
            % Create the Java object on the Event Dispatch Thread (EDT)
            
            jObj = javaObjectEDT(JavaClass,varargin{:});
            
            % Add callback properties
            jObj = handle(jObj,'CallbackProperties');
            
        end %function
        
        
        function jColor = rgbToJavaColor(rgbColor)
            % Convert a MATLAB RGB vector into a Java color resource
            
            validateattributes(rgbColor,{'double'},{'<=',1,'>=',0,'numel',3})
            jColor = javax.swing.plaf.ColorUIResource(rgbColor(1),rgbColor(2),rgbColor(3));
            
        end %function
        
        
        function rgbColor = javaColorToRGB(jColor)
            % Convert a MATLAB RGB vector into a Java color resource
            
            validateattributes(jColor,{'javax.swing.plaf.ColorUIResource'},...
                {'scalar'})
            rgbColor = double([jColor.getRed(), jColor.getGreen(), jColor.getBlue()])/255;
            
        end %function
        
    end %methods
    
    
    %% Get/Set methods
    methods
        
        % CallbacksEnabled
        function set.CallbacksEnabled(obj,value)
            if isvalid(obj)
                if value
                    drawnow;
                end
                obj.CallbacksEnabled = value;
            end
        end
        
    end %methods
    
end % classdef