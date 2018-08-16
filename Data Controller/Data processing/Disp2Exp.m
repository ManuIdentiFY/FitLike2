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
    
    methods
        
        function self = Disp2Exp(varargin)
            self@ProcessDataUnit(varargin{:});
            self.model = DefaultDispersionModel;
        end
        
        % add a DispersionModel object to the list of contributions
        function self = addModel(self,subModel)
%             if ~isequal(class(subModel),'DispersionModel')
%                 error('Wrong class of model, must be a DispersionModel.')
%             end
            if isempty(self.subModel)
                self.subModel = subModel;
            else
                self.subModel(end+1) = subModel;
            end
            self = wrapSubModelList(self); % update the function handles
        end
                
        % Create the sum of all the contributions by wrapping the function
        % handles into standard function handles (parameter array, variable
        % array)
        function self = wrapSubModelList(self)
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
        
        % update the sub models with the best fit values found from the ma
        function self = updateSubModel(self)
            indLim = 0;
            for indsub = 1:length(self.subModel) % otherwise, pass the other values to the corresponding submodel
                indStart = indLim + 1;
                indLim = indLim + length(self.subModel(indsub).parameterName);
                self.subModel(indsub).bestValue = self.model.bestValue(indStart:indLim);
                self.subModel(indsub).errorBar = self.model.errorBar(indStart:indLim);
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
        function self = gatherBoundaries(self)
            self.model.minValue = [];
            self.model.maxValue = [];
            self.model.startPoint = [];
            self.model.isFixed = [];
            for i = 1:length(self.subModel)
                self.model.minValue = [self.model.minValue, self.subModel(i).minValue(:)']; %#ok<*AGROW>
                self.model.maxValue = [self.model.maxValue, self.subModel(i).maxValue(:)'];
                self.model.startPoint = [self.model.startPoint, self.subModel(i).startPoint(:)'];
                self.model.isFixed  = [self.model.isFixed,  self.subModel(i).isFixed(:)'];
            end
        end
        
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
        
        % function that applies a list of processing objects for one
        % dispersion object 'disp'
        function self = applyProcessFunctionToSingleDisp(self,disp,fitpar)
            % keep track of the index of each model, for convenience
            selfindex = num2cell(1:length(self),1);
            % update the main model
            self = wrapSubModelList(self);
%             self.subModel = arrayfun(@(mod)evaluateStartPoint(mod,disp.x,disp.y),self.subModel);
            self = gatherBoundaries(self);            
            % perform the calculations
            selfCell = arrayfun(@(d2e,i) process(d2e,disp,fitpar,i),self,selfindex,'Uniform',0);
            self = [selfCell{:,:}];
            % store the results in the dispersion object
            disp.model = self.model;
            disp.subModel = self.subModel;
        end
        
        % function that applies a list of processing objects to a list of
        % dispersion objects. The result is a table of processing objects.
        function self = applyProcessFunction(self,disp,fitpar)
            selfCell = arrayfun(@(d) applyProcessFunctionToSingleDisp(self,d,fitpar),disp,'Uniform',0);
            self = [selfCell{:,:}];
        end
        
        % evaluate the function over the range of values provided by the
        % array x
        function y = evaluate(self,x)
            y = evaluate(self.model,x);
        end
        
        % evaluate n points from x1 to x2, for easy and nice plotting
        function y = evaluateRange(self,x1,x2,n)
            y = evaluateRange(self.model,x1,x2,n);
        end
        
        
        % TO DO
        function exp = makeExp(self,disp)
            % generate the x-axis for the experiments (needs user input)
            
            % perform the fits (if needs be)
            
            % make the Exp object
            exp = [];
        end
        
    end
    
end