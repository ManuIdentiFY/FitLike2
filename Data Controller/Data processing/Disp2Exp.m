classdef Disp2Exp < ProcessDataUnit
    
    % this class performs the fit over the dispersion data. Several
    % contributions can be added together by using an array of object, each
    % one containing a different component.
    % Performing the fit is done using the function applyProcessFunction,
    % then the result can be used to generate an Experiment object if
    % required (using makeExp).
    
    properties
        model;       % Dispersion model that sums up all the contributions. Used for the processing.
        subModel;    % List of sub-models to be added up.
    end
    
    properties (Abstract)
        
    end
    
    methods
        
        function self = Disp2Exp(varargin)
            self@ProcessDataUnit;
            % TODO: better parsing. Assuming it is the list of sub-models
            self.model = DefaultDispersionModel;
            if ~isempty(varargin)
                self = addModel(self,varargin{1});
            end
        end
        
        % add a DispersionModel object to the list of contributions
        function self = addModel(self,subModel)
%             if ~isequal(class(subModel),'DispersionModel')
%                 error('Wrong class of model, must be a DispersionModel.')
%             end
            if isempty(self.subModel)
                self.subModel = subModel;
            else
                self.subModel = [self.subModel subModel];
            end
            self = wrapSubModelList(self); % update the function handles
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
            if isempty(self.model)
                self.model = DispersionModel;
            end
            self.model.modelEquation = '';
            parNum = 0; % number of parameters in the final model
            varName = self.model.variableName{1};
            model = self.subModel;  %#ok<*PROP> % simplifying the names for clarity
            for indModel = 1:length(model)
                if indModel > 1
                    self.model.modelEquation = [self.model.modelEquation ' + '];
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
                self.model.modelEquation = [self.model.modelEquation 'model(' num2str(indModel) ').modelHandle(' varList{:} ')'];
                
            end
            % generate the function handles to wrap the submodel
            % equations
            % WARNING: we cannot use str2func to generate the function
            % handle, as it does not seem to generate the function
            % properly. There is no escape but to use eval...
            self.model.modelHandle = eval(['@(param,' varName ')' self.model.modelEquation]);
            
            % collect the boundaries corresponding to each sub-model
            self = gatherBoundaries(self);
            
        end
        
        % function that allows estimating the start point. It should be 
        % over-riden by the derived classes
        function self = evaluateStartPoint(self,x,y)
            % you may add some estimation technique here or let each
            % component estimate its parameters using their own methods 
            for indProc = 1:length(self)
                for i = 1:length(self(indProc).subModel)
                    self(indProc).subModel(i) = evaluateStartPoint(self(indProc).subModel(i),x,y);
                end
            end
        end
                
        % update the sub models with the best fit values found from the
        % main model
        function self = updateSubModel(self)
            indLim = 0;
            for indsub = 1:length(self.subModel) % otherwise, pass the other values to the corresponding submodel
                indStart = indLim + 1;
                indLim = indLim + length(self.subModel(indsub).parameterName);
                if length(self.model.bestValue)>=indLim
                    self.subModel(indsub).bestValue = self.model.bestValue(indStart:indLim);
                end
                if length(self.model.errorBar)>=indLim
                    self.subModel(indsub).errorBar = self.model.errorBar(indStart:indLim);
                end
                self.subModel(indsub).gof = self.model.gof;
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
        
        % make a list of all the boudaries for each parameter
        function this = gatherBoundaries(this)
            % init
