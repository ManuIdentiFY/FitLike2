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
            EmptyTab(FitLike, uitab(this.gui.tab));
            EmptyPlusTab(FitLike, uitab(this.gui.tab));            
            
            %%-------------------------CALLBACK--------------------------%%
            % Replace the close function by setting the visibility to off
            set(this.gui.fig,  'closerequestfcn', ...
                @(src, event) this.FitLike.hideWindowPressed(src));  
            
            % Set SelectionChangedFcn calback for tab
            set(this.gui.tab, 'SelectionChangedFcn',...
                @(src, event) this.FitLike.selectTab(src));   
            
            % Set UIContextMenu for tab
            resetUIMenu(this);
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
        function addTab(this)
            % add an empty tab: Just to try different gui objects
            EmptyTab(this.FitLike, uitab(this.gui.tab));
            % push this new tab to the position just before '+' tab
            uistack(this.gui.tab.Children(end),'up');
            % set the selection to this tab
            this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
            % reset tab
            resetUIMenu(this);
        end %addTab
        
        %Remove tab from DisplayManager
        function removeTab(this,idx)
            % delete the selected tab
            delete(this.gui.tab.Children(idx));
            % avoid selection of the panel '+'
            if strcmp(this.gui.tab.SelectedTab.Title,'+')
                this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
            end
            % reset tab
            resetUIMenu(this); 
        end %removeTab       
                
        %Set tab names
        function resetUIMenu(this)           
            % set the contextmenu and loop them to create unique name
            n = length(this.gui.tab.Children);
            for i = 1:n-1
                cmenu = uicontextmenu;
                uimenu(cmenu, 'Label', 'Close Tab', 'Tag', ['UIContextMenu' num2str(i)],...
                    'Callback',@(src,event) this.FitLike.removeTab(src));
                this.gui.tab.Children(i).UIContextMenu = cmenu;
            end         
        end %resetUIMenu        
    end    
end

