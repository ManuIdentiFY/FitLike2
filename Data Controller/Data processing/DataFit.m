classdef DataFit < ProcessDataUnit%DataModel
    %DATAFIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        modelName;          % character string, name of the model, as appearing in the figure legend
        modelEquation;      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
        variableName;       % List of characters, name of the variables appearing in the equation
        parameterName;      % List of characters, name of the parameters appearing in the equation
        isFixed;            % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
        minValue;           % array of values, minimum values reachable for each parameter, respective to the order of parameterName
        maxValue;           % array of values, maximum values reachable for each parameter, respective to the order of parameterName
        startPoint;         % array of values, starting point for each parameter, respective to the order of parameterName
        valueToReturn;      % set which fit parameters must be returned by the function in case where children object are created (R1,..)
        
        % Additional display models custom-defined by the user. It must use
        % the same parameters and variable names as the main function.
        visualisationFunction@cell;  % Visualisation functions user-defined to simplify the analysis of the fit results
    end
    
    properties
        modelHandle;      % function handle that refers to the equation, or to any other function defined by the user
        bestValue;        % array of values, estimated value found from the fit.
        errorBar;         % 2 x n array of values, provide the 95% confidence interval on the estimated fit values (lower and upper errors)
        gof;              % structure that contains all the info required about the goodness of fit
        subModel@DataFit;           % submodels of the main models 
        solver@FitAlgorithm         % solver used for regression fit
    end
    
    methods
        % Constructor
        function this = DataFit()
            % call superclass constructor
            this = this@ProcessDataUnit;
            % set default solver
            this.solver = LsqCurveFit();
            % make function handle
            this = makeFunctionHandle(this);    
        end        
    end
    
    methods
        % redefine the abstract method applyProcess
        function [res, new_data] = applyProcess(this, data)
            % check data and format them
            % TO COMPLETE + TO BE VECTORISED
            xdata = data.x(data.mask);
            ydata = data.y(data.mask);
            dydata = data.dy(data.mask);
            
            if size(xdata,2) > 1; xdata = xdata'; end
            if size(ydata,2) > 1; ydata = ydata'; end
            if size(dydata,2) > 1; dydata = dydata'; end
            
            % check parameter (minValue, maxValue,...) and format them
            this = evaluateStartPoint(this, xdata, ydata);
            % TO COMPLETE
            this.isFixed = logical(this.isFixed); %cast to logical
            
            lb = this.minValue(~this.isFixed);
            ub = this.maxValue(~this.isFixed);
            x0 = this.startPoint(~this.isFixed);
            
            % update function handle
            fun = setFixedParameter(this, this.modelHandle);
            
            % apply fit
            [res.bestValue, res.errorBar, res.gof] = applyFit(this.solver,...
                                    fun, xdata, ydata, dydata, x0, lb, ub);
            
            % gather data and make output structure
            new_data = formatFitData(this, res);            
