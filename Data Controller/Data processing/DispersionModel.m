classdef DispersionModel
    
    properties (Abstract)
        modelName;        % character string, name of the model, as appearing in the figure legend
        modelEquation;    % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
        variableName;     % List of characters, name of the variables appearing in the equation
        parameterName;    % List of characters, name of the parameters appearing in the equation
        isFixed;          % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit. 
        minValue;         % array of values, minimum values reachable for each parameter, respective to the order of parameterName
        maxValue;         % array of values, maximum values reachable for each parameter, respective to the order of parameterName
        startPoint;       % array of values, starting point for each parameter, respective to the order of parameterName 
    end
    properties
        modelHandle;      % function handle that refers to the equation, or to any other function defined by the user
        bestValue;        % array of values, estimated value found from the fit.
        errorBar;         % 2 x n array of values, provide the 95% confidence interval on the estimated fit values (lower and upper errors)
        gof;              % structure that contains all the info required about the goodness of fit
        fitobj;           % fitting object created after the model is used for fitting.
        
        % Additional display models custom defined by the user
        submodels@DispersionModel;  % Visualisation functions user-defined to simplify the analysis of the fit results (TODO)
    end
    
    methods
        % constructor
        function self = DispersionModel(varargin)
            for i = 1:2:length(varargin)
                if isprop(model,varargin{i})
                    self.(varargin{i}) = varargin{i+1};
                end
            end
            % set the default values for all the fields
            if isempty(self.modelName)
                warning('Model name not assigned. Please provide a name to the model, using the field ''modelName'' in the m-file. Choosing a random name.')
                self.modelName = ['Model ' num2str(round(1e9*rand(1,1)))];
            end
            if isempty(self.modelEquation)
                if isempty(self.modelHandle)
                    error('Equation not provided. You must provide an equation to the model using the field ''modelEquation'' in the m-file.')
                else
                    self.modelEquation = func2str(self.modelHandle);
                end
            end
            if isempty(self.modelHandle)
                self = makeFunctionHandle(self);
            end
            if isempty(self.variableName)
                warning('Variable name missing. Assuming it is the last input. Please add its name to the field ''variableName''.')
                handleStr = func2str(self.modelHandle);
                ind = strfind(handleStr,')');
                inputList = handleStr(1:ind(1)); % isolate the @(...) part
                ind = strfind(handleStr,',');
                self.variableName = {inputList(ind+1:end-1)}; % and get the last input
            end
            if ~iscell(self.variableName)
                self.variableName = {self.variableName};
            end
            if isempty(self.parameterName)
                warning('Parameters names missing, using random names. Please add them to the field ''parameterName''.')
                for i = 2:length(nargin(self.modelHandle))
                    self.parameterName{i-1} = ['param' num2str(i)];
                end
            end
            if isempty(self.isFixed)
                self.isFixed = zeros(size(self.parameterName));
            end
            if isempty(self.minValue)
                self.minValue = -Inf*ones(size(self.parameterName));
            end
            if isempty(self.maxValue)
                self.minValue = Inf*ones(size(self.parameterName));
            end
            if isempty(self.startPoint)
                self.startPoint = rand(size(self.parameterName));
            end
        end
        
        % generate the function handle for the fit model. The format is
        % as follows:
        % f = @(parameter_list,variable_name) function_string
        % where parameter_list is an array with the same length as
        % self.parameterName
        % this operation adds all the contributions from the subModel list,
        % recursively.
        function self = makeFunctionHandle(self)
             % check for element-wise operators
            opList = {'^','*','/'};
            for indParam = 1:length(opList)
                op = opList{indParam};
                pos = regexp(self.modelEquation,['[^.]\' op]); % find when the operators are not preceded by a dot
                % make the replacements
                for indsub = length(pos):-1:1
                    self.modelEquation = [self.modelEquation(1:pos(indsub)) '.' self.modelEquation(pos(indsub)+1:end)];
                end
            end
            % make sure we do not repeat the @(...) section
            if ~isequal(self.modelEquation(1),'@')
                str = '@(';
                for i = 1:length(self.parameterName) % written as a list for future-proofing multi-variables models
                    if i>1
                        str(end+1) = ',';
                    end
                    str = [str self.parameterName{i} ]; %#ok<*AGROW>
                end
                for i = 1:length(self.variableName) % written as a list for future-proofing multi-variables models
                    str = [str ',' self.variableName{i} ]; %#ok<*AGROW>
                end
                str = [str ') '];
            end
            % build the string expression
            str = [str self.modelEquation];
            self.modelHandle = str2func(str);
        end
        
        % provide the list of input names
        function varName = listInputNames(self)
            str = func2str(self.modelHandle);
            ind = strfind(str,')');
            str = str(3:ind(1)-1);
            ind = strfind(str,',');
            for i = length(ind):-1:1
                varName{i+1} = str(ind(i)+1:end);
                str(ind(i):end) = [];
            end
            varName{1} = str;
        end
        
        % function that allows estimating the start point. It should be 
        % over-riden by the derived classes
        function self = evaluateStartPoint(self,x,y) %#ok<INUSD>
            
        end
        
        % evaluate the function over the range of values provided by the
        % array x
        function y = evaluate(self,x)
            y = self.modelHandle(self.bestValue,x);
        end
        
        % evaluate n points from x1 to x2, for easy and nice plotting
        function y = evaluateRange(self,x1,x2,n)
            x = logspace(log10(x1),log10(x2),n);
            y = evaluate(self,x);
        end
        
    end
end