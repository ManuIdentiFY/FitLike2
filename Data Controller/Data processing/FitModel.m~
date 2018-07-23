classdef FitModel
    
    properties
        
        modelName = '';        % character string, name of the model, as appearing in the figure legend
        modelEquation = '';    % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
        modelHandle;           % function handle that refers to the equation, or to any other function defined by the user
        variableName = {};     % List of characters, name of the variables appearing in the equation
        parameterName = {};    % List of characters, name of the parameters appearing in the equation
        isFixed = {};          % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit. 
        minValue = {};         % array of values, minimum values reachable for each parameter, respective to the order of parameterName
        maxValue = {};         % array of values, maximum values reachable for each parameter, respective to the order of parameterName
        startPoint = {};       % array of values, starting point for each parameter, respective to the order of parameterName 
        bestValue = {};        % array of values, estimated value found from the fit.
        errorBar = {};         % 2 x n array of values, provide the 95% confidence interval on the estimated fit values (lower and upper errors)
        fitobj = [];           % fitting object created after the model is used for fitting.
    end
    
    methods
        function self = FitModel(varargin)
            for i = 1:2:length(varargin)
                if isprop(model,varargin{i})
                    self.(varargin{i}) = varargin{i+1};
                end
            end
        end
        
        function self = makeFunctionHandle(self)
            % build the string expression
            str = '@(';
            for i = 1:length(self.variableName)
                str = [str, self.variableName{i} ]; %#ok<AGROW>
            end
            
            for i = 1:length(self.parameterName)
                str = [str ',' self.parameterName{i}]; %#ok<AGROW>
            end
            str = [str ') ' self.modelEquation];
            % make the function handle with all variables and parameters:
            self.modelHandle = str2func(str);
            % check for element-wise operators
            % TO DO (find ^ without preceding dots, replace by .^, same for others such as / or *)
        end
        
        % provides the estimations of the model at points x, using the
        % current parameters
        function y = evalModel(self,x)
            y = self.modelHandle(x,self.bestValue{:});
        end
        
        function newObj = addModel(self,other)
            if length(other)>1
                newObj = self;
                for ind = 1:length(other)
                    newObj = addModel(newObj,other(ind));
                end
            else
                newObj = FitModel('modelName',       [self.modelName ' + ' other.modelName],...
                                  'modelEquation',   [func2str(self.modelHandle) ' + '  func2str(other.modelHandle)],...
                                  'modelHandle',     
                newObj.variableName = {};   
                newObj.parameterName = {};  
                newObj.isFixed = {};        
                newObj.minValue = {};       
                newObj.maxValue = {};       
                newObj.startPoint = {};     
                newObj.bestValue = {};      
                newObj.errorBar = {};       
            end
        end
    end
end