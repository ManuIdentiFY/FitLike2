classdef ProcessTab < uix.Container & handle
    %
    % Class that define custom tab for ProcessingManager (Process settings)
    %
    
    properties (Access = public)
        ProcessingManager %main window
        hbox % main horizontal box
        vbox % array of vertical box
        TabTitle % tab title        
        ProcessArray % list of the process
    end
    
    properties (Access = public)
       ArrowIconUp % arrow up
       ArrowIconDown %arrow down
       DeleteIcon %delete 
       SettingIcon %setting
    end
    
    methods
        % Constructor
        function this = ProcessTab(ProcessingManager, tab, TabTitle)
            % Call superclass constructor
            this@uix.Container();
            this.ProcessingManager = ProcessingManager;
            % set Title
            this.TabTitle = TabTitle;
            % Create the grid in the parent tab
            grid = uix.Grid('Parent',this,'Spacing', 2); 
            % set the Parent 
            this.Parent = tab;
            this.Parent.Title = this.TabTitle;            
            %---------------------------BUILDER---------------------------%
            % create main horyzontal box
            this.hbox = uix.HBox( 'Parent', grid, 'Padding', 2);
            % create vertical boxes (fonction name, input type, output
            % type, parameter, remove option)
            this.vbox{1} = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 22]);
            this.vbox{2} = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 22]);
            this.vbox{3} = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 22]);
            this.vbox{4} = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 22]);
            
            % create titles for the boxes
            uicontrol( 'Parent', this.vbox{1}, 'Style', 'text', 'String', 'Name',...
                'FontName','Helvetica','FontSize',8,'FontWeight','bold');
            uicontrol( 'Parent', this.vbox{2}, 'Style', 'text', 'String', 'Input',...
                'FontName','Helvetica','FontSize',8,'FontWeight','bold');
            uicontrol( 'Parent', this.vbox{3}, 'Style', 'text', 'String', 'Output',...
                'FontName','Helvetica','FontSize',8,'FontWeight','bold');
            uix.Empty( 'Parent', this.vbox{4});
            
            % add "add" pushbutton and empty space
            uicontrol( 'Parent', this.vbox{1},...
                       'Style','pushbutton',...
                       'FontSize',7,...
                       'String','Add Process',...
                       'Callback',@(src, event) addProcess(this));
            uix.Empty( 'Parent', this.vbox{2});
            uix.Empty( 'Parent', this.vbox{3});
            uix.Empty( 'Parent', this.vbox{4});

            % set width
            this.hbox.Widths = [-1.8 -1.2 -1.2 -1]; 
            drawnow;
            % get the icons
            icons = load('icon.mat');
            this.ArrowIconUp = icons.arrow_up;
            this.ArrowIconDown = icons.arrow_down;
            this.DeleteIcon = icons.delete_ico;
            this.SettingIcon = icons.setting_ico;
        end %ProcessTab
    end
    
    methods (Access = public)
       % Add new line
       function this = addLine(this, name, intype, outtype)
           % check if this process already exists
           if isempty(this.ProcessArray)
               % just continue
           elseif all(strcmp({this.ProcessArray.functionName}, name) ~= 0)
               warndlg('This process have already been imported!', 'Warning')
               return
           end
           % add a new line to the current tab
            uicontrol( 'Parent', this.vbox{1}, 'Style', 'text', 'String', name,...
                'FontName','Helvetica','FontSize',8);
            uicontrol( 'Parent', this.vbox{2}, 'Style', 'text', 'String', intype,...
                'FontName','Helvetica','FontSize',8);
            uicontrol( 'Parent', this.vbox{3}, 'Style', 'text', 'String', outtype,...
                'FontName','Helvetica','FontSize',8);

            % add some buttons
            h = uix.HButtonBox( 'Parent', this.vbox{4}, 'ButtonSize',[20 20]);
            uicontrol( 'Parent', h, 'Style', 'pushbutton',...
                'CData', this.SettingIcon, 'Tag', 'Parameter',...
                'Callback',@(src, event) changeSettings(this, src));
            uicontrol( 'Parent', h, 'Style', 'pushbutton',...
                'CData', this.ArrowIconUp, 'Tag', 'Up',...
                'Callback',@(src, event) moveProcess(this, src));
            uicontrol( 'Parent', h, 'Style', 'pushbutton',...
                'CData', this.ArrowIconDown, 'Tag', 'Down',...
                'Callback',@(src, event) moveProcess(this, src));
            uicontrol( 'Parent', h, 'Style', 'pushbutton',...
                'CData', this.DeleteIcon,'Tag', 'Delete',...
                'Callback',@(src, event) removeProcess(this, src));
            % reorganize object
            cellfun(@(x) uistack(x.Children(1),'down'), this.vbox, 'Uniform', 0);
            drawnow;
       end %addLine
       
       % Add new process
       function this = addProcess(this)
           % call the process selector
           [name, intype, outtype, processObj] = ProcessTab.processdlg();
           % check if empty and add the process
           if ~isempty(name)
                % add new line
                addLine(this, name, intype, outtype);
                % add processObj
                this.ProcessArray = [processObj this.ProcessArray];
           end
       end %addProcess
       
       % Remove process
       function this = removeProcess(this, src)
           % get index of the selected button from the HBox matching
           tf = src.Parent.Parent.Children == src.Parent; 
           % remove the process
           this.ProcessArray(find(tf)-1) = [];
           % remove this line
           cellfun(@(x) delete(x.Children(tf)), this.vbox, 'Uniform', 0);
           
       end %removeProcess
       
       % Move process
       function this = moveProcess(this, src)
           % get index of the selected button from the HBox matching
           tf = src.Parent.Parent.Children == src.Parent; 
           indx = find(tf);
           n = numel(tf);
           % check which button was pressed
           if strcmp(src.Tag, 'Up')
               % check if we can move the line
               if indx < n - 1
                   % move up
                   cellfun(@(x) uistack(x.Children(indx),'down'), this.vbox, 'Uniform', 0);
                   % move process in the array
                   new_order = 1:n-2;
                   new_order(indx) = new_order(indx) - 1;
                   new_order(indx-1) = new_order(indx-1) + 1;
                   % reorder
                   this.ProcessArray = this.ProcessArray(new_order);    
               end
           else
               % check if we can move the line
               if indx > 2
                   % move down
                   cellfun(@(x) uistack(x.Children(indx),'up'), this.vbox, 'Uniform', 0);
                   % move process in the array
                   new_order = 1:n-2;
                   new_order(indx-1) = new_order(indx-1) - 1;
                   new_order(indx-2) = new_order(indx-2) + 1;
                   % reorder
                   this.ProcessArray = this.ProcessArray(new_order);
               end
           end
       end %moveProcess
       
       % Change settings
       function this = changeSettings(this, src)
           % get index of the selected button from the HBox matching
           tf = src.Parent.Parent.Children(2:end-1) == src.Parent; 
           % call the gui of the processed object
           this.ProcessArray(tf) = changeProcessParameter(this.ProcessArray(tf));
       end %changeSettings
    end
    
    methods (Static = true, Access = public)
        % Display a window where the user can select a process
        function [name, intype, outtype, processObj] = processdlg()
            % define subclass to list
            PROCESS_CLASS = {'Bloc2Zone','Bloc2Bloc','Zone2Disp','Zone2Zone','Disp2Disp'};%name of the class to list
            process_tb = [];
            fitlikeDir = fileparts(which('FitLike.m'));
            % loop 
            for k = 1:numel(PROCESS_CLASS)
                % get subclass
                tb = getSubclasses(PROCESS_CLASS{k}, fitlikeDir);
                tb = tb(2:end,:); % remove superclass
