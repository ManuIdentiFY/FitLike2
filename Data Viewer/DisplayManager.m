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
    
    methods (Access = public)
        % Constructor
        function this = DisplayManager(FitLike)
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Build GUI        
            gui = buildDisplayManager(this.FitLike,...
                this.ToggleToolList, this.PushToolList);
            this.gui = guihandles(gui);
            
            %%-------------------------CALLBACK--------------------------%%
            % Replace the close function by setting the visibility to off
            set(this.gui.fig,  'closerequestfcn', ...
                @(src, event) this.FitLike.hideWindowPressed(src));  
            
            % Set SelectionChangedFcn calback for tab
            set(this.gui.tab, 'SelectionChangedFcn',...
                @(src, event) this.FitLike.selectTab(src));   
            
            % Set callback when moving mouse
            set (this.gui.fig,'WindowButtonMotionFcn',...
                    @(src, event) moveMouse(this));
                
            % reset tab
            setUIMenu(this);
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
            EmptyTab(this.FitLike, uitab(this.gui.tab));
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
        
        %Replace tab
        function this = replaceTab(this, oldTab, newTab)
            % create the new tab
            fh = str2func(newTab);
            fh(this.FitLike, uitab(this.gui.tab));
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
        function [this, plotFlag, tf] = addPlot(this, hData)
            % get the selected tab 
            tab = this.gui.tab.SelectedTab;
            tf = false(1,numel(hData));
            % check if it is an empty tab
            if isa(tab.Children, 'EmptyTab')
                % check the class of the first hData
                switch class(hData(1))
                    case 'Bloc'
                        plotFlag = 0; % To improve
                        return % TO DO
                    case 'Zone'
                        plotFlag = 0; % To improve
                        return % TO DO
                    case 'Dispersion'
                        replaceTab(this, tab, 'DispersionTab');
                end
                tab = this.gui.tab.SelectedTab;
            end
            % call addPlot method of this tab
            % NOTE: REMOVE LOOP
            for k = 1:numel(hData)
                [~,tf(k)] = addPlot(tab.Children, hData(k));
            end
            % check if everything have been plotted or not and send a call
            % to the presenter if not
            if all(tf == 0)
                plotFlag = 1;
            else
                plotFlag = 0;
            end
        end
        
        % call the tab remove method
        function this = removePlot(this, hData)
            % get the selected tab 
            tab = this.gui.tab.SelectedTab;
            for k = 1:numel(hData)
                removePlot(tab.Children, hData(k));
            end
        end
        
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

