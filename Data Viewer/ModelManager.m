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
            [gui, jtable] = buildModelManager(FitLike);
            this.gui = guihandles(gui);     
            
            % Update handle
            this.gui.tree = this.gui.tree.UserData;
            this.gui.jtable = jtable.getModel.getActualModel.getActualModel;
            
            % Set the first tab and the '+' tab
            ModelTab(FitLike, uitab(this.gui.tab),'Model1');
            EmptyPlusTab(FitLike, uitab(this.gui.tab));
            
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
            
            % Set callback for the file selection popup
            set(this.gui.FileSelectionPopup,'Callback',...
                @(src, event) updateResultTable(this));
            
            % Set callback if file is checked
            set(this.gui.tree,'CheckboxClickedCallback',...
                @(src, event) updateFilePopup(this));
            
            % Add listener to the FileManager tree
            addlistener(this.FitLike.FileManager.gui.tree,...
                'TreeUpdate',@(src, event) updateTree(this, src, event));
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
        function this = updateTree(this, ~, event)
            % get the tree
            root = this.gui.tree.Root;
            % check the type of update: insert or delete
            if strcmp(event.Action, 'Add')
                % search the parent node
                parentNode = TreeManager.searchNode(root, event.Parent);
                % unchecked if needed
                if event.Data.Checked
                    event.Data.Checked = 0;
                end
                % copy
                if isempty(parentNode)
                    copy(event.Data, root);
                else
                    copy(event.Data, parentNode);
                end
                % update
                updateFilePopup(this);
                updateResultTable(this);
            elseif strcmp(event.Action, 'Delete')
                % search the node to delete
                for k = 1:numel(event.Data)
                    % search the node
                    node = TreeManager.searchNode(root, event.Data(k));                    
                    delete(node);
                end
                % update
                updateFilePopup(this);
                updateResultTable(this);
            elseif strcmp(event.Action,'ReOrder')
                % reorder children
                node = TreeManager.searchNode(root, event.Data(1));  
                TreeManager.stackNodes(node.Parent.Children, event.NewOrder, []);
            elseif strcmp(event.Action, 'DragDrop')
                % get old parent node
                oldParent = TreeManager.searchNode(root, event.OldParent);  
                % get new parent node
                newParent = TreeManager.searchNode(root, event.Parent);
                % deparent the corresponding node
                tf = strcmp(get(oldParent.Children,'Name'), event.Data.Name);
                hNode = oldParent(tf).Children;
                hNode.Parent = [];
                TreeManager.stackNodes(newParent.Children, event.NewOrder, hNode); 
                % delete old parent if no more children
                if isempty(oldParent.Children)
                    delete(oldParent)
                end
            elseif strcmp(event.Action, 'UpdateName')
                % search the parent nodes
                hParent = TreeManager.searchNode(root, event.Parent); 
                % find the modified nodes
                tf = strcmp(get(hParent.Children,'Name'),event.OldName);
                hParent.Children(tf).Name = event.NewName;
            elseif strcmp(event.Action, 'UpdateIcon')
                % search the node
                hNode = TreeManager.searchNode(root, event.Parent); 
                % reset icon
                setIcon(hNode, event.Data);
            end
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
            ModelTab(this.FitLike, uitab(this.gui.tab),['Model',num2str(nTab)]);
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
        
        % Check file callback
        function this = updateResultTable(this)
            % get the selected file
            if ischar(this.gui.FileSelectionPopup.String)
                return               
            elseif isempty(this.gui.FileSelectionPopup.String{this.gui.FileSelectionPopup.Value})
                return
            end
            % get the file selected
            fileID = this.gui.FileSelectionPopup.UserData{this.gui.FileSelectionPopup.Value};
            tf = strcmp({this.FitLike.RelaxData.fileID}, fileID);
            model = this.FitLike.RelaxData(tf).processingMethod;
            % remove previous results
            nRow = this.gui.jtable.getRowCount();
            for k = 1:nRow
                   % here we use the javaMethodEDT to handle EDT
                   % see https://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt
                   javaMethodEDT('removeRow',this.gui.jtable,0);
            end
            % check if model available
            if isempty(model)
                return
            end
            % add new results
            modelName = model.model.modelName;
            for k = 1:numel(model.subModel)
                % add by submodel
                submodelName = model.subModel(k).modelName;
                parameter = strcat(model.subModel(k).parameterName);
                bestValue = single([model.subModel(k).bestValue]);
                error = single([model.subModel(k).errorBar]);
                for i = 1:numel(parameter)
                       row = {modelName, submodelName, parameter{i}, bestValue(i), error(i)};
                       % here we use the javaMethodEDT to handle EDT
                       % see https://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt
                       javaMethodEDT('addRow',this.gui.jtable,row); 
                end
            end
        end
        
        % File checked in tree callback
        function this = updateFilePopup(this)
            % get the selected fileID;
            fileID = nodes2fileID(this.gui.tree);
            % get the corresponding data
            if ~isempty(fileID)
                [~,~,idx] = intersect(fileID, {this.FitLike.RelaxData.fileID});
                % update file popup
                this.gui.FileSelectionPopup.String = {this.FitLike.RelaxData(idx).filename};
                this.gui.FileSelectionPopup.UserData = {this.FitLike.RelaxData(idx).fileID};
            else
                % reset filepopup
                this.gui.FileSelectionPopup.String = 'Select a file:';
            end
            drawnow;
        end %updateFilePopup
    end      
end

