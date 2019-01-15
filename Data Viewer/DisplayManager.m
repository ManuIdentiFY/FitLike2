classdef DisplayManager < handle
    %
    % View for DisplayManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
    end
    
    % List of the wanted uitoggletool and uipushtool (TooltipString)
    properties
        ToggleToolList = {'Zoom Out','Zoom In','Pan'};
        PushToolList = [];
    end
    
    events
        SelectTab
    end
    
    methods (Access = public)
        % Constructor
        function this = DisplayManager(FitLike)
            %%--------------------------BUILDER--------------------------%%  
            % Build GUI        
            gui = buildDisplayManager(this,...
                this.ToggleToolList, this.PushToolList);
            this.gui = guihandles(gui);
            
            % Set SelectionChangedFcn calback for tab
            set(this.gui.tab, 'SelectionChangedFcn',...
                @(src, event) changeTab(this, src, event));   
            
            % Set callback when moving mouse
            set (this.gui.fig,'WindowButtonMotionFcn',...
                    @(src, event) moveMouse(this));
                
            % reset tab
            setUIMenu(this);
            drawnow;
            
            % Check if presenter is available
            if isa(FitLike,'FitLike')
                % Store a reference to the presenter
                this.FitLike = FitLike;                

                % Replace the close function by setting the visibility to off
                set(this.gui.fig,  'closerequestfcn', ...
                    @(src, event) this.FitLike.hideWindowPressed(src));  
            else
                % set the window visible
                set(this.gui.fig,'Visible','on')
            end
        end %DisplayManager
        
        % Destructor
        function deleteWindow(this)
            %remove the closerequestfcn from the figure, this prevents an
            %infitie loop with the following delete command
            set(this.gui.fig,  'closerequestfcn', '');
            %delete the figure
            delete(this.gui.fig);
            %clear out the pointer to the figure - prevents memory leaks
            this.gui = [];
        end  %deleteWindow    
    end
    
    methods (Access = public)
        % Add tab to DisplayManager
        function this = addTab(this)
            % add an empty tab: Just to try different gui objects
            EmptyTab(this, uitab(this.gui.tab));
            % push this new tab to the position just before '+' tab
            uistack(this.gui.tab.Children(end),'up');
            % set the selection to this tab
            this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
            % reset tab
            setUIMenu(this);
            % EDT synchronisation
            drawnow;
        end %addTab
        
        %Remove tab
        function this = removeTab(this)
            % check the number of children
            n = numel(this.gui.tab.Children);
            % if more than 1 + 1, delete it
            if n > 2
                % delete the selected tab
                delete(this.gui.tab.SelectedTab);
                % check if the new selected tab is not '+'
                if isa(this.gui.tab.SelectedTab.Children,'EmptyPlusTab')
                    this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
                end
            end
        end %removeTab    
        
        % Change tab callback
        function this = changeTab(this, src, ~)
            % check if tab need to be added
            if isa(src.gui.tab.SelectedTab.Children,'EmptyPlusTab')
                addTab(this);
            end
            % notify
            notify(this, 'SelectTab');
        end
        
        %Replace tab: should be improved to speed up GUI
        function this = replaceTab(this, oldTab, newTab)
            % create the new tab
            fh = str2func(newTab);
            fh(this, uitab(this.gui.tab));
            % get the index of the oldTab
            indx = find(this.gui.tab.Children == oldTab);
            n = numel(this.gui.tab.Children);
            % move the new tab to this index
            uistack(this.gui.tab.Children(end), 'up', n-indx);
            % delete the old tab
            delete(oldTab);
            % set the selection to the new tab
            this.gui.tab.SelectedTab = this.gui.tab.Children(indx); 
            % reset tab
            setUIMenu(this);
        end %replaceTab
        
        % Reset uicontextmenu and tab titles
        % Set UIContextMenu
        function this = setUIMenu(this)
            % set contextmenu to the selected tab
            cmenu = uicontextmenu(this.gui.fig);
            uimenu(cmenu, 'Label', 'Close Tab',...
                'Callback',@(src,event) removeTab(this));
            this.gui.tab.SelectedTab.UIContextMenu = cmenu;  
        end

        % call the tab plot method
        function this = addPlot(this, hData, idxZone)
            % check if it is an empty tab
            if strcmp(class(this.gui.tab.SelectedTab.Children), 'EmptyTab') %#ok<STISA>
                % check the class of the first hData
                switch class(hData)
                    case 'Bloc'
                        return % TO DO
                    case 'Zone'
                        replaceTab(this, this.gui.tab.SelectedTab, 'ZoneTab');
                    case 'Dispersion'
                        replaceTab(this, this.gui.tab.SelectedTab, 'DispersionTab');
                end
            % check if correct class
            elseif ~strcmp(class(hData), this.gui.tab.SelectedTab.Children.inputType)
                msg = ['Error: Input data (',class(hData),') does not fit'...
                       ' the current tab (',this.gui.tab.SelectedTab.Children.inputType,')\n'];
                throwWrapMessage(this, msg)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Need a call to FileManager to uncheck the nodes!
                % Pass by FitLike [Manu]
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                return
            end
            % call addPlot method of this tab
            for k = 1:numel(hData)
                addPlot(this.gui.tab.SelectedTab.Children, hData(k), idxZone(k));
            end
        end
        
        % call the tab remove method
        function this = removePlot(this, hData, idxZone)
            % check if empty tab
            if strcmp(class(this.gui.tab.SelectedTab.Children), 'EmptyTab') %#ok<STISA>
                return
            end
            % loop
            for k = 1:numel(hData)
                deletePlot(this.gui.tab.SelectedTab.Children, hData(k), idxZone(k));
            end
        end
        
        % Wrapper to get data from current tab
        function [hData, idxZone] = getData(this)
            % get data
            hData = this.gui.tab.SelectedTab.Children.hData;
            idxZone = this.gui.tab.SelectedTab.Children.idxZone;
        end %getData
        
        % Wrapper to get legend from current tab (avoid fit)
        function [leg, hData] = getLegend(this)
             [leg, hData] = getLegend(this.gui.tab.SelectedTab.Children);
        end
        
        % Wrapper to throw messages in the console or in the terminal in
        % function of FitLike input.
        function this = throwWrapMessage(this, txt)
            % check FitLike
            if ~isa(this.FitLike,'FitLike')
                fprintf(txt);
            else
                notify(this.FitLike, 'ThrowMessage', EventMessage('txt',txt));
            end
        end % throwWrapMessage
        
        % Wrapper to set mask
        function this = setMask(this, src, event)
            % check if FitLike is available
            if isa(this.FitLike,'FitLike')
                setMask(this.FitLike, src, event);
            else
                % Apply the mask on the data in DisplayManager
                if strcmp(event.Action,'SetMask')
                    % get boundaries
                    xmin = event.XRange(1); xmax = event.XRange(2);
                    ymin = event.YRange(1); ymax = event.YRange(2);
                    % define mask
                    for k = 1:numel(event.Data)
                        event.Data(k) = setMask(event.Data(k), event.idxZone(k),...
                            [xmin xmax], [ymin ymax]);
                        % notify
                        notify(event.Data(k), 'DataUpdate', EventFileManager('idxZone',event.idxZone(k)))
                    end
                elseif strcmp(event.Action,'ResetMask')
                    % reset mask
                    for k = 1:numel(event.Data)
                        event.Data(k) = setMask(event.Data(k), event.idxZone(k));
                        % notify
                        notify(event.Data(k), 'DataUpdate', EventFileManager('idxZone',event.idxZone(k)))
                    end
                end
            end
        end %setMask
        
        % mouse move
        function moveMouse(this)
            % check the selected tab
            tab = this.gui.tab.SelectedTab;
            % call the mouse callback fonction of this tab
            moveMouse(tab.Children);
            % pause
            pause(0.001);
        end
    end
end