%             this.model = struct('minValue',[],'maxValue',[],...
%                 'startPoint',[],'isFixed',[],'bestValue',[],'errorBar',[]);
            
            for i = 1:length(this.subModel)
                this.model.minValue = [this.model.minValue, this.subModel(i).minValue(:)']; %#ok<*AGROW>
                this.model.maxValue = [this.model.maxValue, this.subModel(i).maxValue(:)'];
                this.model.startPoint = [this.model.startPoint, this.subModel(i).startPoint(:)'];
                this.model.isFixed  = [this.model.isFixed,  this.subModel(i).isFixed(:)'];
                this.model.bestValue  = [this.model.bestValue,  this.subModel(i).bestValue(:)'];
                this.model.errorBar  = [this.model.errorBar,  this.subModel(i).errorBar(:)'];
            end
        end
        
        % redefine the access functions so that any change to the model or
        % submodel list updates the entire object
        function self = set.model(self,value)
            self.model = value;
            self = updateSubModel(self);
        end
        
%         function self = set.subModel(self,value)
%             self.subModel = value;
%             self = wrapSubModelList(self); % update the function handles
%         end
        
        % sets a function handle into the log space
        % fhlog = log10(fh)
        function fhlog = makeLogFunction(self)
            par = functions(self.model.modelHandle);
            ind = strfind(par.function,')');
            inputList = par.function(3:ind(1)-1);
            fhandle = self.model.modelHandle; %#ok<NASGU>
            fhlog = eval(['@(' inputList ') log10(fhandle(' inputList '))']); % str2func won't work here...
%             fhlog = str2func(['@(' inputList ') log10(fh(' inputList '))']);
        end
        
%         
%         % function that applies a list of processing objects for one
%         % dispersion object 'disp'
%         function self = applyProcessFunctionToSingleDisp(self,dispersion)
%             % keep track of the index of each model, for convenience
%             selfindex = num2cell(1:length(self),1);
%             % update the main model
%             self = wrapSubModelList(self);
% %             self.subModel = arrayfun(@(mod)evaluateStartPoint(mod,disp.x,disp.y),self.subModel);
%             self = gatherBoundaries(self);
%             % check that the model is not empty
%             if isempty(self.subModel)
%                 disp('Model is empty. Please select a dispersion model.')
%                 return
%             end
%             % perform the calculations
%             selfCell = arrayfun(@(d2e,i) process(d2e,dispersion,i),self,selfindex,'UniformOutput',0);
%             self = [selfCell{:,:}];
%             % store the results in the dispersion object
%             dispersion.processingMethod = self;
%         end
%         
%         % function that applies a list of processing objects to a list of
%         % dispersion objects. The result is a table of processing objects.
%         function [self,exp] = applyProcessFunction(self,disp)
%             selfCell = arrayfun(@(d) applyProcessFunctionToSingleDisp(self,d),disp,'UniformOutput',0);
%             self = [selfCell{:,:}];
%             exp = DataUnit;
%             [disp,exp] = link(disp,exp);
%         end
%         
        % evaluate the function over the range of values provided by the
        % array x
        function y = evaluate(self,x)
            y = evaluate(self.model,x);
        end
        
        % evaluate n points from x1 to x2, for easy and nice plotting
        function y = evaluateRange(self,x1,x2,n)
            y = evaluateRange(self.model,x1,x2,n);
        end
        
        % make a list of all the sub-models
        function list = makeModelList(self)
            if length(self)>1
                list = arrayfun(@(o)makeModelList(o),self,'UniformOutput',0);
            else
                list = arrayfun(@(i)class(self.subModel(i)),1:length(self.subModel),'UniformOutput',0);
            end
        end
        
        % TO DO
        % generate a new object from a list of already processed dispersion
        % objects. Makes an experiment from all the dispersion objects that
        % have been processed with an object of the same class as 'self'
        % (which may be an array).
        % the user may also provide a list of parameters to pre-fill the
        % experiment object ('x',x_array,'xlabel','some string',...)
        % TO DO: provide the type of experiment object so that one can
        % customise the behaviour of the output depending on the experiment
        % TO DO: cluster the data by label, put cluster name as legend
        function [exp,disp] = makeExp(self,disp,varargin)
            % treat the case when the processing object is a list
            if length(self)>1
                [exp,disp] = arrayfun(@(o)makeExp(o,disp),self,'UniformOutput',0);
                exp = [exp{:}];
                disp = [disp{:}];
                return
            end
            % now we only have one processing object, and a list of data
            % units
            
            % make one experiment object per parameter in the fit object
            % (do not consider the fixed parameters)
            [~,parameterName] = gatherParameterNames(self);
            exp(1:length(parameterName)) = Experiment(varargin{:});
            for indExp = 1:length(parameterName)
                if isempty(exp(indExp).legendTag)
                    exp(indExp).legendTag = self.functionName;
                end
                if isempty(exp(indExp).yLabel)
                    exp(indExp).yLabel = parameterName{indExp};
                end
            end
            
            % finds all the datasets using the same fitting algorithm
            modelClass = makeModelList(self);
            matchIndex = arrayfun(@(o)cellfun(@(c)isequal(c,modelClass),makeModelList(o.processingMethod),'UniformOutput' ,0),disp,'UniformOutput',0);
            % now collect the data and store it in the experiment object
            for indDisp = 1:length(matchIndex)
                for indMod = 1:length(disp(indDisp).processingMethod)
                    if matchIndex{indDisp}{indMod}
                        for indExp = 1:length(parameterName)
                            exp(indExp).y(end+1) = disp(indDisp).processingMethod(indMod).model.bestValue(indExp);
                            exp(indExp).dy(end+1) = disp(indDisp).processingMethod(indMod).model.errorBar(indExp);
                        end
                        % link the children and parent objects
                        [exp(indExp),disp(indDisp)] = link(exp(indExp),disp(indDisp));
                    end
                end
            end
            
        end
    end
    
    methods (Static)
    
        % set the fixed parameters for a given 
        function fhfixed = setFixedParameter(fh,isFixed,startPoint)
            paramlist = '';
            n = 0;
            for i = 1:length(isFixed)
                if ~isFixed(i)
                    n = n+1;
                    paramlist = [paramlist 'c(' num2str(n) ')'];
                else
                    paramlist = [paramlist num2str(startPoint(i))];
                end
                if i ~=length(isFixed)
                    paramlist = [paramlist ','];
                end
            end
            fhfixed = eval(['@(c,x) fh([' paramlist '],x)']);
        end
        
    end
    
    
    methods (Sealed)
        
        % standard naming convention for the processing function (one
        % dispersion, several processing objects)
        function [exp,dispersion] = processData(self,dispersion)
            % keep track of the index of each model, for convenience
            selfindex = num2cell(1:length(self),1);
%             % update the main model list if necessary
%             self = wrapSubModelList(self);
            % check that the model is not empty
            empt = arrayfun(@(o)isempty(o.subModel),self);
            if sum(empt)
                disp('Model is empty. Please select a dispersion model.')
                return
            end
            % perform the calculations
            selfCell = arrayfun(@(d2e,i) process(d2e,dispersion,i),self,selfindex,'UniformOutput',0);
            self = [selfCell{:,:}];
            % store the results in the dispersion object
            dispersion.processingMethod = self;
            exp = [];
        end
        
    end
    
end