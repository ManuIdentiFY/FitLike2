classdef BiexponentialT1 < Zone2Disp & DataFit
%MONOEXP Compute the 1-exponential decay model. The function is based on a
%non-linear regression using iterative least-squares estimation and returned the
%time constant of the equation y = f(x) with its error as well as the model used.
    properties
        InputChildClass@char; 	% defined in DataUnit2DataUnit
        OutputChildClass@char;	% defined in DataUnit2DataUnit
        functionName@char = 'Biexponential fit';      % character string, name of the model, as appearing in the figure legend
        labelY@char = 'R_1 (s^{-1})';                   % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution field (MHz)';          % string, labels the X-axis data in graphs
        legendTag@cell = {'Long T1','Short T1'};
    end
    
    properties
       modelName = 'Biexponential T1';          % character string, name of the model, as appearing in the figure legend
       modelEquation = 'abs(M0 + A1*exp(-t*R11) + A2*exp(-t*R12))';      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
       variableName = {'t'};                                  % List of characters, name of the variables appearing in the equation
       parameterName = {'M0','A1','R11','A2','R12'};        % List of characters, name of the parameters appearing in the equation
       isFixed = [0 0 0 0 0];                               % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
       minValue = [-Inf -Inf -Inf -Inf -Inf];               % array of values, minimum values reachable for each parameter, respective to the order of parameterName
       maxValue = [Inf Inf Inf Inf Inf];               % array of values, maximum values reachable for each parameter, respective to the order of parameterName
       startPoint = [1 1 1 1 1];             % array of values, starting point for each parameter, respective to the order of parameterName
       valueToReturn = [0 0 1 0 1];          % set which fit parameters must be returned by the function
       visualisationFunction@cell = {};
   end
    
    methods
        function this = BiexponentialT1
            % call superclass constructor
            this = this@Zone2Disp;
            this = this@DataFit;
        end
    end
    
    methods
        % fill in the starting point of the model
        function this = evaluateStartPoint(this, xdata, ydata)  
            ydata = abs(ydata);
            this.startPoint = [ydata(end),...
                               (ydata(1)-ydata(end))*2/3,...
                               3/xdata(end),...
                               (ydata(1)-ydata(end))/3,...
                               10/xdata(end)];
        end %evaluateStartPoint
    end

    
end

