classdef Disp2Exp < ProcessDataUnit
    
    % this class performs the fit over the dispersion data. Several
    % contributions can be added together by using an array of object, each
    % one containing a different component.
    % Performing the fit is done using the function applyProcessFunction,
    % then the result can be used to generate an Experiment object if
    % required (using makeExp).
    
    properties
%         functionHandle % function handle that points to the processing function. 
                       % By default, it is the 'process' function within this object 
                       % but this may be modified by the user to use a custom-made 
                       % processing function.
        modelName = '';        % character string, name of the model, as appearing in the figure legend
        modelEquation = '';    % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
        subModel = [];         % array of other models to add up to the model equation, when making sums of models
        modelHandle;           % function handle that refers to the equation, or to any other function defined by the user
        variableName = {};     % List of characters, name of the variables appearing in the equation
        parameterName = {};    % List of characters, name of the parameters appearing in the equation
        isFixed = [];          % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit. 
        minValue = [];         % array of values, minimum values reachable for each parameter, respective to the order of parameterName
        maxValue = [];         % array of values, maximum values reachable for each parameter, respective to the order of parameterName
        startPoint = [];       % array of values, starting point for each parameter, respective to the order of parameterName 
        bestValue = [];        % array of values, estimated value found from the fit.
        errorBar = [];         % 2 x n array of values, provide the 95% confidence interval on the estimated fit values (lower and upper errors)
        gof = [];              % goodness of fit values provided from the fit algorithm
    end
    
    methods
        
        function self = Disp2Exp(varargin)
            self@ProcessDataUnit;
            if isempty(self.isFixed)
                self.isFixed = zeros(size(self.parameterName));
            end
            if isempty(self.startPoint)
                self.startPoint = zeros(size(self.parameterName));
            end
            if isempty(self.bestValue)
                self.bestValue = zeros(size(self.parameterName));
            end
        end
         
        % generate the function handle for the fit model. The format is
        % as follows:
        % f = @(variable_name, parameter_list) function_string
        % where parameter_list is an array with the same length as
        % self.parameterName
        % this operation adds all the contributions from the subModel list,
        % recursively.
        function self = makeFunctionHandle(self)
            % check for element-wise operators
            % TO DO (find ^ without preceding dots, replace by .^, same for others such as / or *)
            opList = {'^','*','/'};
            for indParam = 1:length(opList)
                op = opList{indParam};
                pos = regexp(self.modelEquation,['[^.]\' op]); % find when the operators are not preceded by a dot
                % make the replacements
                for indsub = length(pos):-1:1
                    self.modelEquation = [self.modelEquation(1:pos(indsub)) '.' self.modelEquation(pos(indsub)+1:end)];
                end
            end
            % build the string expression
            str = '@(param,';
            for i = 1:length(self.variableName) % written as a list for future-proofing multi-variables models
                str = [str, self.variableName{i} ];
            end
            str = [str ') ' self.modelEquation];
            % replace each parameter by the param array
            for indParam = 1:length(self.parameterName)
                pos = regexp(str,['\W?' self.parameterName{indParam} '\W?']);
                for indsub = length(pos):-1:1
                    str = [str(1:pos(indsub)) 'param(' num2str(indParam) ')' str(pos(indsub)+length(self.parameterName{indParam})+1 :end)];
                end
            end
            % finally, add the contributions of the sub-models
            % (recursively)
            for indSubModel = 1:length(self.subModel)
                % generate a handle for the component
                self.subModel(indSubModel) = makeFunctionHandle(self.subModel(indSubModel));
                % modify the parameter indexing to fit the new model
                substr = func2str(self.subModel(indSubModel).modelHandle);
                for indsub = 1:length(self.subModel(indSubModel).parameterName)
                    indParam = indParam +1;
                    substr = strrep(substr,['param(' num2str(indsub) ')'], ['param(' num2str(indParam) ')']);
                end
                % change the variable name for consistency
                for indVar = 1:length(self.variableName)
                    pos = regexp(substr,['\W?' self.subModel(indSubModel).variableName{indVar} '\W?']);
                    for indsub = length(pos):-1:1
                        substr = [substr(1:pos(indsub)) self.variableName{indVar} substr(pos(indsub)+length(self.subModel(indSubModel).variableName{indVar})+1 :end)];
                    end
                end
                % remove the @()
                pos = strfind(substr,')');
                substr = substr(pos+1:end);
                % add the two models together
                str = [str ' + ' substr];
            end
            % make the function handle with all variables and parameters:
            self.modelHandle = str2func(str);
%             self.modelHandle = eval(str); % str2func does not work in this case
        end        
        
        % the function above can be greatly simplified by wrapping function
        % handles (TODO)
        function self = makeFunctionHandle2(self)
            
        end
        
        % update the sub models with the best fit values
        function self = updateSubModel(self,bestValue,errorBar,gof)
            indStart = 1;
            indLim = length(self.parameterName);
            self.bestValue = bestValue(indStart:indLim); % update the values corresponding to the model in the current object
            self.errorBar = errorBar(indStart:indLim);
            self.gof = gof;
            for indsub = 1:length(self.subModel) % otherwise, pass the other values to the corresponding submodel
                indStart = indLim + 1;
                indLim = indLim + length(self.subModel(indsub).parameterName);
                self.subModel(indsub) = updateSubModel(self.subModel(indsub),...
                                                       bestValue(indStart:indLim),...
                                                       errorBar(indStart:indLim),...
                                                       gof);
            end
        end
        
        % make a list of all the names of the parameters used in the model,
        % to facilitate display
        function paramNames = gatherParameterNames(self)
            paramNames = self.parameterName;
            for i = 1:length(self.subModel)
                paramNames = [paramNames gatherParameterNames(self.subModel(i))]; 
            end
        end
        
        % make a list of all the boudaries for each parameter
        function [lowVal,highVal,startVal,fixedVal] = gatherBoundaries(self)
            lowVal = self.minValue(:)';
            highVal = self.maxValue(:)';
            startVal = self.startPoint(:)';
            fixedVal = self.isFixed(:)';
            for i = 1:length(self.subModel)
                [lv,hv,sv,fv] = gatherBoundaries(self.subModel(i));
                lowVal = [lowVal, lv(:)']; %#ok<*AGROW>
                highVal = [highVal, hv];
                startVal = [startVal, sv];
                fixedVal = [fixedVal, fv];
            end
        end
        
        % provide a function handle that is the sum of all the function
        % handles in the model and subModel list
        function fh = addModel(self,subModel)
            self.subModel(end+1) = subModel;
            self = makeFunctionHandle(self); % update the function handles
        end
        
        % sets a function handle into the log space
        % fhlog = log10(fh)
        function fhlog = makeLogFunction(self)
            par = functions(self.modelHandle);
            ind = strfind(par.function,')');
            inputList = par.function(3:ind(1)-1);
            fhandle = self.modelHandle;
            fhlog = eval(['@(' inputList ') log10(fhandle(' inputList '))']); % str2func won't work here...
%             fhlog = str2func(['@(' inputList ') log10(fh(' inputList '))']);
        end
        
        % function that applies a list of processing objects for one
        % dispersion object 'disp'
        function self = applyProcessFunction(self,disp,fitpar)
            % keep track of the index of each model, for convenience
            dispindex = num2cell(1:length(disp),1);
            self = arrayfun(@(x,i) process(x,disp,fitpar,i),self,dispindex,'Uniform',0);
        end
        
        % perform the fit from the sum of all contributions on a single
        % Disp object
        function self = process(self,dispersion,fitpar,index)
            % update the function handles
            self = makeFunctionHandle(self);
            % apply the model to the object in the log space
            fhlog = makeLogFunction(self);
            
            % prepare the fit parameter structure
            fitpar.fh = self.modelHandle;
            fitpar.var = self.variableName;
            [fitpar.low,fitpar.high,fitpar.start,fitpar.fixed] = gatherBoundaries(self);
            opts = statset('nlinfit');
            opts.Robust = 'on'; 
            
            % perform the fit
            x = dispersion.x;
            y = dispersion.y;
            [coeff,residuals,~,cov,MSE] = nlinfit(x,squeeze(y)',fhlog,fitpar.start,opts); %non-linear least squares fit

            % Goodness of fit
            sst = sum((y-mean(y)).^2); %sum of square total
            sse = sum(residuals.^2); %sum of square error
            nData = length(y); 
            nCoeff = length(coeff); 

            gof.rsquare =  1 - sse/sst; 
            gof.adjrsquare = 1 - ((nData-1)/(nData - nCoeff))*(sse/sst); 
            gof.RMSE = sqrt(MSE); %to normalize for comparison
            % Error model computation (95% of the confidence interval)
            try
                ci = nlparci(coeff,residuals,'covar',cov);
            catch ME
                disp(ME.message)
                ci = nan(size(coeff(3)));
            end
            coeffError = coeff' - ci(:,1);
            % Dispersion data
            self.bestValue = coeff; %get the relaxation rate
%             self.errorBar = coeffError; %get the model error on the relaxation rate
%             % Gather the result and store it in the corresponding submodel
            self = updateSubModel(self,coeff,coeffError,gof);
        end
        
        % evaluate the function over the range of values provided by the
        % array x
        function y = evaluate(self,x)
            y = self.modelHandle(x,self.bestValue);
        end
        
        % evaluate n points from x1 to x2
        function y = evaluateRange(self,x1,x2,n)
            x = logspace(log10(x1),log10(x2),n);
            y = evaluate(self,x);
        end
        
        
        % TO DO
        function exp = makeExp(self,disp)
            % generate the x-axis for the experiments (needs user input)
            
            % perform the fits (if needs be)
            
            % make the Exp object
            
        end
        
    end
    
end