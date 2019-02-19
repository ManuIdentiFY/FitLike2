classdef ModelManager < handle
 %
    % View for ModelManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
        hData % data handle
        SelectedData % current selected data
    end
    
    properties (Hidden)
        ls_table %listener to update fit results
        ls % listener to the data handle
    end
    
    methods
        % Constructor
        function this = ModelManager(FitLike)
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Make the figure
            [gui, jtable] = buildModelManager();
            this.gui = guihandles(gui);     
            
            % Update handle
            this.gui.jtable = jtable.getModel.getActualModel.getActualModel;
            
            % Set the first tab and the '+' tab
            ModelTab(this, uitab(this.gui.tab),'Model1');
            EmptyPlusTab(this, uitab(this.gui.tab));
            
            % Set the UI ContextMenu
            setUIMenu(this);
            drawnow;
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
            
            % Set callback for the run pushbutton
            set(this.gui.ExportPushButton, 'Callback',...
                @(src, event) this.FitLike.exportFitResult());
                        
            % Set callback for the file selection popup
            set(this.gui.FileSelectionPopup,'Callback',...
                @(src, event) updateSelection(this));
           
            % Set callback when data are selected
            addlistener(this.FitLike.FileManager,...
                'DataSelected',@(src, event) update(this, src, event));
        end %ModelManager
        
        % Destructor
        function deleteWindow(this)
            % remove listeners
            if ~isempty(this.ls)
                delete(this.ls); this.ls = [];
            end
            
            if ~isempty(this.ls_table)
                delete(this.ls_table); this.ls_table = [];
            end
            % remove handles
            if ~isempty(this.hData)
                this.hData = [];
            end
            
            if ~isempty(this.SelectedData)
                this.SelectedData = [];
            end
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
            ModelTab(this, uitab(this.gui.tab),['Model',num2str(nTab)]);
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
        
        % update the table (fit results)
        function this = updateTable(this)
            % remove previous results
            nRow = this.gui.jtable.getRowCount();
            for k = 1:nRow
                   % here we use the javaMethodEDT to handle EDT
                   % see https://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt
                   javaMethodEDT('removeRow',this.gui.jtable,0);
            end
            
            % get the selected file
            if isempty(this.SelectedData)
                return               
            end

            % check if data are available          
            if isempty(this.SelectedData.processingMethod); return; end
            
            processObj = this.SelectedData.processingMethod;            
            % add new results
            modelName = processObj.modelName;
            for k = 1:numel(processObj.subModel)
                % add by submodel
                submodelName = processObj.subModel(k).modelName;
                parameter = strcat(processObj.subModel(k).parameterName);
                bestValue = single([processObj.subModel(k).bestValue]);
                error = single([processObj.subModel(k).errorBar]);
                for i = 1:numel(parameter)
                       row = {modelName, submodelName, parameter{i}, bestValue(i), error(i)};
                       % here we use the javaMethodEDT to handle EDT
                       % see https://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt
                       javaMethodEDT('addRow',this.gui.jtable,row); 
                end
            end
        end
        
        % function fires when a DataUnit is deleted 
        function this = onDataDeletion(this, src, ~)
            % check the data deleted
            tf = this.hData == src;
            this.hData = this.hData(~tf);
            delete(this.ls(tf)); this.ls = this.ls(~tf);
            
            % update popup
            removePopupItem(this);
        end %onDataDeletion
        
        % fire when data are selected
        function this = update(this, ~, event)
            % check if data are dispersion
            if ~isa(event.Data ,'Dispersion')
                return
            end
            
            % check which action was done
            if strcmp(event.Action, 'Select')
                if isempty(this.hData)
                    this.hData = event.Data;
                    for k = 1:numel(event.Data)
                        l = addlistener(event.Data(k),'DataDeletion',...
                                @(src, event) onDataDeletion(this, src, event));
                        this.ls = [this.ls, l];
                    end
                else
                    % add new data (without duplicates)
                    new_data = setdiff(event.Data, this.hData);
                    if ~isempty(new_data)
                        this.hData = [this.hData, new_data];
                        % add listeners
                        for k = 1:numel(new_data)
                            l = addlistener(new_data(k),'DataDeletion',...
                                    @(src, event) onDataDeletion(this, src, event));
                            this.ls = [this.ls, l];
                        end
                    end
                end
                % update popup
                addPopupItem(this);
            else
                % remove data
                [~,idx] = setdiff(this.hData, event.Data);
                this.hData = this.hData(idx);
                % update listeners
                delete(this.ls(setdiff(1:numel(this.ls), idx))); 
                this.ls = this.ls(idx);
                if isempty(this.ls); this.ls = []; end
                % update popup
                removePopupItem(this);
            end
        end
        
        % add item to the popup
        function this = addPopupItem(this)
            % check current popup state
            hPopup = this.gui.FileSelectionPopup;
            
            % form output name
            for k = numel(this.hData):-1:1
                name{1,k} = [getRelaxProp(this.hData(k), 'filename'),...
                    ' (',this.hData(k).displayName,')'];
            end
            
            if strcmp(hPopup.String, 'Select a dispersion data:')
                hPopup.String = name;
                % update current selection
                updateSelection(this);
            else
                new_name = setdiff(name, hPopup.String); pause(0.005);
                hPopup.String = [hPopup.String; new_name'];
            end
        end %addPopupItem
        
        % remove item from the popup
        function this = removePopupItem(this)
            % check current popup state
            hPopup = this.gui.FileSelectionPopup;
            
            if strcmp(hPopup.String, 'Select a dispersion data:')
                return
            end
            
            % form output name
            for k = numel(this.hData):-1:1
                name{1,k} = [getRelaxProp(this.hData(k), 'filename'),...
                    ' (',this.hData(k).displayName,')'];
            end
            
            oldVal = hPopup.String{hPopup.Value};
            
            if ~isempty(this.hData)
                if hPopup.Value > numel(name)
                    set(hPopup,'String',name,'Value',numel(name));
                else
                    hPopup.String = name;
                end
                newVal = hPopup.String{hPopup.Value};               
            else
                set(hPopup,'String','Select a dispersion data:','Value',1);
                newVal = [];
            end       
            
            if ~isequal(oldVal, newVal)
                updateSelection(this);
            end
        end %removePopupItem
        
        % update the selected data
        function this = updateSelection(this)
            % check the current popup state
            hPopup = this.gui.FileSelectionPopup;
            
            % clear current listener
            delete(this.ls_table); this.ls_table = [];
            
            if strcmp(hPopup.String, 'Select a dispersion data:')
                % clear current selection
                this.SelectedData = [];                
            else
                % get current string
                str = hPopup.String{hPopup.Value};
                % grab the 'Dispersion' flag in the string and separate the
                % filename from the displayName
                idx = strfind(str, 'Dispersion');
                
                displayName = str(idx(end):end-1);
                filename = str(1:idx(end)-3);
                
                % get the data corresponding to these properties
                for k = numel(this.hData):-1:1
                    filename_list{k} = getRelaxProp(this.hData(k), 'filename');
                    displayName_list{k} = this.hData(k).displayName;
                end
                tf = strcmp(filename, filename_list) & strcmp(displayName, displayName_list);
                
                % set this data as the selected one
                this.SelectedData = this.hData(tf);
                % add a listener on it
                this.ls_table = addlistener(this.SelectedData,{'processingMethod'},'PostSet',...
                     @(src, event) updateTable(this));
            end

            % update table
            updateTable(this);
        end %updatePopup
     
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
    end      
end