%             
%             % update sub-models (if any)
%             this = updateSubModel(this);          
        end %applyProcess
                   
        % format output fit data (if childObj is created from fit results)
        function data = formatFitData(this, res)
            %check if value need to be returned
            if isempty(this.valueToReturn) || all(this.valueToReturn == 0)
                data = []; return
            end
            % collect result from fit
            data.y =  res.bestValue(logical(this.valueToReturn));
            data.dy = res.errorBar(logical(this.valueToReturn));
        end %formatFitData
        
        % format output data from process: cell array to array of structure
        % This function could also be used to modify this in order to
        % gather all fit data for instance [Manu]
        function this = formatModel(this, model)
            % check input
            if isempty(model); return; end
            % get data from model and assign it in this
            fld = fieldnames(model{1,1});
            
            
            if numel(model) > 1 && size(model,2) < 2% Zone case
                model = [model{:}];
                for k = 1:numel(fld)
                    val = vertcat(model.(fld{k}));
                    % check for NaN and assign
                    if ~isnumeric(val)
                        this.(fld{k}) = val;
                    elseif all(any(isnan(val) == 0) == 0)
                        this.(fld{k}) = horzcat(model.(fld{k}))';
                    else
                        this.(fld{k}) = val;
                    end
                end
            else                  
                % To change, I do some fixing for zone case [Manu]
                for k = 1:numel(fld)                 
                    % get data
                    val = cellfun(@(x) x.(fld{k}), model, 'Uniform', 0);
                    % assign (initialise the values in case some parameters are
                    % fixed)
                    switch fld{k}
                        case 'bestValue'
                            if iscell(this.bestValue)  % zone processing may require cells here (to be fixed, only arrays should be used)
                                this.bestValue = {this.startPoint};
                                this.bestValue{1}(~this.isFixed) = val{1};
                            else
                                this.bestValue = this.startPoint;
                                this.bestValue(~this.isFixed) = val{1};
                            end
                        case 'errorBar' 
                            if iscell(this.errorBar) % same here
                                this.errorBar = {zeros(size(this.startPoint))};
                                this.errorBar{1}(~this.isFixed) = val{1};
                            else
                                this.errorBar = zeros(size(this.startPoint));
                                this.errorBar(~this.isFixed) = val{1};
                            end
                        otherwise
                            this.(fld{k}) = val;
                    end
                end
            end
            % update sub-models (if any)
            if ~isempty(this.subModel)
                this = updateSubModel(this);
            end
        end %formatData
        
        % generate the function handle for the fit model. The format is
        % as follows:
        % f = @(parameter_list,variable_name) function_string
        % where parameter_list is an array with the same length as
        % self.parameterName
        % this operation adds all the contributions from the subModel list,
        % recursively.
        function this = makeFunctionHandle(this)
            % check that the model is present
            if isempty(this.modelEquation)
                return
            end
             % check for element-wise operators
            opList = {'^','*','/'};
            for indParam = 1:length(opList)
                op = opList{indParam};
                pos = regexp(this.modelEquation,['[^.]\' op]); % find when the operators are not preceded by a dot
                % make the replacements
                for indsub = length(pos):-1:1
                    this.modelEquation = [this.modelEquation(1:pos(indsub)) '.' this.modelEquation(pos(indsub)+1:end)];
                end
            end
            % make sure we do not repeat the @(...) section
            if ~isequal(this.modelEquation(1),'@')
                str = '@(';
                for i = 1:length(this.parameterName) % written as a list for future-proofing multi-variables models
                    if i>1
                        str(end+1) = ',';
                    end
                    str = [str this.parameterName{i} ]; %#ok<*AGROW>
                end
                for i = 1:length(this.variableName) % written as a list for future-proofing multi-variables models
                    str = [str ',' this.variableName{i} ]; %#ok<*AGROW>
                end
                str = [str ') '];
            end
            % build the string expression
            str = [str this.modelEquation];
            this.modelHandle = str2func(str);
        end
        
        % set the fixed parameters for a given 
        function fhfixed = setFixedParameter(this, fh)
            
            fhfixed = @(c,x)localFunction(c,x);
            
            % using nested functions allows creating permanent function
            % handles from custom equations
            function y = localFunction(c,x)
                par = this.startPoint;
                par(~this.isFixed) = c;
                par = num2cell(par);
                if nargin(fh)==2
                    y = fh([par{:}],x);
                else
                    y = fh(par{:},x);
                end
                    
            end
            
%             function y = localFunction(c,x)
%                 par = this.startPoint;
%                 sc = size(c); % deal with the case when multiple data sets are provided (such as zone objects)
%                 for indobj = 1:sc(1)
%                     par(~this.isFixed) = c(indobj,:);
%                     parc = num2cell(par);
%                     if nargin(fh)==2
%                         y(indobj,:) = fh([parc{:}],x);
%                     else
%                         y(indobj,:) = fh(parc{:},x);
%                     end
%                 end
%             end
        end
               
        % update the sub models with the best fit values found from the
        % main model
        function self = updateSubModel(self)
            indLim = 0;
            for indsub = 1:length(self.subModel) % otherwise, pass the other values to the corresponding submodel
                indStart = indLim + 1;
                indLim = indLim + length(self.subModel(indsub).parameterName);
                if length(self.bestValue)>=indLim
                    self.subModel(indsub).bestValue = self.bestValue(indStart:indLim);
                end
                if length(self.errorBar)>=indLim
                    self.subModel(indsub).errorBar = self.errorBar(indStart:indLim);
                end
                self.subModel(indsub).gof = self.gof;
            end
        end
        
        % make a list of all the names of the parameters used in the model,
        % to facilitate display. A unique name is also returned to
        % facilitate the generation of legends
        function [paramNames, uniqueParamNames] = gatherParameterNames(self)
            paramNames = [];
            uniqueParamNames = [];
            for i = 1:length(self.subModel)
                paramNames = [paramNames self.subModel(i).parameterName]; 
                uniqueParamNames = [uniqueParamNames cellfun(@(n)[n '_' num2str(i)],self.subModel(1).parameterName,'UniformOutput',0)]; 
            end
        end
        
        
        % fill in the starting point of the model
        function this = evaluateStartPoint(this, xdata, ydata)
        end
        
        % evaluate the function over the range of values provided by the
        % array x
        % call this in DataUnit directly to custom data access between
        % Bloc, Zone, Dispersion [Manu]
        % OR let this function here but call 
        function y = evaluate(this, x)
            % update function handle
            fun = setFixedParameter(this, this.modelHandle);
            
            y = fun(this.bestValue,x);
        end
        
        % evaluate n points from x1 to x2, for easy and nice plotting
        function y = evaluateRange(this,x1,x2,n)
            x = logspace(log10(x1),log10(x2),n);
            y = evaluate(this,x);
        end
        
        % CHANGESETTINGS(THIS, FIG) create a GUI where parameters
        % can be modified. Two tabs are created:
        % 1. Fit Option: a table where fit parameters can be customed
        % (minValue, maxValue, isFixed, startPoint)
        % 2. Solver Option: a table where solver parameters can be customed
        % (see the wanted solver for parameter details).
        % 
        function this = changeSettings(this, fig)
            % +uitabgroup
            tab = uitabgroup(fig);
            % + tab to change fit options
            tb = uitab(tab, 'Title', 'Fit Options');
            pos = getpixelposition(tb);
            % uitable
            t = uitable(tb, 'Data', [num2cell(logical(this.isFixed')),...
                        num2cell(this.minValue'), num2cell(this.maxValue'), num2cell(this.startPoint')],...
                'ColumnName',{'isFixed','minValue','maxValue','startPoint'},...
                'ColumnFormat',{'logical','numeric','numeric','numeric'},...
                'ColumnWidth', repmat({(pos(3)-100)/4}, 1, 4),...
                'ColumnEditable',true(1,4), 'RowName',this.parameterName,...
                'CellEditCallback',@(src,event) checkParameter_callback(src, event));
            t.Position = [20 20 t.Extent(3) t.Extent(4)];
            % check size
            tb.Units = 'pixel';
            if t.Position(4)+t.Position(1) > tb.Position(4)
                % increase fig size
                n = t.Position(4)+t.Position(1)-tb.Position(4);
                set(fig,'Units','pixel')
                fig.Position(2) = fig.Position(2) - (n+20)/2;
                fig.Position(4) = fig.Position(4) + n + 20;
            end
            %                
            % + tab to change solver options
            tb = uitab(tab, 'Title', 'Solver Options');
            % uitable
            data = struct2cell(this.solver.options)';
            t = uitable(tb, 'Data', data,...
                'ColumnFormat', getOptions(this.solver,'format')',...
                'ColumnEditable',true(size(data)),...
                'ColumnName',fieldnames(this.solver.options),...
                'ColumnWidth',repmat({(pos(3)-130)/size(data,2)}, size(data)),...
                'RowName',{'Parameter'},...
                'CellEditCallback',@(src,event) checkParameter_callback(src, event));  
            t.Position = [20 (pos(4)-50)/2 t.Extent(3) t.Extent(4)];
            
            waitfor(fig); %wait until the figure is deleted
            
            % Nested function to check parameter modifications
            function checkParameter_callback(src, event)
                % check the option type
                if strcmp(src.Parent.Title,'Fit Options')
                    % check the index
                    switch event.Indices(2)
                        case 1 %isFixed
                            this.isFixed(event.Indices(1)) = event.NewData;
                        case 2 %minValue
                            % check that minValue < startPoint
                            if event.NewData > this.startPoint(event.Indices(1))
                                warndlg('minValue need to be lower than startPoint')
                                src.Data{event.Indices(1), event.Indices(2)} = event.PreviousData;
                            else
                                this.minValue(event.Indices(1)) = event.NewData;
                            end
                        case 3 %maxValue
                            % check that maxValue > startPoint
                            if event.NewData < this.startPoint(event.Indices(1))
                                warndlg('maxValue need to be higher than startPoint')
                                src.Data{event.Indices(1), event.Indices(2)} = event.PreviousData;
                            else
                                this.maxValue(event.Indices(1)) = event.NewData;
                            end
                        otherwise %startPoint
                            % check that maxValue > startPoint > minValue
                            if event.NewData > this.maxValue(event.Indices(1)) ||...
                                    event.NewData < this.minValue(event.Indices(1))
                                warndlg('startPoint need to be between minValue and maxValue')
                                src.Data{event.Indices(1), event.Indices(2)} = event.PreviousData;
                            else
                                this.startPoint(event.Indices(1)) = event.NewData;
                            end
                    end
                else
                    % call solver option method
                    fld = t.ColumnName{event.Indices(2)}; 
                    this.solver = setOptions(this.solver, fld, event.NewData);
                    % check output
                    if this.solver.options.(fld) ~= event.NewData
                        src.Data{event.Indices(1), event.Indices(2)} = event.PreviousData;
                    end
                end
            end %checkParameter_callback
        end %changeSettings        
        
        % make a list of all the boudaries for each parameter
        function this = gatherBoundaries(this)
            % init
            this.minValue = []; this.maxValue = [];
            this.startPoint = []; this.isFixed = [];
            this.bestValue = []; this.errorBar = [];
            
            for i = 1:length(this.subModel)
                this.minValue = [this.minValue, this.subModel(i).minValue(:)']; %#ok<*AGROW>
                this.maxValue = [this.maxValue, this.subModel(i).maxValue(:)'];
                this.startPoint = [this.startPoint, this.subModel(i).startPoint(:)'];
                this.isFixed  = [this.isFixed,  this.subModel(i).isFixed(:)'];
                this.bestValue  = [this.bestValue,  this.subModel(i).bestValue(:)'];
                this.errorBar  = [this.errorBar,  this.subModel(i).errorBar(:)'];
            end
        end
    end
    
    methods (Sealed)        
        % add a model object to the list of contributions
        function self = addModel(self,subModel)
            if ~isa(subModel,'DataFit')
                error('Wrong class of model, must be a DataFit object.')
            end
            if isempty(self.subModel)
                % first add the current model
                self.subModel = self;
            end
            % loop over the input
            for k = 1:numel(subModel)
                % check if duplicates
                tf = arrayfun(@(x) strcmp(class(x), class(subModel(k))), self.subModel);
                if any(tf == 1)
                    % change the model name
                    subModel(k).modelName = strcat(subModel(k).modelName,'_',num2str(sum(tf)+1));
                    if sum(tf) == 1 %if first duplicate
                        self.subModel(tf).modelName = strcat(self.subModel(tf).modelName,'_1');
                    end
                end
                % add the new model
                self.subModel = [self.subModel subModel];
            end
            % update the function handles
            self = wrapSubModelList(self); 
        end
        
        % remove a model from the list of contributions
        function self = removeModel(self, idx)
            % check subModel
            if isempty(self.subModel); return; end
            % check input
            if idx < 1 || idx > numel(self.subModel)
                return
            end
            % check duplicates before deletion
            idx_list = find(arrayfun(@(x) strcmp(class(x), class(self.subModel(idx))), self.subModel));

            if numel(idx_list) == 2
                % remove indexing
                self.subModel(idx_list(idx_list~=idx)).modelName = self.subModel(idx_list(idx_list~=idx)).modelName(1:end-2);
            elseif numel(idx_list) > 2
                % decrease indexing
                st = find(idx_list == idx);
                for k = st+1:numel(idx_list)
                    self.subModel(idx_list(k)).modelName = strcat(self.subModel(idx_list(k)).modelName(1:end-1), num2str(st));
                end
            end
            % remove model
            self.subModel = self.subModel([1:idx-1 idx+1:end]);

            % update the function handles
            self = wrapSubModelList(self);
        end %removeModel
        
        % THIS = UPDATEPROP(THIS, FLD, VAL) updates the property
        % specified by FLD and assign the value VAL. If the property is
        % not found, UPDATEPROP calls the same function for the solver.
        function this = updateProp(this, fld, val)
            % search the property
            fld_list = fieldnames(this);
            tf = strcmp(fld_list, fld);
            % check result
            if all(tf == 0)
                % call updateProp for solver
                this.solver = updateProp(this.solver, fld, val);
            else
                this.(fld_list{tf}) = val;
            end
        end
                
        % Create the sum of all the contributions by wrapping the function
        % handles into standard function handles (parameter array, variable
        % array)
        function self = wrapSubModelList(self)
            % deal with the case when a list of objects if given
            if length(self)>1
                self = arrayfun(@(o)wrapSubModelList(o),self);
                return
            end
            % from here on, only one object is being processed
            if isempty(self.subModel)
                return
            end
%             if isempty(self.model)
%                 self.model = DispersionModel;
%             end
            self.modelEquation = '';
            parNum = 0; % number of parameters in the final model
            varName = self.variableName{1};
            model = self.subModel;  %#ok<*PROP> % simplifying the names for clarity
            for indModel = 1:length(model)
                if indModel > 1
                    self.modelEquation = [self.modelEquation ' + '];
                end
                % add the contributions but replaces the parameter names by
                % 'param' and 'x'
                varList = listInputNames(model(indModel));
                for indv = 1:length(model(indModel).parameterName)
                    indPar = find(strcmp(varList,model(indModel).parameterName{indv}));
                    parNum = parNum + 1;
                    varList{indPar} = ['param(' num2str(parNum) '),']; %#ok<*FNDSB>
                end
                for indv = 1:length(model(indModel).variableName)
                    indPar = find(strcmp(varList,model(indModel).variableName{indv}));
                    varList{indPar} = [varName ','];
                end
                varList{end} = varList{end}(1:end-1); % remove the trailing comma
                self.modelEquation = [self.modelEquation 'model(' num2str(indModel) ').modelHandle(' varList{:} ')'];
                
            end
            % generate the function handles to wrap the submodel
            % equations
            % WARNING: we cannot use str2func to generate the function
            % handle, as it does not seem to generate the function
            % properly. There is no escape but to use eval...
            self.modelHandle = eval(['@(param,' varName ')' self.modelEquation]);
            
            % collect the boundaries corresponding to each sub-model
            self = gatherBoundaries(self);
            
        end
        
    end
        
        % should be in Pipeline probably
%         function numberOfInputs(this)
%         end
%         
%         function numberOfOutputs(this)
%         end
end

