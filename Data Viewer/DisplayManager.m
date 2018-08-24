classdef DisplayManager < handle
    %
    % View for DisplayManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
    end
    
    methods (Access = public)
        % Constructor
        function this = DisplayManager(FitLike)
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Make the figure
            this.gui.fig = figure('Name','Display Manager','NumberTitle','off',...
                'MenuBar','none','ToolBar','figure','DockControls','off',...
                'Units','normalized','Position',[0.25 0.1 0.5 0.75]);
            % Make a tab group
            this.gui.tab = uitabgroup(this.gui.fig,'Position',[0 0 1 1]);
            
            % Add an empty tab and one with the mention "+"
            EmptyTab(uitab(this.gui.tab));
            EmptyPlusTab(uitab(this.gui.tab));          
            
            %%-------------------------CALLBACK--------------------------%%
            % Replace the close function by setting the visibility to off
            set(this.gui.fig,  'closerequestfcn', ...
                @(src, event) this.FitLike.hideWindowPressed(src));  
            
            % Set SelectionChangedFcn calback for tab
            set(this.gui.tab, 'SelectionChangedFcn',...
                @(src, event) this.FitLike.selectTab(src));   
            
            % reset tab
            setUIMenu(this)
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
            EmptyTab(uitab(this.gui.tab));
            % push this new tab to the position just before '+' tab
            uistack(this.gui.tab.Children(end),'up');
            % set the selection to this tab
            this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
            % reset tab
            setUIMenu(this);
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
            fh(uitab(this.gui.tab));
            % get the index of the oldTab
            indx = find(this.gui.tab.Children == oldTab);
            n = numel(this.gui.tab.Children);
            % move the new tab to this index
            uistack(this.gui.tab.Children(end), 'up', n-indx);
            % delete the old tab
            delete(oldTab)
            % set the selection to the new tab
            this.gui.tab.SelectedTab = this.gui.tab.Children(indx); 
            % reset tab
            setUIMenu(this)
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
            % check if it is an empty tab
            if isa(tab.Children, 'EmptyTab')
                % check the class of the first hData
                switch class(hData(1))
                    case 'Bloc'
                        return % TO DO
                    case 'Zone'
                        return % TO DO
                    case 'Dispersion'
                        replaceTab(this, tab, 'DispersionTab');
                end
                tab = this.gui.tab.SelectedTab;
            end
            % call addPlot method of this tab
            tf = false(1,numel(hData));
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
        function this = removePlot(this, fileID)
            % get the selected tab 
            tab = this.gui.tab.SelectedTab;
            for k = 1:numel(fileID)
                removePlot(tab.Children, fileID{k})
            end
        end
    end
end

