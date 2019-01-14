classdef DisplayManager < handle
    %
    % View for DisplayManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
        SelectedTab %wrapper to the selected tab
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
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Build GUI        
            gui = buildDisplayManager(this,...
                this.ToggleToolList, this.PushToolList);
            this.gui = guihandles(gui);
            
            % Set the wrapper to the selected tab
            this.SelectedTab = this.gui.tab.SelectedTab;
            
            %%-------------------------CALLBACK--------------------------%%
            % Replace the close function by setting the visibility to off
            set(this.gui.fig,  'closerequestfcn', ...
                @(src, event) this.FitLike.hideWindowPressed(src));  
            
            % Set SelectionChangedFcn calback for tab
            set(this.gui.tab, 'SelectionChangedFcn',...
                @(src, event) changeTab(this, src, event));   
            
            % Set callback when moving mouse
            set (this.gui.fig,'WindowButtonMotionFcn',...
                    @(src, event) moveMouse(this));
                
            % reset tab
            setUIMenu(this);
            drawnow;
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
            this.SelectedTab = this.gui.tab.Children(end-1);
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
                if isa(this.SelectedTab.Children,'EmptyPlusTab')
                    this.SelectedTab = this.gui.tab.Children(end-1);
                end
            end
        end %removeTab    
        
        % Change tab callback
        function this = changeTab(this, src, ~)
            % check if tab need to be added
            if isa(src.SelectedTab.Children,'EmptyPlusTab')
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
            this.SelectedTab = this.gui.tab.Children(indx); 
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
            this.SelectedTab.UIContextMenu = cmenu;  
        end

        % call the tab plot method
        function this = addPlot(this, hData, idxZone)
            % check if it is an empty tab
            if strcmp(class(this.SelectedTab.Children), 'EmptyTab') %#ok<STISA>
                % check the class of the first hData
                switch class(hData(1))
                    case 'Bloc'
                        return % TO DO
                    case 'Zone'
                        replaceTab(this, this.SelectedTab, 'ZoneTab');
                    case 'Dispersion'
                        replaceTab(this, this.SelectedTab, 'DispersionTab');
                end
            % check if correct class
            elseif ~strcmp(class(hData), this.SelectedTab.Children.inputType)
                msg = ['Error: Input data (',class(hData),') does not fit'...
                       ' the current tab (',this.SelectedTab.Children.inputType,')\n'];
                throwWrapMessage(this, msg)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Need a call to FileManager to uncheck the nodes!
                % Pass by FitLike [Manu]
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                return
            end
            % call addPlot method of this tab
            for k = 1:numel(hData)
                addPlot(this.SelectedTab.Children, hData(k), idxZone(k));
            end
        end
        
        % call the tab remove method
        function this = removePlot(this, hData, idxZone)
            % check if empty tab
            if strcmp(class(this.SelectedTab.Children), 'EmptyTab') %#ok<STISA>
                return
            end
            % loop
            for k = 1:numel(hData)
                deletePlot(this.SelectedTab.Children, hData(k), idxZone(k));
            end
        end
        
        % Wrapper to get data from current tab
        function [hData, idxZone] = getData(this)
            % get data
            hData = this.SelectedTab.Children.hData;
            idxZone = this.SelectedTab.Children.idxZone;
        end %getData
        
        % Wrapper to get legend from current tab (avoid fit)
        function [leg, hData] = getLegend(this)
             [leg, hData] = getLegend(this.SelectedTab.Children);
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
            setMask(this.FitLike, src, event);
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

