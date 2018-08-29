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
           
            % add "add" pushbutton and container
            this.container = uicontainer( 'Parent', box);
            addbox = uix.HButtonBox( 'Parent', box,...
                'Padding', 2,'ButtonSize',[150 22]);
            uicontrol( 'Parent', addbox,...
                       'Style','pushbutton',...
                       'FontSize',7,...
                       'String','Add model',...
                       'Callback',@(src, event) addModel(this));
             box.Heights = [-1 22];
        end %ModelTab
    end
    
    methods (Access = public)
       % Add new model
       function this = addModel(this)
            % call the model selector
           [modelName, modelObj] = ModelTab.modeldlg();
           % add this model to the array
           this.ModelArray = [this.ModelArray modelObj];
           % update the gui
           if isempty(this.jtable)
               % create treetable
               header = {'M','Parameter','isFixed?','MinBound','MaxBound','StartPoint'};
               type = {'char','char','logical','','',''};
               editable = {false,false,true,true,true,true};
               data = [repmat({modelName},numel(modelObj.parameterName),1),...
                   modelObj.parameterName',num2cell(logical(modelObj.isFixed')),...
                   num2cell(modelObj.minValue'),num2cell(modelObj.maxValue'),...
                   num2cell(modelObj.startPoint')];

               this.jtable = treeTable(this.container,header,data,...
                   'ColumnTypes',type,'ColumnEditable',editable);
           else
               % count number of row and get jtable
               n = numel(modelObj.parameterName);
               treetable = this.jtable.getModel.getActualModel.getActualModel;
               % add row one by one
               for k = 1:n
                   row = {modelName,modelObj.parameterName{k},...
                      logical(modelObj.isFixed(k)),modelObj.minValue(k),...
                      modelObj.maxValue(k),modelObj.startPoint(k)};
                   % here we use the javaMethodEDT to handle EDT
                   % see https://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt
                   javaMethodEDT('addRow',treetable,row);
               end
           end
       end %addModel
       
       % Remove model
       function this = removeModel(this, ~)

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
    end
end


