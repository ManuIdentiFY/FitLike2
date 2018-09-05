classdef ModelManager < handle
 %
    % View for ModelManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
    end
    
    methods
        % Constructor
        function this = ModelManager(FitLike)
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Make the figure
            gui = buildModelManager();
            this.gui = guihandles(gui);     
            
            % Set the first tab and the '+' tab
            ModelTab(uitab(this.gui.tab),'Model1');
            EmptyPlusTab(uitab(this.gui.tab));
            
            % Set the UI ContextMenu
            setUIMenu(this);            
            %%-------------------------CALLBACK--------------------------%%
            % Replace the close function by setting the visibility to off
            set(this.gui.fig,  'closerequestfcn', ...
                @(src, event) this.FitLike.hideWindowPressed(src)); 
            
            % Set SelectionChangedFcn callback for tab
            set(this.gui.tab, 'SelectionChangedFcn',...
                @(src, event) selectModel(this));
            
            % Set callback for the radio buttons
            set(this.gui.BatchRadioButton, 'Callback',...
                @(src, event) switchFitMode(this, src));
            set(this.gui.SimulationRadioButton, 'Callback',...
                @(src, event) switchFitMode(this, src));
            
            % Set callback for the run pushbutton
            set(this.gui.RunPushButton, 'Callback',...
                @(src, event) this.FitLike.runFit());
        end %ModelManager
        
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
        % Set UIContextMenu
        function this = setUIMenu(this)
            % set contextmenu to the selected tab
            cmenu = uicontextmenu(this.gui.fig);
            uimenu(cmenu, 'Label', 'Rename model',...
                'Callback',@(src,event) renameModel(this));
            uimenu(cmenu, 'Label', 'Load model',...
                'Callback',@(src,event) loadModel(this));
            uimenu(cmenu, 'Label', 'Save model',...
                'Callback',@(src,event) saveModel(this));
            uimenu(cmenu, 'Label', 'Delete model',...
                'Callback',@(src,event) removeModel(this));  
            this.gui.tab.SelectedTab.UIContextMenu = cmenu;  
        end
        
        % Update tree
        function this = updateTree(this)
            % define new parent container
            hParent = this.gui.tree.UserData.Root;
            % delete children
            if ~isempty(hParent.Children)
                delete(hParent.Children)
            end
            % get children
            hChildren = this.FitLike.FileManager.gui.tree.Root.Children;
            % get the tree from FileManager
            copy(hChildren, hParent);
        end %updateTree
        
        % Select Model
        function this = selectModel(this)
            if strcmp(this.gui.tab.SelectedTab.Title,'+')
                addModel(this);
                drawnow;
            end
        end %selectModel
        
        % Add Model
        function this = addModel(this)
            % count tab
            nTab = numel(this.gui.tab.Children);
            % add new tab
            ModelTab(uitab(this.gui.tab),['Model',num2str(nTab)]);
            % push this tab
            uistack(this.gui.tab.Children(end),'up');
            % set the selection to this tab
            this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
            % add UI menu to this tab
            setUIMenu(this);  
        end %addModel
        
        % Remove Model
        function this = removeModel(this)
            % check tab state
            if numel(this.gui.tab.Children) < 3
                return
            else
                % delete current tab
                delete(this.gui.tab.SelectedTab);
                % check if '+' tab selected
                if strcmp(this.gui.tab.SelectedTab.Title,'+')
                    this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
                end
            end
        end %removeModel
        
        % Remame Model
        function this = renameModel(this)
            % get the index of the selected tab
            idx = find(this.gui.tab.Children == this.gui.tab.SelectedTab);
            % open inputdlg
            new_name = inputdlg({'Enter a new pipeline name:'},...
                'Rename Model',[1 70],{['Model',num2str(idx)]});
            % check output and assign new name
            if ~isempty(new_name)
                this.gui.tab.SelectedTab.Title = new_name{1};
            end
        end %renameModel
        
        % Load Model
        function this = loadModel(this)
            % TO DO
        end %loadModel
        
        % Save Model
        function this = saveModel(this)
            %TO DO
        end %saveModel
        
        % Switch Process Mode
        function this = switchFitMode(this, src)
            % check if we need to change the value
            if all([src.Parent.Children.Value] == 1)
                % check the source and reset the other one
                switch src.Tag
                    case 'BatchRadioButton'
                        this.gui.SimulationRadioButton.Value = 0;
                    case  'SimulationRadioButton'
                        this.gui.BatchRadioButton.Value = 0;
                end
            else
                src.Value = 1; % always select one item
            end
        end %switchProcessMode
    end      
end