%                 % add input/output 
%                 oh = str2func(PROCESS_CLASS{k});
%                 obj = oh(); % create an instance of the object
%                 in = obj.InputChildClass;
%                 out=  obj.OutputChildClass;
%                 
                switch PROCESS_CLASS{k}
                    case 'Bloc2Zone'
                        in = 'bloc';
                        out = 'zone';
                    case 'Zone2Disp'
                        in = 'zone';
                        out = 'dispersion';
                    case 'Bloc2Bloc'
                        in = 'bloc';
                        out = 'bloc';
                    case 'Zone2Zone'
                        in = 'zone';
                        out = 'zone';
                    case 'Disp2Disp'
                        in = 'dispersion';
                        out = 'dispersion';
%                     case 'Disp2Exp'
%                         in = 'dispersion';
%                         out = 'experiment';
                end
                
                tb.from = repmat({in},height(tb),1);
                tb.to = repmat({out},height(tb),1);
                % add displayName
                mc = cellfun(@meta.class.fromName, tb.names, 'Uniform',0); %get class data
                tf = strcmp({mc{1}.PropertyList.Name}, 'functionName'); %be sure about the index of the name
                tb.displayName = cellfun(@(x) x.PropertyList(tf).DefaultValue, mc, 'Uniform', 0);
                % concatenate
                process_tb = [process_tb; tb]; %#ok<AGROW>
            end
            
            % create listdlg to select process
            [indx,~] = listdlg('PromptString','Select a process:',...
                           'SelectionMode','single',...
                           'ListString',process_tb.displayName);
                       
            % if process was selected, get the corresponding information
            if ~isempty(indx)
                name = process_tb.displayName{indx};
                intype = process_tb.from{indx};
                outtype = process_tb.to{indx};
                % create the process object using its name
                funcProcess = str2func(process_tb.names{indx});
                processObj = funcProcess();
            else
                name = [];  intype = []; outtype = []; processObj = [];
            end
        end %processdlg()     
        
       % Check process: is the pipeline consistent?
       function tf = checkProcess(this)
           % check number of process
           n = length(this.vbox{2}.Children) - 2;
           % check if empty
           if n < 1
               tf = 0;
               warndlg('No process to run pipeline!','Warning')
           else
               % check that input/output is consistent: bloc-->zone then
               % zone--> dispersion, not the opposite
               from = flip({this.vbox{2}.Children(2:end-1).String}); %get input format
               to = flip({this.vbox{3}.Children(2:end-1).String}); %get output format
                
               if ~strcmp(from{1},'bloc')
                   tf = 0;
                   warndlg('The pipeline need to start by a bloc type!', 'Warning')
               elseif n == 1
                   tf = 1;
               else
                   % check in/out format
                   for k = 1:n-1
                       outFormat = to{k};
                       inFormat = from{k+1};
                       if ~isequal(inFormat, outFormat)
                           tf = 0;
                           warndlg('The input/output type are not consistent to run pipeline!','Warning')
                           return
                       end
                   end
                   % valid pipeline
                   tf = 1;
               end
           end
       end %checkProcess
       
       % Get all the pipeline information as table
       function tb = getPipelineAsTable(this)
           % check if available data
           n = length(this.vbox{2}.Children) - 2;
           % if not empty table
           if n < 1
               name = {}; from = {}; to = {};
               tb = table(name, from, to);
           else
               % get data
               name = {this.vbox{1}.Children(2:end-1).String}';
               from = {this.vbox{2}.Children(2:end-1).String}';
               to   = {this.vbox{3}.Children(2:end-1).String}';
               % set table
               tb = table(name, from, to);
           end
       end %getPipelineAsTable
    end
    
    methods (Access = public)
       % Set the pipeline from table
       function this = setPipelineFromTable(this, tb)
           % remove current pipeline if needed
           n = length(this.vbox{2}.Children) - 2;

           if n > 0
               cellfun(@(x) delete(x.Children(2:end-1)), this.vbox, 'Uniform',0);
           end
           
           % fill the pipeline from the last process to the first.
           for k = height(tb):-1:1
               addLine(this, tb.name{k}, tb.from{k}, tb.to{k});
           end
       end %setPipelineFromTable
    end
    
end

