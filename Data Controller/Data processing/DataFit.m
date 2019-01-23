classdef DataFit < ProcessDataUnit%DataModel
    %DATAFIT Summary of this class goes here
    %   Detailed explanation goes here
    
    
    properties (Abstract)
        modelName;          % character string, name of the model, as appearing in the figure legend
        modelEquation;      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
        variableName;  % List of characters, name of the variables appearing in the equation
        parameterName; % List of characters, name of the parameters appearing in the equation
        isFixed;            % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit. 
        minValue;           % array of values, minimum values reachable for each parameter, respective to the order of parameterName
        maxValue;           % array of values, maximum values reachable for each parameter, respective to the order of parameterName
        startPoint;         % array of values, starting point for each parameter, respective to the order of parameterName 
    end
    
    properties
        modelHandle;      % function handle that refers to the equation, or to any other function defined by the user
        bestValue;        % array of values, estimated value found from the fit.
        errorBar;         % 2 x n array of values, provide the 95% confidence interval on the estimated fit values (lower and upper errors)
        gof;              % structure that contains all the info required about the goodness of fit
        fitobj;           % fitting object created after the model is used for fitting.
        solver@FitAlgorithm
        
        % Additional display models custom-defined by the user. It must use
        % the same parameters and variable names as the main function.
        visualisationFunction@cell;  % Visualisation functions user-defined to simplify the analysis of the fit results
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
        function [this, new_data] = applyProcess(this, data)
            % check data and format them
            % TO COMPLETE
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
            [this.bestValue, this.errorBar, this.gof] = applyFit(this.solver,...
                                    fun, xdata, ydata, dydata, x0, lb, ub);
            
            % gather data and make output structure
            new_data = formatFitData(this);
        end %applyProcess
           
        % format output fit data. Default is empty
        function new_data = formatFitData(this)
            new_data = [];
        end %formatFitData
        
        % generate the function handle for the fit model. The format is
        % as follows:
        % f = @(parameter_list,variable_name) function_string
        % where parameter_list is an array with the same length as
        % self.parameterName
        % this operation adds all the contributions from the subModel list,
        % recursively.
        function this = makeFunctionHandle(this)
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
        function fhfixed = setFixedParameter(this, fh) %#ok<INUSD>
            paramlist = '';
            n = 0;
            for i = 1:length(this.isFixed)
                if ~this.isFixed(i)
                    n = n+1;
                    paramlist = [paramlist 'c(' num2str(n) ')'];
                else
                    paramlist = [paramlist num2str(this.startPoint(i))];
                end
                if i ~=length(this.isFixed)
                    paramlist = [paramlist ','];
                end
            end
            fhfixed = eval(['@(c,x) fh([' paramlist '],x)']);
        end
        
        % fill in the starting point of the model
        function this = evaluateStartPoint(this, xdata, ydata)
        end
        
        % evaluate the function over the range of values provided by the
        % array x
        function y = evaluate(this,x)
            y = this.modelHandle(this.bestValue,x);
        end
        
        % evaluate n points from x1 to x2, for easy and nice plotting
        function y = evaluateRange(this,x1,x2,n)
            x = logspace(log10(x1),log10(x2),n);
            y = evaluate(this,x);
        end
        
        function numberOfInputs(this)
        end
        
        function numberOfOutputs(this)
        end
    end
end

