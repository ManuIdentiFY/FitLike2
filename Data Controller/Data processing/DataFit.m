classdef DataFit < DataModel
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
        
        % Additional display models custom-defined by the user. It must use
        % the same parameters and variable names as the main function.
        visualisationFunction@cell;  % Visualisation functions user-defined to simplify the analysis of the fit results
    end
    
    methods
        function obj = DataFit()
            %DATAFIT Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        % fill in the starting point of the model
        function self = evaluateStartPoint(self)
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

