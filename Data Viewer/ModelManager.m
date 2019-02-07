classdef ModelManager < handle
 %
    % View for ModelManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
    end
    
    properties (Hidden)
        ls_table %listener to update fit results
        ls_popup  %listener to update popup if DataUnit is deleted
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
            
            % Set callback for the file selection popup
            set(this.gui.FileSelectionPopup,'Callback',...
                @(src, event) updateResultTable(this));
            
            % Add listener to the Dispersion tree
            addlistener(this.FitLike.FileManager,...
               'DataSelected',@(src, event) updateFilePopup(this, src, event));
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
        
        % Check file callback
        function this = updateResultTable(this, src , event)
            % handle popup
            hPopup = this.gui.FileSelectionPopup;
            % get the selected file
            if isempty(hPopup.UserData)
                return               
            end
            
            % get the data associated
            dataObj = hPopup.UserData(hPopup.Value);

            % remove previous results
            nRow = this.gui.jtable.getRowCount();
            for k = 1:nRow
                   % here we use the javaMethodEDT to handle EDT
                   % see https://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt
                   javaMethodEDT('removeRow',this.gui.jtable,0);
            end
            % check if data are available
            if isempty(dataObj)
                return
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Need to finish submodel architecture in DataFit!
            if 1; disp('ModelManager: OK!'); return; end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % add new results
            modelName = processObj.modelName;
            for k = 1:numel(model.subModel)
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
        
        % Need to add move listener from updateResultTable to
        % updateFilePopup to respond to runProcess() call. [Manu]
        % Could pass data to the updateResultTable directly, avoiding the
        % need to do multiple call to FitLike to get data (just store
        % handle in UserData!)
        
        % File checked in tree callback
        function this = updateFilePopup(this,~,event)
            return
            % check if data are dispersion
            if ~isa(event.Data ,'Dispersion')
                return
            end
            
            % form output name and ID
            for k = numel(event.Data):-1:1
                new_name{k} = [getRelaxProp(event.Data(k), 'filename'),...
                    ' (',event.Data(k).displayName,')'];
            end
            
            % check format
            if size(event.Data,1) > 1; event.Data = event.Data'; end
            if size(new_name,1) > 1; new_name = new_name'; end
            
            lisflag = 1; %flag for listener
            % check if we add new item or remove one
            hPopup = this.gui.FileSelectionPopup;
            if strcmp(event.Action, 'Select')
                if strcmp(hPopup.String, 'Select a dispersion data:')
                    hPopup.String = new_name;
                    hPopup.UserData = event.Data;
                else
                    % check if duplicates
                    [~,idx] = setdiff(new_name, hPopup.String);
                    hPopup.String = [hPopup.String new_name(idx)];
                    hPopup.UserData = [hPopup.UserData event.Data(idx)];
                end
            else
                [~,idx] = setdiff(hPopup.String, new_name);
                hPopup.UserData = hPopup.UserData(idx);
                
                if isempty(hPopup.UserData)
                    lisflag = 0;
                    hPopup.Value = 1;
                    hPopup.String = 'Select a dispersion data:'; 
                else
                    hPopup.String = hPopup.String(idx);
                end
            end
            
            % update popup listener
            if isempty(this.ls_popup)
                this.ls_popup = addlistener([hPopup.UserData],'DataDeletion',...
                    @(src, event) onDataDeletion(this, src, event));
            else
                delete(this.ls_popup); this.ls_popup = [];
                this.ls_popup = addlistener([hPopup.UserData],'DataDeletion',...
                    @(src, event) onDataDeletion(this, src, event));
            end
            
%             % remove previous listener
%             if ~isempty(this.ls); delete(this.ls); end
%             
%             if lisflag                
%                 % add new one
%                 dataObj = hPopup.UserData(hPopup.Value);
%                 this.ls_table = addlistener(dataObj,{'processingMethod'},'PostSet',...
%                     @(src, event) updateResultTable(this));
%             end
%             drawnow; pause (0.005);
%             updateResultTable(this);
%             drawnow;
        end %updateFilePopup
        
        % function fires when a DataUnit is deleted 
        function this = onDataDeletion(this, src, event)
            h = 1;            
        end %onDataDeletion
        
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

