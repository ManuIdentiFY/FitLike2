classdef ModelTab < uix.Container & handle
    %
    % Class that define custom tab for ProcessingManager (Process settings)
    %
    
    properties (Access = public)
        jtable % treetable 
        container % container for treetable
        TabTitle % tab title        
        ModelArray % list of the model
    end
    
    methods
        % Constructor
        function this = ModelTab(tab, TabTitle)
            % Call superclass constructor
            this@uix.Container();
            % set Title
            this.TabTitle = TabTitle;
            % Create the grid in the parent tab
            grid = uix.Grid('Parent',this,'Spacing', 2); 
            % Create vertical box
            box = uix.VBox( 'Parent', grid, 'Padding', 2);
            % set the Parent 
            this.Parent = tab;
            this.Parent.Title = this.TabTitle;            
           
            % add treetable
            this.container = uicontainer( 'Parent', box);
            
            header = {'M','Parameter','isFixed?','MinBound','MaxBound','StartPoint'};
            type = {'char','char','logical','','',''};
            editable = {false,false,true,true,true,true};
            dummy_data = {'','',true,0,0,0};
            treetable = treeTable(this.container,header,dummy_data,...
                   'ColumnTypes',type,'ColumnEditable',editable); 
               
            % store handle to the data and remove the dummy row   
            this.jtable = treetable.getModel.getActualModel.getActualModel;
            javaMethodEDT('removeRow',this.jtable,0);   
               
            % add add/remove model pushbuttons    
            addbox = uix.HButtonBox( 'Parent', box,...
                'Padding', 2,'ButtonSize',[100 25],'Spacing',20);
            uicontrol( 'Parent', addbox,...
                       'Style','pushbutton',...
                       'FontSize',7,...
                       'String','Add model',...
                       'Callback',@(src, event) addModel(this));
            uicontrol( 'Parent', addbox,...
                       'Style','pushbutton',...
                       'FontSize',7,...
                       'String','Remove model',...
                       'Callback',@(src, event) removeModel(this)); 
             box.Heights = [-1 25];
        end %ModelTab
    end
    
    methods (Access = public)
       % Add new model
       function this = addModel(this)
            % call the model selector
           [modelName, modelObj] = ModelTab.modeldlg();
           % update the gui
           if ~isempty(modelName)
               % add row one by one
               for k = 1:numel(modelObj.parameterName)
                   row = {modelName,modelObj.parameterName{k},...
                      logical(modelObj.isFixed(k)),modelObj.minValue(k),...
                      modelObj.maxValue(k),modelObj.startPoint(k)};
                   % here we use the javaMethodEDT to handle EDT
                   % see https://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt
                   javaMethodEDT('addRow',this.jtable,row);
               end
               % add this model to the array
               this.ModelArray = [this.ModelArray modelObj];
           end
       end %addModel
       
       % Remove model
       function this = removeModel(this)
           % check if model is available
           if isempty(this.ModelArray)
               return
           end
           % get the name of the model imported
           name_list = ModelTab.getJTableData(this.jtable, [], 1);
           % get unique list
           [name,~,ic] = unique(name_list,'stable');
           % ask user which model need to be deleted
           [indx,~] = listdlg('PromptString','Select a model to remove:',...
                           'SelectionMode','single',...
                           'ListString',name);
           % check answer and remove the corresponding model if needed
           if ~isempty(indx)
               idxToRemove = find(ic == indx);
               for k = 1:numel(idxToRemove)
                   % here we use the javaMethodEDT to handle EDT
                   % see https://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt
                   javaMethodEDT('removeRow',this.jtable,idxToRemove(1)-1);
               end
               % update ModelArray
               this.ModelArray(indx) = [];
           end
       end %removeModel
    end
    
    methods (Static = true, Access = public)
        % Display a window where the user can select a model
        function [name, modelObj] = modeldlg()
            % define subclass to list
            MODEL_CLASS = 'DispersionModel'; %name of the class to list
            % get subclass
            tb = getSubclasses(MODEL_CLASS, pwd);
            tb = tb(2:end,:); % remove superclass

            % add displayName
            mc = cellfun(@meta.class.fromName, tb.names, 'Uniform',0); %get class data
            tf = strcmp({mc{1}.PropertyList.Name}, 'modelName'); %be sure about the index of the name
            modelName = cellfun(@(x) x.PropertyList(tf).DefaultValue, mc, 'Uniform', 0);
            
            % create listdlg to select model
            [indx,~] = listdlg('PromptString','Select a model:',...
                           'SelectionMode','single',...
                           'ListString',modelName);
                       
            % if model was selected, get the corresponding information
            if ~isempty(indx)
                name = modelName{indx};
                % create the process object using its name
                fh = str2func(tb.names{indx});
                modelObj = fh();
            else
                name = [];  modelObj = [];
            end
        end %modeldlg()
        
        % Get data in jtable Java
        function data = getJTableData(jtable, rowIdx, colIdx)
            % check input
            if isempty(rowIdx)
                rowIdx = 1:jtable.getRowCount;
            end
            
            if isempty(colIdx)
                colIdx = 1:jtable.getColumnCount;
            end
            % loop over the requested col and row
            for i = numel(rowIdx):-1:1
                for j = numel(colIdx):-1:1
                    data{i,j} = jtable.getValueAt(rowIdx(i)-1,colIdx(j)-1);
                end
            end
            % check if possible to convert to array
            if all(all(cellfun(@isnumeric, data(1,:)) == 1) == 1)
                data = cell2mat(data);
            end
        end
    end
end


