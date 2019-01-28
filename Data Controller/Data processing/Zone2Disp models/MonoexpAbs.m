classdef MonoexpAbs < Zone2Disp & DataFit
%MONOEXP Compute the 1-exponential decay model. The function is based on a
%non-linear regression using iterative least-squares estimation and returned the
%time constant of the equation y = f(x) with its error as well as the model used.
    properties
        InputChildClass@char;
        OutputChildClass@char;
        functionName@char = 'Monoexponential Abs fit';      % character string, name of the model, as appearing in the figure legend
        labelY@char = 'R_1 (s^{-1})';                   % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution field (MHz)';          % string, labels the X-axis data in graphs
        legendTag@cell = {'T1'};
    end
    
    properties
       modelName = 'AbsMonoexponential T1';          % character string, name of the model, as appearing in the figure legend
       modelEquation = ['sqrt(((M0-Minf)*exp(-x*R1)+Minf).^2 +'...
                                 '2*((M0-Minf)*exp(-x*R1)+Minf).*abs(noise) +'...
                                 '2*noise.^2);'];      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
       variableName = {'t'};                                  % List of characters, name of the variables appearing in the equation
       parameterName = {'M0','Minf','R1','noise'};        % List of characters, name of the parameters appearing in the equation
       isFixed = [0 0 0 0];                               % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
       minValue = [-Inf -Inf -Inf -Inf];               % array of values, minimum values reachable for each parameter, respective to the order of parameterName
       maxValue = [Inf Inf Inf Inf];               % array of values, maximum values reachable for each parameter, respective to the order of parameterName
       startPoint = [1 1 1 1];             % array of values, starting point for each parameter, respective to the order of parameterName
       valueToReturn = [0 0 1 0];          % set which fit parameters must be returned by the function
       visualisationFunction@cell = {};
    end

    methods
        function this = MonoexpAbs
            % call superclass constructor
            this = this@Zone2Disp;
            this = this@DataFit;
        end
    end
    
    methods
        % fill in the starting point of the model
        function this = evaluateStartPoint(this, xdata, ydata)
            ydata = abs(ydata);
            this.startPoint = [ydata(1), -ydata(end), 4/xdata(end), min(ydata)/2];
        end
    end %evaluateStartPoint

    
end

